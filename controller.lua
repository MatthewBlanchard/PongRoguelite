Controller = Object()

function Controller:__new(game, character)
	self.game = game
	self.character = character
	self.goalPos = 0.5
end

function Controller:isStriking()
	return false
end

function Controller:constrainGoalPosition(goalPos)
	local paddle = self.paddle

	return math.min(
		math.max(paddle.AABB.halfExtents.y, goalPos),
		self.game.fieldSize.y - paddle.AABB.halfExtents.y
	)
end

PlayerController = Controller()

function PlayerController:mousemoved(dx, dy)
	local moveDelta = dy / love.graphics.getHeight()
	self.goalPos = self:constrainGoalPosition(self.goalPos + moveDelta)
end

function PlayerController:getGoalPosition(dt)
	return self.goalPos
end

function PlayerController:isStriking()
	return love.mouse.isDown(1)
end

DualPlayerController = PlayerController()

function DualPlayerController:getGoalPosition(dt)
	if self.paddle.offHand then
		self.goalPos = math.abs(self.goalPos - .5) + .5
		return self.goalPos
	end

	return self.goalPos
end

function DualPlayerController:constrainGoalPosition(goalPos)
	local paddle = self.paddle

	return math.min(
		math.max(paddle.AABB.halfExtents.y, goalPos),
		self.game.fieldSize.y/2 - paddle.AABB.halfExtents.y
	)
end

ThrowingPlayerController = PlayerController()

function ThrowingPlayerController:__new(game, character)
	Controller.__new(self, game, character)
	self.waitingFlight = false
end

function ThrowingPlayerController:mousemoved(dx, dy)
	local moveDelta = dy / love.graphics.getHeight()
	self.goalPos = self:constrainGoalPosition(self.goalPos + moveDelta)
end

function ThrowingPlayerController:getGoalPosition(dt)
	if self.paddle.inFlight then
		self.goalPos = self.paddle.AABB.position.y
	end

	return self.goalPos
end

AIController = Controller()

function AIController:__new(game, character)
	Controller.__new(self, game, character)
	self.goalPos = .5
	self.predictedGoalPos = .5
	self.goalPos = .5
	self.predicted = false
	self.state = AIController.waitState
	self.striking = false
end

function AIController:predictBallPosition(untilTime)
	-- I know this looks like crap but I think it's slightly more readable this
	-- way
	local fieldY = self.game.fieldSize.y

	local paddleXPos = self.paddle.AABB.position.x

	local ball = self.game.ball
	local ballXPos = self.game.ball.AABB.position.x
	local ballYPos = self.game.ball.AABB.position.y
	local ballYVelocity = self.game.ball.velocity.y

	local ballYDiff = ballYPos
	local ballYMovedInTTP = ballYPos + untilTime * ballYVelocity

	while not (ballYVelocity == 0) do
		local fieldEdge = ballYVelocity > 0 and fieldY - ball:getSize().y or 0 + ball:getSize().y
		local diffToFieldEdge = fieldEdge - ballYDiff
		local timeToFieldEdge = diffToFieldEdge/ballYVelocity

		if timeToFieldEdge > untilTime then
			ballYPos = ballYDiff + untilTime * ballYVelocity
			break
		end

		ballYMovedInTTP = ballYMovedInTTP - timeToFieldEdge * ballYVelocity
		untilTime = untilTime - timeToFieldEdge

		ballYVelocity = -ballYVelocity
		ballYDiff = fieldEdge
	end
	
	return ballYPos
end

function AIController:predictGoalPosTime()
	local springTightness = self.paddle.springTightness
	local springDamping = self.paddle.springDamping
	local mass = self.paddle.mass
	local position = Vector2(self.paddle.AABB.position.x, self.paddle.AABB.position.y)
	local extent = self.paddle.AABB.halfExtents.y
	local velocity = self.paddle.velocity.y
	local goalPos = self.goalPos

	local dir = direction(self.predictedGoalPos, position.y)
	local comp = dir == 1 and math.max or math.min

	local t = 0
	local ht = 0
	local dt = 1/100
	while not (comp(position.y, self.predictedGoalPos) == self.predictedGoalPos) do
		local paddleHalfPos = comp(position.y + extent * dir, self.predictedGoalPos)
		if ht == 0 and paddleHalfPos == self.predictedGoalPos then
			ht = t + dt
		end

		position.y = position.y + velocity * dt

		local moveDelta = direction(goalPos, self.predictedGoalPos) * self.character.trackSpeed * dt
		moveDelta = clampMagnitude(moveDelta, distance(goalPos, self.predictedGoalPos))

		goalPos = goalPos + moveDelta
		local moveDelta = position.y - goalPos
		local moveDir = sign(moveDelta)

		local vel = velocity * moveDir

		force = springDamper(
			springTightness, math.abs(moveDelta),
			springDamping, vel
		) * moveDir
		local accel = force/mass

		velocity = velocity + accel  * dt
		t = t+dt
	end

	return t
