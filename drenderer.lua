DRenderer = Object()

DRenderer.gbufferShader = love.graphics.newShader([[
	uniform Image MainTex;
	extern Image normal;

	void effect()
	{
	    love_Canvases[0] = Texel(MainTex, VaryingTexCoord.xy);
	    love_Canvases[1] = Texel(normal, VaryingTexCoord.xy);
	}
]])

function DRenderer:__new()
	self.albedo = love.graphics.newCanvas()
	self.normal = love.graphics.newCanvas()
end

function DRenderer:beginGBuffer()
	love.graphics.setCanvas(self.albedo, self.normal)
	love.graphics.setShader(self.gbufferShader)
end

function DRenderer:draw(DDrawable, x, y)
	self.gbufferShader:send("normal", DDrawable.normal)

	if DDrawable.quad then
		love.graphics.draw(DDrawable.albedo, DDrawable.quad, x, y)
	else
		love.graphics.draw(DDrawable.albedo, x, y)
	end

end

function DRenderer:endGBuffer()
	love.graphics.setShader()
	love.graphics.setCanvas()
end

function DRenderer:startLighting()
	love.graphics.setBlendMode("add")
end

function DRenderer:endLighting()
	love.graphics.setBlendMode("alpha")
end

function DRenderer:drawLight(light)
	light:draw(self)
end

DDrawable = Object()

function DDrawable:__new(albedo, normal, quad)
	if type(albedo) == "string" then
		albedo = love.graphics.newImage(albedo)
	end

	if type(normal) == "string" then
		normal = love.graphics.newImage(normal)
	end

	self.quad = quad
	self.albedo = albedo
	self.normal = normal
end

DPointLight = Object()

DPointLight.shader = love.graphics.newShader([[
	extern vec3 lightPos;
	extern vec3 lightCol;
	extern Image normal;

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
		vec3 lightDir = normalize(lightPos - vec3(screen_coords, 0));
		float lightDist = distance(lightPos, vec3(screen_coords, 0));

	    vec3 albedo = vec3(Texel(texture, texture_coords));
	    vec3 normal = normalize(Texel(normal, texture_coords).xyz * 2.0 - 1.0) ;

	    vec3 diffuse = max(dot(lightDir, normal), 0.0) * lightCol * albedo;
	    float attenuation =  1.0 / (1.0 + .0001 * pow(lightDist, 2));
	    return vec4(diffuse * attenuation, 1);
	}
]])

function DPointLight:__new(position, color)
	self.position = position
	self.color = color
end

function DPointLight:draw(renderer)
	love.graphics.setShader(self.shader)
		self.shader:send("lightPos", {self.position.x, self.position.y, self.position.z})
		self.shader:send("lightCol", {self.color.r, self.color.g, self.color.b})
		self.shader:send("normal", renderer.normal)
		love.graphics.draw(renderer.albedo, 0, 0)
	love.graphics.setShader()
end

DDirectionalLight = Object()

DDirectionalLight.shader = love.graphics.newShader([[
	extern vec3 lightDir;
	extern vec3 lightCol;
	extern Image normal;

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
		vec3 nlightDir = normalize(lightDir);
	    vec3 albedo = vec3(Texel(texture, texture_coords));
	    vec3 normal = normalize(Texel(normal, texture_coords).xyz * 2.0 - 1.0) ;

	    vec3 diffuse = max(dot(nlightDir, normal), 0.0) * lightCol * albedo;
	    return vec4(diffuse, 1);
	}
]])

function DDirectionalLight:__new(direction, color)
	self.direction = direction
	self.color = color
end

function DDirectionalLight:draw(renderer)
	love.graphics.setShader(self.shader)
		self.shader:send("lightDir", {self.direction.x, self.direction.y, self.direction.z})
		self.shader:send("lightCol", {self.color.r, self.color.g, self.color.b})
		self.shader:send("normal", renderer.normal)
		love.graphics.draw(renderer.albedo, 0, 0)
	love.graphics.setShader()
end