Object = {}

-- Metamethods
function Object:__call(...)
    return self:new(...)
end

-- Constructor
function Object:__new()
end

-- Methods
function Object:new(...)
    local o = {}
   	setmetatable(o, self)
	self.__index = self
	self.__call = Object.__call

    o:__new(...)
    return o
end

function Object:is(o)
	local parent = getmetatable(self)
	while parent do
		if parent == o then
			return true
		end

		parent = getmetatable(parent)
	end

	return false
end

return Object:new()