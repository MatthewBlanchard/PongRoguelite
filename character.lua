local function fidget(startPos)
	local time = 0
	return function(dt)
		time = time + dt
		return startPos + math.sin(time*3)/15
	end
end

Character = Object()

function Character:__new()
	self.isPlayer = false
	self.controller = AIController

	self.name = "Unknown"
	self.HP = 1

	self.waitActivity = fidget
	self.trackSpeed = 1
end

function Character:getPaddle(game)
	print(self)
	return self.weapon:generatePaddle(game, self)
end

Player = Character()

function Player:__new()
	Character.__new(self)
	self.name = "Player"
	self.isPlayer = true
	self.controller = PlayerController

	self.HP = 3
end

-- HERE BE MONSTERS

Goblin = Character()

function Goblin:new()
	Character.__new(self)

	self.name = "Goblin"
	self.HP = 1

	self.weapon = Dagger()
	self.trackSpeed = 2
end

Ogre = Character()

function Ogre:new()
	Character.__new(self)

	self.name = "Ogre"
	self.HP = 1

	self.weapon = Greatsword()
	self.trackSpeed = 1
end


