local json = require('rapidjson')
local decode = json.decode
local function recursiveCast(t)
	local nType = type(t)
	if nType == "userdata" and t == json.null then
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
json.decode = function(data)
	local a,b = decode(data)
	return recursiveCast(a), b
end
return json
