-- Define Object for our entire project.
Object = require "object"
font = love.graphics.newFont("Alkhemikal.ttf", 24)

require "ui/label"
require "util"
require "pong"
require "weapon"
require "character"

math.randomseed(os.time())
math.random() math.random() math.random()

local player = Player()
player.weapon = Dagger(player)

local enemy = Character()
enemy.weapon = Weapons[math.random(#Weapons)](player)


local pongGame = Pong(player, enemy)

function love.update(dt)
	pongGame:update(dt)
end

function love.draw()
	pongGame:draw()
end