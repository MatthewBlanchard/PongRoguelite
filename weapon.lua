Weapon = Object()

-- Subclass this and override these fields with sane values!
function Weapon:__new()
	self.name = "Weapon"

	self.mass = 1
	self.length = 1/6
	self.springTightness = 100
	self.springDamping = 10

	self.strikeMultiplier = .5
	self.strikeWindow = .2
	self.strikeRecoveryTime = .3

	self.isMirrored = false
end

function Weapon:generatePaddle(game, character)
	print(character)
	local paddlePosition
	if character.isPlayer then
		paddlePosition = Vector(0.1, 0.5)
	else
		paddlePosition = Vector(game.fieldSize.x - 0.1, 0.5)
	end

	local paddleExtent = Vector(0.02, self.length/2)
	local paddleAABB = AABB(paddlePosition, paddleExtent)

	local paddle = Paddle(
		game, character.controller(game, character), paddleAABB,
		self.strikeMultiplier, self.mass, self.springTightness, self.springDamping,
		self.strikeWindow, self.strikeRecoveryTime
	)

	paddle.owner = character
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