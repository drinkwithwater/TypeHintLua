local rapidjson = require('rapidjson')
local decode = rapidjson.decode
local function recursiveCast(t)
	local nType = type(t)
	if nType == "userdata" and t == rapidjson.null then
		return nil
	elseif nType == "table" then
		local re = {}
		for k,v in pairs(t) do
			re[k] = recursiveCast(v)
		end
		return re
	else
		return t
	end
end
local json = {}
json.decode = function(data)
	local a,b = decode(data)
	return recursiveCast(a), b
end
json.encode = rapidjson.encode
json.array = function(data)
	return rapidjson.array(data)
end
return json
