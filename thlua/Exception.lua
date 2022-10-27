
local Exception = {}
Exception.__index=Exception
Exception.__tostring=function(t)
	return "Exception:"..t.msg
end

function Exception.new(vMsg, vNode)
	if Exception.is(vMsg) then
		vMsg = vMsg.msg
	end
	return setmetatable({
		msg=tostring(vMsg), -- ..debug.traceback()
		node=vNode,
	}, Exception)
end

function Exception:fixNode(vNode)
	if not self.node then
		self.node = vNode
	end
end

function Exception.is(v)
	return getmetatable(v) == Exception
end

return Exception
