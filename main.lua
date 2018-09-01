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

love.mouse.setGrabbed(true)
love.mouse.setVisible(false)

local player = Player()
player.weapon = Weapons[math.random(#Weapons)](player)

local enemy = Character()
enemy.weapon = Weapons[math.random(#Weapons)](enemy)


local pongGame = Pong(player, enemy)

function love.update(dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end

	pongGame:update(dt)
end

function love.draw()
	pongGame:draw()
end