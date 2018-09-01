Controller = Object()

function Controller:__new(game, character)
	self.game = game
	self.character = character
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

function PlayerController:getGoalPosition(dt)
	local mouseYtoGame = love.mouse.getY() / love.graphics.getHeight()
	self.goalPos = self:constrainGoalPosition(mouseYtoGame)
	return self.goalPos
end

function PlayerController:isStriking()
	return love.mouse.isDown(1)
end

AIController = Controller()

function AIController:__new(game, character)
	Controller.__new(self, game, character)
	self.goalPos = .5
	self.predictedGoalPos = .5
	self.goalPos = .5
	self.predicted = false
	self.state = AIController.waitState
end

function AIController:predictBallPosition()
	-- I know this looks like crap but I think it's slightly more readable this
	-- way
	local fieldY = self.game.fieldSize.y

	local paddleXPos = self.paddle.AABB.position.x

	local ballXPos = self.game.ball.AABB.position.x
	local ballYPos = self.game.ball.AABB.position.y
	local ballYVelocity = self.game.ball.velocity.y

	local ballYDiff = ballYPos
	local timeToPaddle = self:getTimeToPaddle()
	local ballYMovedInTTP = ballYPos + timeToPaddle * ballYVelocity

	while not (ballYVelocity == 0) do
		local fieldEdge = ballYVelocity > 0 and fieldY or 0
		local diffToFieldEdge = fieldEdge - ballYDiff
		local timeToFieldEdge = diffToFieldEdge/ballYVelocity

		if timeToFieldEdge > timeToPaddle then
			ballYPos = ballYDiff + timeToPaddle * ballYVelocity
			break
		end

		ballYMovedInTTP = ballYMovedInTTP - timeToFieldEdge * ballYVelocity
		timeToPaddle = timeToPaddle - timeToFieldEdge

		ballYVelocity = -ballYVelocity
		ballYDiff = fieldEdge
	end
	
	return self:constrainGoalPosition(ballYPos, self.paddle)
end

function AIController:predictGoalPosTime()
	local springTightness = self.paddle.springTightness
	local springDamping = self.paddle.springDamping
	local mass = self.paddle.mass
	local position = Vector(self.paddle.AABB.position.x, self.paddle.AABB.position.y)
	local extent = self.paddle.AABB.halfExtents.y
	local velocity = self.paddle.velocity
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
			self.predictedGoalPos = self:predictBallPosition()
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
		self.waitActivity = self.character.waitActivity(self.paddle.AABB.position.y)
	end

	self.predictedTimeToGoalPos = self:predictGoalPosTime()
	self.goalPos = self:constrainGoalPosition(self.waitActivity(dt))
	
	if self:getTimeToPaddle() < self:predictGoalPosTime() and self:getTimeToPaddle() > 0 then
		print(self:getTimeToPaddle(), self.predictedTimeToGoalPos)
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
		return true
	end

	return false
end

function AIController:getTimeToGoalPos()
	return math.abs((self.goalPos - self.predictedGoalPos)/self.character.trackSpeed)
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

function AIController:isBallIncoming(dt)
	local paddle = self.paddle
	local paddleSide = paddle.AABB.position.x - self.game.fieldSize.x/2
	return sign(self.game.ball.velocity.x) == sign(paddleSide)
end