
local Region = require "thlua.runtime.Region"
local UnionTerm = require "thlua.term.UnionTerm"
local ContextClass = require "thlua.runtime.ContextClass"
local CallContext = ContextClass()

function CallContext.new(vRuntime, vLuaFunction, vLexContext)
	local self = setmetatable({
		_runtime=vRuntime,
		_manager=vRuntime.typeManager,
		_lexContext=vLexContext,
		_fn=vLuaFunction,
	}, CallContext)
	self._region = vRuntime:newRegion(self)
	self._namespace = vLexContext:getNamespace():createChild(self)
	return self
end

function CallContext:getPath()
	return self._fn:getPath()
end

function CallContext:getNamespace()
	return self._namespace
end

function CallContext:getLuaFunction()
	return self._fn
end

function CallContext:REGION(vPos)
	return self:getRegion(), self._namespace.localExport, self._namespace.globalExport
end

function CallContext:recordLateLuaFunction(vFunc)
	self._runtime:recordLateLuaFunction(vFunc)
end

function CallContext:recordDefineLuaFunction(vFunc)
	self._runtime:recordDefineLuaFunction(vFunc)
end

return CallContext
