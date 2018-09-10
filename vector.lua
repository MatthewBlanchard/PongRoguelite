Vector2 = Object()

function Vector2:__new(x, y)
	self.x, self.y = x, y
end

function Vector2.__add(a, b, c)
	return Vector2(a.x + b.x, a.y + b.y)
end

function Vector2.__mul(a, b)
	return Vector2(a.x * b, a.y * b)
end

function Vector2:copy()
	return Vector2(self.x, self.y)
end

function Vector2:magnitude()
	return math.sqrt((self.x * self.x) + (self.y*self.y))
end

function Vector2:normalized()
	local mag = self:magnitude()
	return Vector2(self.x/mag, self.y/mag)
end

Vector3 = Object()

function Vector3:__new(x, y, z)
	self.x = x
	self.y = y
	self.z = z
end

Color = Object()

function Color:__new(r, g, b)
	self.r = r
	self.g = g
	self.b = b
end