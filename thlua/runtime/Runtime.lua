
local TypeManager = require "thlua.manager.TypeManager"
local Hook = require "thlua.Hook"
local TypeFunction = require "thlua.func.TypeFunction"
local NativeFunction = require "thlua.func.NativeFunction"
local LuaFunction = require "thlua.func.LuaFunction"
local TermTuple = require "thlua.tuple.TermTuple"
local Region = require "thlua.runtime.Region"
local CallContext = require "thlua.runtime.CallContext"
local native = require "thlua.native"
local CodeEnv = require "thlua.code.CodeEnv"

--[[@

var.RequireEnv = Struct {
	fn=class.LuaFunction,
	term=Union(False, class.UnionTerm),
	context=class.CallContext,
}


]]

local Runtime = {}

function Runtime.new()
	local self = setmetatable({
		hook=nil, --<< thlua.class.Hook
		func={},
		typeManager=nil, --<< thlua.class.TypeManager
	}, {
		__index=Runtime,
	}) -->> thlua.class.Runtime
	self._requireDict = {}
	self.typeManager = TypeManager.new(self)
	local nSpace = self.typeManager:RootNamespace()
	nSpace:setContextName(self)
	nSpace:close()
	self._namespace = nSpace
	return self
end

function Runtime:getPath()
	return "[root]"
end

function Runtime:init()
	self.hook = Hook.new(self, "root", "0,0", nil)
	self.global_term = native.make(self)
	self.root_region = self:newRegion(self)
	self.lateFnDict = {}
	self.defineFnDict = {}
end

function Runtime:recordLateLuaFunction(vFunc)
	self.lateFnDict[vFunc] = true
end

function Runtime:recordDefineLuaFunction(vFunc)
	self.defineFnDict[vFunc] = true
end

function Runtime:checkDefineLuaFunction()
	for fn, v in pairs(self.defineFnDict) do
		fn:checkDefine()
	end
end

function Runtime:checkLateLuaFunction()
	for fn, v in pairs(self.lateFnDict) do
		fn:checkLateRun()
	end
end

function Runtime:Hook(vFileName, vPos, vRegion)
	local nHook = Hook.new(self, vFileName, vPos, vRegion)
	return nHook
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
	nLuaFunc:meta_native_call(self, nTermTuple)
end

function Runtime:newContext(vLuaFunction, vLexContext)
	return CallContext.new(self, vLuaFunction, vLexContext)
end

function Runtime:load(vCode, vPath)
	local nEnv = CodeEnv.new(vCode, vPath, vPath)
	local nAfterContent = nEnv:genTypingCode()
	local nFunc, nInfo = load(nAfterContent, "typing:"..vPath, "t", setmetatable({}, {
		__index=function(t,k)
			error("indexing global is logic error")
		end
	}))
	if not nFunc then
		error(nInfo)
	end
	local nRunFunc = nFunc()
	local nLuaFunc = self.typeManager:LuaFunction()
	nLuaFunc:setName(vPath)
	nLuaFunc:setRuntime(self)
	nLuaFunc:init(self, {
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
		local ret = nLuaFunc:meta_native_call(self, nTermTuple)
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
	self.hook:error(...)
end

return Runtime