end

function AIController:getGoalPosition(dt)
	if self:getTimeToPaddle() > 0 then
		if not self.predicted then
			self.predicted = true
			self.predictedGoalPos = self:constrainGoalPosition(self:predictBallPosition(self:getTimeToPaddle()))
		end
	elseif self.predicted then
		self.predicted = false
		self.hasStruck = false
	end

	return self.state(self, dt)
end

function AIController:onHit(ball)
	self.state = self.waitState
end

function AIController:waitState(dt)
	if not self.waitActivity then
		self.waitPos = self.paddle.AABB.position.y
		self.waitActivity = self.character.waitActivity(self.paddle.AABB.position.y)
	end

	self.predictedTimeToGoalPos = self:predictGoalPosTime()
	self.goalPos = self:constrainGoalPosition(self.paddle.AABB.position.y + self.waitActivity(dt))
	
	if self:getTimeToPaddle() < self:predictGoalPosTime() and self:getTimeToPaddle() > 0 then
		self.state = self.seekState
		self.waitActivity = nil
		return self:seekState(dt)
	else
		return self.goalPos
	end
end

function AIController:seekState(dt)
	local moveDelta = direction(self.goalPos, self.predictedGoalPos) * self.character.trackSpeed * dt
	moveDelta = clampMagnitude(moveDelta, distance(self.goalPos, self.predictedGoalPos))
	self.goalPos = self.goalPos + moveDelta
	return self.goalPos
end

function AIController:isStriking(dt)
	local ttp = self:getTimeToPaddle()

	if ttp < 0 then
		self.hasStruck = false

		if self.willStrike == false then
			self.willStrike = nil
		end
	end

	if self.willStrike == nil and ttp > 0 then
		local r = randBiDirectional()
		self.willStrike = r > 0
	end

	if not self.strikeDelay and self.willStrike and not self.hasStruck and ttp > 0 then
		self.hasStruck = true
		self.strikeTimer = timer(randBiDirectional()*.05 + ttp)
	elseif self.strikeTimer and self.strikeTimer(dt) then
		self.strikeTimer = nil
		self.willStrike = nil
		self.striking = true
		return true
	end

	self.striking = false
	return false
end

function AIController:getTimeToPaddle()
	local dir = -direction(0, self.game.ball.velocity.x)
	local paddleXPos = self.paddle.AABB.position.x + self.paddle.AABB.halfExtents.x*dir
	local ballXPos = self.game.ball.AABB.position.x - self.game.ball.AABB.halfExtents.x*dir
	local ballXVelocity = self.game.ball.velocity.x
	local ballPaddlePosDiff = paddleXPos - ballXPos
	local ttp = math.abs(ballPaddlePosDiff/ballXVelocity)
	local sign = self:isBallIncoming(1) == true and 1 or -1

	return ttp*sign
end

function AIController:getTimeToXPos(xpos)
	local dir = -direction(0, self.game.ball.velocity.x)
	local ballXPos = self.game.ball.AABB.position.x - self.game.ball.AABB.halfExtents.x*dir
	local ballXVelocity = self.game.ball.velocity.x
	local xposDiff = xpos - ballXPos
	local ttp = math.abs(xposDiff/ballXVelocity)
	local sign = direction(0, ballXVelocity)
	local dirtoXPos = direction(ballXPos, xpos)

	return ttp*sign*dirtoXPos
end

function AIController:isBallIncoming(dt)
	local paddle = self.paddle
	local paddleSide = paddle.AABB.position.x - self.game.fieldSize.x/2
	return sign(self.game.ball.velocity.x) == sign(paddleSide)
end

FollowerAIController = AIController()

function FollowerAIController:__new(game, character)
	AIController:__new(game, character)
	self.following = false
	self.decidedFollowing = false
end

function FollowerAIController:getGoalPosition(dt)
	if self:getTimeToPaddle() > 0 and not self.decidedFollowing then
		self.following = math.random() > 0.5
		self.decidedFollowing = true
	elseif self:getTimeToPaddle() < 0 then
		self.decidedFollowing = false
	end

	if self.following then
		local moveDelta = direction(self.goalPos, self.game.ball:getPosition().y) * self.character.trackSpeed * dt
		moveDelta = clampMagnitude(moveDelta, distance(self.goalPos, self.game.ball:getPosition().y))
		self.goalPos = self.goalPos + moveDelta
		return self.goalPos
	else
		return self.goalPos
	end
end


function FollowerAIController:isStriking(dt)
	return false
end

DualAIController = AIController()

function DualAIController:__new(game, character)
	AIController.__new(self, game, character)
	self.goalPos = .5
	self.predictedGoalPos = .5
	self.predicted = false
	self.state = AIController.waitState
end

