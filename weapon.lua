Weapon = Object()

-- Subclass this and override these fields with sane values!
function Weapon:__new()
	self.name = "Weapon"

	self.mass = 1
	self.length = 1/6
	self.springTightness = 100
	self.springDamping = 10

	self.strikeMultiplier = 1.5
	self.strikeWindow = .2
	self.strikeRecoveryTime = .3

	self.paddleType = Paddle
end

function Weapon:getPaddlePosition(game, character)
	if character.isPlayer or character.isFollower then
		local paddlePosition = Vector2(0.1, 0.5)

		if character.isFollower then
			paddlePosition.x = 0.05 - 0.02
		end

		return paddlePosition
	else
		return Vector2(game.fieldSize.x - 0.1, 0.5)
	end
end
function Weapon:generatePaddle(game, character)
	local paddlePosition = self:getPaddlePosition(game, character)

	local paddleExtent = Vector2(0.02, self.length/2)
	local paddleAABB = AABB(paddlePosition, paddleExtent)

	local paddle = self.paddleType(
		game, paddleAABB,
		self.strikeMultiplier, self.mass, self.springTightness, self.springDamping,
		self.strikeWindow, self.strikeRecoveryTime
	)
	paddle:setController(character.controller(game, character))
	paddle.owner = character
	self.paddle = paddle

	if self.color then
		paddle:setColor(self.color)
	end

	return paddle
end

DualWeapon = Weapon()

function DualWeapon:generatePaddle(game, character)
	local paddlePosition = self:getPaddlePosition(game, character)

	local paddleExtent = Vector2(0.02, self.length/2)
	local paddleAABB = AABB(paddlePosition, paddleExtent)

	local paddle = self.paddleType(
		game, paddleAABB,
		self.strikeMultiplier, self.mass, self.springTightness, self.springDamping,
		self.strikeWindow, self.strikeRecoveryTime
	)
	paddle:setController(character.controller(game, character))
	paddlePosition = Vector2(paddlePosition.x, .75)
	paddleAABB = AABB(paddlePosition, paddleExtent)

	local secondPaddle = self.paddleType(
		game, paddleAABB,
		self.strikeMultiplier, self.mass, self.springTightness, self.springDamping,
		self.strikeWindow, self.strikeRecoveryTime
	)
	secondPaddle:setController(character.controller(game, character))
	secondPaddle.offHand = true
	secondPaddle.owner = character
	secondPaddle.parent = paddle

	paddle.children = { secondPaddle }
	paddle.owner = character
	self.paddle = paddle
	return paddle
end

ThrowingWeapon = Weapon()

function ThrowingWeapon:__new()
	self.paddleType = ThrowingPaddle

	self.airControl = 0 -- 0-1 percentage of control in air
	self.throwForce = 2.5

	self.length = 1/8
end

function ThrowingWeapon:generatePaddle(game, character)
	local paddlePosition = self:getPaddlePosition(game, character)

	local paddleExtent = Vector2(0.02, self.length/2)
	local paddleAABB = AABB(paddlePosition, paddleExtent)

	local paddle = self.paddleType(
		game, paddleAABB,
		self.strikeMultiplier, self.mass, self.springTightness, self.springDamping,
		self.strikeWindow, self.strikeRecoveryTime, self.throwForce, self.airControl
	)
	paddle:setController(character.controller(game, character))
	paddle.owner = character
	self.paddle = paddle
	return paddle
end


--- HERE BE WEAPONS

Weapons = {}

ShortSword = Weapon()

function ShortSword:__new()
	self.name = "Shortsword"
	self.mass = 1
	self.length = 1/6
	self.springTightness = 100
	self.springDamping = 10

	self.strikeMultiplier = 1.5
	self.strikeWindow = .2
	self.strikeRecoveryTime = .3
end

table.insert(Weapons, ShortSword)

GreatSword = Weapon()

function GreatSword:__new()
	self.name = "Greatsword"
	self.mass = 50
	self.length = 1/2.5
	self.springTightness = 800
	self.springDamping = 80

	self.strikeMultiplier = 2
	self.strikeWindow = .2
	self.strikeRecoveryTime = .6
end

table.insert(Weapons, GreatSword)

Dagger = Weapon()

function Dagger:__new()
	self.name = "Dagger"
	self.mass = 1
	self.length = 1/8
	self.springTightness = 150
	self.springDamping = 10

	self.strikeMultiplier = 2
	self.strikeWindow = .1
	self.strikeRecoveryTime = .15
end

table.insert(Weapons, Dagger)

-- Follower specific weapons

Paws = Weapon()

function Paws:__new()
	self.name = "Loyal Hound's Paws"
	self.color = {r = 153/255/2, g = 107/255/2, b =55/255/2
}
	self.mass = 2
	self.length = 1/8
	self.springTightness = 70
	self.springDamping = 6
end