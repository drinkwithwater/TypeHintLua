
local TypeManager = require "thlua.manager.TypeManager"
local TypeFunction = require "thlua.func.TypeFunction"
local NativeFunction = require "thlua.func.NativeFunction"
local LuaFunction = require "thlua.func.LuaFunction"
local TermTuple = require "thlua.tuple.TermTuple"
local Region = require "thlua.runtime.Region"
local CallContext = require "thlua.runtime.CallContext"
local ContextClass = require "thlua.runtime.ContextClass"
local native = require "thlua.native"
local CodeEnv = require "thlua.code.CodeEnv"
local Node = require "thlua.code.Node"

--[[

var.RequireEnv = Struct {
	fn=class.LuaFunction,
	term=Union(False, class.UnionTerm),
	context=class.CallContext,
}


]]

local Runtime = ContextClass()

function Runtime.new()
	local self = setmetatable({
		func={},
		typeManager=nil,
	}, {
		__index=Runtime,
	})
	self._requireDict = {}
	self._runtime = self
	self._region = self:newRegion(self)
	self.typeManager = TypeManager.new(self)
	local nSpace = self.typeManager:RootNamespace()
	nSpace:setContextName(self)
	nSpace:close()
	self._node = Node.newRootNode()
	self._meta = self:Meta(self._node)
	self._namespace = nSpace
	self._lateFnDict = {}
	self._defineFnDict = {}
	self.global_term = native.make(self)
	return self
end

function Runtime:getPath()
	return "[root]"
end

function Runtime:init()
end

function Runtime:recordLateLuaFunction(vFunc)
	self._lateFnDict[vFunc] = true
end

function Runtime:recordDefineLuaFunction(vFunc)
	self._defineFnDict[vFunc] = true
end

function Runtime:checkDefineLuaFunction()
	for fn, v in pairs(self._defineFnDict) do
		fn:checkDefine()
	end
end

function Runtime:checkLateLuaFunction()
	for fn, v in pairs(self._lateFnDict) do
		fn:checkLateRun()
	end
end

function Runtime:getNamespace()
	return self._namespace
end

function Runtime:import(vPath)
	-- TODO better style
    local nContext = self._requireDict[vPath].context
    local nSpace = nContext._namespace
		return nSpace.localExport
end

function Runtime:main(vFileName, vContent)
	local nLuaFunc = self:load(vContent, vFileName)
	local nTermTuple = self.typeManager:TermTuple({})
	nLuaFunc:meta_native_call(self._meta, nTermTuple)
end

function Runtime:newContext(vLuaFunction, vLexContext)
	return CallContext.new(self, vLuaFunction, vLexContext)
end

function Runtime:load(vCode, vPath)
	local nEnv = CodeEnv.new(vCode, vPath, vPath, self._node)
	local nAfterContent = nEnv:genTypingCode()
	local nFunc, nInfo = load(nAfterContent, "typing:"..vPath, "t", setmetatable({}, {
		__index=function(t,k)
			error("indexing global is logic error")
		end
	}))
	if not nFunc then
		error(nInfo)
	end
	local nRunFunc = nFunc(nEnv:getNodeList())
	local nLuaFunc = self.typeManager:LuaFunction()
	nLuaFunc:init(self, self, self._node)
	nLuaFunc:setUnionFn({
		tag=LuaFunction.OPEN,
		fn=self.typeManager:NativeFunction(nRunFunc),
		isGuard=false,
	})
	return nLuaFunc
end

function Runtime:newRegion(vContext)
	return Region.new(self, vContext)
end

function Runtime:require(vPath)
	local nRequireEnv = self._requireDict[vPath]
	if not nRequireEnv then
		local nOkay, nContent, nFileName = CodeEnv.thluaSearchContent(vPath, true)
		if not nOkay then
				error(nContent)
		end
		local nLuaFunc = self:load(nContent, vPath)
		nRequireEnv = {
			term=false,
			fn=nLuaFunc,
			context=false,
		}
		self._requireDict[vPath] = nRequireEnv
		local nTermTuple = self.typeManager:TermTuple({})
		local ret = nLuaFunc:meta_native_call(self._meta, nTermTuple)
		nRequireEnv.term = ret:get(1)
		nRequireEnv.context = ret:getContext()
	end
	local nTerm = nRequireEnv.term
	if not nTerm then
			error("recursive require:"..vPath)
	end
	return nTerm
end

function Runtime:error(...)
	print("runtime error TODO", ...)
end

return Runtime
