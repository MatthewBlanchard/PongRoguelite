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

function Object:parent()
	return getmetatable(self)
end

return Object:new()