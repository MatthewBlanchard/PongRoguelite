local function fidget(startPos)
	local time = 0
	return function(dt)
		time = time + dt
		return math.sin(time*5)/100
	end
end

local function wander(startPos)
	local time = 0
	local direction = direction(0, randBiDirectional())
	return function(dt)
		time = time + dt
		return startPos + direction * time
	end
end

Character = Object()

function Character:__new()
	self.isPlayer = false
	self.controller = AIController

	self.name = "Unknown"
	self.HP = 1

	self.waitActivity = wander
	self.trackSpeed = 1
end

function Character:getPaddle(game)
	local paddle = self.weapon:generatePaddle(game, self)

	if self.follower then
		print "YA"
		paddle:addChild(self.follower:getPaddle(game))
	end

	return paddle
end

Player = Character()

function Player:__new()
	Character.__new(self)

	self.name = "Player"
	self.isPlayer = true
	self.controller = PlayerController

	self.HP = 3
end

-- Followers

LoyalHound = Character()

function LoyalHound:__new()
	Character.__new(self)

	self.name = "Loyal Hound"
	self.isFollower = true
	self.controller = FollowerAIController
	self.HP = 1

	self.weapon = Paws()
	self.trackSpeed = .75
end

-- HERE BE MONSTERS

Goblin = Character()

function Goblin:__new()
	Character.__new(self)

	self.controller = DualAIController
	self.name = "Goblin"
	self.HP = 1

	self.weapon = DualWeapon()
	self.waitActivity = fidget
	self.trackSpeed = 2
end

Ogre = Character()

function Ogre:__new()
	Character.__new(self)

	self.name = "Ogre"
	self.HP = 3

	self.weapon = Greatsword()
	self.waitActivity = wander
	self.trackSpeed = .75
end


