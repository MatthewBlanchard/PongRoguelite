-- Define Object for our entire project.
Object = require "object"
font = love.graphics.newFont("Alkhemikal.ttf", 24)

require "ui/label"
require "gameobject"
require "util"
require "pong"
require "weapon"
require "character"

math.randomseed(os.time())
math.random() math.random() math.random()

love.mouse.setGrabbed(true)
love.mouse.setVisible(false)

local pongGame
function love.load()
	love.mouse.setRelativeMode(true)

	local player = Player()
	player.weapon = ThrowingWeapon(player)
	player.controller = ThrowingPlayerController

	local enemy = Goblin()
	enemy.weapon = ThrowingWeapon(enemy)
	enemy.controller = ThrowingAIController

	pongGame = Pong(player, enemy)
end

function love.mousemoved(x, y, dx, dy)
	pongGame:mousemoved(dx, dy)
end

function love.update(dt)
	if love.keyboard.isDown("escape") then
		love.event.quit()
	end

	pongGame:update(dt)
end

function love.draw()
	pongGame:draw()
end