Vector = Object()

function Vector:__new(x, y)
	self.x, self.y = x, y
end

function Vector.__add(a, b, c)
	return Vector(a.x + b.x, a.y + b.y)
end

function Vector.__mul(a, b)
	return Vector(a.x * b, a.y * b)
end

function Vector:copy()
	return Vector(self.x, self.y)
end

function Vector:magnitude()
	return math.sqrt((self.x * self.x) + (self.y*self.y))
end

function Vector:normalized()
	local mag = self:magnitude()
	return Vector(self.x/mag, self.y/mag)
end