AABB = Object()

function AABB:__new(position, halfExtents)
	if type(halfExtents) == "number" then
		halfExtents = Vector(halfExtents, halfExtents)
	end

	self.position = position
	self.halfExtents = halfExtents
end

function AABB:draw()
	local pos = self.position
	local size = self.halfExtents
	love.graphics.rectangle("fill", pos.x-size.x, pos.y-size.y, size.x*2, size.y*2)
end

function AABB:move(toMove)
	self.position.x = self.position.x + toMove.x
	self.position.y = self.position.y + toMove.y
end


function AABB:overlaps(other)
	local selfminx = self.position.x - self.halfExtents.x
	local selfminy = self.position.y - self.halfExtents.y
	local selfmaxx = self.position.x + self.halfExtents.x
	local selfmaxy = self.position.y + self.halfExtents.y

	local otherminx = other.position.x - other.halfExtents.x
	local otherminy = other.position.y - other.halfExtents.y
	local othermaxx = other.position.x + other.halfExtents.x
	local othermaxy = other.position.y + other.halfExtents.y

	if
	(
		selfmaxx < otherminx or
		selfminx > othermaxx or
		selfmaxy < otherminy or
		selfminy > othermaxy
	) then
		return false
	end

	return true
end