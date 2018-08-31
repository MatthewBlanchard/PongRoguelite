require "vector"
require "aabb"
require "paddle"
require "controller"

Pong = Object()

-- Field size constants. The smallest dimension of the field
-- should always be 1.
Pong.fieldSize = Vector(1.77, 1)

local width, height = love.graphics.getDimensions()
Pong.waitLabel = Label(font, {
	{1, 1, 1},
	"Press ",
	{1, 0, 0},
	"space ",
	{1, 1, 1,},
	"to play!."
}, Vector(width/2, 0))

function Pong:__new(lcharacter, rcharacter)
	self.paddles = {}
	self.time = 0

	table.insert(self.paddles, lcharacter:getPaddle(self))
	table.insert(self.paddles, rcharacter:getPaddle(self))

	local ballOrigin = Vector(self.fieldSize.x/2, self.fieldSize.y/2)
	self.ball = Ball(self, AABB(ballOrigin, Ball.size))

	self.state = self.waitingState
end

function Pong:draw()

	if self.state == self.waitingState then
		self.waitLabel:draw()
	end

	love.graphics.push()
		love.graphics.scale(width/self.fieldSize.x, height/self.fieldSize.y)

		for k, paddle in pairs(self.paddles) do
			paddle:draw()
		end
	
		self.ball:draw()
	love.graphics.pop()
end

function Pong:update(dt)
	self:state(dt)
end

function Pong:waitingState(dt)
	for i = 1, 1000 do
		t = dt / 1000

		for k, paddle in pairs(self.paddles) do
			paddle:update(t)
		end
	end

	if love.keyboard.isDown("space") then
		self.state = self.playingState
	end
end

function Pong:playingState(dt)
	for i = 1, 10 do
		t = dt / 10

		self.ball:update(t)

		for k, paddle in pairs(self.paddles) do
			paddle:update(t)
		end
	end
end

function Pong:scored(ball)
	self.state = self.waitingState

	for k, paddle in pairs(self.paddles) do
		local controller = paddle.controller:parent()

		paddle:__new(
			self, controller(self), paddle.AABB, paddle.strength,
			paddle.mass, paddle.springTightness, paddle.springDamping,
			paddle.strikeWindow, paddle.strikeRecovery
		)
	end
end

Ball = Object()

-- Width/height of the ball constant
Ball.size = .01
Ball.speed = 1

function Ball:__new(game, AABB)
	self.game = game
	self.AABB = AABB
	self.velocity = Vector(self.speed, 0)
	self.time = 1
	self.returns = 30

	local pos = AABB.position
	local size = AABB.halfExtents
	self.mesh = love.graphics.newMesh( 
		{
			{-size.x,-size.y},
			{size.x, -size.y},
			{size.x, size.y},
			{-size.x, size.y}
		}
	)
end

function Ball:draw()
	love.graphics.push()
		local size = self.AABB.halfExtents
		local mag = self.velocity:magnitude()
		local normalVel = self.velocity:normalized()
		local x, y = normalVel.x, normalVel.y
		love.graphics.translate(self.AABB.position.x, self.AABB.position.y)
		love.graphics.rotate(math.atan2(y, x))
		love.graphics.scale(1 + mag/5, 1 - (mag/7))
		love.graphics.draw(self.mesh)
	love.graphics.pop()
end


function Ball:integrate(dt)
	local pos = self.AABB.position

	local moveVector = Vector(self.velocity.x * dt, self.velocity.y * dt)
	self.AABB:move(moveVector)

	for k, paddle in pairs(self.game.paddles) do
		self:handleCollisions(paddle)
	end

	if pos.y - self.size < 0 then
		self.velocity.y = math.abs(self.velocity.y)
	elseif pos.y + self.size > self.game.fieldSize.y then
		self.velocity.y = -math.abs(self.velocity.y)
	end

	if pos.x < 0 or pos.x > self.game.fieldSize.x then
		self.game:scored(self)
		pos.x = self.game.fieldSize.x/2
		pos.y = self.game.fieldSize.y/2
		self.velocity.x = self.speed
		self.velocity.y = 0
		self.lasthit = nil
	end
end

function Ball:handleCollisions(paddle)
	local collided = self:recursiveCheckCollision(paddle)

	if not (self.lasthit == paddle) and collided then
		paddle.state:hitResponse(self)
		self.lasthit = paddle
	end
end

function Ball:recursiveCheckCollision(paddle)
	local collided = self.AABB:overlaps(paddle.AABB)

	if not collided then
		local curpaddle = paddle

		while curpaddle.children do
			for k, paddle in pairs(paddle.children) do
				if self.AABB:overlaps(curpaddle.AABB) then
					return true
				else
					return ball:recursiveCheckCollision()
				end
			end
		end

		return false
	else
		return true
	end
end

function Ball:update(dt)
	self:integrate(dt)
end