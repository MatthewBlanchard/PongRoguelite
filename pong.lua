require "vector"
require "aabb"
require "paddle"
require "controller"

Pong = Object()

-- Field size constants. The smallest dimension of the field
-- should always be 1.
Pong.fieldSize = Vector2(1.77, 1)

local width, height = love.graphics.getDimensions()
Pong.waitLabel = Label(font, {
	{1, 1, 1},
	"Press ",
	{1, 0, 0},
	"space ",
	{1, 1, 1,},
	"to play!."
}, Vector2(width/2, 0))

function Pong:__new(lcharacter, rcharacter)
	self.paddles = {}
	self.characters = {}

	self.hitstopTime = 0
	self.mouseDelta = Vector2(0, 0)

	self.renderer = DRenderer()

	self.background = DDrawable("wallalbedo.png", "wallnormal.png")
	self.background.albedo:setWrap("repeat")
	self.background.normal:setWrap("repeat")

	self.background.quad = love.graphics.newQuad(
	0, 0, love.graphics.getWidth(), love.graphics.getHeight(),
	self.background.albedo:getDimensions())

	self.backgroundLight = DDirectionalLight(Vector3(4, 4, 1), Color(244/512, 232/512, 66/512))
	self.backgroundLight2 = DDirectionalLight(Vector3(-4, -4, 1), Color(66/512, 206/512, 244/512))

	self.ballLightFlicker = flicker(Color(221/255, 115/255, 22/255), .1, .3) 
	self.ballLight = DPointLight(Vector3(0, 0, 100), Color(1, 1, 1))

	table.insert(self.characters, lcharacter)
	table.insert(self.characters, rcharacter)

	table.insert(self.paddles, lcharacter:getPaddle(self))
	table.insert(self.paddles, rcharacter:getPaddle(self))

	local ballOrigin = Vector2(self.fieldSize.x/2, self.fieldSize.y/2)
	self.ball = Ball(self, AABB(ballOrigin, Ball.size))

	self.state = self.waitingState
end

function Pong:draw()
	if self.state == self.waitingState then
		self.waitLabel:draw()
	end


	love.graphics.push()
		love.graphics.scale(2)
		self.ballLight.position.x = self.ball:getPosition().x * width/self.fieldSize.x
		self.ballLight.position.y = self.ball:getPosition().y * height

		self.renderer:beginGBuffer()
			self.renderer:draw(self.background)
		self.renderer:endGBuffer()

		self.renderer:startLighting()
			self.renderer:drawLight(self.backgroundLight)
			self.renderer:drawLight(self.backgroundLight2)
			self.renderer:drawLight(self.ballLight)
		self.renderer:endLighting()
	love.graphics.pop()

	love.graphics.push()
		love.graphics.scale(width/self.fieldSize.x, height/self.fieldSize.y)

		for k, paddle in pairs(self.paddles) do
			paddle:draw()
		end
	
		self.ball:draw()
	love.graphics.pop()
end

function Pong:update(dt)
	self.ballLight.color = self.ballLightFlicker(dt)

	if self.hitstopTime > 0 then
		self.hitstopTime = self.hitstopTime - dt
		return
	end

	self:state(dt)
	self.mouseDelta.x, self.mouseDelta.y = 0, 0
end

function Pong:hitStop(dt)
	self.hitstopTime = dt
end

function Pong:mousemoved(dx, dy)
	for i, paddle in pairs(self.paddles) do
		if paddle.controller.mousemoved then
			paddle.controller:mousemoved(dx, dy)
		end
	end
end

function Pong:scored(ball)
	self.state = self.waitingState
	self.paddles = {}

	for k, char in pairs(self.characters) do
		table.insert(self.paddles, char:getPaddle(self))
	end
end

function Pong:waitingState(dt)
	self.ball.velocity.x = 0

	for i = 1, 1000 do
		t = dt / 1000

		for k, paddle in pairs(self.paddles) do
			paddle:update(t)
		end
	end

	if love.keyboard.isDown("space") then
		self.ball.velocity.x = .5
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

Ball = GameObject()

-- Width/height of the ball constant
Ball.size = .01
Ball.speed = 1

function Ball:__new(game, AABB)
	GameObject.__new(self, game, AABB)
	self:setVelocity(Vector2(self.speed, 0))
	self.time = 1

	self.returns = 0
	self.returnSpeedup = 1/30

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


function Ball:update(dt)
	self:integrate(dt)
end

function Ball:integrate(dt)
	local pos = self.AABB.position

	local moveVector2 = Vector2(self.velocity.x * dt, self.velocity.y * dt)
	self.AABB:move(moveVector2)

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
		self.returns = 0
		self.lasthit = nil
	end
end

function Ball:handleCollisions(paddle)
	local collided = self:recursiveCheckCollision(paddle)

	if not (self.lasthit == paddle.owner) and collided then
		self.velocity = collided:onHit(self)
		self.lasthit = paddle.owner

		local returnDir = sign(self.velocity.x)
		self.returns = self.returns + 1
		self.velocity.x = self.velocity.x + self.returns * self.returnSpeedup * returnDir
		self.velocity.y = self.velocity.y
	end
end

function Ball:recursiveCheckCollision(paddle)
	local collided = self:checkCollision(paddle)

	if not collided then
		local curpaddle = paddle

		for k, child in pairs(paddle.children) do
			if self:checkCollision(child) then
				return child
			else
				return self:recursiveCheckCollision(child)
			end
		end

		return false
	else
		return paddle
	end
end

function flicker(baseColor, period, intensity)
	local t = 0
	local color = Color(baseColor.r, baseColor.g, baseColor.b)
	return function(dt)
		t = t + dt

		if t > period then
			t = 0
			local r = 1 - randBiDirectional() * intensity
			color.r = baseColor.r * r
			color.g = baseColor.g * r
			color.b = baseColor.b * r
		end

		return color
	end
end