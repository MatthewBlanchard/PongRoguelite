Character = Object()

function Character:__new()
	self.isPlayer = false
	self.controller = AIController

	self.HP = 1
end

function Character:getPaddle(game)
	return self.weapon:generatePaddle(game, self)
end

-- HERE BE CHARACTERS
Player = Character()

function Player:__new()
	self.isPlayer = true
	self.controller = PlayerController

	self.HP = 3
end