function DualAIController:constrainGoalPosition(goalPos)
	local paddle = self.paddle

	return math.min(
		math.max(paddle.AABB.halfExtents.y, goalPos),
		self.game.fieldSize.y/2 - paddle.AABB.halfExtents.y
	)
end

function DualAIController:isStriking(dt)
	if self.paddle.offHand then
		return self.paddle.parent.controller.striking
	end

	return AIController.isStriking(self, dt)
end

function DualAIController:onHit(ball)
	if self.paddle.offHand then
		self.paddle.parent.controller.state = self.waitState
	end

	self.state = self.waitState
end

function DualAIController:waitState(dt)
	if not self.waitActivity then
		self.waitPos = self.goalPos
		self.waitActivity = self.character.waitActivity(self.paddle.AABB.position.y)
	end

	self.predictedTimeToGoalPos = self:predictGoalPosTime()
	self.goalPos = self.waitPos + self.waitActivity(dt)
	
	if self:getTimeToPaddle() < self:predictGoalPosTime() and self:getTimeToPaddle() > 0 then
		self.state = self.seekState
		self.waitActivity = nil
		return self:seekState(dt)
	else
		return self.goalPos
	end
end

function DualAIController:getGoalPosition(dt)
	if self:getTimeToPaddle() > 0 then
		if not self.predicted then
			self.predicted = true
			self.predictedGoalPos = self:predictBallPosition()

			if self.predictedGoalPos > .5  and not self.paddle.offHand then
				self.predictedGoalPos = 1 - self.predictedGoalPos
			end

			self.predictedGoalPos = self:constrainGoalPosition(self.predictedGoalPos)
		end
	elseif self.predicted then
		self.predicted = false
		self.hasStruck = false
	end

	if self.paddle.offHand then
		self.goalPos = 1 - self.paddle.parent.controller.goalPos
		return self.goalPos
	end

	return self.state(self, dt)
end

ThrowingAIController = AIController()

function ThrowingAIController:getGoalPosition(dt)
	local timeToApex = self:getTimeToThrowApex()
	local heightofApex = self:getHeightOfApex()
	local ballTimeToApexHeight = self:getTimeToXPos(self.paddle.defaultX + heightofApex)

	if self:getTimeToPaddle() > 0 then
		if not self.predicted then
			self.predicted = true
			self.predictedGoalPos = self:constrainGoalPosition(self:predictBallPosition(ballTimeToApexHeight))
		end
	elseif self.predicted then
		self.predicted = false
		self.hasStruck = false
	end

	return self.state(self, dt)
end

function ThrowingAIController:predictGoalPosTime()
	return AIController.predictGoalPosTime(self) + self:getTimeToThrowApex()
end

function ThrowingAIController:waitState(dt)
	local heightofApex = self:getHeightOfApex()
	local goalTime = self:getTimeToXPos(self.paddle.defaultX + heightofApex)

	if not self.waitActivity then
		self.waitPos = self.paddle.AABB.position.y
		self.waitActivity = self.character.waitActivity(self.paddle.AABB.position.y)
	end

	self.predictedTimeToGoalPos = self:predictGoalPosTime()
	self.goalPos = self:constrainGoalPosition(self.paddle.AABB.position.y + self.waitActivity(dt))
	
	if goalTime < self:predictGoalPosTime() and self:getTimeToPaddle() > 0 then
		self.state = self.seekState
		self.waitActivity = nil
		return self:seekState(dt)
	else
		return self.goalPos
	end
end

function ThrowingAIController:isStriking(dt)
	local timeToApex = self:getTimeToThrowApex()
	local heightofApex = self:getHeightOfApex()
	local ballTimeToApexHeight = self:getTimeToXPos(heightofApex + self.paddle.defaultX)
	local ballYPosAtApexHeight = self:predictBallPosition(self:getTimeToXPos(self.paddle.defaultX + heightofApex))
	local paddleYPosAtApexHeight = self.paddle.AABB.position.y + self.paddle.velocity.y/2 * timeToApex

	if ballTimeToApexHeight < timeToApex then
		--print(paddleYPosAtApexHeight, ballYPosAtApexHeight, ballTimeToApexHeight, timeToApex)
	end

	if 	ballTimeToApexHeight < timeToApex and
		distance(ballYPosAtApexHeight, paddleYPosAtApexHeight) < self.paddle.AABB.halfExtents.y and
		self:getTimeToPaddle() > 0 
	then
		return true
	end
end

function ThrowingAIController:getThrowImpulse()
	return (self.paddle.throwForce*-self.paddle:getSide())/self.paddle.mass
end

function ThrowingAIController:getTimeToThrowApex()
	return self:getThrowImpulse()/6*-self.paddle:getSide()
end

function ThrowingAIController:getHeightOfApex()
	return 0.5 * self:getThrowImpulse()^2 / 6*-self.paddle:getSide()
end

--[[
summary:
time to apex: v/g (v being starting veloocity, g being gravity acceleration
apex height: 0.5 * v^2 / g
]]