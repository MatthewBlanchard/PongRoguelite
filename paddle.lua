Paddle = GameObject()

function Paddle:__new(game, AABB, strength, mass, k, b, swin, srec)
	GameObject.__new(self, game, AABB)

	if AABB then
		self.defaultX = AABB.position.x
	end

	self.color = {r = 1, g = 1, b = 1}
	self.strength = strength
	self.strikeWindow = swin
	self.strikeRecovery = srec

	self.mass = mass
	self.springTightness = k
	self.springDamping = b

	self.defaultState = DefaultState
	self.strikeState = StrikeState
	self.recoveryState = RecoveryState
	self.state = self.defaultState(self)
end

function Paddle:update(dt)
	self.state:update(dt)

	for k, child in pairs(self.children) do
		child.state:update(dt)
	end
end

function Paddle:draw()
	local goalPos = self.controller.goalPos or self.AABB.position.y
	local pgoalPos = self.controller.predictedGoalPos or 0
	local r, g, b

		local diffpos = self.defaultX - self.AABB.position.x
		love.graphics.push()
			local r, g, b = love.graphics.getColor()
			love.graphics.setColor(.1, .1, .1)
			love.graphics.translate(self.AABB.position.x, self.AABB.position.y)
			love.graphics.translate(diffpos, goalPos - self.AABB.position.y)
			self.AABB:draw()
			love.graphics.setColor(r, g, b)
		love.graphics.pop()
	
	local r, g, b = love.graphics.getColor()
	if self.state:is(StrikeState) then
		love.graphics.setColor(1, 0, 0)
	elseif self.state:is(RecoveryState) then
		love.graphics.setColor(.2, .2, .2)
	else
		love.graphics.setColor(self.color.r, self.color.g, self.color.b)
	end

	love.graphics.push()
		love.graphics.translate(self.AABB.position.x, self.AABB.position.y)
		love.graphics.rotate(self.rotation)
		self.AABB:draw()
	love.graphics.pop()

	if r and g and b then
		love.graphics.setColor(r, g, b)
	end

	for k, child in pairs(self.children) do
		child:draw(dt)
	end
end

function Paddle:setController(controller)
	self.controller = controller
	self.controller.paddle = self
end

function Paddle:setColor(color)
	self.color = color
end

function Paddle:integrate(dt, velMul)
	local velMul = velMul or 1

	self.AABB.position = self.AABB.position + self.velocity * velMul * dt
	self.velocity.y = self.velocity.y + self:getGoalPosSpringAcceleration(dt) * velMul * dt
	self.rotation = self.velocity.x*4

	self:handleBoardExtents(dt)
end

function Paddle:handleBoardExtents(dt)
	local pos = self.AABB.position
	local depth, moveDelta, moveDir, vel
	if pos.y + self.AABB.halfExtents.y > self.game.fieldSize.y then
		depth = distance(self.game.fieldSize.y, pos.y + self.AABB.halfExtents.y)
			
		moveDelta = self.game.fieldSize.y - (pos.y + self.AABB.halfExtents.y)
		moveDir = sign(moveDelta)
		vel = self.velocity.y * moveDir
	elseif pos.y - self.AABB.halfExtents.y < 0 then
		depth = distance(0, pos.y - self.AABB.halfExtents.y)

		moveDelta = 0 - (pos.y - self.AABB.halfExtents.y)
		moveDir = sign(moveDelta)
		vel = self.velocity.y * moveDir
	end

	if not depth then return end

	self.velocity.y = self.velocity.y + springDamperCollide(
		self.springTightness*10, depth,
		.5, vel,
		moveDir
	) / self.mass * dt
end

function Paddle:getSide()
	return direction(self.game.fieldSize.x/2, self.AABB.position.x)
end

function Paddle:getGoalPosSpringAcceleration(dt)
	local pos = self.AABB.position
	self.goalPos = self.controller:getGoalPosition(dt)

	local moveDelta = pos.y - self.goalPos
	local moveDir = sign(moveDelta)

	local vel = self.velocity.y * moveDir

	local force = springDamper(
		self.springTightness, math.abs(moveDelta),
		self.springDamping, vel
	) * moveDir


	return force/self.mass
