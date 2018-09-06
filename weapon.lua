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

function Weapon:generatePaddle(game, character)
	local paddlePosition
	if character.isPlayer then
		paddlePosition = Vector(0.1, 0.5)
	else
		paddlePosition = Vector(game.fieldSize.x - 0.1, 0.5)
	end

	local paddleExtent = Vector(0.02, self.length/2)
	local paddleAABB = AABB(paddlePosition, paddleExtent)

	local paddle = self.paddleType(
		game, paddleAABB,
		self.strikeMultiplier, self.mass, self.springTightness, self.springDamping,
		self.strikeWindow, self.strikeRecoveryTime
	)
	paddle:setController(character.controller(game, character))
	paddle.owner = character
	self.paddle = paddle
	return paddle
end

DualWeapon = Weapon()

function DualWeapon:generatePaddle(game, character)
	local paddlePosition
	if character.isPlayer then
		paddlePosition = Vector(0.1, 0.25)
	else
		paddlePosition = Vector(game.fieldSize.x - 0.1, 0.25)
	end

	local paddleExtent = Vector(0.02, self.length/2)
	local paddleAABB = AABB(paddlePosition, paddleExtent)

	local paddle = self.paddleType(
		game, paddleAABB,
		self.strikeMultiplier, self.mass, self.springTightness, self.springDamping,
		self.strikeWindow, self.strikeRecoveryTime
	)
	paddle:setController(character.controller(game, character))
	paddlePosition = Vector(paddlePosition.x, .75)
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
	local paddlePosition
	if character.isPlayer then
		paddlePosition = Vector(0.1, 0.5)
	else
		paddlePosition = Vector(game.fieldSize.x - 0.1, 0.5)
	end

	local paddleExtent = Vector(0.02, self.length/2)
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