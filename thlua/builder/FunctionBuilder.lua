
local Reference = require "thlua.type.Reference"
local LuaFunction = require "thlua.func.LuaFunction"
local Variable = require "thlua.func.Variable"
local AutoArguments = require "thlua.func.AutoArguments"
local TermCase = require "thlua.term.TermCase"
local FunctionBuilder = {}

function FunctionBuilder.Begin(vContext, vRunFunc, vNode)
	local nData = {
		context=vContext,
		node=vNode,
		argList={},
		argDots=false,
		retTuples=false,
		runFunc=vRunFunc,
		guardFunc=false,
		isGuard=false,
		tag=LuaFunction.DEFAULT,
		newTypeRefer=false,
	}
	local nManager = vContext._manager
	local function setTag(vTag)
		if nData.tag == vTag then
			error(nData.tag.."-fn can only be set once")
		end
		assert(nData.tag == LuaFunction.DEFAULT, nData.tag.."-fn can't set "..vTag)
		nData.tag = vTag
	end
	local nHintMethod = {
		NewTable=function(self, vRefer, vStruct)
			vRefer:setTypeAsync(function()
				if Reference.is(vStruct) then
					vStruct = vStruct:getTypeAwait()
				end
				local nTable = nManager:LuaTable()
				nTable:setCtor(nLuaFunc, vStruct)
				nTable.name = tostring(vRefer)
				return nTable
			end)
			setTag(LuaFunction.DEFINE)
			nData.newTypeRefer = vRefer
			assert(not nData.retTuples, "define function can't return other")
			return self
		end,
		Dots=function(self, vTypeOrVariable)
			nData.argDots=vTypeOrVariable
			return self
		end,
		Args=function(self, ...)
			nData.argList = {...}
			return self
		end,
		Ret=function(self, ...)
			local nRetTuples = nData.retTuples
			if not nRetTuples then
				nRetTuples = nManager:EmptyRetTuples()
				nData.retTuples = nRetTuples
			end
			nData.retTuples = nRetTuples:Add(nManager:Tuple(...))
			return self
		end,
		Variable=function(self, vIsGeneric)
			return nManager:Variable(vIsGeneric)
		end,
		nocheck=function(self)
			setTag(LuaFunction.NOCHECK)
			return self
		end,
		open=function(self)
			setTag(LuaFunction.OPEN)
			return self
		end,
		isguard=function(self, vType)
			setTag(LuaFunction.OPEN)
			local nTrue = nManager.type.True
			local nFalse = nManager.type.False
			nData.guardFunc=function(self, vTermTuple)
				-- TODO isguard add refinement
				local nTerm = vTermTuple:get(1)
				local caseTrue = TermCase.new()
				caseTrue:put_and(nTerm, vType)
				local nTypeCaseList = {
					{nTrue, caseTrue},
					{nFalse, TermCase.new()},
				}
				return nManager:mergeToUnionTerm(nTypeCaseList)
			end
			return self
		end,
	}
	return nData, nHintMethod
end

function FunctionBuilder.End(vData)
	local nContext = vData.context
	local nManager = nContext._manager
	local nLuaFunc = nManager:LuaFunction()
	nLuaFunc:init(nContext._runtime, nContext, vData.node)
	local nTag = vData.tag
	if nTag == LuaFunction.OPEN then
		assert(not vData.retTuples, "native function can't set ret")
		nLuaFunc:setUnionFn({
			tag=nTag,
			fn=nManager:NativeFunction(vData.guardFunc or vData.runFunc),
			isGuard=vData.guardFunc and true,
		})
	elseif nTag == LuaFunction.NOCHECK then
		local nList = {}
		for i, arg in pairs(vData.argList) do
			if Variable.is(arg) then
				nList[i] = nManager.type.Any
			else
				nList[i] = arg
			end
		end
		if not vData.retTuples then
			error("nocheck-fn must set ret")
		end
		local nTypeTuple = nManager:Tuple(table.unpack(nList))
		nLuaFunc:setUnionFn({
			tag=nTag,
			fn=nManager:Function(nTypeTuple, vData.retTuples)
		})
	elseif vData.tag == LuaFunction.DEFINE then
		nLuaFunc:setUnionFn({
			tag=nTag,
			fn=false,
			argList=vData.argList,
			argDots=vData.argDots,
			runFunc=vData.runFunc,
			newTypeRefer=vData.newTypeRefer,
			once=false,
		})
		nContext:recordDefineLuaFunction(nLuaFunc)
	elseif vData.tag == LuaFunction.DEFAULT then
		local nAutoArgs = AutoArguments.new(nManager, vData.argList, vData.argDots)
		local nRetTuples = vData.retTuples
		nLuaFunc:setUnionFn({
			tag=nTag,
			fn=false,
			autoArgs=nAutoArgs,
			runFunc=vData.runFunc,
			retTuples=nRetTuples,
			once=false,
		})
		if (not nAutoArgs:hasVariable()) and nRetTuples then
			nContext:recordLateLuaFunction(nLuaFunc)
		end
	end
	return nLuaFunc
end

return FunctionBuilder