end

function Paddle:onHit(ball)

	if self.state:is(StrikeState) then
		self.game:hitStop(.062)
	end

	if self.controller.onHit then
		self.controller:onHit(ball)
	end

	return self.state:hitResponse(ball)
end

function Paddle:onStrike(ball)
end

PaddleState = Object()

function PaddleState:__new(paddle)
	self.paddle = paddle
end

function PaddleState:hitResponse(ball)
	local paddle = self.paddle
	local pos = paddle.AABB.position
	local moveDirX = ball.velocity.x > 0 and -1 or 1
	local moveDirY = pos.y - paddle.goalPos > 0 and -1 or 1
	return Vector2(moveDirX, clamp(paddle.velocity.y, -1, 1))
end

DefaultState = PaddleState()

function DefaultState:update(dt)
	local paddle = self.paddle

	paddle:integrate(dt)


	if paddle.controller:isStriking(dt) then
		self.paddle:onStrike()
		paddle.state = paddle.strikeState(paddle)
	end
end


StrikeState = PaddleState()

function StrikeState:__new(paddle)
	PaddleState.__new(self, paddle)
	self.time = 0
end

function StrikeState:update(dt)
	local paddle = self.paddle

	paddle:integrate(dt)

	if self.time > paddle.strikeWindow then
		paddle.state = paddle.recoveryState(paddle)
	end

	self.time = self.time + dt
end

function StrikeState:hitResponse(ball)
	local paddle = self.paddle
	local pos = paddle.AABB.position
	local moveDirX = ball.velocity.x > 0 and -1 or 1

	return Vector2(moveDirX * paddle.strength, clamp(paddle.velocity.y, -1, 1))
end

RecoveryState = PaddleState()

function RecoveryState:__new(paddle)
	PaddleState.__new(self, paddle)
	self.time = 0
end

function RecoveryState:update(dt)
	local paddle = self.paddle

	paddle:integrate(dt, .2)

	if self.time > paddle.strikeRecovery then
		self.paddle.state = DefaultState(self.paddle)
	end

	self.time = self.time + dt
end

ThrowingPaddle = Paddle()

function ThrowingPaddle:__new(game, AABB, strength, mass, k, b, swin, srec, throw, airc)
	Paddle.__new(self, game, AABB, strength, mass, k, b, swin, srec)
	self.recoveryState = ThrowingRecoveryState
	self.strikeState = ThrowingStrikeState

	self.throwForce = throw
	self.airControl = airc
end

function ThrowingPaddle:integrate(dt, velMul)
	local velMul = velMul or 1

	self.AABB.position = self.AABB.position + self.velocity * velMul * dt

	if not self.inFlight then
		self.velocity.y = self.velocity.y + self:getGoalPosSpringAcceleration(dt) * velMul * dt
	else
		self.velocity.y = self.velocity.y + self:getGoalPosSpringAcceleration(dt) * velMul * dt * self.airControl
	end

	self.velocity.x = self.velocity.x + self:getHorizontalConstraintAcceleration(dt) * velMul * dt
	self.rotation = self.velocity.x*4

	self:handleBoardExtents(dt)
end


function ThrowingPaddle:getHorizontalConstraintAcceleration(dt)
	local pos = self.AABB.position

	local moveDelta = pos.x - self.defaultX
	local moveDir = sign(moveDelta)
	local side = self:getSide()

	if moveDir == self:getSide() then
		local vel = self.velocity.x * moveDir

		force = springDamper(
			self.springTightness*5, math.abs(moveDelta),
			self.springDamping*5, vel
		) * moveDir
	else
		force = self:getSide() * 6
	end

	return force/self.mass
end

function ThrowingPaddle:onStrike()
	self.velocity.x = self.velocity.x + self.throwForce * -self:getSide()/self.mass
	self.velocity.y = self.velocity.y/2
