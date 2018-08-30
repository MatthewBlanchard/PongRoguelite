Controller = Object()

function Controller:__new(game)
	self.game = game
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

AIController.goalPos = .5
AIController.predictedGoalPos = .5
AIController.goalPos = .5
AIController.error = .4
AIController.delay = .2
AIController.delayTimer = 0
AIController.predicted = false

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

local adjustStep = 1
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


	local moveDelta = direction(self.goalPos, self.predictedGoalPos) * adjustStep * dt
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
		self.strikeTimer = timer(randBiDirectional()*.05 + ttp-.2)
	elseif self.strikeTimer and self.strikeTimer(dt) then
		self.strikeTimer = nil
		self.willStrike = nil
		return true
	end

	return false
end

function AIController:getTimeToPaddle()
	local paddleXPos = self.paddle.AABB.position.x
	local ballXPos = self.game.ball.AABB.position.x
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