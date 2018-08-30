local function springDamper(k, x, b, v)
	return -k*x - b * v
end

local function springDamperCollide(k, x, b, v, n)
	return n * k * x - b * n * v
end

Paddle = Object()

function Paddle:__new(game, controller, AABB, strength, mass, k, b, swin, srec)
	self.game = game

	self.controller = controller
	self.controller.paddle = self

	self.AABB = AABB

	self.strength = strength
	self.strikeWindow = swin
	self.strikeRecovery = srec

	self.mass = mass
	self.springTightness = k
	self.springDamping = b

	self.velocity = 0

	self.state = DefaultState(self)
end

function Paddle:update(dt)
	self.state:update(dt)
end

function Paddle:draw()
	local goalPos = self.controller.goalPos or self.AABB.position.y
	love.graphics.push()
		local r, g, b = love.graphics.getColor()
		love.graphics.setColor(.2, .2, .2)
		print()
		love.graphics.translate(0, goalPos - self.AABB.position.y)
		self.AABB:draw()
		love.graphics.setColor(r, g, b)
	love.graphics.pop()

	if self.state:parent() == SwingState then
		local r, g, b = love.graphics.getColor()
		love.graphics.setColor(1, 0, 0)
		self.AABB:draw()
		love.graphics.setColor(r, g, b)
	elseif self.state:parent() == RecoveryState then
		local r, g, b = love.graphics.getColor()
		love.graphics.setColor(.2, .2, .2)
		self.AABB:draw()
		love.graphics.setColor(r, g, b)
	else
		self.AABB:draw()
	end

end

function Paddle:integrate(dt, velMul)
	local velMul = velMul or 1
	local paddle = self
	local pos = paddle.AABB.position

	pos.y = pos.y + paddle.velocity * velMul * dt
	paddle.velocity = paddle.velocity + paddle:getAcceleration(dt) * velMul * dt

	if pos.y + paddle.AABB.halfExtents.y > self.game.fieldSize.y then
		local depth = distance(self.game.fieldSize.y, pos.y + paddle.AABB.halfExtents.y)
			
		local moveDelta = self.game.fieldSize.y - (pos.y + paddle.AABB.halfExtents.y)
		local moveDir = sign(moveDelta)
		local vel = self.velocity * moveDir

		paddle.velocity = paddle.velocity + springDamperCollide(
			self.springTightness*10, depth,
			.5, vel,
			-1
		) / self.mass * dt
	elseif pos.y - paddle.AABB.halfExtents.y < 0 then
		local depth = distance(0, pos.y - paddle.AABB.halfExtents.y)

		local moveDelta = 0 - pos.y + paddle.AABB.halfExtents.y
		local moveDir = sign(moveDelta)
		local vel = self.velocity * moveDir

		paddle.velocity = paddle.velocity + springDamperCollide(
			self.springTightness*10, depth,
			.5, vel,
			1
		) / self.mass * dt
	end
end

function Paddle:getAcceleration(dt)
	local pos = self.AABB.position
	self.goalPos = self.controller:getGoalPosition(dt)

	local moveDelta = pos.y - self.goalPos
	local moveDir = sign(moveDelta)

	local vel = self.velocity * moveDir

	force = springDamper(
		self.springTightness, math.abs(moveDelta),
		self.springDamping, vel
	) * moveDir


	return force/self.mass
end

DefaultState = Object()

function DefaultState:__new(paddle)
	self.paddle = paddle
end

function DefaultState:update(dt)
	local paddle = self.paddle

	paddle:integrate(dt)


	if paddle.controller:isStriking(dt) then
		paddle.state = SwingState(paddle)
	end
end

function DefaultState:hitResponse(ball)
	local paddle = self.paddle
	local pos = paddle.AABB.position
	local moveDirX = ball.velocity.x > 0 and -1 or 1
	local moveDirY = pos.y - paddle.goalPos > 0 and -1 or 1
	ball.velocity.x = moveDirX * ball.speed
	ball.velocity.y = clamp(paddle.velocity, -ball.speed, ball.speed)
end


SwingState = Object()

function SwingState:__new(paddle)
	self.paddle = paddle
	self.time = 0
end

function SwingState:update(dt)
	local paddle = self.paddle

	paddle:integrate(dt)

	if self.time > paddle.strikeWindow then
		paddle.state = RecoveryState(paddle)
	end

	self.time = self.time + dt
end

function SwingState:hitResponse(ball)
	local paddle = self.paddle
	local pos = paddle.AABB.position
	local moveDirX = ball.velocity.x > 0 and -1 or 1
	ball.velocity.x = moveDirX * paddle.strength
	ball.velocity.y = clamp(paddle.velocity, -ball.speed, ball.speed)
end

RecoveryState = Object()

function RecoveryState:__new(paddle)
	self.paddle = paddle
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

function RecoveryState:hitResponse(ball)
	local paddle = self.paddle
	local pos = paddle.AABB.position
	local moveDirX = ball.velocity.x > 0 and -1 or 1
	ball.velocity.x = moveDirX * ball.speed
	ball.velocity.y = clamp(paddle.velocity, -ball.speed, ball.speed)
end