end

function ThrowingPaddle:handleBoardExtents(dt)
	local pos = self.AABB.position
	local st, sd = self.springTightness, self.springDamping

	local depth, moveDelta, moveDir, vel
	if pos.y + self.AABB.halfExtents.y > self.game.fieldSize.y then
		depth = distance(self.game.fieldSize.y, pos.y + self.AABB.halfExtents.y)
			
		moveDelta = self.game.fieldSize.y - (pos.y + self.AABB.halfExtents.y)
		moveDir = sign(moveDelta)
		vel = self.velocity.y * moveDir
	elseif pos.y - self.AABB.halfExtents.y < 0 then
		depth = distance(0, pos.y - self.AABB.halfExtents.y)

		moveDelta = 0 - (pos.y - self.AABB.halfExtents.y)
		moveDir = sign(moveDelta)
		vel = self.velocity.y * moveDir
	end

	if not depth then return end

	if self.inFlight then
		sd = sd * 5
	end

	self.velocity.y = self.velocity.y + springDamperCollide(
		st*10, depth,
		sd, vel,
		moveDir
	) / self.mass * dt
end

ThrowingStrikeState = StrikeState()

function ThrowingStrikeState:__new(paddle)
	PaddleState.__new(self, paddle)
	self.time = 0
	self.checkSide = direction(paddle.defaultX, paddle.AABB.position.x)

	if self.checkSide == 0 then
		self.checkSide = 1
	end
end

function ThrowingStrikeState:update(dt)
	local paddle = self.paddle
	local side = paddle:getSide()
	local checking

	paddle.inFlight = true

	paddle:integrate(dt)

	if self.checkSide == side and direction(paddle.defaultX, paddle.AABB.position.x) == -side then
		self.checkSide = -side
		checking = true
	elseif self.checkSide == -side then
		checking = true
	end

	if direction(paddle.defaultX, paddle.AABB.position.x) == side and checking then
		paddle.state = paddle.recoveryState(paddle)
	end
end

function ThrowingStrikeState:hitResponse(ball)
	local paddle = self.paddle
	local pos = paddle.AABB.position
	local moveDirX = ball.velocity.x > 0 and -1 or 1

	return Vector2(moveDirX * paddle.strength, clamp(paddle.velocity.y, -1, 1))
end

ThrowingRecoveryState = RecoveryState()

function ThrowingRecoveryState:__new(paddle)
	PaddleState.__new(self, paddle)
	self.time = 0
end

function ThrowingRecoveryState:update(dt)
	local paddle = self.paddle

	paddle.inFlight = false
	paddle:integrate(dt)

	if self.time > paddle.strikeRecovery then
		paddle.state = DefaultState(self.paddle)
	end

	self.time = self.time + dt
end

BowPaddle = Paddle()

BowStrikeState = StrikeState()

function BowStrikeState:__new(paddle)
	PaddleState.__new(self, paddle)
	self.time = 0
	self.checkSide = direction(paddle.defaultX, paddle.AABB.position.x)

	if self.checkSide == 0 then
		self.checkSide = 1
	end
end

function BowStrikeState:update(dt)
	local paddle = self.paddle
	local side = paddle:getSide()
	local checking

	paddle.inFlight = true

	paddle:integrate(dt)

	if self.checkSide == side and direction(paddle.defaultX, paddle.AABB.position.x) == -side then
		self.checkSide = -side
		checking = true
	elseif self.checkSide == -side then
		checking = true
	end

	if direction(paddle.defaultX, paddle.AABB.position.x) == side and checking then
		paddle.state = paddle.recoveryState(paddle)
	end
end

function BowStrikeState:hitResponse(ball)
	local paddle = self.paddle
	local pos = paddle.AABB.position
	local moveDirX = ball.velocity.x > 0 and -1 or 1

	return Vector2(moveDirX * paddle.strength, clamp(paddle.velocity.y, -1, 1))
end