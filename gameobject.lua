GameObject = Object()

function GameObject:__new(game, AABB)
	self.game = game
	self.AABB = AABB
	self.velocity = Vector(0, 0)
	self.rotation = 0

	self.children = {}
end

function GameObject:update()
end

function GameObject:draw()
end

function GameObject:getPosition()
	return self.AABB.position:copy()
end

function GameObject:setPosition(vec, y)
	if type(vec) == "number" then
		self.AABB.position.x = vec
		self.AABB.position.y = vec
	else
		self.AABB.position = vec
	end
end

function GameObject:move(vec, y)
	if type(vec) == "number" then
		local x = vec
		self.AABB.position.x = self.AABB.position.x + x
		self.AABB.position.y = self.AABB.position.y + y
	else
		self:setPosition(self:getPosition() + vec)
	end
end

function GameObject:getVelocity()
	return self.velocity:copy()
end

function GameObject:setVelocity(vec)
	self.velocity = vec
end

function GameObject:getSize()
	local mX, mY = 0, 0
	local size = self.AABB.halfExtents
	local rot = self.rotation

	local points = {}

	table.insert(points, Vector(size.x, size.y))
	table.insert(points, Vector(-size.x, size.y))
	table.insert(points, Vector(size.x, -size.y))
	table.insert(points, Vector(-size.x, -size.y))

	for i, point in pairs(points) do
		rX = point.x * math.cos(rot) - point.y * math.sin(rot)
		rY = point.y * math.cos(rot) + point.x * math.sin(rot)

		mX = math.max(math.abs(rX), mX)
		mY = math.max(math.abs(rY), mY)
	end

	return Vector(mX, mY)
end

function GameObject:checkCollision(gameObject)
	local adjustedSelf = AABB(self:getPosition(), self:getSize())
	local adjustedOther = AABB(gameObject:getPosition(), gameObject:getSize())

	return adjustedSelf:overlaps(adjustedOther)
end

function GameObject:getBaseSize()
	return self.AABB.halfExtents
end

function GameObject:setSize(vec)
	self.AABB.halfExtents = vec
end