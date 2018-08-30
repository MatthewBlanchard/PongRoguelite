Label = Object()

function Label:__new(font, text, position)
	self.font = font
	self.text = text
	self.position = position
end

function Label:draw()
	local str = ""

	if type(self.text) == "table" then
		for k,v in pairs(self.text) do
			if type(v) == "string" then
				str = str .. v
			end
		end
	else
		str = self.text
	end

	local wrap = font:getWidth(str)
	love.graphics.setFont(font)
	love.graphics.printf(self.text, self.position.x - wrap/2, self.position.y, wrap, "center")
end