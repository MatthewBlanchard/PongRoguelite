function clamp(num, min, max)
	return math.min(math.max(num, min), max)
end

function sign(num)
	local sign = num > 0 and 1 or -1
	return num == 0 and 0 or sign
end

function direction(from, to)
	local diff = to - from
	return sign(diff)
end

function clampMagnitude(num, mag)
	local s = sign(num)
	num = math.min(math.abs(num), mag) * s
	return num
end

function distance(left, right)
	return math.abs(left - right)
end

function randBiDirectional()
	return (math.random()-.5)*2
end

function timer(threshold)
	local time = 0
	return function(dt)
		time = time + dt
		if time > threshold then
			return true
		end
	end
end
