
local Exception = {}
Exception.__index=Exception
Exception.__tostring=function(t)
	return "Exception:"..t.msg
end

function Exception.new(vMsg)
	return setmetatable({
		msg=tostring(vMsg) -- ..debug.traceback()
	}, Exception)
end

function Exception.is(v)
	return getmetatable(v) == Exception
end

return Exception
