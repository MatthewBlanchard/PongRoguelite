Vector = Object()

function Vector:__new(x, y)
	self.x, self.y = x, y
end

function Vector:magnitude()
	return math.sqrt((self.x * self.x) + (self.y*self.y))
end

function Vector:normalized()
	local mag = self:magnitude()
	return Vector(self.x/mag, self.y/mag)
end