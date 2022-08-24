
local Region = require "thlua.runtime.Region"
local UnionTerm = require "thlua.term.UnionTerm"
local ContextClass = require "thlua.runtime.ContextClass"
local Meta = require "thlua.runtime.Meta"
local CallContext = ContextClass()

function CallContext.new(vRuntime, vApplyNode)
	local self = setmetatable({
		_runtime=vRuntime,
		_manager=vRuntime.typeManager,
		_node=vApplyNode,
		_namespace=false,
		_newTypeRefer=false,
		_meta=false,
	}, CallContext)
	self._region = vRuntime:newRegion(self)
	self._meta = Meta.new(self._runtime, self._node, self, self._region)
	return self
end

function CallContext:newContext(vApplyNode)
	return self._runtime:newContext(vApplyNode)
end

function CallContext:getPath()
	return tostring(self._node)
end

function CallContext:getNamespace()
	return self._namespace
end

function CallContext:setNewTypeRefer(vRefer)
	self._newTypeRefer = vRefer
end

function CallContext:getNewTypeRefer()
	return self._newTypeRefer
end

function CallContext:BEGIN(vLexContext, vBlockNode)
	local nSpace = vLexContext:getNamespace():createChild(self)
	self._namespace = nSpace
	return self:getRegion(), nSpace.localExport, nSpace.globalExport
end

function CallContext:recordLateLuaFunction(vFunc)
	self._runtime:recordLateLuaFunction(vFunc)
end

function CallContext:recordDefineLuaFunction(vFunc)
	self._runtime:recordDefineLuaFunction(vFunc)
end

return CallContext
