
local loaded, packages, require_ = {}, {}, require

local function require(path)
    if loaded[path] then
        return loaded[path]
    elseif packages[path] then
        loaded[path] = packages[path](path)
        return loaded[path]
    else
        return require_(path)
    end
end

--thlua.Enum begin ==========(
do local _ENV = _ENV
packages['thlua.Enum'] = function (...)

local Enum = {}

Enum.SymbolKind_CONST = "const"
Enum.SymbolKind_LOCAL = "local"
Enum.SymbolKind_PARAM = "param"
Enum.SymbolKind_ITER = "iter"

Enum.CastKind_COVAR = "@"
Enum.CastKind_CONTRA = "@>"
Enum.CastKind_CONIL = "@!"
Enum.CastKind_FORCE = "@?"
Enum.CastKind_POLY = "@<"

do return Enum
 end 
end end
--thlua.Enum end ==========)

--thlua.Exception begin ==========(
do local _ENV = _ENV
packages['thlua.Exception'] = function (...)

local class = require "thlua.class"


	  


local Exception = class ()
Exception.__tostring=function(t)
	do return "Exception:"..tostring(t.node)..":"..t.msg
 end end

function Exception:ctor(vMsg, vNode)
	self.msg = tostring(vMsg)
	self.node = vNode
end

do return Exception
 end 
end end
--thlua.Exception end ==========)

--thlua.TestCase begin ==========(
do local _ENV = _ENV
packages['thlua.TestCase'] = function (...)

local Runtime = require "thlua.runtime.DiagnosticRuntime"
local CodeEnv = require "thlua.code.CodeEnv"
local SplitCode = require "thlua.code.SplitCode"

	  
	  


local TestCase = {}
TestCase.__index = TestCase

function TestCase.new(vScript)
	local nLineToResult   = {}
	local nLineList = {}
	for nLine in string.gmatch(vScript, "([^\n]*)") do
		nLineList[#nLineList + 1] = nLine
		if nLine:match("--E$") then
			nLineToResult[#nLineList] = 0
		end
	::continue:: end
	local self = setmetatable({
		_runtime = nil  ,
		_script = vScript,
		_lineToResult = nLineToResult,
	}, TestCase)
	self._runtime = Runtime.new({
		thluaSearch=function(vRuntime, vPath)
			error("test case can't search path")
		end,
		thluaParseFile=function(vRuntime, vFileName)
			if vFileName == "[test]" then
				local ok, nCodeEnv = pcall(CodeEnv.new, self._script, vFileName)
				if not ok then
					error(nCodeEnv)
				end
				do return nCodeEnv
			 end else
				error("test case can only parse its script")
			end
		end,
		thluaGlobalFile=function(vRuntime, vPackage)
			local nContent = require("thlua.global."..vPackage)
			local nCodeEnv = CodeEnv.new(nContent, "@virtual-file:"..vPackage)
			do return nCodeEnv
		 end end
	})
	do return self
 end end

function TestCase:getRuntime()
	do return self._runtime
 end end

function TestCase.go(vScript, vName)
	if not vName then
		local nInfo = debug.getinfo(2)
		print(nInfo.source..":"..nInfo.currentline..":")
	else
		print(vName)
	end
	local case = TestCase.new(vScript)
	local nRuntime = case:getRuntime()
	local oldprint = print
	do
		print = function(...)
		end
	end
	nRuntime:pmain("[test]")
	print = oldprint
	local nLineToResult = case._lineToResult
	for _, nDiaList in pairs(nRuntime:getAllDiagnostic()) do
		for _, nDiagnostic in pairs(nDiaList) do
			local nLine = nDiagnostic.node.l
			local nResult = nLineToResult[nLine]
			if type(nResult) == "number" then
				nLineToResult[nLine] = nResult + 1
			else
				nLineToResult[nLine] = nDiagnostic.msg
			end
		::continue:: end
	::continue:: end
	local l    = {}
	for nLine, nResult in pairs(nLineToResult) do
		l[#l + 1] = {nLine, nResult}
	::continue:: end
	for _, nPair in pairs(l) do
		local nLine, nResult = nPair[1], nPair[2]
		if nResult == 0 then
			print(nLine, "fail: no diagnostic")
		elseif type(nResult) == "string" then
			print(nLine, "fail: diagnostic unexpected", nResult)
		else
			print(nLine, "ok")
		end
	::continue:: end
end


do return TestCase
 end 
end end
--thlua.TestCase end ==========)

--thlua.auto.AutoFlag begin ==========(
do local _ENV = _ENV
packages['thlua.auto.AutoFlag'] = function (...)

do return {}
 end 
end end
--thlua.auto.AutoFlag end ==========)

--thlua.auto.AutoHolder begin ==========(
do local _ENV = _ENV
packages['thlua.auto.AutoHolder'] = function (...)

local Exception = require "thlua.Exception"


	  
	  


local AutoHolder = {}
AutoHolder.__index = AutoHolder
AutoHolder.__tostring = function(self)
	do return "auto@"..tostring(self._node)
 end end

function AutoHolder.new(vNode , vContext)
	local self = setmetatable({
		_node=vNode,
		_context=vContext,
		_term=false
	}, AutoHolder)
	do return self
 end end

function AutoHolder:checkRefineTerm(vContext)
	local nTerm = self._term
	if nTerm then
		do return nTerm
	 end else
		error(Exception.new("undeduced auto param is used", vContext:getNode()))
	end
end

function AutoHolder:setAutoCastType(vContext, vType)
	local nTerm = vContext:RefineTerm(vType)
	self._term = nTerm
	do return nTerm
 end end

function AutoHolder:getRefineTerm()
	do return self._term
 end end

function AutoHolder:getType()
	local nTerm = self._term
	do return nTerm and nTerm:getType()
 end end

function AutoHolder:getNode()
	do return self._node
 end end

function AutoHolder.is(t)
	do return getmetatable(t) == AutoHolder
 end end

do return AutoHolder
 end 
end end
--thlua.auto.AutoHolder end ==========)

--thlua.auto.AutoTail begin ==========(
do local _ENV = _ENV
packages['thlua.auto.AutoTail'] = function (...)

local AutoHolder = require "thlua.auto.AutoHolder"
local DotsTail = require "thlua.tuple.DotsTail"


	  
	  


local AutoTail = {}
AutoTail.__index = AutoTail

function AutoTail.new(vNode, vContext, vInit)
	local self = setmetatable({
		_node=vNode,
		_context=vContext,
		_holderList=vInit or {},
		_sealTail=false  ,
	}, AutoTail)
	do return self
 end end

function AutoTail:getMore(vContext, vMore)
	local nList = self._holderList
	local nHolder = nList[vMore]
	if nHolder then
		do return nHolder
	 end else
		local nSealTail = self._sealTail
		if not nSealTail then
			for i=#nList + 1, vMore do
				nList[i] = AutoHolder.new(self._node, self._context)
			::continue:: end
			do return nList[vMore]
		 end else
			if nSealTail == true then
				do return vContext:NilTerm()
			 end else
				do return nSealTail:getMore(vContext, vMore - #nList)
			 end end
		end
	end
end

function AutoTail:openTailFrom(vContext, vFrom)
	if vFrom == 1 then
		do return self
	 end elseif vFrom > 1 then
		local nSelfHolderList = self._holderList
		local nSelfLen = #nSelfHolderList
		local nNewHolderList = {}
		for i=vFrom, nSelfLen do
			nNewHolderList[#nNewHolderList + 1] = nSelfHolderList[i]
			nSelfHolderList[i] = nil
		::continue:: end
		local nNewAutoTail = AutoTail.new(self._node, self._context, nNewHolderList)
		self._sealTail = nNewAutoTail
		do return nNewAutoTail
	 end else
		error("openTailFrom must take from > 0")
	end
end

function AutoTail:sealTailFrom(vContext, vFrom, vSealTail )
	if vSealTail == true then
		self._sealTail = true
	else
		self._sealTail = DotsTail.new(vContext, vSealTail)
	end
end

    
function AutoTail:recurPutTermWithTail(vList) 
	local nTail = self._sealTail
	if not nTail then
		do return self
	 end end
	for i,v in ipairs(self._holderList) do
		local nTerm = v:getRefineTerm()
		if nTerm then
			vList[#vList + 1] = nTerm
		else
			vList[#vList + 1] = v
		end
	::continue:: end
	if nTail == true then
		do return false
	 end else
		if AutoTail.is(nTail) then
			do return nTail:recurPutTermWithTail(vList)
		 end else
			do return nTail
		 end end
	end
end

           
function AutoTail:_recurPutTypeWhenCheckout(vList, vSeal) 
	for i,v in ipairs(self._holderList) do
		local nType = v:getType()
		if nType then
			vList[#vList + 1] = nType
		else
			do return false
		 end end
	::continue:: end
	local nTail = self._sealTail
	if not nTail then
		if vSeal then
			self._sealTail = true
			do return true
		 end else
			do return false
		 end end
	elseif nTail == true then
		do return true
	 end elseif AutoTail.is(nTail) then
		do return nTail:_recurPutTypeWhenCheckout(vList, vSeal)
	 end else
		do return nTail:getRepeatType()
	 end end
end

function AutoTail:checkTypeTuple(vSeal)
	local nList = {}
	local nDotsType = self:_recurPutTypeWhenCheckout(nList, vSeal or false)
	if not nDotsType then
		do return false
	 end else
		local nContext = self._context
		local nTuple = nContext:getTypeManager():TypeTuple(nContext:getNode(), nList)
		if nDotsType == true then
			do return nTuple
		 end else
			do return nTuple:withDots(nDotsType)
		 end end
	end
end

function AutoTail.is(t)
	do return getmetatable(t) == AutoTail
 end end

do return AutoTail
 end 
end end
--thlua.auto.AutoTail end ==========)

--thlua.boot begin ==========(
do local _ENV = _ENV
packages['thlua.boot'] = function (...)
local boot = require "thlua.code.ParseEnv"

-- start check from a main file
function boot.runCheck(vMainFileName)
	boot.patch()
	local DiagnosticRuntime = require "thlua.runtime.DiagnosticRuntime"
	local nRuntime = DiagnosticRuntime.new()
	assert(nRuntime:pmain(vMainFileName))
end

-- make play groud
function boot.makePlayGround()
	local PlayGround = require "thlua.server.PlayGround"
	local playground = PlayGround.new()
	return function(a, b)
		return playground:update(a, b)
	end
end

-- run language server
function boot.runServer(vMode, vGlobalPathOrNil)
	boot.patch()
	local FastServer = require "thlua.server.FastServer"
	local SlowServer = require "thlua.server.SlowServer"
	local BothServer = require "thlua.server.BothServer"
	local server
	if vMode == "fast" then
		server = FastServer.new(vGlobalPathOrNil)
	elseif vMode == "slow" then
		server = SlowServer.new(vGlobalPathOrNil)
	else
		server = BothServer.new(vGlobalPathOrNil)
	end

	print=function(...)
		--[[client:notify("window/logMessage", {
			message = client:packToString(3, ...),
			type = 3,
		})]]
	end

	server:mainLoop()
end

return boot

end end
--thlua.boot end ==========)

--thlua.builder.DoBuilder begin ==========(
do local _ENV = _ENV
packages['thlua.builder.DoBuilder'] = function (...)

local Exception = require "thlua.Exception"
  

local DoBuilder = {}
DoBuilder.__index=DoBuilder

function DoBuilder.new(vContext, vNode)
	do return setmetatable({
		pass=false,
	}, DoBuilder)
 end end

function DoBuilder:build(vHintInfo)
	if vHintInfo.attrSet.pass then
		self.pass = true
	end
end

do return DoBuilder
 end 
end end
--thlua.builder.DoBuilder end ==========)

--thlua.builder.FunctionBuilder begin ==========(
do local _ENV = _ENV
packages['thlua.builder.FunctionBuilder'] = function (...)

local AutoFlag = require "thlua.auto.AutoFlag"
local AutoFunction = require "thlua.type.func.AutoFunction"
local Reference = require "thlua.refer.Reference"
local Exception = require "thlua.Exception"
local Enum = require "thlua.Enum"
local Interface = require "thlua.type.object.Interface"
local AutoHolder = require "thlua.auto.AutoHolder"
local ClassFactory = require "thlua.type.func.ClassFactory"
local ClassTable = require "thlua.type.object.ClassTable"
local TermTuple = require "thlua.tuple.TermTuple"
local RetBuilder = require "thlua.tuple.RetBuilder"
local class = require "thlua.class"


	  
	  

	  
	    

	  
	      
	   

	   
		 
	

	   
		 
		 
		
		 
		 
		 
		  
	

	   
		
		
		
		
		
	 
		
	


local FunctionBuilder = {}
FunctionBuilder.__index=FunctionBuilder

function FunctionBuilder.new(
	vStack,
	vNode ,
	vUpState,
	vInfo,
	vPrefixHint,
	vParRetMaker
)
	local nManager = vStack:getTypeManager()
	local self = {
		_stack=vStack,
		_manager=nManager,
		_dirtyProcessor=nManager:getDirtyProcessor(),
		_node=vNode,
		_lexCapture=vUpState,
		_prefixHint=vPrefixHint,
		_pass=vPrefixHint.attrSet.pass and true or false,
		_parRetMaker=vParRetMaker,
	}
	for k,v in pairs(vInfo) do
		self[k] = v
	::continue:: end
	setmetatable(self, FunctionBuilder)
	do return self
 end end

function FunctionBuilder:_makeRetTuples(
	vSuffixHint,
	vTypeList,
	vSelfType
)
	local nRetBuilder = RetBuilder.new(self._manager, self._node)
	local ok, err = pcall(vSuffixHint.caller, {
		extends=function(vHint, _)
			error(self._node:toExc("extends can only be used with function:class"))
			do return vHint
		 end end,
		implements=function(vHint, _)
			error(self._node:toExc("impl can only be used with function:class"))
			do return vHint
		 end end,
		isguard=function(vHint, vType)
			error(self._node:toExc("isguard can only be used with function.open"))
			do return vHint
		 end end,
		mapguard=function(vHint, vType)
			error(self._node:toExc("mapguard can only be used with function.open"))
			do return vHint
		 end end,
		RetDots=function(vHint, vFirst, ...)
			nRetBuilder:chainRetDots(self._node, vFirst, ...)
			do return vHint
		 end end,
		Ret=function(vHint, ...)
			nRetBuilder:chainRet(self._node, ...)
			do return vHint
		 end end,
		Err=function(vHint, vErrType)
			nRetBuilder:chainErr(self._node, vErrType)
			do return vHint
		 end end,
	})
	if not ok then
		error(self._node:toExc(tostring(err)))
	end
	if nRetBuilder:isEmpty() then
		do return false
	 end end
	local nRetTuples = nRetBuilder:build()
	if not self._hasRetSome then
		if nRetTuples and not self._pass then
			local hasVoid = false
			local hasSome = false
			nRetTuples:foreachWithFirst(function(vTypeTuple, _)
				if #vTypeTuple > 0 then
					hasSome = true
				else
					hasVoid = true
				end
			end)
			if hasSome and not hasVoid then
				if not self._pass then
					self._stack:getRuntime():nodeError(self._node, "hint return something but block has no RetStat")
				end
			end
		end
	end
	do return nRetTuples
 end end

function FunctionBuilder:_buildInnerFn()  
	local nNode = self._node
	assert(nNode.tag == "Function")
	local nPolyParNum = self._polyParNum
	local nFnMaker = function(vPolyParList, vSelfType)
		local nAutoFn = self._stack:newAutoFunction(nNode, self._lexCapture)
		local nNewStack = nAutoFn:getBuildStack()
		nAutoFn:initAsync(function()
			local nGenParam, nSuffixHint, nGenFunc = self._parRetMaker(nNewStack, vPolyParList, vSelfType)
			local nCastTypeFn = nAutoFn:pickCastTypeFn()
			  
			local nCastArgs = nCastTypeFn and nCastTypeFn:getParTuple():makeTermTuple(nNewStack:inplaceOper())
			local nParTermTuple = nGenParam(nCastArgs)
			local nParTuple = nParTermTuple:checkTypeTuple()
			  
			local nCastRet = nCastTypeFn and nCastTypeFn:getRetTuples()
			local nHintRetTuples = self:_makeRetTuples(nSuffixHint, vPolyParList, vSelfType)
			if nHintRetTuples and nCastRet then
				if not nCastRet:includeTuples(nHintRetTuples) then
					nNewStack:inplaceOper():error("hint return not match when cast")
				end
			end
			local nRetTuples = nHintRetTuples or nCastRet or (not self._hasRetSome and self._manager:VoidRetTuples(self._node))
			do return nParTuple, nRetTuples, function()
				if self._pass then
					if not nParTuple or not nRetTuples then
						error(self._node:toExc("pass function can't take auto return or auto parameter"))
					end
					do return nParTuple, nRetTuples
				 end else
					local nRetTermTuple, nErrType = nGenFunc()
					local nParTuple = nParTuple or nParTermTuple:checkTypeTuple(true)
					if not nParTuple then
						nNewStack:inplaceOper():error("auto parameter deduce failed")
						error(self._node:toExc("auto parameter deduce failed"))
					end
					local nRetTuples = nRetTuples or self._manager:SingleRetTuples(self._node, nRetTermTuple:checkTypeTuple(), nErrType)
					if not nRetTuples then
						          
						nNewStack:inplaceOper():error("auto return deduce failed")
						error(self._node:toExc("auto return deduce failed"))
					end
					do return nParTuple, nRetTuples
				 end end
			end
		 end end)
		do return nAutoFn
	 end end
	if not self._member then
		if nPolyParNum <= 0 then
			local ret = nFnMaker({}, false)
			self._stack:getSealStack():scheduleSealType(ret)
			do return ret
		 end else
			do return self._manager:SealPolyFunction(self._node, function(...)
				do return nFnMaker({...}, false)
			 end end, nPolyParNum, self._stack)
		 end end
	else
		local nPolyFn = self._manager:SealPolyFunction(self._node, function(self, ...)
			do return nFnMaker({...}, self)
		 end end, nPolyParNum + 1, self._stack)
		do return self._manager:AutoMemberFunction(self._node, nPolyFn)
	 end end
end

function FunctionBuilder:_buildOpen()
	if self._hasSuffixHint then
		local nGuardFn = self._stack:newOpenFunction(self._node, self._lexCapture)
		local nMakerStack = nGuardFn:newStack(self._node, self._stack)
		local nSetted = false
		local nGenParam, nSuffixHint, nGenFunc = self._parRetMaker(nMakerStack, {}, false)
		local ok, err = pcall(nSuffixHint.caller, {
			extends=function(vHint, _)
				error(self._node:toExc("extends can only be used with function:class"))
				do return vHint
			 end end,
			implements=function(vHint, _)
				error(self._node:toExc("impl can only be used with function:class"))
				do return vHint
			 end end,
			RetDots=function(vHint, vFirst, ...)
				error(self._node:toExc("open function can't take RetDots"))
				do return vHint
			 end end,
			Ret=function(vHint, ...)
				error(self._node:toExc("open function can't take Ret"))
				do return vHint
			 end end,
			Err=function(vHint, _)
				error(self._node:toExc("open function can't take Err"))
				do return vHint
			 end end,
			isguard=function(vHint, vType)
				assert(not nSetted, self._node:toExc("isguard can only use once here"))
				nGuardFn:lateInitFromIsGuard(vType)
				do return vHint
			 end end,
			mapguard=function(vHint, vDict)
				local nMapObject = self._manager:buildInterface(self._node, vDict)
				assert(not nSetted, self._node:toExc("isguard can only use once here"))
				nGuardFn:lateInitFromMapGuard(nMapObject)
				do return vHint
			 end end,
		})
		if not ok then
			error(Exception.new(tostring(err), self._node))
		end
		do return nGuardFn
	 end else
		do return self._stack:newOpenFunction(self._node, self._lexCapture):lateInitFromBuilder(self._polyParNum, function(vOpenFn, vContext, vPolyArgs, vTermTuple)
			local nGenParam, nSuffixHint, nGenFunc = self._parRetMaker(vContext, vPolyArgs, false)
			nGenParam(vTermTuple)
			do return nGenFunc()
		 end end)
	 end end
end

function FunctionBuilder:_buildClass() 
	local nNode = self._node
	assert(nNode.tag == "Function")
	local nPrefixHint = self._prefixHint
	local nReferOrNil = nil
	local ok, err = pcall(nPrefixHint.caller, {
		class=function(vHint, vRefer)
			assert(vRefer and Reference.is(vRefer), self._node:toExc("impl's first arg must be a Reference"))
			nReferOrNil = vRefer
			do return vHint
		 end end,
	})
	if not ok then
		error(self._node:toExc(tostring(err)))
	end
	local nRefer = assert(nReferOrNil, self._node:toExc("reference not setted when function:class"))
	local nPolyParNum = self._polyParNum
	local nFnMaker = function(vPolyParList)
		local nInterfaceGetter = function(vSuffixHint)  
			local nImplementsArg = nil
			local nExtendsArg = nil
			local nErrType = nil
			local ok, err = pcall(vSuffixHint.caller, {
				implements=function(vHint, vInterface)
					nImplementsArg = vInterface
					do return vHint
				 end end,
				extends=function(vHint, vBaseClass)
					nExtendsArg = vBaseClass
					do return vHint
				 end end,
				Ret=function(vHint, ...)
					error(self._node:toExc("class function can't take Ret"))
					do return vHint
				 end end,
				RetDots=function(vHint, vFirst, ...)
					error(self._node:toExc("class function can't take RetDots"))
					do return vHint
				 end end,
				Err=function(vHint, vErrType)
					nErrType = self._dirtyProcessor:easyToType(self._node, vErrType)
					do return vHint
				 end end,
				isguard=function(vHint, vType)
					error(self._node:toExc("isguard can only be used with function.open"))
					do return vHint
				 end end,
				mapguard=function(vHint, vType)
					error(self._node:toExc("mapguard can only be used with function.open"))
					do return vHint
				 end end,
			})
			if not ok then
				error(Exception.new(tostring(err), self._node))
			end
			local nExtendsTable = false
			if nExtendsArg then
				local nType = nExtendsArg:checkAtomUnion()
				if nType:isUnion() then
					error(self._node:toExc("base class can't be union"))
				end
				if ClassTable.is(nType) then
					nExtendsTable = nType
				else
					if nType == self._manager.type.False or nType == self._manager.type.Nil then
						       
					else
						error(self._node:toExc("base class type must be ClassTable"))
					end
				end
			end
			local nImplementsInterface = nExtendsTable and nExtendsTable:getInterface() or self._manager.type.AnyObject
			if nImplementsArg then
				local nType = nImplementsArg:checkAtomUnion()
				if nType:isUnion() then
					error(self._node:toExc("interface can't be union"))
				end
				if Interface.is(nType) then
					nImplementsInterface = nType
				else
					if nType == self._manager.type.False or nType == self._manager.type.Nil then
						      
					else
						self._stack:getRuntime():nodeError(self._node, "implements must take Interface or false value")
					end
				end
			end
			do return nExtendsTable, nImplementsInterface, nErrType
		 end end
		local nFactory = self._stack:newClassFactory(nNode, self._lexCapture)
		local nClassTable = nFactory:getClassTable()
		local nNewStack = nFactory:getBuildStack()
		local nGenParam = nil
		local nGenFunc = nil
		local nErrType = nil
		nClassTable:initAsync(function()
			local nGenParam_, nSuffixHint, nGenFunc_ = self._parRetMaker(nNewStack, vPolyParList, false)
			nGenParam = nGenParam_
			nGenFunc = nGenFunc_
			local nExtends, nImplements, nErrType_ = nInterfaceGetter(nSuffixHint)
			nErrType = nErrType_
			do return nExtends, nImplements
		 end end)
		nFactory:initAsync(function()
			nClassTable:waitInit()
			local nParTermTuple = nGenParam(false)
			local nParTuple = nParTermTuple:checkTypeTuple()
			local nRetTuples = self._manager:SingleRetTuples(self._node, self._manager:TypeTuple(self._node, {nClassTable}), nErrType)
			do return nParTuple, nRetTuples, function()
				nNewStack:setClassTable(nClassTable)
				nGenFunc()
				local nParTuple = nParTuple or nParTermTuple:checkTypeTuple(true)
				if not nParTuple then
					nNewStack:inplaceOper():error("auto parameter deduce failed")
					error(self._node:toExc("auto parameter deduce failed"))
				end
				nClassTable:onBuildFinish()
				do return nParTuple, nRetTuples
			 end end
		 end end)
		do return nFactory
	 end end
	if nPolyParNum <= 0 then
		local nFactory = nFnMaker({})
		nRefer:setAssignAsync(self._node, function()
			do return nFactory:getClassTable(true)
		 end end)
		self._stack:getSealStack():scheduleSealType(nFactory)
		do return nFactory
	 end else
		local nPolyFn = self._manager:SealPolyFunction(self._node, function(...)
			do return nFnMaker({...})
		 end end, nPolyParNum, self._stack)
		nRefer:setTemplateAsync(self._node, function(...)
			local nFactory = nPolyFn:noCtxCastPoly({...})
			assert(ClassFactory.is(nFactory), "class factory's poly must return factory type")
			do return nFactory:getClassTable(true)
		 end end, nPolyParNum)
		do return nPolyFn
	 end end
end

function FunctionBuilder:build()
	local nAttrSet = self._prefixHint.attrSet
	if nAttrSet.open then
		do return self:_buildOpen()
	 end elseif nAttrSet.class then
		if self._member then
			error(self._node:toExc("class factory can't be member-function-like"))
		end
		do return self:_buildClass()
	 end else
		do return self:_buildInnerFn()
	 end end
end

do return FunctionBuilder
 end 
end end
--thlua.builder.FunctionBuilder end ==========)

--thlua.builder.TableBuilder begin ==========(
do local _ENV = _ENV
packages['thlua.builder.TableBuilder'] = function (...)

local OpenTable = require "thlua.type.object.OpenTable"
local AutoTable = require "thlua.type.object.AutoTable"
local RefineTerm = require "thlua.term.RefineTerm"
local Exception = require "thlua.Exception"
local class = require "thlua.class"
local TableBuilder = {}


	  
	  



	   
		
		
		
		
	
	    


TableBuilder.__index=TableBuilder

function TableBuilder.new(vStack,
	vNode,
	vHintInfo,
	vPairMaker
)
	do return setmetatable({
		_stack=vStack,
		_node=vNode,
		_isConst=vNode.isConst,
		_hintInfo=vHintInfo,
		_pairMaker=vPairMaker,
		_selfInitDict=false  ,
	}, TableBuilder)
 end end

function TableBuilder._makeLongHint(self)
	do return {
		Init=function(vLongHint, vInitDict )
			self._selfInitDict = vInitDict
			do return vLongHint
		 end end,
	}
 end end

function TableBuilder:_build(vNewTable )
	      
	local nStack = self._stack
	local nManager = nStack:getTypeManager()
	local vList, vDotsStart, vDotsTuple = self._pairMaker()
	local nTypePairList   = {}
	for i, nPair in ipairs(vList) do
		local nKey = nPair.key:getType()
		local nTerm = nPair.value
		local nValue = nTerm:getType()
		if nPair.autoPrimitive and not self._isConst then
			   
		end
		if nKey:isUnion() or not nKey:isSingleton() then
			nValue = nManager:checkedUnion(nValue, nManager.type.Nil)
			if OpenTable.is(vNewTable) then
				self._stack:getRuntime():nodeError(self._node, "open table can only take singleton type as key")
			else
				nTypePairList[i] = {nKey, nValue}
			end
		else
			nTypePairList[i] = {nKey, nValue}
		end
	::continue:: end
	if vDotsTuple then
		local nTypeTuple = vDotsTuple:checkTypeTuple()
		local nRepeatType = nTypeTuple:getRepeatType()
		if nRepeatType then
			if OpenTable.is(vNewTable) then
				self._stack:getRuntime():nodeError(self._node, "open table can only take singleton type as key")
			else
				nTypePairList[#nTypePairList + 1] = {
					nManager.type.Integer, nManager:checkedUnion(nRepeatType, nManager.type.Nil)
				}
			end
		else
			for i=1, #nTypeTuple do
				local nKey = nManager:Literal(vDotsStart + i - 1)
				local nType = assert(vDotsTuple:rawget(i)):getType()
				nTypePairList[#nTypePairList + 1] = {
					nKey, nType
				}
			::continue:: end
		end
	end
	local nSelfInitDict = self._selfInitDict
	if nSelfInitDict then
		for nKey, nValue in pairs(nSelfInitDict) do
			nKey:checkAtomUnion():foreach(function(vSubKey)
				nTypePairList[#nTypePairList + 1] = {
					vSubKey, nManager:checkedUnion(nValue, nManager.type.Nil)
				}
			end)
		::continue:: end
	end
	local nKeyUnion, nTypeDict = nManager:typeMapReduce(nTypePairList, function(vList)
		do return nManager:unionReduceType(vList)
	 end end)
	if OpenTable.is(vNewTable) then
		vNewTable:initByBranchKeyValue(self._node, self._stack:topBranch(), nKeyUnion, nTypeDict)
	else
		vNewTable:initByKeyValue(self._node, nKeyUnion, nTypeDict)
	end
end

function TableBuilder:build()
	local nLongHint = self:_makeLongHint()
	local ok, err = pcall(self._hintInfo.caller, nLongHint)
	if not ok then
		error(Exception.new(tostring(err), self._node))
	end
	local nStack = self._stack
	local nManager = nStack:getTypeManager()
	local nAttrSet = self._hintInfo.attrSet
	if nAttrSet.class then
		local nNewTable = assert(nStack:getClassTable(), "only function:class(xxx) can build table hint with {.class")
		self:_build(nNewTable)
		do return nNewTable
	 end else
		if nAttrSet.open then
			if self._selfInitDict then
				self._selfInitDict = false
				self._stack:getRuntime():nodeError(self._node, "open table can't use Init()")
			end
			local nNewTable = OpenTable.new(nManager, self._node, self._stack)
			self:_build(nNewTable)
			do return nNewTable
		 end else
			local nNewTable = AutoTable.new(nManager, self._node, self._stack)
			self:_build(nNewTable)
			do return nNewTable
		 end end
	end
end

do return TableBuilder
 end 
end end
--thlua.builder.TableBuilder end ==========)

--thlua.class begin ==========(
do local _ENV = _ENV
packages['thlua.class'] = function (...)
local class2meta={}
local meta2class={}


	  
	  


local META_FIELD = {
	__call=1,
	__tostring=1,
	__len=1,
	__bor=1,
	__band=1,
	__pairs=1,
	    
}

local function class (super)
	local class_type={}
	  
	class_type.ctor=false
	class_type.super=super
	class_type.new=function (...)  
			local obj={}
			do
				local function create(c,...)
					if c.super then
						create(c.super,...)
					end
					if c.ctor then
						c.ctor(obj,...)
					end
				end

				create(class_type,...)
			end
			setmetatable(obj, class_type.meta)
			do return obj
		 end end
	local vtbl={}
	local meta={
		__index=vtbl
	}
	class_type.isDict = (setmetatable({}, {
		__index=function(type2is , if_type)
			local cur_type = class_type
			while cur_type do
				if cur_type == if_type then
					type2is[if_type] = true
					do return true
				 end else
					cur_type = cur_type.super
				end
			::continue:: end
			type2is[if_type] = false
			do return false
		 end end
	}) )  
	class_type.is=function(v)
		local nClassType = meta2class[getmetatable(v) or 1]
		local nIsDict = nClassType and nClassType.isDict
		do return nIsDict and nIsDict[class_type] or false
	 end end
	class_type.meta=meta
	class2meta[class_type]=meta
	meta2class[meta]=class_type

	setmetatable(class_type,{__newindex=
		function(t,k,v)
			if META_FIELD[k] then
				meta[k] = v
			else
				vtbl[k]=v
			end
		end
	})

	if super then
		local super_meta = class2meta[super]
		for k,v in pairs(super_meta.__index) do
			vtbl[k] = v
		::continue:: end
		for k,v in pairs(super_meta) do
			if k ~= "__index" then
				meta[k] = v
			end
		::continue:: end
	end

	do return class_type
 end end

do return class
 end 
end end
--thlua.class end ==========)

--thlua.code.CodeEnv begin ==========(
do local _ENV = _ENV
packages['thlua.code.CodeEnv'] = function (...)

local ParseEnv = require "thlua.code.ParseEnv"
local Node = require "thlua.code.Node"
local Exception = require "thlua.Exception"
local VisitorExtend = require "thlua.code.VisitorExtend"
local SymbolVisitor = require "thlua.code.SymbolVisitor"
local SearchVisitor = require "thlua.code.SearchVisitor"
local HintGener = require "thlua.code.HintGener"
local SplitCode = require "thlua.code.SplitCode"
local class = require "thlua.class"


	  
	  
	    
	   
	   
		  
		  
		 
	


local CodeEnv = {}
CodeEnv.__index=CodeEnv

function CodeEnv.new(vCode , vChunkName, vChunkWithInject)
	local nSplitCode = SplitCode.is(vCode) and vCode or SplitCode.new(vCode)
	local self = setmetatable({
		_code = nSplitCode,
		_chunkName = vChunkName,
		_searcher = SearchVisitor.new(nSplitCode),
		_nodeList = {},
		_typingCode = "--[[no gen code ]]",
		_astTree = nil,
		_luaCode = "",
		_typingFn = nil,
	}, CodeEnv)
	if not vChunkWithInject then
		local nAst, nErr = ParseEnv.parse(nSplitCode:getContent())
		if not nAst then
			self:_prepareBaseNode(nErr)
			error(Exception.new(nErr[1], nErr))
		end
		self._astTree = nAst
		self._luaCode = nErr
	else
		self._astTree = vChunkWithInject
	end
	self._typingFn = (self:_buildTypingFn() ) 
	do return self
 end end

function CodeEnv:_prepareBaseNode(vNode)
	vNode.path = self._chunkName
	vNode.l, vNode.c = self._code:fixupPos(vNode.pos, vNode)
	Node.bind(vNode)
end

function CodeEnv:_prepareAstNode(vNode, vParent)
	local nNodeList = self._nodeList
	local nIndex = #nNodeList + 1
	nNodeList[nIndex] = vNode
	vNode.index = nIndex
	vNode.parent = vParent or nil
	self:_prepareBaseNode(vNode)
end

function CodeEnv:_prepare()
	local nAst = self._astTree
	assert(#self._nodeList == 0, "node list has been setted")
	      
	local nStack = {}
	local nVisitor = VisitorExtend(function(visitor, vNode)
		  
		self:_prepareAstNode(vNode, nStack[#nStack] or false)
		   
		nStack[#nStack + 1] = vNode
		visitor:rawVisit(vNode)
		nStack[#nStack] = nil
	end)
	nVisitor:realVisit(nAst)
	   
	self._searcher:realVisit(nAst)
	   
	local nSymbolVisitor = SymbolVisitor.new(self._code)
	nSymbolVisitor:realVisit(nAst)
	   
	local gener = HintGener.new(self._astTree)
	local nTypingCode = gener:genCode()
	self._typingCode = nTypingCode
end

function CodeEnv:_buildTypingFn()
	self:_prepare()
	local nFunc, nInfo = load(self._typingCode, self._chunkName, "t", setmetatable({}, {
		__index=function(t,k)
			    
			error("indexing global is fatal error, name="..k)
		end
	}))
	if not nFunc then
		error(Exception.new(tostring(nInfo), self._astTree))
	end
	assert(type(nFunc) == "function", Exception.new("typing code must return function", self._astTree))
	if not nFunc then
		    
		error(Exception.new(tostring(nInfo), self._astTree))
	end
	do return nFunc
 end end

function CodeEnv:getNodeList()
	do return self._nodeList
 end end

function CodeEnv:getAstTree()
	do return self._astTree
 end end

function CodeEnv:getTypingCode()
	do return self._typingCode
 end end

function CodeEnv:getTypingFn()
	do return self._typingFn
 end end

function CodeEnv:makeFocusList(vNode)
	local nCurNode = vNode
	local nFocusList = {}
	while nCurNode do
		if nCurNode.tag == "Function" then
			local nFunc = nCurNode  
			if nFunc.letNode then
				nFocusList[#nFocusList + 1] = nFunc
			end
		end
		nCurNode = nCurNode.parent
	::continue:: end
	do return nFocusList
 end end

function CodeEnv:traceBlockRegion(vTraceList) 
	local nRetBlock = self._astTree[3]
	for i=1,#vTraceList-1 do
		local nTrace = vTraceList[i]
		local nNextBlock = nRetBlock.subBlockList[nTrace]
		if not nNextBlock then
			break
		else
			nRetBlock = nNextBlock
		end
	::continue:: end
	do return nRetBlock, self:makeFocusList(nRetBlock)
 end end

function CodeEnv:searchHintExprBySuffix(vPos)  
	local nPair = self._searcher:searchHintSuffixPair(vPos)
	if not nPair then
		do return false
	 end end
	local nRetBlock = nil
	local nPrefixNode = nPair[1]
	    
	local nCurNode = nPrefixNode
	local nInHint = true
	while nCurNode do
		if nCurNode.tag == "HintSpace" then
			nInHint = false
		elseif nCurNode.tag == "Block" then
			if not nInHint then
				nRetBlock = nCurNode  
				break
			end
		end
		nCurNode = nCurNode.parent
	::continue:: end
	if not nRetBlock then
		do return false
	 end end
	do return nPrefixNode, nRetBlock, self:makeFocusList(nPrefixNode)
 end end

function CodeEnv:searchExprBySuffix(vPos) 
	local nPair = self._searcher:searchSuffixPair(vPos)
	if not nPair then
		do return false
	 end end
	local nPrefixNode = nPair[1]
	do return nPrefixNode, self:makeFocusList(nPrefixNode)
 end end

function CodeEnv:searchIdent(vPos)
	do return self._searcher:searchIdent(vPos)
 end end

function CodeEnv:getChunkName()
	do return self._chunkName
 end end

function CodeEnv:getSplitCode()
	do return self._code
 end end

function CodeEnv.is(v)
	do return getmetatable(v) == CodeEnv
 end end

function CodeEnv.genInjectFnByError(vSplitCode, vFileUri, vWrongContent) 
	local nRightAst, nErrNode = ParseEnv.parse(vWrongContent)
	if nRightAst then
		do return false
	 end end
	local nInjectTrace = nErrNode[2]
	if not nInjectTrace then
		do return false
	 end end
	local nChunk = nInjectTrace.capture
	local nOkay, nInjectFn = pcall(function()
		assert(nChunk.injectNode)
		local nFocusEnv = CodeEnv.new(vSplitCode, vFileUri, nChunk)
		
			    
		
		local nRawInjectFn = (nFocusEnv:getTypingFn() ) 
		do return function(vStack, vGetter)
			do return nRawInjectFn(nFocusEnv:getNodeList(), vStack, vGetter)
		 end end
	 end end)
	if nOkay then
		do return nInjectFn, nInjectTrace
	 end else
		do return false
	 end end
end

function CodeEnv:getLuaCode()
	do return self._luaCode
 end end

do return CodeEnv
 end 
end end
--thlua.code.CodeEnv end ==========)

--thlua.code.HintGener begin ==========(
do local _ENV = _ENV
packages['thlua.code.HintGener'] = function (...)



  
  

   
	             
	  
 
	


   

  
	   
	  
		   
	
	 




local function autoPrimitive(vExpr)
	local nTag = vExpr.tag
	if nTag == "String" or nTag == "Number" or nTag == "True" or nTag == "False" then
		do return not vExpr.isConst
	 end else
		do return false
	 end end
end

local TagToVisiting = {
	Chunk=function(self, node)
		local nInjectNode = node.injectNode
		if not nInjectNode then
			do return {
				'local ____nodes,____stk,____globalTerm=... ',
				self:visitIdentDef(node[1], "____globalTerm"),
				" return ", self:stkWrap(node).CHUNK_TYPE(self:visitFunc(node))
			}
		 end else
			if nInjectNode.tag ~= "HintSpace" then
				do return {
					'local ____nodes,____stk,____injectGetter=... ',
					"local let, _ENV, _G = ____stk:INJECT_BEGIN() ",
					" return ", self:visit(nInjectNode),
				}
			 end else
				do return {
					'local ____nodes,____stk,____injectGetter=... ',
					"local let, _ENV, _G = ____stk:INJECT_BEGIN() ",
					" return ", self:fixIHintSpace(nInjectNode),
				}
			 end end
		end
	end,
	HintTerm=function(self, node)
		do return self:stkWrap(node).HINT_TERM(self:fixIHintSpace(node[1]))
	 end end,
	Block=function(self, node)
		do return self:concatList(node, function(i, vStatNode)
			do return self:visit(vStatNode)
		 end end, " ")
		    
		   
		   
		   
		     
			   
				    
			
				    
			
			    
				  
			
		
		    
		
			 
				  
						 
				  
				
					  
							 
					  
				
			
		
	 end end,
	Do=function(self, node)
		do return self:rgnWrap(node).DO(
			self:visitLongHint(node.hintLong),
			self:fnWrap()(self:visit(node[1]))
		)
	 end end,
	Set=function(self, node)
		do return {
			" local ", self:concatList(node[1], function(i,v)
				do return "____set_a"..i
			 end end, ","),
			"=", self:stkWrap(node).EXPRLIST_UNPACK(tostring(#node[1]), self:visit(node[2])),
			self:concatList(node[1], function(i, vVarNode)
				if vVarNode.tag == "Ident" then
					local nDefineIdent = vVarNode.defineIdent
					if nDefineIdent then
						do return self:stkWrap(vVarNode).SYMBOL_SET(
							self:codeNode(nDefineIdent),
							"____set_a"..i
						)
					 end else
						local nIdentENV = vVarNode.isGetFrom
						if self._chunk.injectNode and nIdentENV == self._chunk[1] then
							     
							do return ""
						 end else
							do return self:stkWrap(vVarNode).GLOBAL_SET(
								self:codeNode(nIdentENV  ),
								"____set_a"..i
							)
						 end end
					end
				else
					do return self:stkWrap(vVarNode).META_SET(
						self:visit(vVarNode[1]),
						self:visit(vVarNode[2]),
						"____set_a"..i
					)
				 end end
			end, " ")
		}
	 end end,
	While=function(self, node)
		do return self:rgnWrap(node).WHILE(
			self:visit(node[1]),
			self:fnWrap()(self:visit(node[2]))
		)
	 end end,
	Repeat=function(self, node)
		do return self:rgnWrap(node).REPEAT(
			self:fnWrap()(self:visit(node[1])),
			self:fnWrap()(self:visit(node[2]))
		)
	 end end,
	If=function(self, node)
		local function put(exprNode, blockNode, nextIndex, level)
			local nNext1Node, nNext2Node = node[nextIndex], node[nextIndex + 1]
			if nNext1Node then
				if nNext2Node then
					assert(nNext1Node.tag ~= "Block" and nNext2Node.tag == "Block", "if statement error")
					do return self:rgnWrap(node).IF_TWO(
						self:visit(exprNode),
						self:fnWrap()(self:visit(blockNode)), self:codeNode(blockNode),
						self:fnWrap()(put(nNext1Node, nNext2Node, nextIndex + 2, level + 1))
					)
				 end else
					assert(nNext1Node.tag == "Block")
					do return self:rgnWrap(node).IF_TWO(
						self:visit(exprNode),
						self:fnWrap()(self:visit(blockNode)), self:codeNode(blockNode),
						self:fnWrap()(self:visit(nNext1Node)), self:codeNode(nNext1Node)
					)
				 end end
			else
				do return self:rgnWrap(node).IF_ONE(
					self:visit(exprNode),
					self:fnWrap()(self:visit(blockNode)), self:codeNode(blockNode)
				)
			 end end
		end
		local nExpr, nBlock = node[1], node[2]
		assert(nExpr.tag ~= "Block" and nBlock.tag == "Block", "if statement error")
		do return put(nExpr, nBlock, 3, 1)
	 end end,
	Fornum=function(self, node)
		local nHasStep = node[5] and true or false
		local nBlockNode = node[5] or node[4]
		assert(nBlockNode.tag == "Block", "4th or 5th node must be block")
		do return self:rgnWrap(node).FOR_NUM(
			self:visit(node[2]), self:visit(node[3]), nHasStep and self:visit(node[4]) or "nil",
			self:fnWrap("____fornum")(
				self:visitIdentDef(node[1], "____fornum"),
				self:visit(nBlockNode)
			),
			self:codeNode(nBlockNode)
		)
	 end end,
	Forin=function(self, node)
		do return {
			"local ____n_t_i=", self:stkWrap(node).EXPRLIST_REPACK("false", self:listWrap(self:visit(node[2]))),
			self:rgnWrap(node).FOR_IN(self:fnWrap("____iterTuple")(
				"local ", self:concatList(node[1], function(i, vNode)
					do return "____forin"..i
				 end end, ","),
				"=", self:stkWrap(node).EXPRLIST_UNPACK(tostring(#node[1]), "____iterTuple"),
				self:concatList(node[1], function(i, vIdent)
					do return self:visitIdentDef(vIdent, "____forin"..i)
				 end end, " "),
				self:visit(node[3])
			), "____n_t_i")
		}
	 end end,
	Local=function(self, node)
		local nExprList = node[2]
		do return {
			line=node.l,
			"local ", self:concatList(node[1], function(i, vNode)
				do return "____lo"..i
			 end end, ","), "=",
			#node[2] > 0
				and self:stkWrap(node).EXPRLIST_UNPACK(tostring(#node[1]), self:visit(node[2]))
				or self:concatList(node[1], function(i, vNode)
					  
					do return "nil"
				 end end, ", "),
			self:concatList(node[1], function(i, vIdent)
				local nCurExpr = nExprList[i]
				do return self:visitIdentDef(vIdent, "____lo"..i, nil, nCurExpr and autoPrimitive(nCurExpr) or nil)
			 end end, " ")
		}
	 end end,
	Localrec=function(self, node)
		  
		do return self:visitIdentDef(node[1], self:visit(node[2]), true)
	 end end,
	Goto=function(self, node)
		  
		do return {}
	 end end,
	Label=function(self, node)
		  
		do return {}
	 end end,
	Return=function(self, node)
		do return self:rgnWrap(node).RETURN(
			self:stkWrap(node).EXPRLIST_REPACK(
				"false",
				self:listWrap(self:visit(node[1]))
			)
		)
	 end end,
	Continue=function(self, node)
		do return self:rgnWrap(node).CONTINUE()
	 end end,
	Break=function(self, node)
		do return self:rgnWrap(node).BREAK()
	 end end,
	Call=function(self, node)
		do return self:stkAutoUnpack(node,
			self:stkWrap(node).META_CALL(
				self:visit(node[1]),
				self:stkWrap(node).EXPRLIST_REPACK(
					"true",
					self:listWrap(#node[2] > 0 and self:visit(node[2]) or "")
				)
			)
		)
	 end end,
	Invoke=function(self, node)
		local nHintPolyArgs = node.hintPolyArgs
		do return self:stkAutoUnpack(node,
			self:stkWrap(node).META_INVOKE(
				self:visit(node[1]),
				"\""..node[2][1].."\"",
				self:listWrap(nHintPolyArgs and self:fixIHintSpace(nHintPolyArgs) or ""),
				self:stkWrap(node).EXPRLIST_REPACK(
					"false",
					self:listWrap(#node[3] > 0 and self:visit(node[3]) or "")
				)
			)
		)
	 end end,
	HintSpace=function(self, node)
		if node.kind == "StatHintSpace" then
			         
			do return {
				line = node.l,
				" local ____hintStat=function() ",
				self:fixIHintSpace(node),
				" end ____hintStat() "
			}
		 end else
			error("visit long space or short space in other function")
			do return {}
		 end end
	end,
	Dots=function(self, node)
		do return self:stkAutoUnpack(node, "____vDOTS")
	 end end,
	Nil=function(self, node)
		do return self:stkWrap(node).NIL_TERM()
	 end end,
	True=function(self, node)
		do return self:stkWrap(node).LITERAL_TERM("true")
	 end end,
	False=function(self, node)
		do return self:stkWrap(node).LITERAL_TERM("false")
	 end end,
	Number=function(self, node)
		do return self:stkWrap(node).LITERAL_TERM(self:codeNodeValue(node))
	 end end,
	String=function(self, node)
		do return self:stkWrap(node).LITERAL_TERM(self:codeNodeValue(node))
	 end end,
	Function=function(self, node)
		do return self:visitFunc(node)
	 end end,
	Table=function(self, node)
		local count = 0
		local i2i  = {}
		local tailDots = nil
		for i, nItem in ipairs(node) do
			if nItem.tag ~= "Pair" then
				count = count + 1
				i2i[i] = count
				local nExprTag = nItem.tag
				if i==#node and (nExprTag == "Dots" or nExprTag == "Invoke" or nExprTag == "Call") then
					tailDots = nItem
				end
			end
		::continue:: end
		do return self:stkWrap(node).TABLE_NEW(
			self:visitLongHint(node.hintLong),
			self:fnRetWrap(self:listWrap(self:concatList (node, function(i, vTableItem)
				if vTableItem.tag ~= "Pair" then
					if i==#node and tailDots then
						do return "nil"
					 end else
						do return self:dictWrap({
							node=self:codeNode(vTableItem),
							autoPrimitive=tostring(autoPrimitive(vTableItem)),
							key=self:stkWrap(vTableItem).LITERAL_TERM(tostring(i2i[i])),
							value=self:visit(vTableItem)
						})
					 end end
				else
					do return self:dictWrap({
						node=self:codeNode(vTableItem),
						autoPrimitive=tostring(autoPrimitive(vTableItem[2])),
						key=self:visit(vTableItem[1]),
						value=self:visit(vTableItem[2])
					})
				 end end
			end, ",")), tostring(count), tailDots and self:visit(tailDots) or "nil")
		)
	 end end,
	Op=function(self, node)
		local nLogicOpSet  = {["or"]=1,["not"]=1,["and"]=1}
		local nOper = node[1]
		if nLogicOpSet[nOper] then
			if nOper == "not" then
				do return self:rgnWrap(node).LOGIC_NOT(
					self:visit(node[2])
				)
			 end elseif nOper == "or" then
				do return self:rgnWrap(node).LOGIC_OR(
					self:visit(node[2]), self:fnRetWrap(self:visit(node[3]))
				)
			 end elseif nOper == "and" then
				do return self:rgnWrap(node).LOGIC_AND(
					self:visit(node[2]), self:fnRetWrap(self:visit(node[3]))
				)
			 end else
				error("invalid case branch")
			end
		else
			local nRight = node[3]
			if not nRight then
				do return self:stkWrap(node).META_UOP(
					"\""..node[1].."\"",
					self:visit(node[2])
				)
			 end elseif node[1] == "==" then
				do return self:stkWrap(node).META_EQ_NE(
					"true",
					self:visit(node[2]),
					self:visit(nRight)
				)
			 end elseif node[1] == "~=" then
				do return self:stkWrap(node).META_EQ_NE(
					"false",
					self:visit(node[2]),
					self:visit(nRight)
				)
			 end else
				do return self:stkWrap(node).META_BOP_SOME(
					"\""..node[1].."\"",
					self:visit(node[2]),
					self:visit(nRight)
				)
			 end end
		end
	end,
	HintAt=function(self, node)
		local nHintShort = node.hintShort
		do return self:stkWrap(node).CAST_HINT(
			{"(", self:visit(node[1]), ")"},
			string.format("%q", nHintShort.castKind),
			self:fixIHintSpace(nHintShort)
		)
	 end end,
	Paren=function(self, node)
		do return self:visit(node[1])
	 end end,
	Ident=function(self, node)
		assert(node.kind ~= "def")
		local nDefineIdent = node.defineIdent
		if nDefineIdent then
			local symbol = self:codeNode(nDefineIdent)
			local nParent = node.parent
			while nParent.tag == "Paren" do
				nParent = nParent.parent
			::continue:: end
			local nParentTag = nParent.tag
			local nParentParentTag = nParent.parent.tag
			if nParentTag == "ExprList" then
				local nSymbolGet = self:stkWrap(node).SYMBOL_GET(symbol, "true")

				if nParentParentTag == "Invoke" or nParentParentTag == "Call" then
					  
					do return self:fnRetWrap(nSymbolGet)
				 end else
					do return nSymbolGet
				 end end
			else
				do return self:stkWrap(node).SYMBOL_GET(symbol, "false")
			 end end
		else
			local nIdentENV = node.isGetFrom
			if self._chunk.injectNode and nIdentENV == self._chunk[1] then
				do return self:stkWrap(node).INJECT_GET(
					"____injectGetter"
				)
			 end else
				do return self:stkWrap(node).GLOBAL_GET(
					self:codeNode(nIdentENV  )
				)
			 end end
		end
	end,
	Index=function(self, node)
		do return self:stkWrap(node).META_GET(
			self:visit(node[1]), self:visit(node[2]),
			tostring(node.notnil or false)
		)
	 end end,
	ExprList=function(self, node)
		do return self:concatList(node, function(i, expr)
			do return self:visit(expr)
		 end end, ",")
	 end end,
	ParList=function(self, node)
		error("implement in other way")
		do return self:concatList (node, function(i, vParNode)
			do return vParNode.tag == "Ident" and "____v_"..vParNode[1]..vParNode.index or "____vDOTS"
		 end end, ",")
	 end end,
	VarList=function(self, node)
		do return self:concatList(node, function(i, varNode)
			do return self:visit(varNode)
		 end end, ",")
	 end end,
	IdentList=function(self, node)
		do return self:concatList(node, function(i, identNode)
			do return self:visit(identNode)
		 end end, ",")
	 end end,
}

local HintGener = {}
HintGener.__index = HintGener

function HintGener:visit(vNode)
	local nUnionNode = vNode
	local nFunc = TagToVisiting[nUnionNode.tag]
	if nFunc then
		do return nFunc(self, nUnionNode)
	 end else
		do return ""
	 end end
end

function HintGener:fixIHintSpace(vHintSpace)
	local nResult = {}
	for k,v in ipairs(vHintSpace.evalScriptList) do
		if v.tag == "HintScript" then
			local nLast = nil
			for s in string.gmatch(v[1], "[^\n]*") do
				nLast = {
					line = true,
					" ", s, " "
				}
				nResult[#nResult + 1] = nLast
			::continue:: end
			if nLast then
				nLast.line = nil
			end
		else
			nResult[#nResult + 1] = self:stkWrap(v).EVAL(self:visit(v[1]))
			nResult[#nResult + 1] = {
				line=v.endLine, " "
			}
		end
	::continue:: end
	do return nResult
 end end

function HintGener:codeNodeValue(vNode )
	do return "____nodes["..vNode.index.."][1]"
 end end

function HintGener:codeNode(vNode)
	do return "____nodes["..vNode.index.."]"
 end end

function HintGener:visitIdentDef(vIdentNode, vValue, vIsParamOrRec, vAutoPrimitive)
	local nHintShort = vIdentNode.hintShort
	do return {
		line=vIdentNode.l,
		" ", self:stkWrap(vIdentNode).SYMBOL_NEW(
			string.format("%q", vIdentNode.symbolKind), tostring(vIdentNode.symbolModify or false),
			vValue, vIsParamOrRec and "nil" or (nHintShort and self:fixIHintSpace(nHintShort) or "nil"),
			tostring(vAutoPrimitive)
		)
	}
 end end

function HintGener:fnWrap(...)
	local nArgsString = table.concat({...}, ",")
	do return function(...)
		local nList = {...}
		local nResult = { " function(", nArgsString, ") " }
		for i=1, #nList do
			nResult[#nResult+1] = nList[i]
			nResult[#nResult+1] = " "
		::continue:: end
		nResult[#nResult+1] = " end "
		do return nResult
	 end end
 end end

function HintGener:fnRetWrap(...)
	local nList = {...}
	local nResult = { " function() return " }
	for i=1, #nList do
		nResult[#nResult+1] = nList[i]
		if i~=#nList then
			nResult[#nResult+1] = ","
		end
	::continue:: end
	nResult[#nResult+1] = " end "
	do return nResult
 end end

function HintGener:dictWrap(vDict )
	local nList = {}
	nList[#nList + 1] = "{"
	for k,v in pairs(vDict) do
		nList[#nList + 1] = k
		nList[#nList + 1] = "="
		nList[#nList + 1] = v
		nList[#nList + 1] = ","
	::continue:: end
	nList[#nList + 1] = "}"
	do return nList
 end end

function HintGener:listWrap(...)
	local nList = {...}
	local nResult = { "{" }
	for i=1, #nList do
		nResult[#nResult+1] = nList[i]
		if i~=#nList then
			nResult[#nResult+1] = ","
		end
	::continue:: end
	nResult[#nResult+1] = "}"
	do return nResult
 end end


	  
		    

		
		
		
		
		
		

		
		

		
		
		

		
		
		
		

		
		
		

		
		
		

		
		
	

function HintGener:stkWrap(vNode) 
	do return setmetatable({}, {
		__index=function(t,vName)
			do return function(...)
				do return self:prefixInvoke("____stk", vName, vNode, ...)
			 end end
		 end end,
	})
 end end


	  
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	

function HintGener:rgnWrap(vNode) 
	do return setmetatable({}, {
		__index=function(t,vName)
			do return function(...)
				do return self:prefixInvoke("____stk", vName, vNode, ...)
			 end end
		 end end,
	})
 end end

function HintGener:prefixInvoke(vPrefix, vName, vNode, ...)
	local nList = {...}
	local nResult = {
		line=vNode.l,
		vPrefix, ":", vName, "(", self:codeNode(vNode),
	}
	for i=1, #nList do
		nResult[#nResult+1] = ","
		nResult[#nResult+1] = nList[i]
	::continue:: end
	nResult[#nResult+1] = ")"
	do return nResult
 end end

function HintGener:stkAutoUnpack(vNode, vInner)
	local nParent = vNode.parent
	local nAutoUnpack = true
	if nParent.tag == "ExprList" or nParent.tag == "ParList" or nParent.tag == "Block" then
		nAutoUnpack = false
	elseif nParent.tag == "Table" then
		local nTableNode = nParent  
		if nTableNode[#nTableNode] == vNode then
			    
			nAutoUnpack = false
		end
	end
	if nAutoUnpack then
		do return self:stkWrap(vNode).EXPRLIST_UNPACK("1", vInner)
	 end else
		do return vInner
	 end end
end

function HintGener:chunkLongHint()
	do return self:dictWrap({
		attrSet="{open=1}",
		caller="function(____longHint) return ____longHint end"
	})
 end end

function HintGener:visitLongHint(vHintSpace)
	local nCallGen = (vHintSpace and #vHintSpace.evalScriptList > 0) and {
		":", self:fixIHintSpace(vHintSpace)
	} or ""
	local nAttrList = vHintSpace and vHintSpace.attrList or ({}  )
	local l = {}
	for i=1, #nAttrList do
		l[#l + 1] = nAttrList[i] .. "=1"
	::continue:: end
	do return self:dictWrap({
		attrSet=self:listWrap(table.unpack(l)),
		caller=self:fnWrap("____longHint")("return ____longHint", nCallGen)
	})
 end end

function HintGener:visitFunc(vNode )
	local nIsChunk = vNode.tag == "Chunk"
	local nHintPrefix = nIsChunk and self:chunkLongHint() or self:visitLongHint(vNode.hintPrefix)
	local nHintSuffix = nIsChunk and self:chunkLongHint() or self:visitLongHint(vNode.hintSuffix)
	local nParList = nIsChunk and vNode[2] or vNode[1]
	local nBlockNode = nIsChunk and vNode[3] or vNode[2]
	local nLastNode = nParList[#nParList]
	local nLastDots = (nLastNode and nLastNode.tag == "Dots") and nLastNode
	local nParamNum = nLastDots and #nParList-1 or #nParList
	local nFirstPar = nParList[1]
	local nIsMember = nFirstPar and nFirstPar.tag == "Ident" and nFirstPar.isSelf or false
	local nPolyParList = vNode.hintPolyParList
	local nPolyUnpack = {}
	local nPolyParNum = nPolyParList and #nPolyParList or 0
	if nPolyParList and nPolyParNum > 0 then
		nPolyUnpack = {
			" local ", self:concatList(nPolyParList, function(_, vPolyPar)
				do return vPolyPar
			 end end, ","), "=", self:concatList(nPolyParList, function(i, vPolyPar)
				do return "____polyArgs["..tostring(i).."]"
			 end end, ",")
		}
	end
	do return self:stkWrap(vNode).FUNC_NEW(self:dictWrap({
		_hasRetSome=tostring(vNode.retFlag or false),
		_hasSuffixHint=tostring((not nIsChunk and vNode.hintSuffix) and true or false),
		_polyParNum=tostring(nPolyParNum),
		_parNum=tostring(nParamNum),
		_member=tostring(nIsMember),
	}), nHintPrefix,
	   
		self:fnWrap("____newStk","____polyArgs", "____self")(
			"local ____stk,let,_ENV,_G=____newStk,____newStk:BEGIN(____stk,", self:codeNode(nBlockNode), ") ",
			nPolyUnpack,
			   
			" local ____vDOTS=false ",
			     
			" return ", self:fnWrap("____termArgs")(
				self:concatList (nParList, function(i, vParNode)
					local nHintShort = vParNode.hintShort
					local nHintType = nHintShort and self:fixIHintSpace(nHintShort) or self:stkWrap(vParNode).AUTO()
					if vParNode.tag ~= "Dots" then
						if i == 1 then
							            
							nHintType = {
								"(____self or ", nHintType, ")"
							}
						end
						do return {
							"local ____tempv"..i.."=",
							self:rgnWrap(vParNode).PARAM_UNPACK("____termArgs", tostring(i), nHintType),
							self:visitIdentDef(vParNode, "____tempv"..i, true)
						}
					 end else
						do return {
							"____vDOTS=",
							self:rgnWrap(vParNode).PARAM_DOTS_UNPACK("____termArgs", tostring(nParamNum), nHintType)
						}
					 end end
				end, " "),
				nLastDots and "" or self:rgnWrap(nParList).PARAM_NODOTS_UNPACK("____termArgs", tostring(nParamNum)),
				" return ", self:rgnWrap(nParList).PARAM_PACKOUT(
					self:listWrap(self:concatList (nParList, function(i, vParNode)
						if vParNode.tag ~= "Dots" then
							do return "____tempv"..i
						 end end
					end, ",")),
					(nLastDots) and "____vDOTS" or tostring(false)
				)
			), ",", nHintSuffix, ",",
			self:fnWrap()(
				self:visit(nBlockNode),
				" return ",
				self:rgnWrap(vNode).END()
			)
		)
	  
	)
 end end

function HintGener:concatList(
	vList,
	vFunc ,
	vSep
)
	local nResult = {}
	local nLen = #vList
	for i=1,nLen do
		nResult[#nResult + 1] = vFunc(i, vList[i])
		nResult[#nResult + 1] = i~=nLen and vSep or nil
	::continue:: end
	do return nResult
 end end

function HintGener.new(vChunk)
	local self = setmetatable({
		_chunk=vChunk,
	}, HintGener)
	do return self
 end end

function HintGener:genCode()
	local nBufferList = {}
	local nLineCount = 1
	local function recurAppend(vResult, vDepth)
		if type(vResult) == "table" then
			local nLine = vResult.line
			if type(nLine) == "number" then
				while nLineCount < nLine do
					nBufferList[#nBufferList+1] = "\n"
					nLineCount = nLineCount + 1
				::continue:: end
			end
			for _, v in ipairs(vResult) do
				recurAppend(v, vDepth+1)
			::continue:: end
			if nLine == true then
				nBufferList[#nBufferList+1] = "\n"
				nLineCount = nLineCount + 1
			end
		else
			nBufferList[#nBufferList+1] = tostring(vResult)
		end
	end
	recurAppend(self:visit(self._chunk), 0)
	local re = table.concat(nBufferList)
	do return re
 end end

do return HintGener
 end 
end end
--thlua.code.HintGener end ==========)

--thlua.code.Node begin ==========(
do local _ENV = _ENV
packages['thlua.code.Node'] = function (...)


local Enum = require "thlua.Enum"
local Exception = require "thlua.Exception"



  
  

   
	
	
	
	
	
	
	


    
	
	


    
	


   
	


   

  
	  
	  
	  
	  
	  
	  
	   
	  
	  
	  
  

  
	  
	   
	  
	  
  

   
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	


  
	  
	  
 

  
	  
	
	   
 

   
	
	
	   
 

  
	
	  
	   
  

  
	
	         
	  
  

  
	
	    
 

    

  
	
	
 

  
	  
	  
	  
 

  
	  
	  
	  
 

  
	  
	  
	  
 

  
	  
	  
	  
 

  
	  
	   
  

  
	  
	  
	  
	  
	   
	   
 

  
	  
	  
	  
	  
 

  
	  
	  
	  
	  
 

  
	  
	  
	  
	  
 

  
	  
	  
 

  
	  
	  
 

  
	  
	  
 

  
	  
 

  
	  
 

   
	
	


  
	  
	  
	  
 

  
	  
	  
	
	  
	  
	  
 

   
	
	


  
	  
	  
	  
	  
 

     
	  
	  
	             
	  
	
	  
 

  
	  
	  
	   
	
	
	
	
	  
	  
 

   

   
	
	
	
	
	
	
	
	
	
	
	
	
	
	


  
	  


  
	  
	  


  
	  
	  


  
	  
	  
	  


  
	  
	  
	  
	  


  
	  
	  
	  
	  
	  
	  
	  
	         
	  
	  


  
	  
	
	  
	   
 

  
	  
	  
	  


  
	  
	  
	  
	   


  
	  
	  


  
	  
	  


  
	  
	  
	  


  
	  
	   
 

  
	  
	  
 

  
	  
	  
 

  
	  
	  
 

   
    
	  
	    


  

  

  

    

  

   

   

   
	
	             
	
	


  
	  
	  
	  
 

  
	  
 

   
	
 



local Node = {}



  
	
	
	
	


  
	
	
	
	
	



Node.__index=Node

function Node.__tostring(self)
	local before = self.path..":".. self.l ..(self.c > 0 and ("," .. self.c) or "")
	do return before
 end end

function Node.toExc(vNode, vMsg)
	do return Exception.new(vMsg, vNode)
 end end

function Node.newRootNode(vFileName)
	do return setmetatable({tag = "Root", pos=1, posEnd=1, l=1, c=1, path=vFileName}, Node)
 end end

function Node.newDebugNode(vDepth)
	     
	local nInfo = debug.getinfo(vDepth or 3)
	do return setmetatable({tag = "Debug", pos=1, posEnd=1, l=nInfo.currentline, c=1, path=nInfo.source}, Node)
 end end

function Node.bind(vRawNode)
	do return setmetatable(vRawNode, Node)
 end end

do return Node

 end 
end end
--thlua.code.Node end ==========)

--thlua.code.ParseEnv begin ==========(
do local _ENV = _ENV
packages['thlua.code.ParseEnv'] = function (...)
--[[
This module implements a parser for Lua 5.3 with LPeg,
and generates an Abstract Syntax Tree.

Some code modify from
https://github.com/andremm/typedlua and https://github.com/Alloyed/lua-lsp
]]
local ok, lpeg = pcall(require, "lpeg")
if not ok then
	ok, lpeg = pcall(require, "lulpeg")
	if not ok then
		error("lpeg or lulpeg not found")
	end
end
lpeg.setmaxstack(1000)
lpeg.locale(lpeg)

local ParseEnv = {}

ParseEnv.__index = ParseEnv

local Cenv = lpeg.Carg(1)
local Cpos = lpeg.Cp()
local cc = lpeg.Cc

local function throw(vErr)
	return lpeg.Cmt(Cenv, function(_, i, env)
		error(env:makeErrNode(i, "syntax error : "..vErr))
		return true
	end)
end

local vv=setmetatable({}, {
	__index=function(t,tag)
		local patt = lpeg.V(tag)
		t[tag] = patt
		return patt
	end
})

local vvA=setmetatable({
	IdentDefT=lpeg.V("IdentDefT") + throw("expect a 'Name'"),
	IdentDefN=lpeg.V("IdentDefN") + throw("expect a 'Name'"),
}, {
	__index=function(t,tag)
		local patt = lpeg.V(tag) + throw("expect a '"..tag.."'")
		t[tag] = patt
		return patt
	end
})

local function token (patt)
  return patt * vv.Skip
end

local function symb(str)
	if str=="." then
		return token(lpeg.P(".")*-lpeg.P("."))
	elseif str==":" then
		return token(lpeg.P(":")*-lpeg.P(":"))
	elseif str=="-" then
		return token(lpeg.P("-")*-lpeg.P("-"))
	elseif str == "[" then
		return token(lpeg.P("[")*-lpeg.S("=["))
	elseif str == "~" then
		return token(lpeg.P("~")*-lpeg.P("="))
	elseif str == "@" then
		return token(lpeg.P("@")*-lpeg.S("!<>?"))
	elseif str == "(" then
		return token(lpeg.P("(")*-lpeg.P("@"))
	else
		return token(lpeg.P(str))
	end
end

local function symbA(str)
  return symb(str) + throw("expect symbol '"..str.."'")
end

local function kw (str)
  return token(lpeg.P(str) * -vv.NameRest)
end

local function kwA(str)
  return kw(str) + throw("expect keyword '"..str.."'")
end

local function kwLoopEnd(str)
  return lpeg.Cmt(Cenv*Cpos*kw(str), function(_, _, env, pos)
	env:continueMarkLabel(pos)
	return true
  end) + throw("expect keyword '"..str.."'")
end

local exprF = {
	binOp=function(e1, op, e2)
		if not op then
			return e1
		else
			return {tag = "Op", pos=e1.pos, posEnd=e2.posEnd, op, e1, e2 }
		end
	end,
	suffixed=function(e1, e2)
		local e2tag = e2.tag
		assert(e2tag == "HintAt" or e2tag == "Call" or e2tag == "Invoke" or e2tag == "Index", "exprSuffixed args exception")
		e2.pos = e1.pos
		e2[1] = e1
		return e2
	end,
	hintAt=function(pos, e, hintShort, posEnd)
		return { tag = "HintAt", pos = pos, [1] = e, hintShort=hintShort, posEnd=posEnd}
	end,
	hintExpr=function(pos, e, hintShort, posEnd, env)
		if not hintShort then
			return e
		else
			local eTag = e.tag
			if eTag == "Dots" or eTag == "Call" or eTag == "Invoke" then
				env:markParenWrap(pos, hintShort.pos)
			end
			-- TODO, use other tag
			return { tag = "HintAt", pos = pos, [1] = e, hintShort = hintShort, posEnd=posEnd}
		end
	end
}

local parF = {
	identUse=function(vPos, vName, vNotnil, vPosEnd)
		return {tag="Ident", pos=vPos, posEnd=vPosEnd, [1] = vName, kind="use", notnil=vNotnil}
	end,
	identDef=function(vPos, vName, vHintShort, vPosEnd)
		return {tag="Ident", pos=vPos, posEnd=vPosEnd, [1] = vName, kind="def", hintShort=vHintShort}
	end,
	identDefSelf=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "self", kind="def", isSelf=true}
	end,
	identDefENV=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "_ENV", kind="def"}
	end,
	identDefLet=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "let", kind="def"}
	end,
}


local function buildLoadChunk(vPos, vBlock)
	return {
		tag="Chunk", pos=vPos, posEnd=vBlock.posEnd,
		letNode = parF.identDefLet(vPos),
		[1]=parF.identDefENV(vPos),
		[2]={
			tag="ParList",pos=vPos,posEnd=vPos,
			[1]={
				tag="Dots",pos=vPos,posEnd=vPos
			}
		},
		[3]=vBlock,
		[4]=false
	}
end

local function buildInjectChunk(expr)
	local nChunk = buildLoadChunk(expr.pos, {
		tag="Block", pos=expr.pos, posEnd=expr.posEnd,
	})
	nChunk.injectNode = expr
	return nChunk
end

local function buildHintInjectChunk(shortHintSpace)
	local nChunk = buildLoadChunk(shortHintSpace.pos, {
		tag="Block", pos=shortHintSpace.pos, posEnd=shortHintSpace.posEnd,
	})
	nChunk.injectNode = shortHintSpace
	return nChunk
end

local tagC=setmetatable({
}, {
	__index=function(t,tag)
		local f = function(patt)
			-- TODO , make this faster : 1. rm posEnd, 2. use table not lpeg.Ct
			if patt then
				return lpeg.Ct(lpeg.Cg(Cpos, "pos") * lpeg.Cg(lpeg.Cc(tag), "tag") * patt * lpeg.Cg(Cpos, "posEnd"))
			else
				return lpeg.Ct(lpeg.Cg(Cpos, "pos") * lpeg.Cg(Cpos, "posEnd") * lpeg.Cg(lpeg.Cc(tag), "tag"))
			end
		end
		t[tag] = f
		return f
	end
})

local hintC={
	-- short hint
	wrap=function(isStat, pattBegin, pattBody, pattEnd)
		pattBody = Cenv * pattBody / function(env, ...) return {...} end
		return Cenv *
					Cpos * pattBegin * vv.HintBegin *
					Cpos * pattBody * vv.HintEnd *
					Cpos * (pattEnd and pattEnd * Cpos or Cpos) / function(env,p1,castKind,p2,innerList,p3,p4)
			local evalList = env:captureEvalByVisit(innerList)
			env:markDel(p1, p4-1)
			local nHintSpace = env:buildIHintSpace(isStat and "StatHintSpace" or "ShortHintSpace", innerList, evalList, p1, p2, p3-1)
			nHintSpace.castKind = castKind
			return nHintSpace
		end
	end,
	-- long hint
	long=function()
		local name = tagC.String(vvA.Name)
		local colonInvoke = name * symbA"(" * vv.ExprListOrEmpty * symbA")";
		local pattBody = (
			(symb"." * vv.HintBegin * name)*(symb"." * name)^0+
			symb":" * vv.HintBegin * colonInvoke
		) * (symb":" * colonInvoke)^0 * vv.HintEnd
		return Cenv * Cpos * pattBody * Cpos / function(env, p1, ...)
			local l = {...}
			local posEnd = l[#l]
			env:markDel(p1, posEnd-1)
			l[#l] = nil
			local middle = nil
			local nAttrList = {}
			for i, nameOrExprList in ipairs(l) do
				local nTag = nameOrExprList.tag
				if nTag == "ExprList" then
					if not middle then
						middle = i-1
					end
				else
					assert(nTag == "String")
					nAttrList[#nAttrList + 1] = nameOrExprList[1]
				end
			end
			local nEvalList = env:captureEvalByVisit(l)
			if middle then
				local nHintSpace = env:buildIHintSpace("LongHintSpace", l, nEvalList, p1, l[middle].pos, posEnd-1)
				nHintSpace.attrList = nAttrList
				return nHintSpace
			else
				local nHintSpace = {
					tag = "HintSpace",
					kind = "LongHintSpace",
					pos = p1,
					posEnd = posEnd,
					attrList = nAttrList,
					evalScriptList = {},
					table.unpack(l),
				}
				return nHintSpace
			end
		end
	end,
	-- string to be true or false
	take=function(patt)
		return lpeg.Cmt(Cenv*Cpos*patt*Cpos, function(_, i, env, pos, posEnd)
			if not env.hinting then
				env:markDel(pos, posEnd-1)
				return true
			else
				return false
			end
		end) * vv.Skip
	end,
}

local function chainOp (pat, kwOrSymb, op1, ...)
	local sep = kwOrSymb(op1) * lpeg.Cc(op1)
	local ops = {...}
	for _, op in pairs(ops) do
		sep = sep + kwOrSymb(op) * lpeg.Cc(op)
	end
  return lpeg.Cf(pat * lpeg.Cg(sep * pat)^0, exprF.binOp)
end

local function suffixedExprByPrimary(primaryExpr)
	local notnil = lpeg.Cg(vv.NotnilHint*cc(true) + cc(false), "notnil")
	local polyArgs = lpeg.Cg(vv.AtPolyHint + cc(false), "hintPolyArgs")
	-- . index
	local index1 = tagC.Index(cc(false) * symb(".") * tagC.String(vv.Name) * notnil)
	-- [] index
	local index2 = tagC.Index(cc(false) * symb("[") * vvA.Expr * symbA("]") * notnil)
	-- invoke
	local invoke = tagC.Invoke(cc(false) * symb(":") * tagC.String(vv.Name) * notnil * polyArgs * vvA.FuncArgs)
	-- call
	local call = tagC.Call(cc(false) * vv.FuncArgs)
	-- atPoly
	local atPoly= Cpos * cc(false) * vv.AtPolyHint * Cpos / exprF.hintAt
	-- add completion case
	local succPatt = lpeg.Cf(primaryExpr * (index1 + index2 + invoke + call + atPoly)^0, exprF.suffixed);
	return lpeg.Cmt(Cpos*succPatt * Cenv * Cpos*((symb(".") + symb(":"))*cc(true) + cc(false)), function(_, _, pos, expr, env, posEnd, triggerCompletion)
		if not triggerCompletion then
			if expr.tag == "HintAt" then
				local curExpr = expr[1]
				while curExpr.tag == "HintAt" do
					curExpr = curExpr[1]
				end
				-- if poly cast is after invoke or call, then add ()
				if curExpr.tag == "Invoke" or curExpr.tag == "Call" then
					env:markParenWrap(pos, curExpr.posEnd)
				end
			end
			return true, expr
		else
			local nNode = env:makeErrNode(posEnd+1, "syntax error : expect a name")
			if not env.hinting then
				nNode[2] = {
					pos=pos,
					capture=buildInjectChunk(expr),
					script=env._subject:sub(pos, posEnd - 1),
					traceList=env.scopeTraceList
				}
			else
				local innerList = {expr}
				local evalList = env:captureEvalByVisit(innerList)
				local hintSpace = env:buildIHintSpace("ShortHintSpace", innerList, evalList, pos, pos, posEnd-1)
				nNode[2] = {
					pos=pos,
					capture=buildHintInjectChunk(hintSpace),
					script=env._subject:sub(pos, posEnd-1),
					traceList=env.scopeTraceList
				}
			end
			-- print("scope trace:", table.concat(env.scopeTraceList, ","))
			error(nNode)
			return false
		end
	end)
end

local G = lpeg.P { "TypeHintLua";
	Shebang = lpeg.P("#") * (lpeg.P(1) - lpeg.P("\n"))^0 * lpeg.P("\n");
	TypeHintLua = vv.Shebang^-1 * vv.Chunk * (lpeg.P(-1) + throw("invalid chunk"));

  -- hint & eval begin {{{
	HintAssetNot = lpeg.Cmt(Cenv, function(_, i, env)
		assert(not env.hinting, env:makeErrNode(i, "syntax error : hint space only allow normal lua syntax"))
		return true
	end);

	HintBegin = lpeg.Cmt(Cenv, function(_, i, env)
		if not env.hinting then
			env.hinting = true
			return true
		else
			error(env:makeErrNode(i, "syntax error : hint space only allow normal lua syntax"))
			return false
		end
	end);

	HintEnd = lpeg.Cmt(Cenv, function(_, _, env)
		assert(env.hinting, "hinting state error when lpeg parsing when success case")
		env.hinting = false
		return true
	end);

	EvalBegin = lpeg.Cmt(Cenv, function(_, i, env)
		if env.hinting then
			env.hinting = false
			return true
		else
			error(env:makeErrNode(i, "syntax error : eval syntax can only be used in hint"))
			return false
		end
	end);

	EvalEnd = lpeg.Cmt(Cenv, function(_, i, env)
		assert(not env.hinting, "hinting state error when lpeg parsing when success case")
		env.hinting = true
		return true
	end);

	NotnilHint = hintC.take(lpeg.P("!"));

	ValueConstHint = hintC.take(lpeg.P("const")*-vv.NameRest);

	AtCastHint = hintC.wrap(
		false,
		symb("@") * cc("@") +
		symb("@!") * cc("@!") +
		symb("@>") * cc("@>") +
		symb("@?") * cc("@?"),
		vv.SimpleExpr) ;

	ColonHint = hintC.wrap(false, symb(":") * cc(false), vv.SimpleExpr);

	LongHint = hintC.long();

	StatHintSpace = hintC.wrap(true, symb("(@") * cc(nil),
		vv.DoStat + vv.ApplyOrAssignStat + throw("StatHintSpace need DoStat or Apply or AssignStat inside"),
	symbA(")"));

	--[[HintTerm = suffixedExprByPrimary(
		tagC.HintTerm(hintC.wrap(false, symb("(@") * cc(false), vv.EvalExpr + vv.SuffixedExpr, symbA(")"))) +
		vv.PrimaryExpr
	);]]

	HintPolyParList = Cenv * Cpos * symb("@<") * vvA.Name * (symb"," * vv.Name)^0 * symbA(">") * Cpos / function(env, pos, ...)
		local l = {...}
		local posEnd = l[#l]
		l[#l] = nil
		env:markDel(pos, posEnd - 1)
		return l
	end;

	AtPolyHint = hintC.wrap(false, symb("@<") * cc("@<"),
		vvA.SimpleExpr * (symb"," * vv.SimpleExpr)^0, symbA(">"));

	EvalExpr = tagC.HintEval(symb("$") * vv.EvalBegin * vvA.SimpleExpr * vv.EvalEnd);

  -- hint & eval end }}}


	-- parser
	-- Chunk = tagC.Chunk(Cpos/parF.identDefENV * tagC.ParList(tagC.Dots()) * vv.Skip * vv.Block);
	Chunk = Cpos * vv.Skip * vv.Block/buildLoadChunk;

	FuncPrefix = kw("function") * (vv.LongHint + cc(nil));
	FuncDef = vv.FuncPrefix * vv.FuncBody / function(vHint, vFuncExpr)
		vFuncExpr.hintPrefix = vHint
		return vFuncExpr
	end;

	Constructor = (function()
		local Pair = tagC.Pair(((symb"[" * vvA.Expr * symbA"]") + tagC.String(vv.Name)) * symb"=" * vv.Expr)
		local Field = Pair + vv.Expr
		local fieldsep = symb(",") + symb(";")
		local FieldList = (Field * (fieldsep * Field)^0 * fieldsep^-1)^-1
		return tagC.Table(symb("{") * lpeg.Cg(vv.LongHint, "hintLong")^-1 * FieldList * symbA("}"))
	end)();

	IdentUse = Cpos*vv.Name*(vv.NotnilHint * cc(true) + cc(false))*Cpos/parF.identUse;
	IdentDefT = Cpos*vv.Name*(vv.ColonHint + cc(nil))*Cpos/parF.identDef;
	IdentDefN = Cpos*vv.Name*cc(nil)*Cpos/parF.identDef;

	LocalIdentList = tagC.IdentList(vvA.IdentDefT * (symb(",") * vv.IdentDefT)^0);
	ForinIdentList = tagC.IdentList(vvA.IdentDefN * (symb(",") * vv.IdentDefN)^0);

	ExprListOrEmpty = tagC.ExprList(vv.Expr * (symb(",") * vv.Expr)^0) + tagC.ExprList();

	ExprList = tagC.ExprList(vv.Expr * (symb(",") * vv.Expr)^0);

	FuncArgs = tagC.ExprList(symb("(") * (vv.Expr * (symb(",") * vv.Expr)^0)^-1 * symb(")") +
             vv.Constructor + vv.String);

	String = tagC.String(token(vv.LongString)*lpeg.Cg(cc(true), "isLong") + token(vv.ShortString));

	UnaryExpr = (function()
		local UnOp = kw("not")/"not" + symb("-")/"-" + symb("~")/"~" + symb("#")/"#"
		local PowExpr = vv.SimpleExpr * ((symb("^")/"^") * vv.UnaryExpr)^-1 / exprF.binOp
		return tagC.Op(UnOp * vv.UnaryExpr) + PowExpr
	end)();
	ConcatExpr = (function()
		local MulExpr = chainOp(vv.UnaryExpr, symb, "*", "//", "/", "%")
		local AddExpr = chainOp(MulExpr, symb, "+", "-")
	  return AddExpr * ((symb("..")/"..") * vv.ConcatExpr) ^-1 / exprF.binOp
	end)();
	Expr = (function()
		local ShiftExpr = chainOp(vv.ConcatExpr, symb, "<<", ">>")
		local BAndExpr = chainOp(ShiftExpr, symb, "&")
		local BXorExpr = chainOp(BAndExpr, symb, "~")
		local BOrExpr = chainOp(BXorExpr, symb, "|")
		local RelExpr = chainOp(BOrExpr, symb, "~=", "==", "<=", ">=", "<", ">")
		local AndExpr = chainOp(RelExpr, kw, "and")
		local OrExpr = chainOp(AndExpr, kw, "or")
		return OrExpr
	end)();

	SimpleExpr = Cpos * (
						-- (vv.ValueConstHint * cc(true) + cc(false)) * (
						cc(false) * (
							vv.String +
							tagC.Number(token(vv.Number)) +
							tagC.False(kw"false") +
							tagC.True(kw"true") +
							vv.Constructor
						)/function(isConst, t)
							t.isConst = isConst
							return t
						end +
						tagC.Nil(kw"nil") +
						vv.FuncDef +
						vv.SuffixedExpr +
						tagC.Dots(symb"...") +
						vv.EvalExpr
					) * (vv.AtCastHint + cc(nil)) * Cpos * Cenv/ exprF.hintExpr;

	PrimaryExpr = vv.IdentUse + tagC.Paren(symb"(" * vv.Expr * symb")");

	SuffixedExpr = suffixedExprByPrimary(vv.PrimaryExpr);

	ApplyOrAssignStat = lpeg.Cmt(Cenv*vv.SuffixedExpr * ((symb(",") * vv.SuffixedExpr) ^ 0 * symb("=") * vv.ExprList)^-1, function(_,pos,env,first,...)
		if not ... then
			if first.tag == "Call" or first.tag == "Invoke" then
				return true, first
			else
				error(env:makeErrNode(pos, "syntax error: "..tostring(first.tag).." expression can't be a single stat"))
			end
		else
			local nVarList = {
				tag="VarList", pos=first.pos, posEnd = 0,
				first, ...
			}
			local nExprList = nVarList[#nVarList]
			nVarList[#nVarList] = nil
			nVarList.posEnd = nVarList[#nVarList].posEnd
			for _, varExpr in ipairs(nVarList) do
				if varExpr.tag ~= "Ident" and varExpr.tag ~= "Index" then
					error(env:makeErrNode(pos, "syntax error: only identify or index can be left-hand-side in assign statement"))
				elseif varExpr.notnil then
					error(env:makeErrNode(pos, "syntax error: notnil can't be used on left-hand-side in assign statement"))
				end
			end
			return true, {
				tag="Set", pos=first.pos, posEnd=nExprList.posEnd,
				nVarList,nExprList
			}
		end
	end);

	Block = lpeg.Cmt(Cenv, function(_,pos,env)
		if not env.hinting then
			--local nLineNum = select(2, env._subject:sub(1, pos):gsub('\n', '\n'))
			--print(pos, nLineNum)
			local len = #env.scopeTraceList
			env.scopeTraceList[len + 1] = 0
			if len > 0 then
				env.scopeTraceList[len] = env.scopeTraceList[len] + 1
			end
		end
		return true
	end) * tagC.Block(vv.Stat^0 * vv.RetStat^-1) * lpeg.Cmt(Cenv, function(_,_,env)
		if not env.hinting then
			env.scopeTraceList[#env.scopeTraceList] = nil
		end
		return true
	end);
	DoStat = tagC.Do(kw"do" * lpeg.Cg(vv.LongHint, "hintLong")^-1 * vv.Block * kwA"end");
	FuncBody = (function()
		local IdentDefTList = vv.IdentDefT * (symb(",") * vv.IdentDefT)^0;
		local DotsHintable = tagC.Dots(symb"..." * lpeg.Cg(vv.ColonHint, "hintShort")^-1)
		local ParList = tagC.ParList(IdentDefTList * (symb(",") * DotsHintable)^-1 + DotsHintable^-1);
		return tagC.Function(
			lpeg.Cg(Cpos/parF.identDefLet, "letNode")*
			lpeg.Cg(vv.HintPolyParList, "hintPolyParList")^-1*symbA("(") * ParList * symbA(")") *
			lpeg.Cg(vv.LongHint, "hintSuffix")^-1 * vv.Block * kwA("end"))
	end)();

	RetStat = lpeg.Cmt(Cenv * Cpos * kw("return") * vv.ExprListOrEmpty * symb(";")^-1 * Cpos, function(_,_,env,pos,exprList,posEnd)
		env:continueMarkReturn(pos, posEnd)
		return true, {tag="Return", exprList, pos=pos, posEnd=posEnd}
	end);

	Stat = (function()
		local LocalFunc = vv.FuncPrefix * tagC.Localrec(vvA.IdentDefN * vv.FuncBody) / function(vHint, vLocalrec)
			vLocalrec[2].hintPrefix = vHint
			return vLocalrec
		end
		local LocalAssign = tagC.Local(vv.LocalIdentList * (symb"=" * vvA.ExprList + tagC.ExprList()))
		local LocalStat = kw"local" * (LocalFunc + LocalAssign + throw("wrong local-statement")) +
				Cenv * Cpos * kw"const" * vv.HintAssetNot * (LocalFunc + LocalAssign + throw("wrong const-statement")) / function(env, pos, t)
					env:markConst(pos)
					t.isConst = true
					return t
				end
		local FuncStat = (function()
			local function makeNameIndex(ident1, ident2)
				return { tag = "Index", pos=ident1.pos, posEnd=ident2.posEnd, ident1, ident2}
			end
			local FuncName = lpeg.Cf(vv.IdentUse * (symb"." * tagC.String(vv.Name))^0, makeNameIndex)
			local MethodName = symb(":") * tagC.String(vv.Name) + cc(false)
			return Cpos * vv.FuncPrefix * FuncName * MethodName * Cpos * vv.FuncBody * Cpos / function (pos, hintPrefix, varPrefix, methodName, posMid, funcExpr, posEnd)
				funcExpr.hintPrefix = hintPrefix
				if methodName then
					table.insert(funcExpr[1], 1, parF.identDefSelf(pos))
					varPrefix = makeNameIndex(varPrefix, methodName)
				end
				return {
					tag = "Set", pos=pos, posEnd=posEnd,
					{ tag="VarList", pos=pos, posEnd=posMid, varPrefix},
					{ tag="ExprList", pos=posMid, posEnd=posEnd, funcExpr },
				}
			end
		end)()
		local LabelStat = tagC.Label(symb"::" * vv.Name * symb"::")
		local BreakStat = tagC.Break(kw"break")
		local ContinueStat = Cenv*tagC.Continue(kw"continue")*vv.HintAssetNot/function(env,node)
			env:continueMarkGoto(node.pos)
			return node
		end
		local GoToStat = tagC.Goto(kw"goto" * vvA.Name)
		local RepeatStat = tagC.Repeat(kw"repeat" * vv.Block * kwLoopEnd"until" * vvA.Expr)
		local IfStat = tagC.If(kw("if") * vvA.Expr * kwA("then") * vv.Block *
			(kw("elseif") * vvA.Expr * kwA("then") * vv.Block)^0 *
			(kw("else") * vv.Block)^-1 *
			kwA("end"))
		local WhileStat = tagC.While(kw("while") * vvA.Expr * kwA("do") * vv.Block * kwLoopEnd("end"))
		local ForStat = (function()
			local ForBody = kwA("do") * vv.Block
			local ForNum = tagC.Fornum(vv.IdentDefN * symb("=") * vvA.Expr * symbA(",") * vvA.Expr * (symb(",") * vv.Expr)^-1 * ForBody)
			local ForIn = tagC.Forin(vv.ForinIdentList * kwA("in") * vvA.ExprList * ForBody)
			return kw("for") * (ForNum + ForIn + throw("wrong for-statement")) * kwLoopEnd("end")
		end)()
		local BlockEnd = lpeg.P("return") + "end" + "elseif" + "else" + "until" + lpeg.P(-1)
		return vv.StatHintSpace +
         LocalStat + FuncStat + LabelStat + BreakStat + GoToStat + ContinueStat +
				 RepeatStat + ForStat + IfStat + WhileStat +
				 vv.DoStat + vv.ApplyOrAssignStat + symb(";") + (lpeg.P(1)-BlockEnd)*throw("wrong statement")
	end)();

	-- lexer
	Skip     = (lpeg.space^1 + vv.Comment)^0;
	Comment  = Cenv*Cpos*
		lpeg.P"--" * (vv.LongString / function () return end + (lpeg.P(1) - lpeg.P"\n")^0)
		*Cpos/function(env, pos, posEnd) env:markDel(pos, posEnd-1) return end;

	Number = (function()
		local Hex = (lpeg.P"0x" + lpeg.P"0X") * lpeg.xdigit^1
		local Decimal = lpeg.digit^1 * lpeg.P"." * lpeg.digit^0
									+ lpeg.P"." * -lpeg.P"." * lpeg.digit^1
		local Expo = lpeg.S"eE" * lpeg.S"+-"^-1 * lpeg.digit^1
		local Int = lpeg.digit^1
		local Float = Decimal * Expo^-1 + Int * Expo
		return lpeg.C(Hex + Float + Int) / tonumber
	end)();

	LongString = (function()
		local Equals = lpeg.P"="^0
		local Open = "[" * lpeg.Cg(Equals, "openEq") * "[" * lpeg.P"\n"^-1
		local Close = "]" * lpeg.C(Equals) * "]"
		local CloseEq = lpeg.Cmt(Close * lpeg.Cb("openEq"), function (s, i, closeEq, openEq) return #openEq == #closeEq end)
		return Open * lpeg.C((lpeg.P(1) - CloseEq)^0) * (Close+throw("--[...[comment  not close")) / function (s, eqs) return s end
	end)();

	ShortString = lpeg.P('"') * lpeg.C(((lpeg.P('\\') * lpeg.P(1)) + (lpeg.P(1) - lpeg.P('"')))^0) * (lpeg.P'"' + throw('" not close'))
							+ lpeg.P("'") * lpeg.C(((lpeg.P("\\") * lpeg.P(1)) + (lpeg.P(1) - lpeg.P("'")))^0) * (lpeg.P"'" + throw("' not close"));

	NameRest = lpeg.alnum + lpeg.P"_";

	Name = (function()
		local RawName = (lpeg.alpha + lpeg.P"_") * vv.NameRest^0
		local Keywords  = lpeg.P"and" + "break" + "do" + "elseif" + "else" + "end"
		+ "false" + "for" + "function" + "goto" + "if" + "in"
		+ "local" + "nil" + "not" + "or" + "repeat" + "return"
		+ "then" + "true" + "until" + "while" + "const" + "continue"
		local Reserved = Keywords * -vv.NameRest
		return token(-Reserved * lpeg.C(RawName));
	end)();

}

function ParseEnv.new(vSubject)
	local self = setmetatable({
		hinting = false,
		scopeTraceList = {},
		_subject = vSubject,
		_posToChange = {},
	}, ParseEnv)
	local nOkay, nAstOrErr = pcall(lpeg.match, G, vSubject, nil, self)
	if not nOkay then
		if type(nAstOrErr) == "table" and nAstOrErr.tag == "Error" then
			self._astOrErr = nAstOrErr
		else
			self._astOrErr = self:makeErrNode(1, "unknown parse error: "..tostring(nAstOrErr))
		end
	else
		self._astOrErr = nAstOrErr
	end
	return self
end

function ParseEnv:getAstOrErr()
	return self._astOrErr
end

function ParseEnv:makeErrNode(vPos, vErr)
	return {
		tag="Error",
		pos=vPos,
		posEnd=vPos,
		vErr
	}
end

function ParseEnv:buildIHintSpace(vTag, vInnerList, vEvalList, vRealStartPos, vStartPos, vFinishPos)
	local nHintSpace = {
		tag = "HintSpace",
		kind = vTag,
		pos = vRealStartPos,
		posEnd = vFinishPos + 1,
		evalScriptList = {},
		table.unpack(vInnerList)
	}
	local nEvalScriptList = nHintSpace.evalScriptList
	local nSubject = self._subject
	for _, nHintEval in ipairs(vEvalList) do
		nEvalScriptList[#nEvalScriptList + 1] = {
			tag = "HintScript",
			pos=vStartPos,
			posEnd=nHintEval.pos,
			[1] = nSubject:sub(vStartPos, nHintEval.pos-1)
		}
		nEvalScriptList[#nEvalScriptList + 1] = nHintEval
		vStartPos = nHintEval.posEnd
	end
	if vStartPos <= vFinishPos then
		nEvalScriptList[#nEvalScriptList + 1] = {
			tag="HintScript",
			pos=vStartPos,
			posEnd=vFinishPos+1,
			[1]=nSubject:sub(vStartPos, vFinishPos)
		}
	end
	return nHintSpace
end

-- '@' when hint for invoke and call, need to add paren
-- eg.
--   aFunc() @ Integer -> (aFunc())
-- so mark paren here
function ParseEnv:markParenWrap(vStartPos, vFinishPos)
	self._posToChange[vStartPos] = "("
	self._posToChange[vFinishPos-1] = ")"
end

-- hint script to be delete
function ParseEnv:markDel(vStartPos, vFinishPos)
	self._posToChange[vStartPos] = vFinishPos
end

-- local -> const
function ParseEnv:markConst(vStartPos)
	self._posToChange[vStartPos] = "const"
end

-- continue -> goto continue
function ParseEnv:continueMarkGoto(vStartPos)
	self._posToChange[vStartPos] = "goto"
end

-- for end / repeat until / while end -> for ::continue:: end, repeat ::continue:: until, while ::continue:: end
function ParseEnv:continueMarkLabel(vStartPos)
	self._posToChange[vStartPos] = "::continue::"
end

-- return xxx -> do return xxx end
function ParseEnv:continueMarkReturn(vStartPos, vFinishPos)
	self._posToChange[vStartPos] = "do"
	self._posToChange[vFinishPos] = "end"
end

function ParseEnv:assertWithLineNum()
	local nNode = self._astOrErr
	local nLineNum = select(2, self._subject:sub(1, nNode.pos):gsub('\n', '\n'))
	if nNode.tag == "Error" then
		local nMsg = self._chunkName..":".. nLineNum .." ".. nNode[1]
		error(nMsg)
	end
end

function ParseEnv:captureEvalByVisit(vNode, vList)
	vList = vList or {}
	for i=1, #vNode do
		local nChildNode = vNode[i]
		if type(nChildNode) == "table" then
			if nChildNode.tag == "HintEval" then
				vList[#vList + 1] = nChildNode
			else
				self:captureEvalByVisit(nChildNode, vList)
			end
		end
	end
	return vList
end

function ParseEnv:genLuaCode()
	self:assertWithLineNum()
	local nSubject = self._subject
	local nPosToChange = self._posToChange
	local nStartPosList = {}
	for nStartPos, _ in pairs(nPosToChange) do
		nStartPosList[#nStartPosList + 1] = nStartPos
	end
	table.sort(nStartPosList)
	local nContents = {}
	local nPreFinishPos = 0
	for _, nStartPos in pairs(nStartPosList) do
		if nStartPos <= nPreFinishPos then
			-- do nothing in hint space
		else
			local nChange = nPosToChange[nStartPos]
			if type(nChange) == "number" then
				-- 1. save lua code
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = nLuaCode
				-- 2. replace hint code with space and newline
				local nFinishPos = nPosToChange[nStartPos]
				local nHintCode = nSubject:sub(nStartPos, nFinishPos)
				nContents[#nContents + 1] = nHintCode:gsub("[^\r\n\t ]", "")
				nPreFinishPos = nFinishPos
			--[[elseif type(nChange) == "string" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = nChange
				nPreFinishPos = nStartPos]]
			elseif nChange == "const" then
				nContents[#nContents + 1] = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = "local"
				nPreFinishPos = nStartPos + 4
			elseif nChange == "(" then
				nContents[#nContents + 1] = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = nChange
				nPreFinishPos = nStartPos-1
			elseif nChange == ")" then
				nContents[#nContents + 1] = nSubject:sub(nPreFinishPos + 1, nStartPos)
				nContents[#nContents + 1] = nChange
				nPreFinishPos = nStartPos
			elseif nChange == "goto" or nChange == "::continue::" or nChange == "do" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = nChange
				nContents[#nContents + 1] = " "
				nPreFinishPos = nStartPos-1
			elseif nChange == "end" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = " "
				nContents[#nContents + 1] = nChange
				nContents[#nContents + 1] = " "
				nPreFinishPos = nStartPos-1
			else
				error("unexpected branch")
			end
		end
	end
	nContents[#nContents + 1] = nSubject:sub(nPreFinishPos + 1, #nSubject)
	return table.concat(nContents)
end

local boot = {}
-- return luacode | false, errmsg
function boot.compile(vContent, vChunkName)
	vChunkName = vChunkName or "[anonymous script]"
	local nAstOrFalse, nCodeOrErr = boot.parse(vContent)
	if not nAstOrFalse then
		local nLineNum = select(2, vContent:sub(1, nCodeOrErr.pos):gsub('\n', '\n'))
		local nMsg = vChunkName..":".. nLineNum .." ".. nCodeOrErr[1]
		return false, nMsg
	else
		return nCodeOrErr
	end
end

-- return false, errorNode | return chunkNode, string
function boot.parse(vContent)
	local nEnv = ParseEnv.new(vContent)
	local nAstOrErr = nEnv:getAstOrErr()
	if nAstOrErr.tag == "Error" then
		return false, nAstOrErr
	else
		return nAstOrErr, nEnv:genLuaCode()
	end
end

local load = load
function boot.load(chunk, chunkName, ...)
	local f, err = load(chunk, chunkName, ...)
	if f then
		-- if lua parse success, just return
		return f
	end
	local luaCode, err = boot.compile(chunk, chunkName)
	if not luaCode then
		return false, err
	end
	local f, err = load(luaCode, chunkName, ...)
	if not f then
		return false, err
	end
	return f
end

local patch = false

-- patch for load thlua code in lua
function boot.patch()
	if not patch then
		local path = package.path:gsub("[.]lua", ".thlua")
		table.insert(package.searchers, function(name)
			local fileName, err1 = package.searchpath(name, path)
			if not fileName then
				return err1
			end
			local file, err2 = io.open(fileName, "r")
			if not file then
				return err2
			end
			local thluaCode = file:read("*a")
			file:close()
			return assert(boot.load(thluaCode, fileName))
		end)
		patch = true
	end
end

return boot

end end
--thlua.code.ParseEnv end ==========)

--thlua.code.SearchVisitor begin ==========(
do local _ENV = _ENV
packages['thlua.code.SearchVisitor'] = function (...)

local VisitorExtend = require "thlua.code.VisitorExtend"
local Exception = require "thlua.Exception"



  
  
   
	  
	  
	 


  
	   
	  
		   
	
	 




local TagToVisiting = {
	Chunk=function(self, vNode)
		self:rawVisit(vNode)
		table.sort(self._identList, function(a, b)
			do return a.pos < b.pos
		 end end)
		table.sort(self._suffixPairList, function(a, b)
			do return a.pos < b.pos
		 end end)
		table.sort(self._hintSuffixPairList, function(a, b)
			do return a.pos < b.pos
		 end end)
	end,
	HintEval=function(self, vNode)
		self:reverseInHint(false)
		self:rawVisit(vNode)
		self:reverseInHint(true)
	end,
	HintSpace=function(self, vNode)
		self:reverseInHint(true)
		self:rawVisit(vNode)
		self:reverseInHint(false)
	end,
	Ident=function(self, vNode)
		self:rawVisit(vNode)
		table.insert(self._identList, vNode)
		if vNode.kind == "use" then
			local nPair = {
				pos=vNode.pos,posEnd=vNode.posEnd,
				vNode, vNode
			}
			table.insert(self._inHintSpace and self._hintSuffixPairList or self._suffixPairList, nPair)
		end
	end,
	Index=function(self, vNode)
		self:rawVisit(vNode)
		local nSuffixExpr = vNode[2]
		if nSuffixExpr.tag == "String" or nSuffixExpr.tag == "Number" then
			local nPair = {
				pos=nSuffixExpr.pos, posEnd=nSuffixExpr.posEnd,
				vNode, nSuffixExpr
			}
			table.insert(self._inHintSpace and self._hintSuffixPairList or self._suffixPairList, nPair)
		end
	end,
	Invoke=function(self, vNode)
		self:rawVisit(vNode)
		local nSuffixExpr = vNode[2]
		local nPair = {
			pos=nSuffixExpr.pos, posEnd=nSuffixExpr.posEnd,
			vNode, nSuffixExpr
		}
		table.insert(self._inHintSpace and self._hintSuffixPairList or self._suffixPairList, nPair)
	end,
	Call=function(self, vNode)
		self:rawVisit(vNode)
		local nFirstArg = vNode[2][1]
		if nFirstArg and nFirstArg.tag == "String" then
			local nPair = {
				pos=nFirstArg.pos, posEnd=nFirstArg.posEnd,
				vNode, nFirstArg
			}
			table.insert(self._inHintSpace and self._hintSuffixPairList or self._suffixPairList, nPair)
		end
	end,
}

local SearchVisitor = VisitorExtend(TagToVisiting)

function SearchVisitor:reverseInHint(vTarget)
	assert(self._inHintSpace ~= vTarget)
	self._inHintSpace = vTarget
end

function SearchVisitor.new(vSplitCode)
	local self = setmetatable({
		_code = vSplitCode,
		_inHintSpace=false,
		_identList = {},
		_suffixPairList = {},
		_hintSuffixPairList = {},
	}, SearchVisitor)
	do return self
 end end

function SearchVisitor:searchSuffixPair(vPos)
	local nIndex, nPair = self._code:binSearch(self._suffixPairList, vPos)
	if not nIndex then
		do return false
	 end end
	if vPos < nPair.pos or vPos >= nPair.posEnd then
		do return false
	 end end
	do return nPair
 end end

function SearchVisitor:searchHintSuffixPair(vPos)
	local nIndex, nPair = self._code:binSearch(self._hintSuffixPairList, vPos)
	if not nIndex then
		do return false
	 end end
	if vPos < nPair.pos or vPos >= nPair.posEnd then
		do return false
	 end end
	do return nPair
 end end

function SearchVisitor:searchIdent(vPos)
	local nIndex, nNode = self._code:binSearch(self._identList, vPos)
	if not nIndex then
		do return false
	 end end
	if vPos >= nNode.pos + #nNode[1] or vPos > nNode.posEnd then
		do return false
	 end end
	do return nNode
 end end

do return SearchVisitor
 end 
end end
--thlua.code.SearchVisitor end ==========)

--thlua.code.SplitCode begin ==========(
do local _ENV = _ENV
packages['thlua.code.SplitCode'] = function (...)

local class = require "thlua.class"


	
	  
	  
		
		
	


local SplitCode = class ()

local function split(vContent) 
	local nLineList = {}
	local nLinePosList = {}
	local nLineCount = 0
	local nStartPos = 1
	local nFinishPos = 0
	while true do
		nLineCount = nLineCount + 1
		nFinishPos = vContent:find("[\r\n]", nStartPos)
		if not nFinishPos then
			if nStartPos <= #vContent then
				nLinePosList[#nLinePosList + 1] = {
					pos=nStartPos,
					posEnd=#vContent
				}
				nLineList[#nLineList + 1] = vContent:sub(nStartPos)
			end
			break
		else
			if vContent:sub(nFinishPos, nFinishPos + 1) == "\r\n" then
				nFinishPos = nFinishPos + 1
			end
			nLinePosList[#nLinePosList + 1] = {
				pos=nStartPos,
				posEnd=nFinishPos
			}
			nLineList[#nLineList + 1] = vContent:sub(nStartPos, nFinishPos)
			nStartPos = nFinishPos + 1
		end
	::continue:: end
	do return nLineList, nLinePosList
 end end

function SplitCode:ctor(vContent, ...)
	self._content = vContent
	self._lineList, self._linePosList = split(vContent)
end

function SplitCode:binSearch(vList, vPos) 
	if #vList <= 0 then
		do return false
	 end end
	if vPos < vList[1].pos then
		do return false
	 end end
	local nLeft = 1
	local nRight = #vList
	local count = 0
	while nRight > nLeft do
		count = count + 1
		local nMiddle = (nLeft + nRight) // 2
		local nMiddle1 = nMiddle + 1
		if vPos < vList[nMiddle].pos then
			nRight = nMiddle - 1
		elseif vPos >= vList[nMiddle1].pos then
			nLeft = nMiddle1
		else
			nLeft = nMiddle
			nRight = nMiddle
		end
	::continue:: end
	do return nLeft, vList[nLeft]
 end end

function SplitCode:lcToPos(vLine, c)
	local nLinePos = self._linePosList
	local nLineInfo = nLinePos[vLine]
	local nLineCount = #nLinePos
	if nLineInfo then
		if c <= 1 then
			do return nLineInfo.pos
		 end else
			do return nLineInfo.pos + c - 1
		 end end
	else
		if vLine > nLineCount then
			do return #self._content + 1
		 end else
			do return 1
		 end end
	end
end

function SplitCode:fixupPos(vPos, vNode) 
	local line, lineInfo = self:binSearch(self._linePosList, vPos)
	if not line or not lineInfo then
		if vPos > #self._content then
			do return #self._linePosList + 1, 1
		 end else
			do return 1, 1
		 end end
	else
		do return line, vPos - lineInfo.pos + 1
	 end end
end

function SplitCode:getContent()
	do return self._content
 end end

function SplitCode:getLine(vLine)
	do return self._lineList[vLine]
 end end

do return SplitCode
 end 
end end
--thlua.code.SplitCode end ==========)

--thlua.code.SymbolVisitor begin ==========(
do local _ENV = _ENV
packages['thlua.code.SymbolVisitor'] = function (...)

local VisitorExtend = require "thlua.code.VisitorExtend"
local Exception = require "thlua.Exception"
local Enum = require "thlua.Enum"



  
  

  
	   
	  
		   
	
	 


   
	
	
	
	




local TagToVisiting = {
	Do=function(self, stm)
		local nHintLong = stm.hintLong
		if nHintLong then
			self:realVisit(nHintLong)
		end
		self:withScope(stm[1], nil, function()
			self:rawVisit(stm)
		end)
	end,
	Table=function(self, node)
		local nHintLong = node.hintLong
		if nHintLong then
			self:realVisit(nHintLong)
		end
		for i=1, #node do
			self:realVisit(node[i])
		::continue:: end
	end,
	While=function(self, stm)
		self:withScope(stm[2], nil, function()
			self:rawVisit(stm)
		end)
	end,
	Repeat=function(self, stm)
		self:withScope(stm[1], nil, function()
			self:rawVisit(stm)
		end)
	end,
	   
	Fornum=function(self, stm)
		local nBlockNode = stm[5]
		self:realVisit(stm[2])
		self:realVisit(stm[3])
		if nBlockNode then
			self:realVisit(stm[4])
		else
			local nSubNode = stm[4]
			assert(nSubNode.tag == "Block", "node must be block here")
			nBlockNode = nSubNode
		end
		self:withScope(nBlockNode, nil, function()
			self:symbolDefine(stm[1], Enum.SymbolKind_ITER)
			 
			           
			self:realVisit(assert(nBlockNode))
		end)
	end,
	Forin=function(self, stm)
		local nBlockNode = stm[3]
		self:realVisit(stm[2])
		self:withScope(nBlockNode, nil, function()
			for i, name in ipairs(stm[1]) do
				self:symbolDefine(name, Enum.SymbolKind_ITER)
			::continue:: end
			self:realVisit(nBlockNode)
		end)
	end,
	Return=function(self, stm)
		if #stm[1] > 0 then
			self._regionStack[#self._regionStack].retFlag = true
		end
		self:rawVisit(stm)
	end,
	Function=function(self, func)
		local nHintLong = func.hintPrefix
		if nHintLong then
			self:realVisit(nHintLong)
		end
		local nBlockNode = func[2]
		self:withScope(nBlockNode, func, function()
			local nParFullHint = true
			for i, par in ipairs(func[1]) do
				if par.tag == "Ident" then
					self:symbolDefine(par, Enum.SymbolKind_PARAM)
					if not par.isSelf and not par.hintShort then
						nParFullHint = false
					end
				else
					self:dotsDefine(par)
					if not par.hintShort then
						nParFullHint = false
					end
				end
			::continue:: end
			local nHintLong = func.hintSuffix
			if nHintLong then
				self:realVisit(nHintLong)
			end
			 
			self:realVisit(nBlockNode)
			local nPolyParList = func.hintPolyParList
			func.parFullHint = nParFullHint
			if not nParFullHint then
				if nPolyParList and #nPolyParList > 0 then
					           
					  
				end
			else
				if not func.hintPolyParList then
					func.hintPolyParList = {}
				end
			end
		end)
	end,
	If=function(self, node)
		for i, subNode in ipairs(node) do
			if subNode.tag == "Block" then
				self:withScope(subNode, nil, function()
					self:realVisit(subNode)
				end)
			else
				self:realVisit(subNode)
			end
		::continue:: end
	end,
	Block=function(self, stm)
		self:rawVisit(stm)
	end,
	Local=function(self, stm)
		local nIdentList = stm[1]
		self:realVisit(stm[2])
		 
		for i, name in ipairs(nIdentList) do
			self:symbolDefine(name, stm.isConst and Enum.SymbolKind_CONST or Enum.SymbolKind_LOCAL)
		::continue:: end
	end,
	Set=function(self, stm)
		local nVarList = stm[1]
		for i=1, #nVarList do
			local var = nVarList[i]
			if var.tag == "Ident" then
				self:symbolUse(var, true)
			end
		::continue:: end
		self:rawVisit(stm)
	end,
	Localrec=function(self, stm)
		self:symbolDefine(stm[1], stm.isConst and Enum.SymbolKind_CONST or Enum.SymbolKind_LOCAL)
		self:realVisit(stm[2])
	end,
	Dots=function(self, node)
		self:dotsUse(node)
	end,
	Ident=function(self, node)
		assert(node.kind == "use")
		if node.isGetFrom ~= nil then           
		else
			self:symbolUse(node, false)
		end
	end,
	Chunk=function(self, chunk)
		local nBlockNode = chunk[3]
		self:withScope(nBlockNode, chunk, function()
			self:symbolDefine(chunk[1], Enum.SymbolKind_LOCAL)
			for k, name in ipairs(chunk[2]) do
				if name.tag == "dots" then
					self:dotsDefine(name)
				end
			::continue:: end
			self:realVisit(nBlockNode)
			local nInjectNode = chunk.injectNode
			if nInjectNode then
				self:realVisit(nInjectNode)
			end
		end)
	end,
	HintSpace=function(self, node)
		self:reverseInHint(true)
		if node.kind == "StatHintSpace" then
			self:realVisit(node[1])
		else
			for i=1, #node do
				self:realVisit(node[i])
			::continue:: end
		end
		self:reverseInHint(false)
	end,
	HintEval=function(self, vNode)
		vNode.endLine = self._code:fixupPos(vNode.posEnd)
		self:reverseInHint(false)
		self:realVisit(vNode[1])
		self:reverseInHint(true)
	end,
}

local SymbolVisitor = VisitorExtend(TagToVisiting)

function SymbolVisitor:reverseInHint(vTarget)
	assert(self._inHintSpace ~= vTarget)
	self._inHintSpace = vTarget
end

function SymbolVisitor:withHintBlock(vBlockNode, vFuncNode, vInnerCall)
	assert(vBlockNode.tag == "Block", "node tag must be Block or Function but get "..tostring(vBlockNode.tag))
	local nHintStack = self._hintStack
	local nStackLen = #nHintStack
	vBlockNode.subBlockList = {}
	local nPreNode = nHintStack[nStackLen]
	if nPreNode.tag == "Block" then
		vBlockNode.symbolTable = setmetatable({}, {
			__index=nPreNode.symbolTable,
		})
	else
		vBlockNode.symbolTable = {
			let=nPreNode,
		}
	end
	table.insert(self._hintStack, vBlockNode)
	if vFuncNode then
		vFuncNode.letNode = false
		table.insert(self._hintFuncStack, vFuncNode)
		vInnerCall()
		table.remove(self._hintFuncStack)
	else
		vInnerCall()
	end
	table.remove(self._hintStack)
end

function SymbolVisitor:withScope(vBlockNode, vFuncOrChunk, vInnerCall)
	assert(vBlockNode.tag == "Block", "node tag must be Block but get "..tostring(vBlockNode.tag))
	if self._inHintSpace then
		self:withHintBlock(vBlockNode, vFuncOrChunk  , vInnerCall)
		do return
	 end end
	vBlockNode.subBlockList = {}
	local nScopeStack = self._scopeStack
	local nStackLen = #nScopeStack
	if nStackLen > 0 then
		local nPreScope = nScopeStack[nStackLen]
		vBlockNode.symbolTable = setmetatable({}, {
			__index=nPreScope.symbolTable,
		})
		table.insert(nPreScope.subBlockList, vBlockNode)
	else
		vBlockNode.symbolTable = {}
	end
	table.insert(self._scopeStack, vBlockNode)
	if vFuncOrChunk then
		table.insert(self._regionStack, vFuncOrChunk)
		table.insert(self._hintStack, assert(vFuncOrChunk.letNode))
		vInnerCall()
		table.remove(self._regionStack)
		table.remove(self._hintStack)
	else
		vInnerCall()
	end
	table.remove(self._scopeStack)
end

function SymbolVisitor:symbolDefine(vIdentNode, vImmutKind)   
	   
	vIdentNode.symbolKind = vImmutKind
	vIdentNode.symbolModify = false
	local nName = vIdentNode[1]
	if not self._inHintSpace then
		local nHintShort = vIdentNode.hintShort
		if nHintShort then
			self:realVisit(nHintShort)
		end
		local nScope = self._scopeStack[#self._scopeStack]
		local nLookupNode = nScope.symbolTable[nName]
		nScope.symbolTable[nName] = vIdentNode
		vIdentNode.lookupIdent = nLookupNode
	else
		local nBlockOrRegion = self._hintStack[#self._hintStack]
		if nBlockOrRegion.tag == "Block" then
			local nLookupNode = nBlockOrRegion.symbolTable[nName]
			nBlockOrRegion.symbolTable[nName] = vIdentNode
			vIdentNode.lookupIdent = nLookupNode
		else
			error("local stat can't existed here..")
		end
	end
end

function SymbolVisitor:dotsDefine(vDotsNode)
	local nCurRegion = self._inHintSpace and self._hintFuncStack[#self._hintFuncStack] or self._regionStack[#self._regionStack]
	nCurRegion.symbol_dots = vDotsNode
end

function SymbolVisitor:dotsUse(vDotsNode)
	local nCurRegion = self._inHintSpace and self._hintFuncStack[#self._hintFuncStack] or self._regionStack[#self._regionStack]
	local nDotsDefine = nCurRegion and nCurRegion.symbol_dots
	if not nDotsDefine then
		error(Exception.new("cannot use '...' outside a vararg function", vDotsNode))
	end
end

function SymbolVisitor:hintSymbolUse(vIdentNode, vIsAssign)
	local nBlockOrLetIdent = self._hintStack[#self._hintStack]
	local nName = vIdentNode[1]
	local nDefineNode = nil
	if nBlockOrLetIdent.tag == "Block" then
		nDefineNode = nBlockOrLetIdent.symbolTable[nName]
	else
		if nName == "let" then
			nDefineNode = nBlockOrLetIdent
		end
	end
	if not nDefineNode then
		vIdentNode.defineIdent = false
		if nBlockOrLetIdent.tag == "Block" then
			vIdentNode.isGetFrom = nBlockOrLetIdent.symbolTable["let"]
		else
			vIdentNode.isGetFrom = nBlockOrLetIdent
		end
	else
		if vIsAssign then
			nDefineNode.symbolModify = true
			vIdentNode.isGetFrom = false
		else
			vIdentNode.isGetFrom = true
		end
		vIdentNode.defineIdent = nDefineNode
	end
end

function SymbolVisitor:symbolUse(vIdentNode, vIsAssign)
	if self._inHintSpace then
		self:hintSymbolUse(vIdentNode, vIsAssign)
		do return
	 end end
	local nScope = self._scopeStack[#self._scopeStack]
	local nDefineNode = nScope.symbolTable[vIdentNode[1]]
	if not nDefineNode then
		local nEnvIdent = nScope.symbolTable._ENV
		vIdentNode.isGetFrom = nEnvIdent
		vIdentNode.defineIdent = false
		do return
	 end end
	if vIsAssign then
		if nDefineNode.symbolKind == Enum.SymbolKind_CONST then
			error(Exception.new("cannot assign to const variable '"..vIdentNode[1].."'", vIdentNode))
		else
			nDefineNode.symbolModify = true
		end
		vIdentNode.isGetFrom = false
	else
		vIdentNode.isGetFrom = true
	end
	vIdentNode.defineIdent = nDefineNode
end

function SymbolVisitor.new(vCode)
	local self = setmetatable({
		_code=vCode,
		_scopeStack={},
		_regionStack={},
		_inHintSpace=false,
		_hintStack={} ,
		_hintFuncStack={},
	}, SymbolVisitor)
	do return self
 end end

do return SymbolVisitor
 end 
end end
--thlua.code.SymbolVisitor end ==========)

--thlua.code.VisitorExtend begin ==========(
do local _ENV = _ENV
packages['thlua.code.VisitorExtend'] = function (...)

local Node = require "thlua.code.Node"
local Exception = require "thlua.Exception"



  

   
	
	


  
	   
	  
		   
	
	 




local TagToTraverse = {
	Chunk=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
		self:realVisit(node.letNode)
		local nInjectExpr = node.injectNode
		if nInjectExpr then
			self:realVisit(nInjectExpr)
		end
	end,
	HintTerm=function(self,node)
		self:realVisit(node[1])
	end,
	Block=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		::continue:: end
	end,

	 
	Do=function(self, node)
		local nHintLong = node.hintLong
		if nHintLong then
			self:realVisit(nHintLong)
		end
		self:realVisit(node[1])
	end,
	Set=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	While=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Repeat=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	If=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		::continue:: end
	end,
	Forin=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
	end,
	Fornum=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
		self:realVisit(node[4])
		local last = node[5]
		if last then
			self:realVisit(last)
		end
	end,
	Local=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Localrec=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Goto=function(self, node)
	end,
	Return=function(self, node)
		self:realVisit(node[1])
	end,
	Continue=function(self, node)
	end,
	Break=function(self, node)
	end,
	Label=function(self, node)
	end,
	 
	Call=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Invoke=function(self, node)
		local hint = node.hintPolyArgs
		if hint then
			self:realVisit(hint)
		end
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
	end,

	 
	Nil=function(self, node)
	end,
	False=function(self, node)
	end,
	True=function(self, node)
	end,
	Number=function(self, node)
	end,
	String=function(self, node)
	end,
	Function=function(self, node)
		local nHintLong = node.hintPrefix
		if nHintLong then
			self:realVisit(nHintLong)
		end
		local nLetNode = node.letNode
		if nLetNode then
			self:realVisit(nLetNode)
		end
		self:realVisit(node[1])
		local nHintLong = node.hintSuffix
		if nHintLong then
			self:realVisit(nHintLong)
		end
		self:realVisit(node[2])
	end,
	Table=function(self, node)
		local nHintLong = node.hintLong
		if nHintLong then
			self:realVisit(nHintLong)
		end
		for i=1, #node do
			self:realVisit(node[i])
		::continue:: end
	end,
	Op=function(self, node)
		self:realVisit(node[2])
		local right = node[3]
		if right then
			self:realVisit(right)
		end
	end,
	Paren=function(self, node)
		self:realVisit(node[1])
	end,
	Dots=function(self, node)
	end,
	HintAt=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node.hintShort)
	end,

	 
	Index=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Ident=function(self, node)
		local nHintShort = node.kind == "def" and node.hintShort
		if nHintShort then
			self:realVisit(nHintShort)
		end
	end,

	 
	ParList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		::continue:: end
	end,
	ExprList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		::continue:: end
	end,
	VarList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		::continue:: end
	end,
	IdentList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		::continue:: end
	end,
	Pair=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	HintSpace=function(self, node)
		if node.kind == "StatHintSpace" then
			self:realVisit(node[1])
		else
			for i=1, #node do
				self:realVisit(node[i])
			::continue:: end
		end
	end,
	HintScript=function(self, node)
	end,
	HintEval=function(self, node)
		self:realVisit(node[1])
	end,
}

local function VisitorExtend(vDictOrFunc)
	local nType = type(vDictOrFunc)
	if nType == "table" then
		local t = {}
		t.__index = t
		function t:realVisit(node)
			local tag = node.tag
			local f = vDictOrFunc[tag] or TagToTraverse[tag]
			if not f then
				error("tag="..tostring(tag).."not existed")
			end
			f(self, node)
		end
		function t:rawVisit(node)
			TagToTraverse[node.tag](self, node)
		end
		do return t
	 end elseif nType == "function" then
		
			   
				
				
			
		
		local t = {
			realVisit=function(self, vNode)
				vDictOrFunc(self, vNode)
			end,
			rawVisit=function(self, vNode)
				TagToTraverse[vNode.tag](self, vNode)
			end
		}
		do return t
	 end else
		error("VisitorExtend must take a function or dict for override")
	end
end

do return VisitorExtend
 end 
end end
--thlua.code.VisitorExtend end ==========)

--thlua.context.ApplyContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.ApplyContext'] = function (...)

local class = require "thlua.class"
local OpenFunction = require "thlua.type.func.OpenFunction"
local BaseFunction = require "thlua.type.func.BaseFunction"
local AssignContext = require "thlua.context.AssignContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"
local RecurChain = require "thlua.context.RecurChain"
local RefineTerm = require "thlua.term.RefineTerm"
local ObjectField = require "thlua.type.object.ObjectField"


	  


local ApplyContext = class (AssignContext)

function ApplyContext:ctor(vNode, ...)
	self._curCase = false  
	self._once = false
	self._recurChain = false  
	self._lookTargetSet = {}    
	self._stack:getRuntime():recordApplyContext(vNode, self)
	self._finalReturn = false 
end

function ApplyContext:outLookdownNode(vNodeSet )
	for nTarget,_ in pairs(self._lookTargetSet) do
		if ObjectField.is(nTarget) then
			for nNode, _ in pairs(nTarget:getUseNodeSet()) do
				vNodeSet[nNode] = true
			::continue:: end
		else
			local nUseNodeSet = nTarget:getUseNodeSet()
			if nUseNodeSet then
				for nNode, _ in pairs(nUseNodeSet) do
					vNodeSet[nNode] = true
				::continue:: end
			end
		end
	::continue:: end
end

function ApplyContext:outLookupNode(vNodeSet )
	for nTarget,_ in pairs(self._lookTargetSet) do
		if ObjectField.is(nTarget) then
			local nLookupNode = nTarget:getInitNode()
			local nValueType = nTarget:getValueType()
			if BaseFunction.is(nValueType) then
				local nUseNodeSet = nValueType:getUseNodeSet()
				if nUseNodeSet then
					nLookupNode = nValueType:getNode()
				end
			end
			vNodeSet[nLookupNode] = true
		else
			vNodeSet[nTarget:getNode()] = true
		end
	::continue:: end
end

            
function ApplyContext:addLookTarget(vTarget )
	self._lookTargetSet[vTarget] = true
	if ObjectField.is(vTarget) then
		vTarget:putUseNode(self._node)
		local nValueType = vTarget:getValueType()
		if BaseFunction.is(nValueType) then
			local nUseNodeSet = nValueType:getUseNodeSet()
			if nUseNodeSet then
				nUseNodeSet[self._node] = true
			end
		end
	else
		local nUseNodeSet = vTarget:getUseNodeSet()
		if nUseNodeSet then
			nUseNodeSet[self._node] = true
		end
	end
end

function ApplyContext:recursiveChainTestAndRun(vSelfType, vFunc) 
	local nRecurChain = self._recurChain
	if not nRecurChain then
		nRecurChain = RecurChain.new()
		self._recurChain = nRecurChain
	end
	do return nRecurChain:testAndRun(vSelfType, vFunc)
 end end

function ApplyContext:withCase(vCase, vFunc)
	assert(not self._curCase, "apply context case in case error")
	self._curCase = vCase
	vFunc()
	self._curCase = false
	self._once = true
end

function ApplyContext:pushNothing()
	self._once = true
end

function ApplyContext:openAssign(vType)
	if self._once then
		error(Exception.new("table assign new field can't be mixed actions", self._node))
	end
	vType:setAssigned(self)
	self._once = true
end

   
function ApplyContext:nativeOpenReturn(vTermTuple)
	assert(not self._curCase)
	self._curCase = VariableCase.new()
	self:pushOpenReturn(vTermTuple)
	self._curCase = false
end

function ApplyContext:pushOpenReturn(vTermTuple)
	if RefineTerm.is(vTermTuple) then
		local nFirst = vTermTuple:getType()
		vTermTuple:foreach(function(vType, vCase)
			self:pushFirstAndTuple(vType, nil, vCase)
		end)
	else
		self:unfoldTermTuple(vTermTuple, function(vFirstType, vTypeTuple, vCase)
			self:pushFirstAndTuple(vFirstType, vTypeTuple, vCase)
		end)
	end
	self._once = true
end

function ApplyContext:pushFirstAndTuple(vFirstType, vTuple, vCase)
	error("push return not implement in ApplyContext")
end

function ApplyContext:pushRetTuples(vRetTuples)
	error("push return not implement in ApplyContext")
end

function ApplyContext:raiseError(vErrType)
	self._stack:RAISE_ERROR(self, vErrType)
end

function ApplyContext:getFinalReturn()
	do return self._finalReturn
 end end

do return ApplyContext
 end 
end end
--thlua.context.ApplyContext end ==========)

--thlua.context.AssignContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.AssignContext'] = function (...)

local class = require "thlua.class"

local Struct = require "thlua.type.object.Struct"
local RefineTerm = require "thlua.term.RefineTerm"
local VariableCase = require "thlua.term.VariableCase"
local AutoHolder = require "thlua.auto.AutoHolder"
local TypedFunction = require "thlua.type.func.TypedFunction"
local AutoTable = require "thlua.type.object.AutoTable"
local AutoFunction = require "thlua.type.func.AutoFunction"

local TermTuple = require "thlua.tuple.TermTuple"
local AutoFlag = require "thlua.auto.AutoFlag"
local AutoHolder = require "thlua.auto.AutoHolder"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"

local ListDict = require "thlua.manager.ListDict"
local OperContext = require "thlua.context.OperContext"


	  
	  
	   


local AssignContext = class (OperContext)

function AssignContext:ctor(...)
	self._finish = false  
end

function AssignContext:matchArgsToTypeDots(
	vNode,
	vTermTuple,
	vParNum,
	vHintDots
)
	local nTailTermList = {}
	for i=vParNum + 1, #vTermTuple do
		local nTerm = vTermTuple:get(self, i)
		nTailTermList[#nTailTermList + 1] = self:assignTermToType(nTerm, vHintDots)
	::continue:: end
	local nTermTail = vTermTuple:getTail()
	if AutoTail.is(nTermTail) then
		local nMore = vParNum - #vTermTuple
		if nMore <= 0 then
			nTermTail:sealTailFrom(self, 1, vHintDots)
		else
			nTermTail:sealTailFrom(self, nMore + 1, vHintDots)
		end
	end
	do return self:UTermTupleByTail({}, DotsTail.new(self, vHintDots))
 end end

function AssignContext:matchArgsToAutoDots(
	vNode,
	vTermTuple,
	vParNum
)
	local nTailTermList = {}
	for i=vParNum + 1, #vTermTuple do
		nTailTermList[#nTailTermList + 1] = vTermTuple:get(self, i)
	::continue:: end
	local nTermTail = vTermTuple:getTail()
	if not AutoTail.is(nTermTail) then
		if nTermTail then
			do return self:UTermTupleByTail(nTailTermList, DotsTail.new(self, nTermTail:getRepeatType()))
		 end else
			do return self:UTermTupleByTail(nTailTermList)
		 end end
	else
		local nMore = vParNum - #vTermTuple
		if nMore <= 0 then
			do return self:UTermTupleByTail(nTailTermList, nTermTail)
		 end else
			do return self:UTermTupleByTail(nTailTermList, nTermTail:openTailFrom(self, nMore + 1))
		 end end
	end
end

function AssignContext:matchArgsToNoDots(
	vNode,
	vTermTuple,
	vParNum
)
	for i=vParNum + 1, #vTermTuple do
		vTermTuple:get(self, i)
		self:error("parameters is not enough")
	::continue:: end
	local nTermTail = vTermTuple:getTail()
	if AutoTail.is(nTermTail) then
		local nMore = vParNum - #vTermTuple
		if nMore <= 0 then
			nTermTail:sealTailFrom(self, 1, true)
		else
			nTermTail:sealTailFrom(self, nMore + 1, true)
		end
	end
end

function AssignContext:matchArgsToTypeTuple(
	vNode,
	vTermTuple,
	vTypeTuple
)
	local nParNum = #vTypeTuple
	for i=1, #vTermTuple do
		local nAutoTerm = vTermTuple:get(self, i)
		local nHintType = vTypeTuple:get(i)
		self:assignTermToType(nAutoTerm, nHintType)
	::continue:: end
	for i=#vTermTuple + 1, nParNum do
		local nAutoTerm = vTermTuple:get(self, i)
		local nHintType = vTypeTuple:get(i)
		self:assignTermToType(nAutoTerm, nHintType)
	::continue:: end
	local nDotsType = vTypeTuple:getRepeatType()
	if nDotsType then
		self:matchArgsToTypeDots(vNode, vTermTuple, nParNum, nDotsType)
	else
		self:matchArgsToNoDots(vNode, vTermTuple, nParNum)
	end
end


       
       
         
               

function AssignContext:tryIncludeCast(
	vAutoFnCastDict,
	vDstType,
	vSrcType
) 
	local nCollection = self._manager:TypeCollection()
	local nDstFnPart = vDstType:partTypedFunction()
	local nDstObjPart = vDstType:partTypedObject()
	local nIncludeSucc = true
	local nCastSucc = true
	local nPutFnPart = false
	local nPutObjPart = false
	vSrcType:foreach(function(vSubType)
		if AutoTable.is(vSubType) and vSubType:isCastable() and not nDstObjPart:isNever() then
			nPutObjPart = true
			local nMatchOne = false
			nDstObjPart:foreach(function(vAtomType)
				if Struct.is(vAtomType) then
					local nAutoFnCastDict = vSubType:castMatchOne(self, vAtomType)
					if nAutoFnCastDict then
						vAutoFnCastDict:putAll(nAutoFnCastDict)
						nCollection:put(vAtomType)
						nMatchOne = true
					end
				end
			end)
			if not nMatchOne then
				nCastSucc = false
			end
		elseif AutoFunction.is(vSubType) and vSubType:isCastable() and not nDstFnPart:isNever() then
			vAutoFnCastDict:putOne(vSubType, nDstFnPart)
			nPutFnPart = true
		elseif vDstType:includeAtom(vSubType) then
			nCollection:put(vSubType)
		else
			nIncludeSucc = false
		end
	end)
	if not nIncludeSucc then
		do return false
	 end else
		if nPutFnPart then
			nCollection:put(nDstFnPart)
		end
		if not nCastSucc and nPutObjPart then
			nCollection:put(nDstObjPart)
		end
		do return nCollection:mergeToAtomUnion(), nCastSucc
	 end end
end

function AssignContext:includeAndCast(vDstType, vSrcType, vWhen)
	local nFnLateDict = self:newAutoFnCastDict()
	local nIncludeType, nCastSucc = self:tryIncludeCast(nFnLateDict, vDstType, vSrcType)
	if nIncludeType then
		self:runLateCast(nFnLateDict)
		if not nCastSucc then
			if vWhen then
				self:error("type cast fail when "..tostring(vWhen))
			else
				self:error("type cast fail")
			end
		end
	else
		if vWhen then
			self:error("type not match when "..tostring(vWhen))
		else
			self:error("type not match")
		end
	end
	do return nIncludeType
 end end

function AssignContext:assignTermToType(vAutoTerm, vDstType)
	local nSrcType = vAutoTerm:getType()
	local nDstType = vDstType:checkAtomUnion()
	if not nSrcType then
		vAutoTerm:setAutoCastType(self, nDstType)
	else
		self:includeAndCast(nDstType, nSrcType)
	end
	      
	do return self:RefineTerm(nDstType)
 end end

function AssignContext:finish()
	assert(not self._finish, "context finish can only called once")
	self._finish = true
end

function AssignContext:newAutoFnCastDict()
	do return ListDict ()
 end end

function AssignContext:runLateCast(vDict)
	vDict:forKList(function(vAutoFn, vTypeFnList)
		for _, nTypeFn in ipairs(vTypeFnList) do
			if TypedFunction.is(nTypeFn) then
				vAutoFn:checkWhenCast(self, nTypeFn)
			end
		::continue:: end
	end)
end

function AssignContext:unfoldTermTuple(vTermTuple, vFunc  )
	local nFirstTerm = vTermTuple:get(self, 1)
	if #vTermTuple == 0 then
		vFunc(nFirstTerm:getType(), vTermTuple:checkTypeTuple(), nil)
		do return
	 end end
	local nTail = vTermTuple:getTail()
	local nRepeatType = nTail and nTail:getRepeatType()
	nFirstTerm:foreach(function(vAtomType, vCase)
		local nTypeList = {vAtomType}
		for i=2, #vTermTuple do
			local nTerm = vTermTuple:get(self, i)
			local nType = vCase[nTerm:attachImmutVariable()]
			if not nType then
				nTypeList[i] = nTerm:getType()
			else
				nTypeList[i] = assert(nTerm:getType():safeIntersect(nType), "unexcepted intersect when return")
			end
		::continue:: end
		local nTypeTuple = self._manager:TypeTuple(self._node, nTypeList)
		local nTypeTuple = nRepeatType and nTypeTuple:withDots(nRepeatType) or nTypeTuple
		vFunc(vAtomType, nTypeTuple, vCase)
	end)
end

do return AssignContext
 end 
end end
--thlua.context.AssignContext end ==========)

--thlua.context.CompletionKind begin ==========(
do local _ENV = _ENV
packages['thlua.context.CompletionKind'] = function (...)

do return {
    Text = 1,
    Method = 2,
    Function = 3,
    Constructor = 4,
    Field = 5,
    Variable = 6,
    Class = 7,
    Interface = 8,
    Module = 9,
    Property = 10,
    Unit = 11,
    Value = 12,
    Enum = 13,
    Keyword = 14,
    Snippet = 15,
    Color = 16,
    File = 17,
    Reference = 18,
    Folder = 19,
    EnumMember = 20,
    Constant = 21,
    Struct = 22,
    Event = 23,
    Operator = 24,
    TypeParameter = 25,
} end 
end end
--thlua.context.CompletionKind end ==========)

--thlua.context.FieldCompletion begin ==========(
do local _ENV = _ENV
packages['thlua.context.FieldCompletion'] = function (...)

local class = require "thlua.class"
local CompletionKind = require "thlua.context.CompletionKind"
local MemberFunction = require "thlua.type.func.MemberFunction"
local BaseFunction = require "thlua.type.func.BaseFunction"
local ClassFactory = require "thlua.type.func.ClassFactory"
local Reference = require "thlua.refer.Reference"
local SpaceTable = require "thlua.refer.SpaceTable"
local SpaceBuiltin = require "thlua.refer.SpaceBuiltin"

local TemplateReferCom = require "thlua.refer.TemplateReferCom"
local TypeReferCom = require "thlua.refer.TypeReferCom"

local FloatLiteral = require "thlua.type.basic.FloatLiteral"
local IntegerLiteral = require "thlua.type.basic.IntegerLiteral"
local StringLiteral = require "thlua.type.basic.StringLiteral"
local BooleanLiteral= require "thlua.type.basic.BooleanLiteral"


	  
	   
		
	


local FieldCompletion = class ()

function FieldCompletion:ctor()
	self._passDict = {} 
	self._keyToKind = {} 
end

local LiteralMetaDict  = {
	[StringLiteral.meta]= true,
	[IntegerLiteral.meta]= true,
	[FloatLiteral.meta]= true,
	[BooleanLiteral.meta]= true,
}

local function isLiteral(vType)
	local nMeta = getmetatable(vType)
	if nMeta and LiteralMetaDict[nMeta] then
		do return true
	 end else
		do return false
	 end end
end

function FieldCompletion:putField(vKey, vValue)
	local nType = vValue:checkAtomUnion()
	if MemberFunction.is(nType) then
		self._keyToKind[vKey] = CompletionKind.Method
	elseif ClassFactory.is(nType) then
		self._keyToKind[vKey] = CompletionKind.Function
	elseif BaseFunction.is(nType) then
		self._keyToKind[vKey] = CompletionKind.Function
	elseif isLiteral(nType) then
		self._keyToKind[vKey] = CompletionKind.Constant
	else
		self._keyToKind[vKey] = CompletionKind.Field
	end
end

function FieldCompletion:putSpaceField(vKey, vValue)
	if SpaceTable.checkSpace(vValue) then
		self._keyToKind[vKey] = CompletionKind.Module
	elseif SpaceBuiltin.is(vValue) then
		self._keyToKind[vKey] = CompletionKind.Function
	elseif Reference.is(vValue) then
		local nCom = vValue:getComNowait()
		if TypeReferCom.is(nCom) then
			self._keyToKind[vKey] = CompletionKind.Class
		elseif TemplateReferCom.is(nCom) then
			self._keyToKind[vKey] = CompletionKind.Function
		else
			self._keyToKind[vKey] = CompletionKind.Variable
		end
	else
		self._keyToKind[vKey] = CompletionKind.Class
	end
end

function FieldCompletion:testAndSetPass(vAtomType)
	if self._passDict[vAtomType] then
		do return false
	 end else
		self._passDict[vAtomType] = true
		do return true
	 end end
end

function FieldCompletion:foreach(vOnPair )
	for k,v in pairs(self._keyToKind) do
		vOnPair(k, v)
	::continue:: end
end

do return FieldCompletion
 end 
end end
--thlua.context.FieldCompletion end ==========)

--thlua.context.LogicContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.LogicContext'] = function (...)

local class = require "thlua.class"
local OpenFunction = require "thlua.type.func.OpenFunction"
local OperContext = require "thlua.context.OperContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"


	  


local LogicContext = class (OperContext)

function LogicContext:ctor(
	...
)
end

function LogicContext:logicCombineTerm(vLeft, vRight, vRightAndCase)
	local nTypeCaseList = {}
	vLeft:foreach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = {vType, vCase}
	end)
	vRight:foreach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = {vType, vCase & vRightAndCase}
	end)
	do return self:mergeToRefineTerm(nTypeCaseList)
 end end

function LogicContext:logicNotTerm(vTerm)
	local nTypeCaseList = {}
	local nBuiltinType = self._manager.type
	vTerm:trueEach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = { nBuiltinType.False, vCase }
	end)
	vTerm:falseEach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = { nBuiltinType.True, vCase }
	end)
	do return self:mergeToRefineTerm(nTypeCaseList)
 end end

function LogicContext:logicTrueTerm(vTerm)
	local nTypeCaseList = {}
	vTerm:trueEach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = {vType, vCase}
	end)
	do return self:mergeToRefineTerm(nTypeCaseList)
 end end

function LogicContext:logicFalseTerm(vTerm)
	local nTypeCaseList = {}
	vTerm:falseEach(function(vType, vCase)
		nTypeCaseList[#nTypeCaseList + 1] = {vType, vCase}
	end)
	do return self:mergeToRefineTerm(nTypeCaseList)
 end end

do return LogicContext
 end 
end end
--thlua.context.LogicContext end ==========)

--thlua.context.MorePushContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.MorePushContext'] = function (...)

local class = require "thlua.class"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local OpenFunction = require "thlua.type.func.OpenFunction"
local ApplyContext = require "thlua.context.ApplyContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"


	  


local MorePushContext = class (ApplyContext)

     
function MorePushContext:ctor(
	...
)
	self._retMaxLength = 0
	self._retRepCollection = self._manager:TypeCollection()
	self._retList = {} 
end

function MorePushContext:pushFirstAndTuple(vFirstType, vTypeTuple, vCase)
	local nCurCase = assert(self._curCase, "[FATAL] MorePushContext push value without case")
	self._retList[#self._retList + 1] = {
		vFirstType, vCase and (vCase & nCurCase) or nCurCase, vTypeTuple
	}
	local nLength = vTypeTuple and #vTypeTuple or 1
	if nLength > self._retMaxLength then
		self._retMaxLength = nLength
	end
	if vTypeTuple then
		local nRepeatType = vTypeTuple:getRepeatType()
		if nRepeatType then
			self._retRepCollection:put(nRepeatType)
		end
	end
end

function MorePushContext:pushRetTuples(vRetTuples)
	self:raiseError(vRetTuples:getErrType())
	vRetTuples:foreachWithFirst(function(vTypeTuple, vFirst)
		self:pushFirstAndTuple(vFirst:checkAtomUnion(), vTypeTuple)
	end)
end

function MorePushContext:pcallMergeReturn(vErrType)
	self._retMaxLength = self._retMaxLength + 1
	local nRetList = self._retList
	local nTrue = self._manager.type.True
	local nFalse = self._manager.type.False
	for i=1, #nRetList do
		local nTypeCaseTuple = nRetList[i]
		nTypeCaseTuple[1] = nTrue
		local nTuple = nTypeCaseTuple[3]
		if nTuple then
			nTypeCaseTuple[3] = nTuple:leftAppend(nTrue)
		else
			nTypeCaseTuple[3] = self._manager:TypeTuple(self._node, {nTrue})
		end
	::continue:: end
	nRetList[#nRetList + 1] = {
		nFalse, VariableCase.new(), self._manager:TypeTuple(self._node, {nFalse, vErrType})
	}
	if self._retMaxLength < 2 then
		self._retMaxLength = 2
	end
	do return self:mergeReturn()
 end end

function MorePushContext:mergeReturn()
	    
	local nRetList = self._retList
	local nMaxLength = self._retMaxLength
	local nRepeatType = self._retRepCollection:mergeToAtomUnion()
	local nRepeatType = (not nRepeatType:isNever()) and nRepeatType or false
	if nMaxLength <= 0 then
		do return self:FixedTermTuple({}, nRepeatType)
	 end end
	local nTermList = {}
	      
	for i=2,nMaxLength do
		local nCollection = self._manager:TypeCollection()
		for _, nType1TupleCase in pairs(nRetList) do
			local nTypeTuple = nType1TupleCase[3]
			local nType = nTypeTuple and nTypeTuple:get(i) or self._manager.type.Nil
			nCollection:put(nType)
		::continue:: end
		local nTypeI = nCollection:mergeToAtomUnion()
		nTermList[i] = self:RefineTerm(nTypeI)
	::continue:: end
	    
	local nTypeCaseList = {}
	for _, nType1TupleCase in pairs(nRetList) do
		local nType1 = nType1TupleCase[1]
		local nCase = nType1TupleCase[2]:copy()
		local nTypeTuple = nType1TupleCase[3]
		for i=2,nMaxLength do
			local nType = nTypeTuple and nTypeTuple:get(i):checkAtomUnion() or self._manager.type.Nil
			nCase:put_and(nTermList[i]:attachImmutVariable(), nType)
		::continue:: end
		nTypeCaseList[#nTypeCaseList + 1] = {
			nType1, nCase
		}
	::continue:: end
	nTermList[1] = self:mergeToRefineTerm(nTypeCaseList)
	do return self:FixedTermTuple(nTermList, nRepeatType)
 end end

do return MorePushContext
 end 
end end
--thlua.context.MorePushContext end ==========)

--thlua.context.NoPushContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.NoPushContext'] = function (...)

local class = require "thlua.class"
local OpenFunction = require "thlua.type.func.OpenFunction"
local ApplyContext = require "thlua.context.ApplyContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"


	  


local NoPushContext = class (ApplyContext)

function NoPushContext:pushFirstAndTuple(vFirstType, vTuple, vCase)
	self:pushNothing()
end

function NoPushContext:pushRetTuples(vRetTuples)
	self:raiseError(vRetTuples:getErrType())
	self:pushNothing()
end

do return NoPushContext
 end 
end end
--thlua.context.NoPushContext end ==========)

--thlua.context.OnePushContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.OnePushContext'] = function (...)

local RefineTerm = require "thlua.term.RefineTerm"
local TermTuple = require "thlua.tuple.TermTuple"
local class = require "thlua.class"
local OpenFunction = require "thlua.type.func.OpenFunction"
local ApplyContext = require "thlua.context.ApplyContext"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"


	  


local OnePushContext = class (ApplyContext)

function OnePushContext:ctor(
	_,_,_,vNotnil
)
	self._retList = {}  
	self._notnil = vNotnil
end

function OnePushContext:pushFirstAndTuple(vFirstType, vTuple, vCase)
	local nCurCase = assert(self._curCase, "[FATAL] OnePushContext push value without case")
	self._retList[#self._retList + 1] = {
		self._notnil and vFirstType:notnilType() or vFirstType, vCase and (vCase & nCurCase) or nCurCase
	}
end

function OnePushContext:pushRetTuples(vRetTuples)
	self:raiseError(vRetTuples:getErrType())
	self:pushFirstAndTuple(vRetTuples:getFirstType())
end

function OnePushContext:mergeFirst()
	local nTypeCaseList = {}
	for _, nType1TupleCase in pairs(self._retList) do
		local nType1 = nType1TupleCase[1]
		local nCase = nType1TupleCase[2]
		nTypeCaseList[#nTypeCaseList + 1] = {
			nType1, nCase
		}
	::continue:: end
	do return self:mergeToRefineTerm(nTypeCaseList)
 end end

do return OnePushContext
 end 
end end
--thlua.context.OnePushContext end ==========)

--thlua.context.OperContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.OperContext'] = function (...)

local class = require "thlua.class"

local Exception = require "thlua.Exception"
local RefineTerm = require "thlua.term.RefineTerm"
local VariableCase = require "thlua.term.VariableCase"
local AutoHolder = require "thlua.auto.AutoHolder"
local TypedFunction = require "thlua.type.func.TypedFunction"
local AutoTable = require "thlua.type.object.AutoTable"
local AutoFunction = require "thlua.type.func.AutoFunction"

local TermTuple = require "thlua.tuple.TermTuple"
local AutoFlag = require "thlua.auto.AutoFlag"
local AutoHolder = require "thlua.auto.AutoHolder"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"


	  
	  


local OperContext = class ()

function OperContext:ctor(
	vNode,
	vStack,
	vManager,
	...
)
	self._node=vNode
	self._manager=vManager
	self._stack = vStack
end

function OperContext:newException(vMsg)
	do return Exception.new(vMsg, self._node)
 end end

function OperContext:UTermTupleByAppend(vTermList, vTermTuple  )
	if TermTuple.is(vTermTuple) then
		for i=1, #vTermTuple do
			local nTerm = vTermTuple:rawget(i)
			vTermList[#vTermList + 1] = nTerm
		::continue:: end
		do return self:UTermTupleByTail(vTermList, vTermTuple:getTail())
	 end else
		if vTermTuple then
			vTermList[#vTermList + 1] = vTermTuple
		end
		do return self:UTermTupleByTail(vTermList, false)
	 end end
end

function OperContext:UTermTupleByTail(vTermList, vTail  )
	if AutoTail.is(vTail) then
		vTail = vTail:recurPutTermWithTail(vTermList)
	end
	if AutoTail.is(vTail) then
		do return TermTuple.new(self, true, vTermList, vTail or false, false)
	 end end
	local nHasAuto = false
	if not nHasAuto then
		for i=1, #vTermList do
			local nAuto = vTermList[i]
			if AutoHolder.is(nAuto) then
				local nTerm = nAuto:getRefineTerm()
				if not nTerm then
					nHasAuto = true
					break
				else
					vTermList[i] = nAuto
				end
			end
		::continue:: end
	end
	if nHasAuto then
		do return TermTuple.new(self, true, vTermList, vTail or false, false)
	 end else
		do return TermTuple.new(self, false, vTermList  , vTail or false, false)
	 end end
end

function OperContext:FixedTermTuple(vTermList, vDotsType , vTypeTuple)
	if vDotsType then
		local nTail = DotsTail.new(self, vDotsType)
		do return TermTuple.new(self, false, vTermList, nTail, vTypeTuple or false)
	 end else
		do return TermTuple.new(self, false, vTermList, false, vTypeTuple or false)
	 end end
end

function OperContext:RefineTerm(vType)
	do return RefineTerm.new(self._node, vType:checkAtomUnion())
 end end

function OperContext:NeverTerm()
	do return RefineTerm.new(self._node, self._manager.type.Never)
 end end

local function orReduceCase(vCaseList)
	if #vCaseList == 1 then
		do return vCaseList[1]
	 end end
	local nNewCase = VariableCase.new()
	local nFirstCase = vCaseList[1]
	for nImmutVariable, nLeftType in pairs(nFirstCase) do
		local nFinalType = nLeftType
		local nPass = false
		for i=2, #vCaseList do
			local nCurCase = vCaseList[i]
			local nCurType = nCurCase[nImmutVariable]
			if nCurType then
				nFinalType = nFinalType | nCurType
			else
				nPass = true
				break
			end
		::continue:: end
		if not nPass then
			nNewCase[nImmutVariable] = nFinalType
		end
	::continue:: end
	do return nNewCase
 end end

function OperContext:mergeToRefineTerm(vTypeCasePairList)
	local nKeyUnion, nTypeDict = self._manager:typeMapReduce(vTypeCasePairList, function(vList)
		do return orReduceCase(vList)
	 end end)
	do return RefineTerm.new(self._node, nKeyUnion, nTypeDict)
 end end

function OperContext:NilTerm()
	do return RefineTerm.new(self._node, self._manager.type.Nil)
 end end

function OperContext:error(...)
	self._stack:getRuntime():stackNodeError(self._stack, self._node, ...)
	 
end

function OperContext:warn(...)
	self._stack:getRuntime():nodeWarn(self._node, ...)
end

function OperContext:info(...)
	self._stack:getRuntime():nodeInfo(self._node, ...)
end

function OperContext:getNode()
	do return self._node
 end end

function OperContext:getRuntime()
	do return self._stack:getRuntime()
 end end

function OperContext:getTypeManager()
	do return self._manager
 end end

function OperContext:getStack()
	do return self._stack
 end end

do return OperContext
 end 
end end
--thlua.context.OperContext end ==========)

--thlua.context.RecurChain begin ==========(
do local _ENV = _ENV
packages['thlua.context.RecurChain'] = function (...)

local class = require "thlua.class"


	  


local RecurChain = class ()

function RecurChain:ctor()
	self._curPushChain = {}  
end

function RecurChain:testAndRun(vSelfType, vFunc) 
	local nChain = self._curPushChain
	for i=1, #nChain do
		if nChain[i] == vSelfType then
			do return false
		 end end
	::continue:: end
	nChain[#nChain + 1] = vSelfType
	local nRet = vFunc()
	nChain[#nChain] = nil
	do return true, nRet
 end end

do return RecurChain end 
end end
--thlua.context.RecurChain end ==========)

--thlua.context.ReturnContext begin ==========(
do local _ENV = _ENV
packages['thlua.context.ReturnContext'] = function (...)

local class = require "thlua.class"
local AssignContext = require "thlua.context.AssignContext"
local TypedFunction = require "thlua.type.func.TypedFunction"


	  


local ReturnContext = class (AssignContext)

function ReturnContext:ctor(...)
end

function ReturnContext:returnMatchTuples(
	vSrcTuple,
	vRetTuples
) 
	local nAutoFnCastDict = self:newAutoFnCastDict()
	local nOneMatchSucc = false
	local nOneCastSucc = false
	vRetTuples:foreachWithFirst(function(vDstTuple, _)
		local nMatchSucc, nCastSucc = self:tryMatchCast(nAutoFnCastDict, vSrcTuple, vDstTuple)
		if nMatchSucc then
			nOneMatchSucc = true
			if nCastSucc then
				nOneCastSucc = true
			end
		end
	end)
	if nOneMatchSucc then
		self:runLateCast(nAutoFnCastDict)
		do return true, nOneCastSucc
	 end else
		do return false
	 end end
end

function ReturnContext:tryMatchCast(
	vAutoFnCastDict,
	vSrcTuple,
	vDstTuple
) 
	local nCastResult = true
	for i=1, #vSrcTuple do
		local nDstType = vDstTuple:get(i):checkAtomUnion()
		local nSrcType = vSrcTuple:get(i):checkAtomUnion()
		local nIncludeType, nCastSucc = self:tryIncludeCast(vAutoFnCastDict, nDstType, nSrcType)
		if not nIncludeType then
			do return false
		 end else
			nCastResult = nCastResult and nCastSucc
		end
	::continue:: end
	for i=#vSrcTuple + 1, #vDstTuple do
		local nDstType = vDstTuple:get(i):checkAtomUnion()
		local nSrcType = vSrcTuple:get(i):checkAtomUnion()
		local nIncludeType, nCastSucc = self:tryIncludeCast(vAutoFnCastDict, nDstType, nSrcType)
		if not nIncludeType then
			do return false
		 end else
			nCastResult = nCastResult and nCastSucc
		end
	::continue:: end
	local nSrcRepeatType = vSrcTuple:getRepeatType()
	if nSrcRepeatType then
		local nDstRepeatType = vDstTuple:getRepeatType()
		if not nDstRepeatType then
			do return false
		 end elseif not nDstRepeatType:includeAll(nSrcRepeatType) then
			do return false
		 end end
	end
	do return true, nCastResult
 end end

do return ReturnContext
 end 
end end
--thlua.context.ReturnContext end ==========)

--thlua.global.basic begin ==========(
do local _ENV = _ENV
packages['thlua.global.basic'] = function (...)
do return [[

_ENV._G = _ENV

_ENV._VERSION = "" @ String

-- builtin
-- _ENV.assert = nil

function.pass _ENV.collectgarbage(
    opt:OrNil("collect", "stop", "restart", "count", "step", "isrunning", "incremental", "generational"),
    arg:OrNil(Integer)
)
end

function.pass _ENV.dofile()
end

-- builtin
-- _ENV.error = nil

-- builtin
-- _ENV.getmetatable = nil

-- builtin
-- _ENV.ipair = nil

-- builtin
-- _ENV.load = nil

-- builtin
-- _ENV.loadfile = nil

-- builtin
-- _ENV.next = nil

-- builtin
-- _ENV.pairs = nil

-- builtin
-- _ENV.pcall = nil

-- builtin
-- _ENV.pcall = nil


function.open _ENV.tonumber(v:Any, base)
    return 0.0@OrNil(Number)
end

function.pass _ENV.tostring(v:Any):Ret(String)
end

function.pass _ENV.print(...:Any)
end

function.pass _ENV.rawset(a:Any, b:Any,c:Any)
end

function.pass _ENV.rawget(a:Any, b:Any):Ret(Any)
end

]] end 
end end
--thlua.global.basic end ==========)

--thlua.global.coroutine begin ==========(
do local _ENV = _ENV
packages['thlua.global.coroutine'] = function (...)
do return [[

const coroutine = {}

function.pass coroutine.close(co:Thread)
end

function.pass coroutine.create(f:AnyFunction):Ret(Thread)
end

function.pass coroutine.isyieldable(co:OrNil(Thread)):Ret(Boolean)
end

function.pass coroutine.resume(co:Thread, ...:Any):Ret(True):Ret(False, String)
end

function.pass coroutine.running():Ret(Thread, Boolean)
end

function.pass coroutine.status(co:Thread):Ret(Union("running", "suspended", "normal", "dead"))
end

function.pass coroutine.wrap(f:AnyFunction):Ret(AnyFunction)
end

function.pass coroutine.yield():RetDots(Any)
end

_ENV.coroutine = coroutine

]] end 
end end
--thlua.global.coroutine end ==========)

--thlua.global.debug begin ==========(
do local _ENV = _ENV
packages['thlua.global.debug'] = function (...)
do return [[


const debug = {}

(@let.DebugInfo = Struct {
    namewhat=String,
    isvararg=Boolean,
    ntransfer=Integer,
    nups=Integer,
    currentline=Integer,
    func=AnyFunction,
    nparams=Integer,
    short_src=String,
    ftransfer=Integer,
    istailcall=Boolean,
    lastlinedefined=Integer,
    linedefined=Integer,
    source=String,
    what=String,
})

function.pass debug.debug()
end

function.pass debug.gethook(co:OrNil(Thread))
end


(@let.WhatOrNil = OrNil("n", "S", "l", "t", "u", "f", "r", "L"))
const function.pass _getinfo(f:Union(Integer, AnyFunction), what:WhatOrNil):Ret(DebugInfo) end
function.open debug.getinfo(coOrF, ...)
    if type(coOrF) == "thread" then
        return _getinfo(...)
    else
        return _getinfo(coOrF, ...)
    end
end

const function.pass _getlocal(f:Union(Integer, AnyFunction), local_:Integer):Ret(Nil):Ret(String, Any) end
function.open debug.getlocal(coOrF, ...)
    if type(coOrF) == "thread" then
        return _getlocal(...)
    else
        return _getlocal(coOrF, ...)
    end
end

function.pass debug.getmetatable(value:Any):Ret(Any)
end

function.pass debug.getregistry():Ret(Any)
end

function.pass debug.getupvalue(f:AnyFunction, up:Integer):Ret(String, Any)
end

function.pass debug.getuservalue(u:Any, n:OrNil(Integer)):Ret(Any, Boolean)
end

const function.pass _sethook(hook:AnyFunction, mask:String, count:OrNil(Integer)) end
function.open debug.sethook(coOrHook,...)
    if type(coOrF) == "thread" then
        return _sethook(...)
    else
        return _sethook(coOrF, ...)
    end
end

const function.pass _setlocal(level:Integer, local_:Integer, value:Any) end
function.open debug.setlocal(coOrLevel, ...)
    if type(coOrLevel) == "thread" then
        return _setlocal(...)
    else
        return _setlocal(coOrLevel, ...)
    end
end

function.pass debug.setmetatable(t:Any, v:OrNil(Any)):Ret(Any)
end

function.pass debug.setupvalue(f:AnyFunction, up:Integer, value:Any):Ret(String)
end

const function.pass _traceback(message:OrNil(String), level:OrNil(Integer)):Ret(String) end
function.open debug.traceback(coOrMsg, ...)
    if type(coOrMsg) == "thread" then
        return _traceback(...)
    else
        return _traceback(coOrMsg, ...)
    end
end

function.open debug.upvalueid(f:AnyFunction, n:Integer)
    (@print("debug.upvalueid TODO"))
end

function.open debug.upvaluejoin(f1:AnyFunction, n1:Integer, f2:AnyFunction, n2:Integer)
    (@print("debug.upvaluejoin TODO"))
end

_ENV.debug = debug

]]
 end 
end end
--thlua.global.debug end ==========)

--thlua.global.io begin ==========(
do local _ENV = _ENV
packages['thlua.global.io'] = function (...)
do return [[

(@let.ReadMode = Union(
    Integer, "n", "a", "l", "L"
))

const file = {}

const function:class(let.File) newFile()
    return setmetatable({.class}, {
        __index=file
    })
end

function.pass file:close()
end

function.pass file:flush()
end

function.pass file:lines(...:ReadMode):Ret(Fn():Ret(OrNil(String)))
end

function.pass file:read(...:ReadMode):Ret(OrNil(String))
end

function.pass file:seek(whence:OrNil("set", "cur", "end"), offset:OrNil(Integer)):Ret(Integer, OrNil(String))
end

function.pass file:setvbuf(mode:Union("no", "full", "line"), size:OrNil(Integer))
end

function.pass file:write(...:Union(String,Number)):Ret(File):Ret(Nil, String)
end

const io = {}

function.pass io.close(file:OrNil(File))
end

function.pass io.flush()
end

function.pass io.input(file:OrNil(String, File)):Ret(File)
end

function.pass io.lines(filename:OrNil(String), ...:ReadMode):Ret(Fn():Ret(OrNil(String)), Nil, Nil, OrNil(File))
end

(@let.OpenMode = Union(
    "r", "w", "a",
    "r+", "w+", "a+",
    "rb", "wb", "ab",
    "r+b", "w+b", "a+b"
))
function.pass io.open(filename:String, mode:OpenMode):Ret(File):Ret(Nil, String)
end

function.pass io.output(file:OrNil(String, File)):Ret(File)
end

function.pass io.popen(prog:String, mode:OrNil("r", "w")):Ret(File):Ret(Nil, String)
end

function.pass io.read(...:ReadMode):Ret(OrNil(String))
end

function.pass io.tmpfile():Ret(File)
end

function.open io.type(file):mapguard({file=File, ["closed file"]=File})
end

function.pass io.write(...:Union(String, Number)):Ret(File):Ret(Nil, String)
end

_ENV.io = io

]] end 
end end
--thlua.global.io end ==========)

--thlua.global.math begin ==========(
do local _ENV = _ENV
packages['thlua.global.math'] = function (...)
do return [[

const math = {}

function.pass math.abs(x:Number):Ret(Number)
end

function.pass math.acos(x:Number):Ret(Number)
end

function.pass math.asin(x:Number):Ret(Number)
end

function.pass math.atan(y:Number, x:OrNil(Number)):Ret(Number)
end

function.pass math.ceil(x:Number):Ret(Integer)
end

function.pass math.cos(x:Number):Ret(Number)
end

function.pass math.deg(x:Number):Ret(Number)
end

function.pass math.exp(x:Number):Ret(Number)
end

function.pass math.floor(x:Number):Ret(Integer)
end

function.pass math.fmod(x:Number, y:Number):Ret(Number)
end

math.huge = nil @! Literal(1.0/0.0)

function.pass math.log(x:Number, base:OrNil(Number)):Ret(Number)
    base = base or math.exp(1)
end

function.pass math.max(x:Number, ...:Number):Ret(Number)
end

math.maxinteger = nil@! Literal(9223372036854775807)

function.pass math.min(x:Number, ...:Number):Ret(Number)
end

math.mininteger = nil@! Literal(-9223372036854775808)

function.pass math.modf(x:Number):Ret(Integer, Number)
end

math.pi = 3.14159265358979323846

function.pass math.rad(x:Number):Ret(Number)
end

function.pass math.random(m:OrNil(Integer), n:OrNil(Integer)):Ret(Number)
end

function.pass math.randomseed(x:OrNil(Integer), y:OrNil(Integer))
end

function.pass math.sin(x:Number):Ret(Number)
end

function.pass math.sqrt(x:Number):Ret(Number)
end

function.pass math.tan(x:Number):Ret(Number)
end

function.pass math.tointeger(x:Any):Ret(OrNil(Integer))
end

function.open math.type(x):mapguard({float=Number, integer=Integer})
end

function.pass math.ult(m:Integer, n:Integer):Ret(Boolean)
end

_ENV.math = math

]] end 
end end
--thlua.global.math end ==========)

--thlua.global.os begin ==========(
do local _ENV = _ENV
packages['thlua.global.os'] = function (...)
do return [[

const os = {}

function.pass os.clock():Ret(Number)
end

function.pass os.exit(code:OrNil(Boolean, Integer), close:OrNil(True)):Ret(Number)
end

_ENV.os = os

]] end 
end end
--thlua.global.os end ==========)

--thlua.global.package begin ==========(
do local _ENV = _ENV
packages['thlua.global.package'] = function (...)
do return [[

const package = {}

function.pass package.searchpath(name:String, path:String, sep:OrNil(String), rep:OrNil(String)):Ret(Nil, String):Ret(String)
end

package.config = ""@String

_ENV.package = package

]]
 end 
end end
--thlua.global.package end ==========)

--thlua.global.string begin ==========(
do local _ENV = _ENV
packages['thlua.global.string'] = function (...)
do return [[

const string = {}

-- Returns the internal numeric codes of the characters s[i], s[i+1], ..., s[j].
function.pass string.byte(s:String, i:OrNil(Integer), j:OrNil(Integer)):RetDots(Integer)
end

-- Receives zero or more integers. Returns a string with length equal to the number of arguments
function.pass string.char(...:Integer):RetDots(String)
    -- TODO, maybe use open function ?
end

-- Returns a string containing a binary representation (a binary chunk) of the given function.
function.pass string.dump(fn:AnyFunction, strip:OrNil(Boolean)):Ret(String)
end

-- Looks for the first match of pattern in the string s.
function.pass string.find(s:String, pattern:String, init:OrNil(Integer), plain:OrNil(Boolean)):RetDots(Integer, Integer, String):Ret(Nil)
end

-- Returns a formatted version of its variable number of arguments following the description given in its first argument, which must be a string. The format string follows the same rules as the ISO C function sprintf. The only differences are that the conversion specifiers and modifiers F, n, *, h, L, and l are not supported and that there is an extra specifier, q. Both width and precision, when present, are limited to two digits.
function.pass string.format(s:String, ...:Any):Ret(String)
    -- TODO, use open function to check formatstring matching
end

-- Returns an iterator function that, each time it is called, returns the next captures from pattern over the string s.
function.pass string.gmatch(s:String, pattern:String, init:OrNil(Integer)):Ret(Fn():RetDots(String))
end

-- Returns a copy of s in which all (or the first n, if given) occurrences of the pattern have been replaced by a replacement string specified by repl,
function.pass string.gsub(
    s:String,
    pattern:String,
    repl:Union(String, Fn(String):Dots(String):Ret(String), Dict(String, String)),
    n:OrNil(Integer)
):Ret(String, Integer)
end

-- Receives a string and returns its length.
function.pass string.len(s:String):Ret(Integer)
end

-- Receives a string and returns a copy of this string with all uppercase letters changed to lowercase.
function.pass string.lower(s:String):Ret(String)
end

-- Looks for the first match of the pattern in the string s.
function.pass string.match(s:String, pattern:String, init:OrNil(Integer)):RetDots(String)
end

-- Returns a binary string containing the values v1, v2.
function.pass string.pack(fmt:String, ...:Union(String, Number)):Ret(String)
    -- TODO use open function?
end

-- Returns the size of a string resulting from string.pack with the given format.
function.pass string.packsize(fmt:String):Ret(Integer)
end

-- Returns a string that is the concatenation of n copies of the string s separated by the string sep.
function.pass string.rep(s:String, n:Integer, sep:OrNil(String)):Ret(String)
end

-- Returns a string that is the string s reversed.
function.pass string.reverse(s:String):Ret(String)
end

-- Returns the substring of s that starts at i and continues until j; i and j can be negative.
function.pass string.sub(s:String, i:Integer, j:OrNil(Integer)):Ret(String)
end

-- Returns the values packed in string s (see string.pack) according to the format string fmt.
function.pass string.unpack(fmt:String, s:Integer, pos:OrNil(Integer)):RetDots(Union(String, Number))
    -- TODO use open function?
end

-- Receives a string and returns a copy of this string with all lowercase letters changed to uppercase.
function.pass string.upper(s:String):Ret(String)
end

_ENV.string = string

return string

]] end 
end end
--thlua.global.string end ==========)

--thlua.global.table begin ==========(
do local _ENV = _ENV
packages['thlua.global.table'] = function (...)
do return [[

const table = {}

function.open table.concat(list, sep:OrNil(String), i:OrNil(Integer), j:OrNil(Integer))
    const element:OrNil(String, Integer) = list[1@Integer]
    return "" @ String
end

function.open table.insert(list, ...)
    (@let.ElementTypeNilable = $(list[1@Integer]))
    const len = select("#", ...)
    if len == 1 then
        const value:ElementTypeNilable = ...
    elseif len == 2 then
        const pos:OrNil(Integer), value:ElementTypeNilable = ...
    else
        -- TODO
        (@print("table insert must table 2 or 3 arguments, TODO, mus print error in out stack"))
    end
end

function.open table.move(a1, f, e, t, a2)
    -- TODO
end

function.open table.pack(...)
    return {n=1@Integer, ...}
end

function.open table.remove(list, pos:OrNil(Integer))
    return list[1@Integer]
end

function.open table.sort(list, comp)
    const element = list[1@Integer]!
    if comp == nil then
        -- TODO check with function in hint space
        const element:Union(String, Number) = element
    else
        const comp:Fn($element, $element):Ret(Boolean) = comp
    end
end

function.open table.unpack(list, i:OrNil(Integer), j:OrNil(Integer))
    -- TODO
end

_ENV.table = table

]] end 
end end
--thlua.global.table end ==========)

--thlua.global.utf8 begin ==========(
do local _ENV = _ENV
packages['thlua.global.utf8'] = function (...)
do return [[

const utf8 = {}

_ENV.utf8 = utf8

]] end 
end end
--thlua.global.utf8 end ==========)

--thlua.manager.DirtyProcessor begin ==========(
do local _ENV = _ENV
packages['thlua.manager.DirtyProcessor'] = function (...)

local Exception = require "thlua.Exception"
local Reference = require "thlua.refer.Reference"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local BaseUnionType = require "thlua.type.union.BaseUnionType"

local DirtyProcessor = {}

DirtyProcessor.__index = DirtyProcessor


	  


function DirtyProcessor.new(vTypeManager)
    local self = setmetatable({
        _manager = vTypeManager,
		_runtime = vTypeManager:getRuntime()
    }, DirtyProcessor)
    do return self
 end end

function DirtyProcessor:makeDirtyException(vNode, vMsg)
	do return Exception.new(vMsg, vNode)
 end end

function DirtyProcessor:easyToType(vNode, vData)
	local nOkay, nType = self:peasyToType(vData)
	if nOkay then
		do return nType
	 end else
		error(self:makeDirtyException(vNode, nType))
	end
end

function DirtyProcessor:easyToTypeList(vNode, ...)
	local l = {...}
	for i=1,#l do
		l[i] = self:easyToType(vNode, l[i])
	::continue:: end
	do return l  
 end end

function DirtyProcessor:peasyToType(vData)  
	local t = type(vData)
	if t == "table" then
		if Reference.is(vData) or BaseAtomType.is(vData) or BaseUnionType.is(vData) then
			do return true, vData
		 end else
			do return false, "to type failed"
		 end end
	elseif t == "number" or t == "string" or t == "boolean"then
		do return true, self._manager:Literal(vData    )
	 end else
		do return false, "easyToType("..t..") invalid"
	 end end
end

function DirtyProcessor:checkObjectMetaCom(vNode, vData)
end

do return DirtyProcessor end 
end end
--thlua.manager.DirtyProcessor end ==========)

--thlua.manager.ListDict begin ==========(
do local _ENV = _ENV
packages['thlua.manager.ListDict'] = function (...)


	  


do return function  ()
    local t = {
        _keyToList={}  ,
    }
    function t:putOne(k, v)
        local nList = self._keyToList[k]
        if not nList then
            self._keyToList[k] = {v}
        else
            nList[#nList + 1] = v
        end
    end
    function t:putAll(v)
        local nSelfKeyToList = self._keyToList
        v:forKList(function(vKey, vList)
            local nList = nSelfKeyToList[vKey]
            if not nList then
                nSelfKeyToList[vKey] = {table.unpack(vList)}
            else
                for i,v in ipairs(vList) do
                    nList[#nList + 1] = v
                ::continue:: end
            end
        end)
    end
    function t:get(k)
        do return self._keyToList[k]
     end end
    function t:pop(k)
        local nList = self._keyToList[k]
        self._keyToList[k] = nil
        do return nList
     end end
    function t:forKV(vFunc )
        for k,vList in pairs(self._keyToList) do
            for _, v in ipairs(vList) do
                vFunc(k,v)
            ::continue:: end
        ::continue:: end
    end
    function t:forKList(vFunc )
        for k,vList in pairs(self._keyToList) do
            vFunc(k,vList)
        ::continue:: end
    end
    do return t
 end end
 end 
end end
--thlua.manager.ListDict end ==========)

--thlua.manager.ScheduleEvent begin ==========(
do local _ENV = _ENV
packages['thlua.manager.ScheduleEvent'] = function (...)

local ScheduleEvent = {}
ScheduleEvent.__index = ScheduleEvent

  

function ScheduleEvent.new(vManager, vThread)
	do return setmetatable({
		_scheduleManager=vManager,
		_selfCo=vThread,
		_coToSid={} ,
	}, ScheduleEvent)
 end end

function ScheduleEvent:wait()
	local nCoToSid = self._coToSid
	if nCoToSid then
		local nManager = self._scheduleManager
		local nSessionId = nManager:genSessionId()
		local nCurCo = coroutine.running()
		nCoToSid[nCurCo] = nSessionId
		nManager:coWait(nCurCo, nSessionId, self._selfCo)
	end
end

function ScheduleEvent:wakeup()
	local nCoToSid = self._coToSid
	if nCoToSid then
		self._coToSid = false
		local nManager = self._scheduleManager
		for co, sid in pairs(nCoToSid) do
			nManager:coWakeup(co, sid)
		::continue:: end
	end
end

function ScheduleEvent:isWaken()
	do return not self._coToSid
 end end

do return ScheduleEvent
 end 
end end
--thlua.manager.ScheduleEvent end ==========)

--thlua.manager.ScheduleManager begin ==========(
do local _ENV = _ENV
packages['thlua.manager.ScheduleManager'] = function (...)

local ScheduleEvent = require "thlua.manager.ScheduleEvent"
local Exception = require "thlua.Exception"
local class = require "thlua.class"

local ScheduleTask = require "thlua.manager.ScheduleTask"


	  
	   
		  
		  
	


local ScheduleManager = class ()

function ScheduleManager:ctor()
	self._coToTask={}   
	self._coToScheduleParam={}  
	self._coToWaitingInfo={} 
	self._sessionIdCounter=0
	self._selfCo=coroutine.running()
end

function ScheduleManager:newTask(vStack)
	local nTask = ScheduleTask.new(self, vStack)
	self._coToTask[nTask:getSelfCo()] = nTask
	do return nTask
 end end

function ScheduleManager:coWait(vWaitCo, vWaitSid, vDependCo)
	assert(vWaitCo == coroutine.running(), "wait co must be current co")
	if vDependCo then
		local nWaitingTask = self._coToTask[vWaitCo]
		if not nWaitingTask then
			local nDependTask = self._coToTask[vDependCo]
			error("can only call coWait in a task, try to get:"..tostring(nDependTask))
		else
			local nDependTask = self._coToTask[vDependCo]
			if nDependTask then
				if not nWaitingTask:canWaitType() and not nDependTask:getStack() then
					error("type not setted"..tostring(nDependTask))
				end
			end
		end
		local nCurCo = vDependCo
		while nCurCo do
			if nCurCo == vWaitCo then
				break
			else
				local nNextWaitingInfo = self._coToWaitingInfo[nCurCo]
				if nNextWaitingInfo then
					nCurCo = nNextWaitingInfo.dependCo
				else
					nCurCo = nil
					break
				end
			end
		::continue:: end
		if nCurCo then
			   
			error("recursive build type:"..tostring(self._coToTask[nCurCo]))
		end
	else
		vDependCo = self._selfCo
	end
	self._coToWaitingInfo[vWaitCo] = {
		waitSid = vWaitSid,
		dependCo = vDependCo,
	}
	coroutine.yield()
end

function ScheduleManager:coWakeup(vWaitCo, vWaitSid)
	local nWaitingInfo = self._coToWaitingInfo[vWaitCo]
	if not nWaitingInfo then
		   
		print("session is cancel when wakeup")
		do return
	 end elseif vWaitSid ~= nWaitingInfo.waitSid then
		print("wait sid not match when wakeup")
		do return
	 end end
	self._coToWaitingInfo[vWaitCo] = nil
	self._coToScheduleParam[vWaitCo] = true
	local nTask = self._coToTask[coroutine.running()]
	if not nTask or nTask:getStack() then
		self:_schedule()
	end
end

function ScheduleManager:coStart(vCo, vFunc)
	self._coToScheduleParam[vCo] = vFunc
	local nTask = self._coToTask[coroutine.running()]
	if not nTask or nTask:getStack() then
		self:_schedule()
	end
end

function ScheduleManager:_schedule()
	while true do
		local nCoToParam = self._coToScheduleParam
		if not next(nCoToParam) then
			break
		else
			self._coToScheduleParam = {}  
			for co, param in pairs(nCoToParam) do
				assert(coroutine.resume(co, param))
			::continue:: end
		end
	::continue:: end
end

function ScheduleManager:genSessionId()
	local nNewId = self._sessionIdCounter + 1
	self._sessionIdCounter = nNewId
	do return nNewId
 end end

function ScheduleManager:makeEvent(vThread)
	do return ScheduleEvent.new(self, vThread)
 end end

do return ScheduleManager
 end 
end end
--thlua.manager.ScheduleManager end ==========)

--thlua.manager.ScheduleTask begin ==========(
do local _ENV = _ENV
packages['thlua.manager.ScheduleTask'] = function (...)

local Exception = require "thlua.Exception"

local ScheduleEvent = require "thlua.manager.ScheduleEvent"
local class = require "thlua.class"


	  


local ScheduleTask = class ()

     
function ScheduleTask:ctor(vScheduleManager, vStack)
	self._scheduleManager = vScheduleManager
	self._selfCo = coroutine.create(function(vRunFn)
		local ok, nExc = pcall(vRunFn)
		if not ok then
			local nStack = self:getStack()
			if nStack then
				if Exception.is(nExc) then
					nStack:getRuntime():nodeError(nExc.node, nExc.msg)
				else
					nStack:getRuntime():nodeError(nStack:getNode(), tostring(nExc))
				end
			end
			if not nStack or nStack:isRoot() then
				error(nExc)
			end
		end
	end)
	self._stack = vStack or false
end

function ScheduleTask:getSelfCo()
	do return self._selfCo
 end end

function ScheduleTask:canWaitType()
	do return not self._stack
 end end

function ScheduleTask:runAsync(vFunc)
	self._scheduleManager:coStart(self._selfCo, vFunc)
end

function ScheduleTask:getStack()
	do return self._stack
 end end

function ScheduleTask:makeEvent()
	do return self._scheduleManager:makeEvent(self._selfCo)
 end end

function ScheduleTask:makeWildEvent()
	do return self._scheduleManager:makeEvent()
 end end

do return ScheduleTask
 end 
end end
--thlua.manager.ScheduleTask end ==========)

--thlua.manager.TypeCollection begin ==========(
do local _ENV = _ENV
packages['thlua.manager.TypeCollection'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"

local StringLiteralUnion = require "thlua.type.union.StringLiteralUnion"
local MixingNumberUnion = require "thlua.type.union.MixingNumberUnion"
local IntegerLiteralUnion = require "thlua.type.union.IntegerLiteralUnion"
local FloatLiteral = require "thlua.type.basic.FloatLiteral"
local ObjectUnion = require "thlua.type.union.ObjectUnion"
local FuncUnion = require "thlua.type.union.FuncUnion"
local ComplexUnion = require "thlua.type.union.ComplexUnion"
local FalsableUnion = require "thlua.type.union.FalsableUnion"


	  


local FastBitsSet = {
	[TYPE_BITS.NIL]=true,
	[TYPE_BITS.FALSE]=true,
	[TYPE_BITS.TRUE]=true,
	[TYPE_BITS.THREAD]=true,
	[TYPE_BITS.LIGHTUSERDATA]=true,
	[TYPE_BITS.TRUTH]=true,
}

local TrueBitSet = {
	[TYPE_BITS.TRUE]=true,
	[TYPE_BITS.OBJECT]=true,
	[TYPE_BITS.FUNCTION]=true,
	[TYPE_BITS.NUMBER]=true,
	[TYPE_BITS.STRING]=true,
	[TYPE_BITS.THREAD]=true,
	[TYPE_BITS.LIGHTUSERDATA]=true,
}

local TypeCollection = {}
TypeCollection.__index=TypeCollection

function TypeCollection.new(vManager)
	local self = setmetatable({
		_manager=vManager,
		_type=vManager.type,
		_bitsToSet={}   ,
		_metaSet={}   ,
		_bits=0  ,
 		_count=0  ,
	}, TypeCollection)
	do return self
 end end


function TypeCollection:put(vType)
	local nType = vType:checkAtomUnion()
	local nBitsToSet = self._bitsToSet
	local nMetaSet = self._metaSet
	local nCurBits = self._bits
	local nCurCount = self._count
	nType:foreach(function(vAtomType)
		nCurBits = nCurBits | vAtomType.bits
		     
		local nAtomBits = vAtomType.bits
		local nSet = nBitsToSet[nAtomBits]
		if not nSet then
			nSet = {}
			nBitsToSet[nAtomBits] = nSet
		end
		if not nSet[vAtomType] then
			nSet[vAtomType] = true
			nCurCount = nCurCount + 1
		end
		     
		local nMeta = getmetatable(vAtomType)
		nMetaSet[nMeta] = true
	end)
	self._bits = nCurBits
	self._count = nCurCount
end

function TypeCollection:_makeSimpleTrueType(vBit, vSet )
	local nUnionType = nil
	if vBit == TYPE_BITS.TRUE then
		do return self._type.True
	 end elseif vBit == TYPE_BITS.NUMBER then
		local nNumberType = self._type.Number
		if vSet[nNumberType] then
			do return nNumberType
		 end end
		local nHasFloatLiteral = self._metaSet[FloatLiteral.meta]
		local nIntegerType = self._type.Integer
		if vSet[nIntegerType] and not nHasFloatLiteral then
			do return nIntegerType
		 end end
		if nHasFloatLiteral then
			nUnionType = MixingNumberUnion.new(self._manager)
		else
			nUnionType = IntegerLiteralUnion.new(self._manager)
		end
	elseif vBit == TYPE_BITS.STRING then
		local nStringType = self._type.String
		if vSet[nStringType] then
			do return nStringType
		 end end
		nUnionType = StringLiteralUnion.new(self._manager)
	elseif vBit == TYPE_BITS.OBJECT then
		nUnionType = ObjectUnion.new(self._manager)
	elseif vBit == TYPE_BITS.FUNCTION then
		nUnionType = FuncUnion.new(self._manager)
	elseif vBit == TYPE_BITS.THREAD then
		do return self._type.Thread
	 end elseif vBit == TYPE_BITS.LIGHTUSERDATA then
		do return self._type.LightUserdata
	 end else
		error("bit can't be="..tostring(vBit))
	end
	for nType, _ in pairs(vSet) do
		nUnionType:putAwait(nType)
	::continue:: end
	do return self._manager:_unifyUnion(nUnionType)
 end end

function TypeCollection:mergeToAtomUnion()
	local nBits = self._bits
	   
	if nBits == 0 then
		    
		do return self._type.Never
	 end else
		              
		if self._count == 1 or FastBitsSet[nBits] then
			local nOneType = (next(self._bitsToSet[nBits]))
			do return (assert(nOneType, "logic error when type merge"))
		 end end
	end
	local nTruableBits = nBits & (~ (TYPE_BITS.NIL | TYPE_BITS.FALSE))
	local nFalsableBits = nBits & (TYPE_BITS.NIL | TYPE_BITS.FALSE)
	    
	local nTrueBitToType  = {}
	for nBit, nSet in pairs(self._bitsToSet) do
		if TrueBitSet[nBit] then
			nTrueBitToType[nBit] = self:_makeSimpleTrueType(nBit, nSet)
		end
	::continue:: end
	local nTrueType = self._type.Never
	if TrueBitSet[nTruableBits] then
		        
		nTrueType = nTrueBitToType[nTruableBits]
	elseif nTruableBits == TYPE_BITS.TRUTH then
		   
		nTrueType = self._type.Truth
	elseif next(nTrueBitToType) then
		                  
		local nComplexUnion = ComplexUnion.new(self._manager, nTruableBits, nTrueBitToType)
		nTrueType = self._manager:_unifyUnion(nComplexUnion)
	end
	    
	if nFalsableBits == 0 then
		do return nTrueType
	 end else
		local nUnionType = FalsableUnion.new(self._manager, nTrueType, nFalsableBits)
		do return self._manager:_unifyUnion(nUnionType)
	 end end
end

function TypeCollection.is(vData)
	do return getmetatable(vData) == TypeCollection
 end end

do return TypeCollection
 end 
end end
--thlua.manager.TypeCollection end ==========)

--thlua.manager.TypeManager begin ==========(
do local _ENV = _ENV
packages['thlua.manager.TypeManager'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local TypeCollection = require "thlua.manager.TypeCollection"
local Node = require "thlua.code.Node"
local Exception = require "thlua.Exception"

local Never = require "thlua.type.union.Never"
local StringLiteral = require "thlua.type.basic.StringLiteral"
local String = require "thlua.type.basic.String"
local FloatLiteral = require "thlua.type.basic.FloatLiteral"
local Number = require "thlua.type.basic.Number"
local IntegerLiteral = require "thlua.type.basic.IntegerLiteral"
local Integer = require "thlua.type.basic.Integer"
local BooleanLiteral= require "thlua.type.basic.BooleanLiteral"
local Nil = require "thlua.type.basic.Nil"
local Thread = require "thlua.type.basic.Thread"
local Enum = require "thlua.type.basic.Enum"
local LightUserdata = require "thlua.type.basic.LightUserdata"
local Truth = require "thlua.type.basic.Truth"
local TypedObject = require "thlua.type.object.TypedObject"
local Struct = require "thlua.type.object.Struct"
local Interface = require "thlua.type.object.Interface"
local OpenTable = require "thlua.type.object.OpenTable"
local AutoTable = require "thlua.type.object.AutoTable"
local SealTable = require "thlua.type.object.SealTable"
local OpenFunction = require "thlua.type.func.OpenFunction"
local TypedFunction = require "thlua.type.func.TypedFunction"
local TypedPolyFunction = require "thlua.type.func.TypedPolyFunction"
local SealPolyFunction = require "thlua.type.func.SealPolyFunction"
local AnyFunction = require "thlua.type.func.AnyFunction"
local Reference = require "thlua.refer.Reference"

local MemberFunction = require "thlua.type.func.MemberFunction"
local AutoMemberFunction = require "thlua.type.func.AutoMemberFunction"
local TypedMemberFunction = require "thlua.type.func.TypedMemberFunction"

local StringLiteralUnion = require "thlua.type.union.StringLiteralUnion"
local MixingNumberUnion = require "thlua.type.union.MixingNumberUnion"
local ObjectUnion = require "thlua.type.union.ObjectUnion"
local FuncUnion = require "thlua.type.union.FuncUnion"
local FalsableUnion = require "thlua.type.union.FalsableUnion"
local ComplexUnion = require "thlua.type.union.ComplexUnion"

local RetTuples = require "thlua.tuple.RetTuples"
local TypeTuple = require "thlua.tuple.TypeTuple"
local TypeTupleDots = require "thlua.tuple.TypeTupleDots"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local ScheduleEvent = require "thlua.manager.ScheduleEvent"
local DirtyProcessor = require "thlua.manager.DirtyProcessor"

local BaseReadyType = require "thlua.type.basic.BaseReadyType"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local BaseUnionType = require "thlua.type.union.BaseUnionType"
local MetaEventCom = require "thlua.type.object.MetaEventCom"
local native = require "thlua.native"

local AsyncUnion = require "thlua.refer.AsyncUnion"

local TypeRelation = require "thlua.manager.TypeRelation"


	  
	   
		  
		  
	


local TypeManager = {}
TypeManager.__index=TypeManager

local function makeBuiltinFunc(vManager)
	local self = {
		string=nil,
		next=native.make_next(vManager),
		inext=native.make_inext(vManager),
		bop={
			mathematic_notdiv=native.make_mathematic(vManager),
			mathematic_divide=native.make_mathematic(vManager, true),
			comparison=native.make_comparison(vManager),
			bitwise=native.make_bitwise(vManager),
			concat=native.make_concat(vManager),
		},
	}
	do return self
 end end

function TypeManager.new(
	vRuntime,
	vRootNode,
	vScheduleManager
)
	local function makeBuiltinType(vManager)
		local self = {
			Never = vManager:_unifyUnion(Never.new(vManager)),
			Nil = Nil.new(vManager),
			False = BooleanLiteral.new(vManager, false),
			True = BooleanLiteral.new(vManager, true),
			Thread = Thread.new(vManager),
			Number = Number.new(vManager),
			Integer = Integer.new(vManager),
			String = String.new(vManager),
			Truth = Truth.new(vManager),
			LightUserdata = LightUserdata.new(vManager),
			AnyFunction = AnyFunction.new(vManager, vRootNode),
			Boolean = nil  ,
			Any = nil  ,
			AnyObject = nil  ,
		}
		do return self
	 end end
	local self = setmetatable({
		_runtime=vRuntime,
		  
		type=nil  ,
		builtin=nil  ,
		generic={}   ,
		_pairToRelation={}   ,
		_floatLiteralDict = {} ,
		_integerLiteralDict = {} ,
		_sbLiteralDict={}  ,
		_unionSignToType=(setmetatable({}, {__mode="v"}) )  ,
		_typeIdCounter=0,
		_rootNode=vRootNode,
		_scheduleManager=vScheduleManager,
		_dirtyProcessor=nil,
	}, TypeManager)
	self._dirtyProcessor = DirtyProcessor.new(self)
	self.type = makeBuiltinType(self)
	self.type.Boolean = self:buildUnion(vRootNode, self.type.False, self.type.True)
	self.type.Any = self:buildUnion(vRootNode, self.type.False, self.type.Nil, self.type.Truth)
	self.type.AnyObject = self:buildInterface(vRootNode, {})
	self.generic.Dict = self:buildTemplate(vRootNode, function(vKey,vValue)
		assert(vKey and vValue, "key or value can't be nil when build Dict")
		do return self:buildStruct(vRootNode, {[vKey]=vValue}, {__Next=vKey})
	 end end)
	self.generic.Cond = self:buildTemplate(vRootNode, function(vCond,v1,v2)
		local nType = vCond
		if Reference.is(vCond) then
			nType = vCond:checkAtomUnion()
		end
		if nType:isUnion() then
			error("Cond's first value can't be union")
		end
		do return (nType == self.type.Nil or nType == self.type.False) and v2 or v1
	 end end)
	self.generic.IDict = self:buildTemplate(vRootNode, function(vKey,vValue)
		assert(vKey and vValue, "key or value can't be nil when build IDict")
		do return self:buildInterface(vRootNode, {[vKey]=vValue}, {__Next=vKey})
	 end end)
	self.generic.List = self:buildTemplate(vRootNode, function(vValue)
		assert(vValue, "value can't be nil when build List")
		do return self:buildStruct(vRootNode, {[self.type.Integer]=vValue}, {__Next=self.type.Integer, __len=self.type.Integer})
	 end end)
	self.generic.IList = self:buildTemplate(vRootNode, function(vValue)
		assert(vValue, "value can't be nil when build IList")
		do return self:buildInterface(vRootNode, {[self.type.Integer]=vValue}, {__len=self.type.Integer})
	 end end)
	self.generic.KeyOf = self:buildTemplate(vRootNode, function(vOneType)
		local nObject = vOneType
		if Reference.is(vOneType) then
			nObject = vOneType:checkAtomUnion()
		end
		if not TypedObject.is(nObject) then
			error("key of can only worked on object function")
		end
		local nKeyRefer, _ = nObject:getKeyTypes()
		local nRefer = self:Reference(false)
		nRefer:setUnionAsync(nObject:getNode(), function()
			do return nKeyRefer:getListAwait(), function()
				nKeyRefer:getTypeAwait()
			end
		 end end)
		do return nRefer
	 end end)
	do return self
 end end

function TypeManager:lateInit()
	self.builtin = makeBuiltinFunc(self)
end

function TypeManager:lateInitStringLib(vStringLib)
	self.builtin.string = vStringLib
end

function TypeManager:isLiteral(vType)
	if StringLiteral.is(vType) or FloatLiteral.is(vType) or IntegerLiteral.is(vType) or BooleanLiteral.is(vType) then
		do return true
	 end else
		do return false
	 end end
end

function TypeManager:_checkAllType(vData)
	if Reference.is(vData) or BaseAtomType.is(vData) or BaseUnionType.is(vData) then
		do return vData
	 end end
	do return false
 end end

function TypeManager:TypeCollection()
	do return TypeCollection.new(self)
 end end

function TypeManager:AsyncUnion(vTask)
	do return AsyncUnion.new(self, vTask)
 end end

function TypeManager:_buildCombineObject(vNode, vIsInterface, vObjectList)
	local nNewObject = vIsInterface and Interface.new(self, vNode) or Struct.new(self, vNode)
	nNewObject:buildAsync(function(vAsyncKey)
		if vIsInterface then
			assert(#vObjectList>=1, "Intersect must take at least one arguments")
		else
			assert(#vObjectList >= 2, "StructExtend must take at least one interface after struct")
		end
		local nKeyList = {}
		local nKeyValuePairList   = {}
		local nIntersectSet  = {}
		local nMetaEventComList = {}
		local nIntersectNextKey = self.type.Any
		for i=1,#vObjectList do
			local nTypedObject = vObjectList[i]
			if Reference.is(nTypedObject) then
				nTypedObject = nTypedObject:checkAtomUnion()
			end
			if not TypedObject.is(nTypedObject) then
				error("Interface or Struct is expected here")
				break
			end
			if i == 1 then
				if vIsInterface then
					assert(Interface.is(nTypedObject), "Intersect must take Interface")
					nIntersectSet[nTypedObject] = true
				else
					assert(not Interface.is(nTypedObject), "StructExtend must take Struct as first argument")
				end
			else
				assert(Interface.is(nTypedObject), vIsInterface
					and "Intersect must take Interface as args"
					or "StructExtend must take Interface after first argument")
				nIntersectSet[nTypedObject] = true
			end
			local nValueDict = nTypedObject:getValueDict()
			local nKeyRefer, nNextKey = nTypedObject:getKeyTypes()
			for _, nKeyType in ipairs(nKeyRefer:getListAwait()) do
				nKeyList[#nKeyList + 1] = nKeyType
				nKeyValuePairList[#nKeyValuePairList + 1] = {nKeyType, nValueDict[nKeyType]}
			::continue:: end
			nMetaEventComList[#nMetaEventComList + 1] = nTypedObject:getMetaEventCom() or nil
			if nIntersectNextKey then
				if nNextKey then
					local nTypeOrFalse = nIntersectNextKey:safeIntersect(nNextKey)
					if not nTypeOrFalse then
						error("intersect error")
					else
						nIntersectNextKey = nTypeOrFalse
					end
				else
					nIntersectNextKey = false
				end
			end
		::continue:: end
		local _, nFinalValueDict = self:typeMapReduce(nKeyValuePairList, function(vList)
			do return self:intersectReduceType(vNode, vList)
		 end end)
		local nKeyAtomUnion = vAsyncKey:setAtomList(nKeyList)
		if #nMetaEventComList > 0 then
			local nNewEventCom = self:makeMetaEventCom(nNewObject)
			nNewEventCom:initByMerge(nMetaEventComList)
			nNewObject:lateInit(nIntersectSet, nFinalValueDict, nIntersectNextKey, nNewEventCom)
		else
			nNewObject:lateInit(nIntersectSet, nFinalValueDict, nIntersectNextKey, false)
		end
		       
		nNewObject:lateCheck()
	end)
	do return nNewObject
 end end

function TypeManager:buildExtendStruct(vNode, vFirst  ,
	... )
	local nStruct = self:_checkAllType(vFirst) or self:buildStruct(vNode, vFirst   )
	local l = {nStruct, ...}
	do return self:_buildCombineObject(vNode, false, l)
 end end

function TypeManager:buildExtendInterface(vNode, ... )
	local l = {...}
	do return self:_buildCombineObject(vNode, true, l)
 end end

function TypeManager:checkedUnion(...)
	local l = {...}
	local nCollection = self:TypeCollection()
	for i=1, select("#", ...) do
		l[i]:checkAtomUnion():foreach(function(vAtomType)
			nCollection:put(vAtomType)
		end)
	::continue:: end
	do return nCollection:mergeToAtomUnion()
 end end

function TypeManager:buildEnum(vNode, vArgType)
	local nNewRefer = self:Reference(false)
	nNewRefer:setUnionAsync(vNode, function()
		local nType = self._dirtyProcessor:easyToType(vNode, vArgType)
		local nSuperType = Reference.is(nType) and nType:waitTypeCom():getTypeAwait() or nType
		do return {Enum.new(self, nSuperType)}
	 end end)
	do return nNewRefer
 end end

function TypeManager:addEnum(vNode, vEnumType, ...)
	       
	local nType = self._dirtyProcessor:easyToType(vNode, vEnumType)
	local nEnumType = nType:checkAtomUnion()
	assert(Enum.is(nEnumType), Exception.new("enum must take Enum as first arg", vNode))
	local l = {...}
	local nLen = select("#", ...)
	for i=1, nLen do
		local nItem = self._dirtyProcessor:easyToType(vNode, l[i])
		nEnumType:addType(nItem)
	::continue:: end
end

function TypeManager:buildUnion(vNode, ...)
	local l = {...}
	local nLen = select("#", ...)
	local nNewRefer = self:Reference(false)
	nNewRefer:setUnionAsync(vNode, function()
		local nTypeList = {}
		for i=1, nLen do
			local nItem = self._dirtyProcessor:easyToType(vNode, l[i])
			if Reference.is(nItem) then
				local nAsyncType = nItem:waitTypeCom():getTypeNowait()
				if nAsyncType:isAsync() then
					local nList = nAsyncType:getListAwait()
					table.move(nList, 1, #nList, #nTypeList + 1, nTypeList)
				else
					nAsyncType:foreach(function(vAtom)
						nTypeList[#nTypeList + 1] = vAtom
					end)
				end
			else
				nItem:foreach(function(vAtom)
					nTypeList[#nTypeList + 1] = vAtom
				end)
			end
		::continue:: end
		do return nTypeList
	 end end)
	do return nNewRefer
 end end

function TypeManager:buildInterface(vNode, vTable, vMetaEventDict )
	do return self:_buildTypedObject(vNode, vTable, vMetaEventDict, true)
 end end

function TypeManager:buildStruct(vNode, vTable, vMetaEventDict )
	do return self:_buildTypedObject(vNode, vTable, vMetaEventDict, false)
 end end

function TypeManager:_buildTypedObject(vNode, vTable, vMetaEventDict , vIsInterface)  
	local nNextKey = vMetaEventDict and vMetaEventDict.__Next or false
	local nNewObject = vIsInterface and Interface.new(self, vNode) or Struct.new(self, vNode)
	nNewObject:buildAsync(function(vAsyncKey)
		local nIndependentList = {}
		local nKeyList = {}
		local nValueDict  = {}
		for nKey, nValue in pairs(vTable) do
			local nValueType = self._dirtyProcessor:easyToType(vNode, nValue)
			local nKeyType = self._dirtyProcessor:easyToType(vNode, nKey)
			nIndependentList[#nIndependentList + 1] = nKeyType
			nKeyType:checkAtomUnion():foreach(function(vAtomType)
				nKeyList[#nKeyList + 1] = vAtomType
				if vAtomType:isSingleton() then
					nValueDict[vAtomType] = nValueType
				else
					nValueDict[vAtomType] = self:buildUnion(vNode, nValueType, self.type.Nil)
				end
			end)
		::continue:: end
		local nKeyAtomUnion = vAsyncKey:setAtomList(nKeyList)
		if vMetaEventDict then
			local nNewEventCom = self:makeMetaEventCom(nNewObject)
			nNewEventCom:initByEventDict(vMetaEventDict)
			nNewObject:lateInit({}, nValueDict, nNextKey, nNewEventCom)
		else
			nNewObject:lateInit({}, nValueDict, nNextKey, false)
		end
		nNewObject:lateCheck()
		if not self:typeCheckIndependent(nIndependentList, nKeyAtomUnion) then
			error("Object's key must be independent")
		end
	end)
	do return nNewObject
 end end

function TypeManager:buildIDict(vNode, vKey, vValue)
	do return self:buildInterface(vNode, {[vKey]=vValue})
 end end

function TypeManager:buildDict(vNode, vKey, vValue)
	do return self:buildStruct(vNode, {[vKey]=vValue}, {__Next=vKey})
 end end

function TypeManager:buildIList(vNode, vValue)
	do return self:buildInterface(vNode, {[self.type.Integer]=vValue}, {__len=self.type.Integer})
 end end

function TypeManager:buildList(vNode, vValue)
	do return self:buildStruct(vNode, {[self.type.Integer]=vValue}, {__len=self.type.Integer, __Next=self.type.Integer})
 end end

function TypeManager:buildOrNil(vNode, ...)
	do return self:buildUnion(vNode, self.type.Nil, ...)
 end end

function TypeManager:buildOrFalse(vNode, ...)
	do return self:buildUnion(vNode, self.type.False, ...)
 end end

function TypeManager:_unifyUnion(vNewType)
	local nSign = vNewType:unionSign()
	local nSignToType = self._unionSignToType
	local nOldType = nSignToType[nSign]
	if not nOldType then
		vNewType:initWithTypeId(self:genTypeId())
		nSignToType[nSign] = vNewType
		do return vNewType
	 end else
		do return nOldType
	 end end
end

function TypeManager:atomRecordTypeUnionSign(vType)
	self._unionSignToType[tostring(vType.id)] = vType
end

function TypeManager:metaNativeOpenFunction(vFn)
	local nOpenFn = self._runtime:getRootStack():newOpenFunction(self._rootNode)
	nOpenFn:lateInitFromMetaNative(vFn)
	do return nOpenFn
 end end

function TypeManager:fixedNativeOpenFunction(vFn)
	local nOpenFn = self._runtime:getRootStack():newOpenFunction(self._rootNode)
	nOpenFn:lateInitFromOperNative(vFn)
	do return nOpenFn
 end end

function TypeManager:stackNativeOpenFunction(vFn)
	local nOpenFn = self._runtime:getRootStack():newOpenFunction(self._rootNode)
	nOpenFn:lateInitFromAutoNative(vFn)
	do return nOpenFn
 end end

function TypeManager:Literal(vValue  )   
	local t = type(vValue)
	if t == "number" then
		if math.type(vValue) == "integer" then
			local nLiteralDict = self._integerLiteralDict
			local nLiteralType = nLiteralDict[vValue]
			if not nLiteralType then
				nLiteralType = IntegerLiteral.new(self, vValue)
				nLiteralDict[vValue] = nLiteralType
			end
			do return nLiteralType
		 end else
			local nLiteralDict = self._floatLiteralDict
			local nLiteralType = nLiteralDict[vValue]
			if not nLiteralType then
				nLiteralType = FloatLiteral.new(self, vValue)
				nLiteralDict[vValue] = nLiteralType
			end
			do return nLiteralType
		 end end
	else
		local nLiteralDict = self._sbLiteralDict
		local nLiteralType = nLiteralDict[vValue]
		if not nLiteralType then
			if t == "string" then
				nLiteralType = StringLiteral.new(self, vValue)
				nLiteralDict[vValue] = nLiteralType
			elseif t == "boolean" then
				if vValue then
					nLiteralType = self.type.True
				else
					nLiteralType = self.type.False
				end
				nLiteralDict[vValue] = nLiteralType
			else
				error("literal must take boolean or number or string value but got:"..tostring(t))
			end
		end
		do return nLiteralType
	 end end
end

function TypeManager:TypeTuple(vNode, vTypeList)
	do return TypeTuple.new(self, vNode, vTypeList)
 end end

function TypeManager:VoidRetTuples(vNode, vErrType)
	do return RetTuples.new(self, vNode, {self:TypeTuple(vNode, {})}, vErrType or false)
 end end

function TypeManager:SingleRetTuples(vNode, vTypeTuple, vErrType)
	do return RetTuples.new(self, vNode, {vTypeTuple}, vErrType or false)
 end end

function TypeManager:buildMfn(vNode, ...)
	local nHeadlessFn = self:buildFn(vNode, ...)
	do return TypedMemberFunction.new(self, vNode, nHeadlessFn)
 end end

function TypeManager:buildPfn(vNode, vFunc)
	local nInfo = debug.getinfo(vFunc)
	local nPolyParNum=nInfo.nparams
	if nInfo.isvararg then
		error("poly function can't be vararg")
	end
	do return TypedPolyFunction.new(self, vNode, vFunc, nPolyParNum)
 end end

function TypeManager:buildFn(vNode, ...)
	local nParTuple = self:TypeTuple(vNode, self._dirtyProcessor:easyToTypeList(vNode, ...))
	do return TypedFunction.new(self, vNode, nParTuple, false)
 end end

function TypeManager:checkedFn(...)
	local nParTuple = self:TypeTuple(self._rootNode, self._dirtyProcessor:easyToTypeList(self._rootNode, ...))
	do return TypedFunction.new(self, self._rootNode, nParTuple, false)
 end end

function TypeManager:SealPolyFunction(vNode, vFunc, vPolyParNum, vStack)
	do return SealPolyFunction.new(self, vNode, vFunc, vPolyParNum, vStack)
 end end

function TypeManager:AutoMemberFunction(vNode, vPolyFn)
	do return AutoMemberFunction.new(self, vNode, vPolyFn)
 end end

function TypeManager:TypedFunction(vNode, vParTuple, vRetTuples)
	assert(TypeTuple.is(vParTuple) or TypeTupleDots.is(vParTuple))
	assert(RetTuples.is(vRetTuples))
	do return TypedFunction.new(self, vNode, vParTuple, vRetTuples)
 end end

function TypeManager:makeMetaEventCom(vObject )
	do return MetaEventCom.new(self, vObject)
 end end

function TypeManager:buildTemplate(vNode, vFunc)
	local nInfo = debug.getinfo(vFunc)
	local nParNum = nInfo.nparams
	if nInfo.isvararg then
		error("template's parameter number is undetermined")
	end
	do return self:buildTemplateWithParNum(vNode, vFunc, nParNum)
 end end

function TypeManager:buildTemplateWithParNum(vNode, vFunc, vParNum)
	local nRefer = self:Reference(false)
	nRefer:setTemplateAsync(vNode, vFunc, vParNum)
	do return nRefer
 end end

function TypeManager:Reference(vName )
	local nRefer = Reference.new(self, vName)
	do return nRefer
 end end

function TypeManager:typeCheckIndependent(vList, vFinalType)
	local nLeftCount = 0
	for k,v in pairs(vList) do
		v:checkAtomUnion():foreach(function(_)
			nLeftCount = nLeftCount + 1
		end)
	::continue:: end
	local nRightCount = 0
	vFinalType:foreach(function(_)
		nRightCount = nRightCount + 1
	end)
	do return nRightCount == nLeftCount
 end end

function TypeManager:typeMapReduce(
	vTypePairList  ,
	vReduceFn
)  
	local nCollection = self:TypeCollection()
	for _, nPair in ipairs(vTypePairList) do
		local nFieldType = nPair[1]
		if nFieldType:isReference() then
			nFieldType = nFieldType:checkAtomUnion()
			nPair[1] = nFieldType
		end
		nCollection:put(nFieldType)
	::continue:: end
	local nKeyUnion = nCollection:mergeToAtomUnion()
	   
	local nTypeToList  = {}
	for _, nPair in ipairs(vTypePairList) do
		local nKey = nPair[1]
		local nValueType = nPair[2]
		nKey:foreach(function(vSubType)
			local nIncludeType = assert(nKeyUnion:includeAtom(vSubType), "merge error")
			local nList = nTypeToList[nIncludeType]
			if not nList then
				nTypeToList[nIncludeType] = {nValueType}
			else
				nList[#nList + 1] = nValueType
			end
		end)
	::continue:: end
	   
	local nTypeDict  = {}
	for k,v in pairs(nTypeToList) do
		nTypeDict[k] = vReduceFn(v)
	::continue:: end
	do return nKeyUnion, nTypeDict
 end end

function TypeManager:unionReduceType(vList)
	if #vList == 1 then
		do return vList[1]
	 end end
	local nCollection = self:TypeCollection()
	for _, nType in ipairs(vList) do
		nType:foreach(function(vAtomType)
			nCollection:put(vAtomType)
		end)
	::continue:: end
	do return nCollection:mergeToAtomUnion()
 end end

function TypeManager:intersectReduceType(vNode, vList)
	local nFirst = vList[1]
	if #vList == 1 then
		do return nFirst
	 end end
	local nRefer = self:Reference(false)
	nRefer:setUnionAsync(vNode, function()
		local nFinalType = nFirst:checkAtomUnion()
		for i=2, #vList do
			local nCurType = vList[i]
			local nInterType = nFinalType:safeIntersect(nCurType)
			if not nInterType then
				error("unexpected intersect")
			else
				nFinalType = nInterType
			end
		::continue:: end
		local nAtomList = {}
		nFinalType:foreach(function(vAtomType)
			nAtomList[#nAtomList + 1] = vAtomType
		end)
		if nFinalType:isNever() then
			error("object intersect can't has never field")
		end
		do return nAtomList, function()
			do return nFinalType
		 end end
	 end end)
	do return nRefer
 end end

function TypeManager:makePair(vLeft, vRight)
	local nLeftId, nRightId = vLeft.id, vRight.id
	assert(nLeftId ~= 0 and nRightId ~=0, "use id ==0")
	do return TypeRelation.shiftPair(nLeftId, nRightId)
 end end

function TypeManager:makeDuPair(vLeft, vRight)  
	local nLeftId, nRightId = vLeft.id, vRight.id
	if nLeftId < nRightId then
		do return false, TypeRelation.shiftPair(nLeftId, nRightId), TypeRelation.shiftPair(nRightId, nLeftId)
	 end else
		do return true, TypeRelation.shiftPair(nRightId, nLeftId), TypeRelation.shiftPair(nLeftId, nRightId)
	 end end
end

function TypeManager:attachPairRelation(vLeft, vRight, vWaitCreate)
	local nInverse, nLRPair, nRLPair = self:makeDuPair(vLeft, vRight)
	if nInverse then
		vRight, vLeft = vLeft, vRight
	end
	local nRelation = self._pairToRelation[nLRPair]
	local nResult = false
	if vWaitCreate then
		if not nRelation then
			nRelation = TypeRelation.new(self)
			self._pairToRelation[nLRPair] = nRelation
			nRelation:buildByObject(vLeft, vRight)
		end
		nResult = nRelation:getAwait()
	else
		if nRelation then
			nResult = nRelation:getNowait()
		end
	end
	if not nResult then
		do return nil
	 end end
	if nInverse then
		if nResult == ">" then
			do return "<"
		 end elseif nResult == "<" then
			do return ">"
		 end else
			do return nResult
		 end end
	else
		do return nResult
	 end end
end

function TypeManager:getRuntime()
	do return self._runtime
 end end

function TypeManager:literal2Primitive(vType)
	if BooleanLiteral.is(vType) then
		do return self.type.Boolean:checkAtomUnion()
	 end elseif FloatLiteral.is(vType) then
		do return self.type.Number
	 end elseif IntegerLiteral.is(vType) then
		do return self.type.Integer
	 end elseif StringLiteral.is(vType) then
		do return self.type.String
	 end else
		do return vType
	 end end
end

function TypeManager:signTemplateArgs(vTypeList)
	local nIdList = {}
	for i=1,#vTypeList do
		nIdList[i] = vTypeList[i].id
	::continue:: end
	do return table.concat(nIdList, "-")
 end end

function TypeManager:genTypeId()
	local nNewId = self._typeIdCounter + 1
	self._typeIdCounter = nNewId
	do return nNewId
 end end

function TypeManager:dump()
	for k,v in pairs(self._unionSignToType) do
		print(k, tostring(v))
	::continue:: end
end

function TypeManager:getScheduleManager()
	do return self._scheduleManager
 end end

function TypeManager:getDirtyProcessor()
	do return self._dirtyProcessor
 end end

do return TypeManager
 end 
end end
--thlua.manager.TypeManager end ==========)

--thlua.manager.TypeRelation begin ==========(
do local _ENV = _ENV
packages['thlua.manager.TypeRelation'] = function (...)

local class = require "thlua.class"
local Interface = require "thlua.type.object.Interface"

local TypeRelation = {}
TypeRelation.__index = TypeRelation

TypeRelation.HAS = ">"
TypeRelation.IN = "<"
TypeRelation.EQUAL = "="
TypeRelation.SOME = "&"
TypeRelation.NONE = "~"


	  
          


function TypeRelation.new(vManager)
    local nTask = vManager:getScheduleManager():newTask()
    local self = setmetatable({
        _manager = vManager,
        _task = nTask,
        _buildEvent = nTask:makeEvent(),
        _result = false  ,
        _smallIdObj = nil,
        _bigIdObj = nil,
    }, TypeRelation)
    do return self
 end end

local function shiftPair(vId1, vId2)
	do return (vId1 << 32) + vId2
 end end
TypeRelation.shiftPair = shiftPair

function TypeRelation:getAwait()
    self._buildEvent:wait()
    do return assert(self._result)
 end end

function TypeRelation:getNowait()
    do return self._result
 end end

function TypeRelation:buildByObject(vLeft, vRight)
    if vLeft.id > vRight.id then
        vLeft, vRight = vRight, vLeft
    end
    self._smallIdObj = vLeft
    self._bigIdObj = vRight
    self._task:runAsync(function()
        local nLeftId = vLeft.id
        local nRightId = vRight.id
        local nLRPair, nRLPair = shiftPair(nLeftId, nRightId), TypeRelation.shiftPair(nRightId, nLeftId)
        local nLRInclude = vLeft:assumeIncludeObject({[nLRPair]=true}, vRight)
        local nRLInclude = vRight:assumeIncludeObject({[nRLPair]=true}, vLeft)
        if nLRInclude and nRLInclude then
            self._result = TypeRelation.EQUAL
        elseif nLRInclude then
            self._result = TypeRelation.HAS
        elseif nRLInclude then
            self._result = TypeRelation.IN
        else
            if Interface.is(vLeft) and Interface.is(vRight) then
                local nIntersect = vLeft:assumeIntersectInterface({[nLRPair]=true,[nRLPair]=true}, vRight)
                if nIntersect then
                    self._result = TypeRelation.SOME
                else
                    self._result = TypeRelation.NONE
                end
            else
                self._result = TypeRelation.NONE
            end
        end
        self._buildEvent:wakeup()
    end)
end

do return TypeRelation end 
end end
--thlua.manager.TypeRelation end ==========)

--thlua.native begin ==========(
do local _ENV = _ENV
packages['thlua.native'] = function (...)

local TermTuple = require "thlua.tuple.TermTuple"
local TypedFunction = require "thlua.type.func.TypedFunction"
local SealTable = require "thlua.type.object.SealTable"
local OpenTable = require "thlua.type.object.OpenTable"
local AutoTable = require "thlua.type.object.AutoTable"
local RefineTerm = require "thlua.term.RefineTerm"
local StringLiteral = require "thlua.type.basic.StringLiteral"
local IntegerLiteral = require "thlua.type.basic.IntegerLiteral"
local Integer = require "thlua.type.basic.Integer"
local FloatLiteral = require "thlua.type.basic.FloatLiteral"
local Number = require "thlua.type.basic.Number"
local Truth = require "thlua.type.basic.Truth"
local Exception = require "thlua.Exception"
local VariableCase = require "thlua.term.VariableCase"

local native = {}


	  
	   


function native._toTable(vManager, vTable)
	local nPairList  = {}
	for k,v in pairs(vTable) do
		nPairList[#nPairList + 1] = {
			vManager:Literal(k), v
		}
	::continue:: end
  local nKeyUnion, nTypeDict = vManager:typeMapReduce(nPairList, function(vList)
		do return vManager:unionReduceType(vList)
	 end end)
	local nTable = AutoTable.new(vManager, vManager:getRuntime():getNode(), vManager:getRuntime():getRootStack())
	nTable:initByKeyValue(vManager:getRuntime():getNode(), nKeyUnion, nTypeDict)
	do return nTable
 end end

function native.make(vRuntime)
	local nManager = vRuntime:getTypeManager()
	local global = {
		 
		setmetatable=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			do return vStack:withOnePushContext(vStack:getNode(), function(vContext)
				local nTerm1 = vTermTuple:checkFixed(vContext, 1)
				local nType1 = nTerm1:getType()
				local nType2 = vTermTuple:checkFixed(vContext, 2):getType()
				if nType1:isUnion() or nType2:isUnion() then
					vContext:error("setmetatable can't take union type")
				else
					nType1 = nType1:checkAtomUnion()
					nType2 = nType2:checkAtomUnion()
					if SealTable.is(nType2) or OpenTable.is(nType2) then
						nType2:setAssigned(vContext)
						nType1:native_setmetatable(vContext, nType2)
					else
						vContext:error("metatable must be table but get:"..tostring(nType2))
					end
				end
				vContext:nativeOpenReturn(nTerm1)
			end):mergeFirst()
		 end end),
		getmetatable=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nTerm1 = vTermTuple:get(vContext, 1)
			local nTypeCaseList = {}
			nTerm1:foreach(function(vType1, vVariableCase)
				nTypeCaseList[#nTypeCaseList + 1] = {
					vType1:native_getmetatable(vContext),
					vVariableCase,
				}
			end)
			do return vContext:mergeToRefineTerm(nTypeCaseList)
		 end end),
		next=nManager.builtin.next,
		ipairs=nManager:metaNativeOpenFunction(function(vContext, vType)
			local nTypeTuple = vType:meta_ipairs(vContext) or nManager:TypeTuple(vContext:getNode(), {nManager.builtin.inext, vType, nManager:Literal(0)})
			vContext:pushFirstAndTuple(nTypeTuple:get(1):checkAtomUnion(), nTypeTuple)
		end),
		pairs=nManager:metaNativeOpenFunction(function(vContext, vType)
			local nTypeTuple = vType:meta_pairs(vContext) or nManager:TypeTuple(vContext:getNode(), {nManager.builtin.next, vType, nManager.type.Nil})
			vContext:pushFirstAndTuple(nTypeTuple:get(1):checkAtomUnion(), nTypeTuple)
		end),
		rawequal=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			 
			 
			print("rawequal TODO")
			do return vContext:RefineTerm(nManager.type.Boolean)
		 end end),
		type=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nTerm = vTermTuple:get(vContext, 1)
			local nTypeCaseList = {}
			nTerm:foreach(function(vType, vVariableCase)
				nTypeCaseList[#nTypeCaseList + 1] = {
					vType:native_type(), vVariableCase
				}
			end)
			do return vContext:mergeToRefineTerm(nTypeCaseList)
		 end end),
		  
		select=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			local nFirstType = vTermTuple:get(vContext, 1):getType()
			if nFirstType == nManager:Literal("#") then
				if vTermTuple:getTail() then
					do return vContext:RefineTerm(nManager.type.Integer)
				 end else
					do return vContext:RefineTerm(nManager:Literal(#vTermTuple-1))
				 end end
			else
				if IntegerLiteral.is(nFirstType) then
					local nStart = nFirstType:getLiteral()
					if nStart > 0 then
						do return vTermTuple:select(vContext, nStart + 1)
					 end elseif nStart < 0 then
						vContext:error("select first < 0 TODO")
						do return vContext:FixedTermTuple({})
					 end else
						vContext:error("select's first arguments is zero")
						do return vContext:FixedTermTuple({})
					 end end
				else
					if Integer.is(nFirstType) then
						local nCollection = nManager:TypeCollection()
						for i=2, #vTermTuple do
							local nType = vTermTuple:get(vContext, i):getType()
							nCollection:put(nType)
						::continue:: end
						local nRepeatType = vTermTuple:getRepeatType()
						if nRepeatType then
							nCollection:put(nRepeatType)
						end
						local nFinalType = nCollection:mergeToAtomUnion()
						if nRepeatType then
							do return nManager:TypeTuple(vContext:getNode(), {}):withDots(nRepeatType):makeTermTuple(vContext)
						 end else
							local nReList = {}
							for i=2, #vTermTuple do
								nReList[#nReList + 1] = nFinalType
							::continue:: end
							do return nManager:TypeTuple(vContext:getNode(), nReList):makeTermTuple(vContext)
						 end end
					else
						vContext:error("select's first value must be integer or integer-literal")
						do return vContext:FixedTermTuple({})
					 end end
				end
			end
		end),
		require=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			do return vStack:withOnePushContext(vStack:getNode(), function(vContext)
				local nFileName = vTermTuple:get(vContext, 1):getType()
				if StringLiteral.is(nFileName) then
					local nPath = nFileName:getLiteral()
					local nRetTerm, nOpenFn = vRuntime:require(vStack:getNode(), nPath)
					vContext:addLookTarget(nOpenFn)
					vContext:nativeOpenReturn(nRetTerm)
				else
					vContext:warn("require take non-const type ")
					vContext:nativeOpenReturn(vContext:RefineTerm(nManager.type.Any))
				end
			end):mergeFirst()
		 end end),
		load=nManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
			 
			do return vContext:RefineTerm(nManager.type.AnyFunction)
		 end end),
		       
		pcall=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			local nHeadContext = vStack:inplaceOper()
			local nFunc = vTermTuple:get(nHeadContext, 1):checkRefineTerm(nHeadContext)
			local nArgs = vTermTuple:select(nHeadContext, 2)
			local nCallContext = vStack:prepareMetaCall(vStack:getNode(), nFunc, function() do return nArgs  end end)
			do return nCallContext:pcallMergeReturn(vStack:mergeEndErrType())
		 end end),
		xpcall=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			local nHeadContext = vStack:inplaceOper()
			local nFunc1 = vTermTuple:get(nHeadContext, 1):checkRefineTerm(nHeadContext)
			local nFunc2 = vTermTuple:get(nHeadContext, 2):checkRefineTerm(nHeadContext)
			local nArgs = vTermTuple:select(nHeadContext, 3)
			local nCallContext = vStack:prepareMetaCall(vStack:getNode(), nFunc1, function() do return nArgs  end end)
			local nErrType = vStack:mergeEndErrType()
			local nHandleContext = vStack:prepareMetaCall(vStack:getNode(), nFunc2, function() do return nCallContext:FixedTermTuple({nCallContext:RefineTerm(nErrType)})  end end)
			local nHandleReturn = nHandleContext:mergeReturn()
			local nType = RefineTerm.is(nHandleReturn) and nHandleReturn:getType() or nHandleReturn:get(nHandleContext, 1):getType()
			do return nCallContext:pcallMergeReturn(nType)
		 end end),
		error=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			local nOperCtx = vStack:inplaceOper()
			vStack:getApplyStack():nativeError(nOperCtx, vTermTuple:checkFixed(nOperCtx, 1))
			do return nOperCtx:FixedTermTuple({})
		 end end),
		assert=nManager:stackNativeOpenFunction(function(vStack, vTermTuple)
			local nHeadContext = vStack:inplaceOper()
			local nFirst = vTermTuple:checkFixed(nHeadContext, 1)
			local nSecond = vTermTuple:rawget(2)
			vStack:getApplyStack():nativeAssert(nHeadContext, nFirst, nSecond and nSecond:checkRefineTerm(nHeadContext))
			local nLogicContext = vStack:newLogicContext(vStack:getNode())
			do return vStack:inplaceOper():FixedTermTuple({nLogicContext:logicTrueTerm(nFirst)})
		 end end),
	}

	local nGlobalTable = native._toTable(vRuntime:getTypeManager(), global)
    nGlobalTable:setName("_G")

	do return nGlobalTable
 end end

function native.make_inext(vManager)
	local nInteger = vManager.type.Integer
	local nNil = vManager.type.Nil
	do return vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
		local nFirstTerm = vTermTuple:get(vContext, 1)
		    
		local nNotNilValue = vContext:getStack():anyNodeMetaGet(vContext:getNode(), nFirstTerm, vContext:RefineTerm(nInteger), true):getType()
		local nValueTerm = vContext:RefineTerm(vManager:checkedUnion(nNotNilValue, nNil))
		local nKeyValue  = {
			[nInteger]=nNotNilValue,
			[nNil]=nNil,
		}
		local nTypeCaseList = {}
		for nOneKey, nOneValue in pairs(nKeyValue) do
			local nCase = VariableCase.new()
			nCase:put_and(nValueTerm:attachImmutVariable(), nOneValue)
			nTypeCaseList[#nTypeCaseList + 1] = {
				nOneKey, nCase
			}
		::continue:: end
		local nKeyTerm = vContext:mergeToRefineTerm(nTypeCaseList)
		do return vContext:FixedTermTuple({nKeyTerm, nValueTerm})
	 end end)
 end end

function native.make_next(vManager)
	do return vManager:fixedNativeOpenFunction(function(vContext, vTermTuple)
		local nType1 = vTermTuple:get(vContext, 1):getType()
		nType1 = nType1:trueType()
		local nType2 = vTermTuple:get(vContext, 2):getType()
		if nType1:isUnion() then
			if nType1:isNever() then
				vContext:error("next must take table as first type")
			else
				vContext:error("TODO: next Union type")
			end
			do return vContext:FixedTermTuple({vContext:NilTerm(), vContext:NilTerm()})
		 end else
			local nValueType, nKeyValue = nType1:native_next(vContext, nType2)
			local nValueTerm = vContext:RefineTerm(nValueType)
			local nTypeCaseList = {}
			for nOneKey, nOneValue in pairs(nKeyValue) do
				local nCase = VariableCase.new()
				nCase:put_and(nValueTerm:attachImmutVariable(), nOneValue)
				nTypeCaseList[#nTypeCaseList + 1] = {
					nOneKey, nCase
				}
			::continue:: end
			local nKeyTerm = vContext:mergeToRefineTerm(nTypeCaseList)
			do return vContext:FixedTermTuple({nKeyTerm, nValueTerm})
		 end end
	end)
 end end

function native.make_mathematic(vManager, vIsDivide)
	local nNumber = vManager.type.Number
	if vIsDivide then
		do return vManager:checkedFn(nNumber, nNumber):Ret(nNumber)
	 end end
	local nInteger = vManager.type.Integer
	do return vManager:stackNativeOpenFunction(function(vStack, vTermTuple)
		local nOperCtx = vStack:inplaceOper()
		local nType1 = vTermTuple:checkFixed(nOperCtx, 1):getType()
		local nType2 = vTermTuple:checkFixed(nOperCtx, 2):getType()
		local nHasFloat = false
		local nEachFn = function(vAtomType)
			if FloatLiteral.is(vAtomType) or Number.is(vAtomType) then
				nHasFloat = true
			elseif not (IntegerLiteral.is(vAtomType) or Integer.is(vAtomType)) then
				nOperCtx:error("math operator must take number")
			end
		end
		nType1:foreach(nEachFn)
		nType2:foreach(nEachFn)
		if nHasFloat then
			do return nOperCtx:FixedTermTuple({nOperCtx:RefineTerm(nNumber)})
		 end else
			do return nOperCtx:FixedTermTuple({nOperCtx:RefineTerm(nInteger)})
		 end end
	end)
 end end

function native.make_comparison(vManager)
	local nNumber = vManager.type.Number
	do return vManager:checkedFn(nNumber, nNumber):Ret(vManager.type.Boolean)
 end end

function native.make_bitwise(vManager)
	local nInteger = vManager.type.Integer
	do return vManager:checkedFn(nInteger, nInteger):Ret(nInteger)
 end end

function native.make_concat(vManager)
	local nType = vManager:checkedUnion(vManager.type.String, vManager.type.Number)
	do return vManager:checkedFn(nType, nType):Ret(vManager.type.String)
 end end

do return native

 end 
end end
--thlua.native end ==========)

--thlua.refer.AsyncUnion begin ==========(
do local _ENV = _ENV
packages['thlua.refer.AsyncUnion'] = function (...)

local ScheduleTask = require "thlua.manager.ScheduleTask"
local class = require "thlua.class"
local Exception = require "thlua.Exception"

  

local AsyncUnion = class ()

function AsyncUnion.__tostring(self)
	local l = {}
	local nTypeList = self._typeList
	if nTypeList then
		for i, v in ipairs(nTypeList) do
			l[i] = tostring(v)
		::continue:: end
		do return "AsyncUnion("..table.concat(l, ",")..")"
	 end else
		do return "AsyncUnion(?)"
	 end end
end

function AsyncUnion:ctor(vManager, vTask)
	self._manager=vManager
	self._task = vTask
	self._mayRecursive=false
	self._typeList=false
	self._resultType=false
	self._listBuildEvent=vTask:makeEvent()
	self._resultBuildEvent=vTask:makeEvent()
end

function AsyncUnion:getResultType()
	do return self._resultType
 end end

function AsyncUnion:getTypeAwait()
	if not self._resultType then
		self._resultBuildEvent:wait()
	end
	do return (assert(self._resultType, "result type not setted"))
 end end

function AsyncUnion:getMayRecursive()
	do return self._mayRecursive
 end end

function AsyncUnion:getListAwait()
	if not self._typeList then
		self._listBuildEvent:wait()
	end
	do return (assert(self._typeList, "type list not setted"))
 end end

function AsyncUnion:setAtomList(vAtomList, vLateRunner)
	assert(not self._typeList, "type list has been setted")
	    
	self._typeList = vAtomList
	for k, v in ipairs(vAtomList) do
		if v:mayRecursive() then
			self._mayRecursive = true
		end
	::continue:: end
	self._listBuildEvent:wakeup()
	if vLateRunner then
		local nResultType = vLateRunner()
		if nResultType then
			self._resultType = nResultType
			self._resultBuildEvent:wakeup()
			do return nResultType
		 end end
	end
	      
	local nResultType = nil
	if #vAtomList == 0 then
		nResultType = self._manager.type.Never
	elseif #vAtomList == 1 then
		nResultType = vAtomList[1]
	else
		local nCollection = self._manager:TypeCollection()
		for _, v in ipairs(vAtomList) do
			nCollection:put(v)
		::continue:: end
		nResultType = nCollection:mergeToAtomUnion()
	end
	self._resultType = nResultType
	self._resultBuildEvent:wakeup()
	do return nResultType
 end end

function AsyncUnion:foreachAwait(vFunc)
	local nResultType = self._resultType
	if nResultType then
		nResultType:foreach(vFunc)
	else
		local nListType = self:getListAwait()
		for _, v in ipairs(nListType) do
			vFunc(v)
		::continue:: end
	end
end

function AsyncUnion:isAsync()
	do return true
 end end

do return AsyncUnion
 end 
end end
--thlua.refer.AsyncUnion end ==========)

--thlua.refer.Letspace begin ==========(
do local _ENV = _ENV
packages['thlua.refer.Letspace'] = function (...)

local class = require "thlua.class"
local Namespace = require "thlua.refer.Namespace"
local SpaceTable = require "thlua.refer.SpaceTable"
local Exception = require "thlua.Exception"
local Reference = require "thlua.refer.Reference"


	  


local Letspace = class (Namespace)
Letspace.__tostring=function(self)
	do return "letspace-" .. tostring(self._node).."|"..tostring(self._key or "!keynotset")
 end end

function Letspace:ctor(vManager, vNode, _, vParentSpace)
    self._parentSpace = vParentSpace
    self._envTable = SpaceTable.createEnvTable(self, self._key2type)
    self._globalTable = SpaceTable.createGlobalTable(self, vParentSpace)
end

function Letspace:parentHasKey(vKeyType)
	do return self._parentSpace:pureGet(vKeyType) and true or false
 end end

function Letspace:pureGet(vKeyType)
	do return self._key2type[vKeyType] or self._parentSpace:pureGet(vKeyType)
 end end

function Letspace:globalGet(vNode, vKeyType)
    local nValue = self:pureGet(vKeyType)
    if nValue then
        do return nValue
     end else
        error(Exception.new("key with empty value, key="..tostring(vKeyType), vNode))
    end
end

function Letspace:getGlobalTable()
    do return self._globalTable
 end end

function Letspace:export()  
    do return self._localTable, self._envTable, self._globalTable
 end end

function Letspace:spaceTablePutCompletion(vSpaceTable, vCompletion)
    local nWhat = getmetatable(vSpaceTable).__what
    if nWhat == "_ENV" then
        self:putCompletion(vCompletion)
        self._parentSpace:spaceTablePutCompletion(vSpaceTable, vCompletion)
    elseif nWhat == "_G" then
        
            
                
                   
            
        
        
    else
        self:putCompletion(vCompletion)
    end
end

do return Letspace
 end 
end end
--thlua.refer.Letspace end ==========)

--thlua.refer.NameLocation begin ==========(
do local _ENV = _ENV
packages['thlua.refer.NameLocation'] = function (...)


local class = require "thlua.class"


	  


local NameLocation = class ()

function NameLocation.__tostring(self)
    do return "NameLocation tostring TODO"
 end end

function NameLocation:ctor(vSpace, vKey)
    self._space = vSpace
    self._key = vKey
end

do return NameLocation end 
end end
--thlua.refer.NameLocation end ==========)

--thlua.refer.Namespace begin ==========(
do local _ENV = _ENV
packages['thlua.refer.Namespace'] = function (...)

local Exception = require "thlua.Exception"
local Reference = require "thlua.refer.Reference"
local StringLiteral = require "thlua.type.basic.StringLiteral"
local SpaceTable = require "thlua.refer.SpaceTable"
local SpaceBuiltin = require "thlua.refer.SpaceBuiltin"
local NameLocation= require "thlua.refer.NameLocation"
local Node = require "thlua.code.Node"
local class = require "thlua.class"


	  
	   


local Namespace = class ()
Namespace.__tostring=function(self)
	do return "namespace-" .. tostring(self._node).."|"..tostring(self._key or "!keynotset")
 end end

function Namespace:ctor(vManager, vNode, vIndexTable , ...)
	self._manager=vManager
	self._key2type={}          
	self._closed=false
	self._node=vNode
	self._key=false 
	self._localTable = SpaceTable.createLocalTable(self, self._key2type)
	if vIndexTable then   
		for k,v in pairs(vIndexTable) do
			self._key2type[k] = v
		::continue:: end
	end
	do return self
 end end

function Namespace:assertSpaceKeyType(vNode, vKey)
	local nOkay, nType = self._manager:getDirtyProcessor():peasyToType(vKey)
	if not nOkay then
		error(Exception.new(nType, vNode))
	end
	local nFinalKey = nType
	if Reference.is(nFinalKey) then
		nFinalKey = nFinalKey:checkAtomUnion()
	end
	if not nFinalKey:isUnion() then
		do return nFinalKey
	 end else
		error(Exception.new("namespace's key can't be union type", vNode))
	end
end

function Namespace:pureGet(vKeyType)
	do return self._key2type[vKeyType]
 end end

function Namespace:parentHasKey(vKeyType)
	do return false
 end end

function Namespace:localGet(vNode, vKeyType)
	local rawgetV = self._key2type[vKeyType]
	if rawgetV then
		do return rawgetV
	 end end
    if self:parentHasKey(vKeyType) then
        error(Exception.new("'let' can only get symbol in current level key="..tostring(vKeyType), vNode))
    end
	if self._closed then
		error(Exception.new("namespace closed, can't create key="..tostring(vKeyType), vNode))
	end
	local refer = self._manager:Reference(tostring(vKeyType))
	refer:pushReferNode(vNode)
	self._key2type[vKeyType] = refer
	do return refer
 end end

function Namespace:localSet(vNode, vKeyType, vNewValue)
	if self._closed then
		error(Exception.new("namespace closed, can't create key="..tostring(vKeyType), vNode))
	end
	local rawgetV = self._key2type[vKeyType]
	if rawgetV then
		if Reference.is(rawgetV) then
			rawgetV:setAssignAsync(vNode, function() do return vNewValue  end end)
		else
			error(Exception.new("assign conflict: key="..tostring(vKeyType), vNode))
		end
	else
		if self:parentHasKey(vKeyType) then
            error(Exception.new("'let' shadow set key="..tostring(vKeyType), vNode))
		end
		local nAssignSpace = SpaceTable.checkSpace(vNewValue)
		if nAssignSpace then
			nAssignSpace:trySetKey(tostring(vKeyType))
			self._key2type[vKeyType] = vNewValue  
		elseif SpaceBuiltin.is(vNewValue) then
            error(Exception.new("space-builtin function can't assign between space"..tostring(vKeyType), vNode))
		else
			local refer = self._manager:Reference(tostring(vKeyType))
			refer:setAssignAsync(vNode, function() do return vNewValue  end end)
			self._key2type[vKeyType] = refer
		end
	end
end

function Namespace:trySetKey(vKey)
	if not self._key then
		self._key = vKey
	end
end

function Namespace:close()
	self._closed=true
end

function Namespace:spaceTablePutCompletion(vSpaceTable, vCompletion)
    local nWhat = getmetatable(vSpaceTable).__what
	if nWhat ~= "_G" then
		self:putCompletion(vCompletion)
	end
end

function Namespace:putCompletion(vCompletion)
	for k,v in pairs(self._key2type) do
		if StringLiteral.is(k) then
			vCompletion:putSpaceField(k:getLiteral(), v)
		end
	::continue:: end
end

function Namespace:getNode()
	do return self._node
 end end

function Namespace:getGlobalTable()
	do return false
 end end

function Namespace:getLocalTable()
	do return self._localTable
 end end

SpaceTable.checkSpace = function (v)
	local nMeta = getmetatable(v)
	if type(nMeta) == "table" then
		local self = nMeta.__namespace
		if Namespace.is(self) then
			do return self
		 end end
	end
	do return nil
 end end

do return Namespace
 end 
end end
--thlua.refer.Namespace end ==========)

--thlua.refer.Reference begin ==========(
do local _ENV = _ENV
packages['thlua.refer.Reference'] = function (...)

local Exception = require "thlua.Exception"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Node = require "thlua.code.Node"

local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local BaseUnionType = require "thlua.type.union.BaseUnionType"

local AsyncUnion = require "thlua.refer.AsyncUnion"

local TypeReferCom = require "thlua.refer.TypeReferCom"
local TemplateReferCom = require "thlua.refer.TemplateReferCom"

local ScheduleEvent = require "thlua.manager.ScheduleEvent"

local ScheduleTask = require "thlua.manager.ScheduleTask"

local class = require "thlua.class"


	  
	   


local Reference = class ()

Reference.__call=function(self, ...)
	  
	local nNode = Node.newDebugNode()
	local nArgList = self._manager:getDirtyProcessor():easyToTypeList(nNode, ...)
	local nKey = self._manager:signTemplateArgs(nArgList)
	local nCom = self._com
	if TemplateReferCom.is(nCom) then
		do return nCom:call(nNode, nKey, nArgList)
	 end elseif nCom then
		error(Exception.new("template reference expected here", nNode))
	end
	local nDict = self._callDict
	local nRefer = nDict[nKey]
	if not nRefer then
		nRefer = self._manager:Reference(false)
		nRefer:setAssignAsync(nNode, function()
			local nCom = self:waitTemplateCom()
			do return nCom:call(nNode, nKey, nArgList)
		 end end)
		nDict[nKey] = nRefer
	end
	do return nRefer
 end end

function Reference.__tostring(self)
	do return self:detailString({}, false)
 end end

function Reference.__bor(vLeft, vRight)
	do return vLeft._manager:checkedUnion(vLeft, vRight)
 end end

function Reference.__band(vLeft, vRight)
	local nTypeOrFalse = vLeft:safeIntersect(vRight)
	if nTypeOrFalse then
		do return nTypeOrFalse
	 end else
		error("unexpected intersect")
	end
end

function Reference:ctor(vManager, vKeyOrFalse)
	local nTask = vManager:getScheduleManager():newTask()
	self._manager = vManager
	self._task = nTask
	self._key=vKeyOrFalse
	self._callDict={} 
	self._assignNode=false
	self._referNodes={}
	self.id=vManager:genTypeId()
	self.bits=false
	self._assignComEvent = nTask:makeEvent()
	self._com=false
end

function Reference:getKey()
	do return self._key
 end end

function Reference:detailString(v, vVerbose)
	local nCom = self._com
	if not nCom then
		do return "Reference("..(tostring(self._key) or tostring(self._assignNode))..")"
	 end else
		if TypeReferCom.is(nCom) then
			do return "TypeReference("..tostring(nCom:getTypeNowait())..")"
		 end else
			do return "TemplateReference("..(tostring(self._key) or tostring(self._assignNode))..")"
		 end end
	end
end

function Reference:getComNowait()
	do return self._com
 end end

function Reference:getComAwait()
	if not self._com then
		self._assignComEvent:wait()
	end
	local nCom = assert(self._com, "com not setted after wait finish")
	do return nCom
 end end

function Reference:waitTypeCom()
	local nCom = self:getComAwait()
	assert(TypeReferCom.is(nCom), "type reference expected, but get template reference")
	do return nCom
 end end

function Reference:waitTemplateCom()
	local nCom = self:getComAwait()
	assert(TemplateReferCom.is(nCom), "template reference expected, but get some other reference")
	do return nCom
 end end

function Reference:_setComAndWakeup(vCom)
	self._com = vCom
	self._assignComEvent:wakeup()
end

function Reference:setAssignAsync(vNode, vGetFunc)
	assert(not self._assignNode, Exception.new("refer has been setted:"..tostring(self), vNode))
	self._assignNode = vNode
	self._task:runAsync(function()
		local nAssignValue = vGetFunc()
		if Reference.is(nAssignValue) then
			local nCom = nAssignValue:getComAwait()
			self:_setComAndWakeup(nCom)
		elseif BaseAtomType.is(nAssignValue) then
			local nCom = TypeReferCom.new(self._manager, self._task, nAssignValue)
			self:_setComAndWakeup(nCom)
		elseif BaseUnionType.is(nAssignValue) then
			local nCom = TypeReferCom.new(self._manager, self._task, nAssignValue)
			self:_setComAndWakeup(nCom)
		else
			error("namespace assign a non-type value")
		end
	end)
end

function Reference:setTemplateAsync(vNode, vFunc, vParNum)
	assert(not self._assignNode, Exception.new("refer has been setted:"..tostring(self), vNode))
	self._assignNode = vNode
	local nCom = TemplateReferCom.new(self._manager, self, vFunc, vParNum)
	self._task:runAsync(function()
		self:_setComAndWakeup(nCom)
	end)
end

function Reference:setUnionAsync(
	vNode,
	vGetList 
)
	assert(not self._assignNode, Exception.new("refer has been setted:"..tostring(self), vNode))
	self._assignNode = vNode
	local nAsyncUnion = self._manager:AsyncUnion(self._task)
	self._task:runAsync(function()
		nAsyncUnion:setAtomList(vGetList())
	end)
	local nCom = TypeReferCom.new(self._manager, self._task, nAsyncUnion)
	self:_setComAndWakeup(nCom)
end

function Reference:getAssignNode()
	do return self._assignNode
 end end

function Reference:getReferNode()
	do return self._referNodes
 end end

function Reference:pushReferNode(vNode)
	local nNodes = self._referNodes
	nNodes[#nNodes + 1] = vNode
end

function Reference:checkAtomUnion()
	do return self:waitTypeCom():getTypeAwait()
 end end

function Reference:isReference()
	do return true
 end end

function Reference:foreachAwait(vFunc)
	local nResultType = self:waitTypeCom():getTypeNowait()
	if not nResultType:isAsync() then
		nResultType:foreach(vFunc)
	else
		local nListType = nResultType:getListAwait()
		for _, v in ipairs(nListType) do
			vFunc(v)
		::continue:: end
	end
end

function Reference:intersectAtom(vRightType)
	local nType = self:checkAtomUnion()
	do return nType:intersectAtom(vRightType)
 end end

function Reference:includeAtom(vRightType)
	local nType = self:checkAtomUnion()
	do return nType:includeAtom(vRightType)
 end end

function Reference:assumeIntersectSome(vAssumeSet, vRight)
	local nResultType = self:waitTypeCom():getTypeNowait()
	if not nResultType:isAsync() then
		do return nResultType:assumeIntersectSome(vAssumeSet, vRight)
	 end else
		local nSomeIntersect = false
		local nTypeList = nResultType:getListAwait()
		vRight:foreachAwait(function(vAtomType)
			if nSomeIntersect then
				do return
			 end end
			local nCurIntersect = false
			for _, nType in ipairs(nTypeList) do
				if nType:assumeIntersectAtom(vAssumeSet, vAtomType) then
					nCurIntersect = true
					break
				end
			::continue:: end
			if nCurIntersect then
				nSomeIntersect = true
			end
		end)
		do return nSomeIntersect
	 end end
end

function Reference:assumeIncludeAll(vAssumeSet, vRight, vSelfType)
	local nResultType = self:waitTypeCom():getTypeNowait()
	if not nResultType:isAsync() then
		do return nResultType:assumeIncludeAll(vAssumeSet, vRight, vSelfType)
	 end else
		local nAllInclude = true
		local nTypeList = nResultType:getListAwait()
		vRight:foreachAwait(function(vAtomType)
			if not nAllInclude then
				do return
			 end end
			local nCurInclude = false
			for _, nType in ipairs(nTypeList) do
				if nType:assumeIncludeAtom(vAssumeSet, vAtomType, vSelfType) then
					nCurInclude = true
					break
				end
			::continue:: end
			if not nCurInclude then
				nAllInclude = false
			end
		end)
		do return nAllInclude
	 end end
end

function Reference:unionSign()
	do return tostring(self.id)
 end end

function Reference:safeIntersect(vRight)
	do return self:checkAtomUnion():safeIntersect(vRight)
 end end

function Reference:includeAll(vRight)
	do return self:assumeIncludeAll(nil, vRight)
 end end

function Reference:intersectSome(vRight)
	do return self:assumeIntersectSome(nil, vRight)
 end end

function Reference:mayRecursive()
	local nTypeCom = self:waitTypeCom()
	local nResultType = nTypeCom:getTypeNowait()
	if nResultType:isAsync() then
		do return nResultType:getMayRecursive()
	 end else
		do return nResultType:mayRecursive()
	 end end
end

do return Reference
 end 
end end
--thlua.refer.Reference end ==========)

--thlua.refer.SpaceBuiltin begin ==========(
do local _ENV = _ENV
packages['thlua.refer.SpaceBuiltin'] = function (...)

local Node = require "thlua.code.Node"
local class = require "thlua.class"

  

local SpaceBuiltin = {}
SpaceBuiltin.__index = SpaceBuiltin
SpaceBuiltin.__tostring=function(self)
    do return "BuiltinFn-"..self._name
 end end
SpaceBuiltin.__call=function(self, ...)
    do return self._func(Node.newDebugNode(), ...)
 end end

function SpaceBuiltin.new(vFunc, vName)
    do return setmetatable({
        _func=vFunc,
        _name=vName,
    }, SpaceBuiltin)
 end end

function SpaceBuiltin.is(v)
    do return getmetatable(v) == SpaceBuiltin
 end end

do return SpaceBuiltin
 end 
end end
--thlua.refer.SpaceBuiltin end ==========)

--thlua.refer.SpaceTable begin ==========(
do local _ENV = _ENV
packages['thlua.refer.SpaceTable'] = function (...)

local Reference = require "thlua.refer.Reference"
local Exception = require "thlua.Exception"
local Node = require "thlua.code.Node"


	  


local SpaceTable = {}

local function __createBaseTable(vSpace)
	  
	do return setmetatable({}, {
		__index={},
		__tostring=function(_)
			do return tostring(vSpace).."->BaseSpaceTable"
		 end end,
		__what=false ,
		__namespace=vSpace,
	})
 end end

function SpaceTable.createLocalTable(vSpace, vKeyToType )
    do return setmetatable({
    }, {
		__index=function(_,k)
			local nNode = Node.newDebugNode()
			local nKeyType = vSpace:assertSpaceKeyType(nNode, k)
			do return vSpace:localGet(nNode, nKeyType)
		 end end,
		__newindex=function(_,k,newV)
			local nNode = Node.newDebugNode()
			local nKeyType = vSpace:assertSpaceKeyType(nNode, k)
			vSpace:localSet(nNode, nKeyType, newV)
		end,
		__tostring=function(_)
			do return tostring(vSpace).."->SpaceTable"
		 end end,
		__what=false,
		__namespace=vSpace,
    })
 end end

function SpaceTable.createEnvTable(vSpace, vKeyToType )
    do return setmetatable({
    }, {
		__index=function(_,k) 
			local nNode = Node.newDebugNode()
			local nKeyType = vSpace:assertSpaceKeyType(nNode, k)
			do return vSpace:globalGet(nNode, nKeyType)
		 end end,
		__newindex=function(t,k,v)
			local nNode = Node.newDebugNode()
			error(Exception.new("global can't assign", nNode))
		end,
		__tostring=function(_)
			do return tostring(vSpace).."-_ENV"
		 end end,
		__what="_ENV",
		__namespace=vSpace,
    })
 end end

function SpaceTable.createGlobalTable(vSelfSpace, vParentSpace)
    local nMeta = vParentSpace:getGlobalTable() or _G
    local self = setmetatable({}, {
        __index=nMeta  ,
        __tostring=function(_)
			do return tostring(vSelfSpace).."-_G"
         end end,
		__what="_G",
        __namespace=vSelfSpace,
    })
    do return self
 end end

do return SpaceTable end 
end end
--thlua.refer.SpaceTable end ==========)

--thlua.refer.TemplateReferCom begin ==========(
do local _ENV = _ENV
packages['thlua.refer.TemplateReferCom'] = function (...)

local Exception = require "thlua.Exception"

  

local TemplateReferCom = {}
TemplateReferCom.__index = TemplateReferCom

function TemplateReferCom.new(
	vManager,
	vRefer,
	vFunc,
	vParNum
)
	local self = setmetatable({
		_manager=vManager,
		_refer=vRefer,
		_parNum=vParNum,
		_func=vFunc,
		_cache={} ,
	}, TemplateReferCom)
	do return self
 end end

function TemplateReferCom:call(vNode, vKey, vArgList)
	local nFn = self._func
	local nRefer = self._cache[vKey]
	if not nRefer then
		nRefer = self._manager:Reference(false)
		nRefer:setAssignAsync(vNode, function()
			if #vArgList ~= self._parNum then
				error(Exception.new("template args num not match", vNode))
			end
			do return nFn(table.unpack(vArgList))
		 end end)
		self._cache[vKey] = nRefer
	end
	do return nRefer
 end end

function TemplateReferCom.is(self)
	do return getmetatable(self) == TemplateReferCom
 end end

do return TemplateReferCom
 end 
end end
--thlua.refer.TemplateReferCom end ==========)

--thlua.refer.TypeReferCom begin ==========(
do local _ENV = _ENV
packages['thlua.refer.TypeReferCom'] = function (...)


local AsyncUnion = require "thlua.refer.AsyncUnion"
local Exception = require "thlua.Exception"

  

local TypeReferCom = {}
TypeReferCom.__index = TypeReferCom

function TypeReferCom.new(
	vManager,
	vTask,
	vAssignType 
)
	local nIsAsync = AsyncUnion.is(vAssignType)
	local self = setmetatable({
        _manager=vManager,
        _task=vTask,
		_asyncType=nIsAsync and vAssignType or false,
		_readyType=(not nIsAsync) and vAssignType or false,
	}, TypeReferCom)
	do return self
 end end

function TypeReferCom:getTypeNowait() 
	do return assert(self._readyType or self._asyncType)
 end end

function TypeReferCom:getTypeAwait()
	local nReadyType = self._readyType
	if not nReadyType then
		nReadyType = assert(self._asyncType):getTypeAwait()
		self._readyType = nReadyType
	end
	do return nReadyType
 end end

function TypeReferCom.is(self)
	do return getmetatable(self) == TypeReferCom
 end end

do return TypeReferCom
 end 
end end
--thlua.refer.TypeReferCom end ==========)

--thlua.runtime.BaseRuntime begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.BaseRuntime'] = function (...)

local TypedFunction = require "thlua.type.func.TypedFunction"
local TypeManager = require "thlua.manager.TypeManager"
local OpenFunction = require "thlua.type.func.OpenFunction"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local TermTuple = require "thlua.tuple.TermTuple"
local native = require "thlua.native"
local Node = require "thlua.code.Node"
local Namespace = require "thlua.refer.Namespace"
local Letspace = require "thlua.refer.Letspace"
local Exception = require "thlua.Exception"
local VariableCase = require "thlua.term.VariableCase"
local SpaceBuiltin = require "thlua.refer.SpaceBuiltin"

local BaseStack = require "thlua.runtime.BaseStack"
local OpenStack = require "thlua.runtime.OpenStack"
local SealStack = require "thlua.runtime.SealStack"
local AutoFunction = require "thlua.type.func.AutoFunction"

local ScheduleManager = require "thlua.manager.ScheduleManager"
local class = require "thlua.class"
local CodeEnv = require "thlua.code.CodeEnv"


	  
	  

	   
		  
		 
		  
	

	   
		
		
		
	

	   
		
		
		
		
		
	



local DefaultLoader = {
	thluaSearch=function(vRuntime, vPath)
		local fileName, err1 = package.searchpath(vPath, vRuntime:getSearchPath() or "./?.thlua;./?.d.thlua")
		if not fileName then
			do return false, err1
		 end end
		do return true, fileName
	 end end,
	thluaParseFile=function(vRuntime, vFileName)
		local file, err = io.open(vFileName, "r")
		if not file then
			error(err)
		end
		local nContent = assert(file:read("*a"), "file "..vFileName.. " read fail")
		file:close()
		local nCodeEnv = CodeEnv.new(nContent, vFileName)
		do return nCodeEnv
	 end end,
	thluaGlobalFile=function(vRuntime, vPackage)
		local nContent = require("thlua.global."..vPackage)
		local nFileName = "@virtual-file:"..vPackage
		local nCodeEnv = CodeEnv.new(nContent, "@virtual-file:"..vPackage)
		do return nCodeEnv, nFileName
	 end end
}

local BaseRuntime = class ()

function BaseRuntime:ctor(vLoader)
	self._searchPath = false  
	self._loader=vLoader or DefaultLoader
	self._pathToFileName={} 
	self._loadedDict={} 
	self._scheduleManager=ScheduleManager.new()
	   
	self._node=nil
	self._manager=nil
	self._globalTable=nil
	self._rootStack=nil
end

function BaseRuntime:getCodeEnv(vFileName)
	local nState = self._loadedDict[vFileName]
	if nState then
		do return nState.codeEnv
	 end else
		do return false
	 end end
end

function BaseRuntime:import(vDst)
	   
	if type(vDst) == "string" then
		local nPath = vDst  
		local nNode = Node.newDebugNode()
		local nLoadedState = self:_cacheLoadPath(Node.newDebugNode(), nPath)
		local nStack = nLoadedState.stack
		if not nStack then
			error(Exception.new("recursive import:"..nPath, nNode))
		end
		local nSpace = nStack:getNamespace()
		do return nSpace:getLocalTable()
	 end elseif BaseAtomType.is(vDst) then
		local nStack = vDst:findRequireStack()
		if nStack then
			local nSpace = nStack:getNamespace()
			do return nSpace:getLocalTable()
		 end else
			error("import can only take type in a require stack"..debug.traceback())
		end
	else
		error("import can only take string or type as first argument")
	end
end

local nGlobalPackage = {
	"basic",
	"coroutine",
	"debug",
	"io",
	"math",
	"os",
	"package",
	"string",
	"table",
	"utf8",
}

function BaseRuntime:pmain(vRootFileUri)  
	self._node=Node.newRootNode(vRootFileUri)
	self._manager=TypeManager.new(self, self._node, self._scheduleManager)
	local nAutoFn = AutoFunction.new(self._manager, self._node, false)
	local nRootStack = nAutoFn:getBuildStack()
	self._rootStack = nRootStack
	self._manager:lateInit()
	self._globalTable = native.make(self)
	nRootStack:rootSetNamespace(self:RootNamespace())
	local t1 = os.clock()
	local ok, err = pcall(function()
		nAutoFn:initAsync(function()
			for _, pkg in ipairs(nGlobalPackage) do
				local nLoadedState = self:_cacheLoadGlobal(pkg)
				if pkg == "string" then
					local nRetType = nLoadedState.term:getType()
					assert(not nRetType:isUnion(), "string lib's return can't be union")
					self._manager:lateInitStringLib(nRetType)
				end
			::continue:: end
			do return false, false, function()
				local nLoadedState = self:_cacheLoadFile(self._node, vRootFileUri)
				local nParTuple = self._manager:TypeTuple(self._node, {})
				local nRetTuples = self._manager:VoidRetTuples(self._node)
				do return nParTuple, nRetTuples
			 end end
		 end end)
		nAutoFn:startPreBuild()
		nAutoFn:startLateBuild()
	end)
	if not ok then
		if Exception.is(err) then
			self:nodeError(err.node, err.msg)
		else
			self:nodeError(self._node, err)
		end
	end
	local t2 = os.clock()
	print(t2-t1)
	 
	do return ok, err
 end end

function BaseRuntime:lateSchedule(vAutoFn)
	error("implement lateSchedule function in extends class")
end

function BaseRuntime:recordBranch(vNode, vBranch)
	 
end

function BaseRuntime:recordApplyContext(vNode, vContext)
	 
end

function BaseRuntime:SealStack(...)
	do return SealStack.new(self, ...)
 end end

function BaseRuntime:OpenStack(...)
	do return OpenStack.new(self, ...)
 end end

function BaseRuntime:_cacheLoadGlobal(vPkg)
	local nCodeEnv, nFileName = self._loader.thluaGlobalFile(self, vPkg)
	local nOpenFn = nCodeEnv:getTypingFn()(nCodeEnv:getNodeList(), self._rootStack, self:makeGlobalTerm())
	local nContext = self._rootStack:newNoPushContext(self._node)
	local nTermTuple = nContext:FixedTermTuple({})
	local nRet, nStack = nOpenFn:meta_open_call(nContext, nTermTuple, true)
	local nLoadedState = {
		openFn=nOpenFn,
		codeEnv=nCodeEnv,
		term = TermTuple.is(nRet) and nRet:checkFixed(nContext, 1) or nRet:checkRefineTerm(nContext),
		stack = nStack,
	}
	self._loadedDict[nFileName] = nLoadedState
	do return nLoadedState
 end end

function BaseRuntime:_cacheLoadFile(vNode, vFileName)
	local nLoadedState = self._loadedDict[vFileName]
	if not nLoadedState then
		local nCodeEnv = self._loader.thluaParseFile(self, vFileName)
		local nOpenFn = nCodeEnv:getTypingFn()(nCodeEnv:getNodeList(), self._rootStack, self:makeGlobalTerm())
		nLoadedState = {
			openFn=nOpenFn,
			codeEnv=nCodeEnv,
		}
		self._loadedDict[vFileName] = nLoadedState
		local nContext = self._rootStack:newNoPushContext(vNode)
		local nTermTuple = nContext:FixedTermTuple({})
		local nRet, nStack = nOpenFn:meta_open_call(nContext, nTermTuple, true)
		nLoadedState.term = TermTuple.is(nRet) and nRet:checkFixed(nContext, 1) or nRet:checkRefineTerm(nContext)
		nLoadedState.stack = nStack
	end
	do return nLoadedState
 end end

function BaseRuntime:_cacheLoadPath(vNode, vPath)
	local nFileName = self._pathToFileName[vPath]
	if not nFileName then
		local nOkay, nSearchFileName = self._loader.thluaSearch(self, vPath)
		if not nOkay then
			error(Exception.new(nSearchFileName, vNode))
		else
			nFileName = nSearchFileName
		end
	end
	local nLoadedState = self._loadedDict[nFileName] or self:_cacheLoadFile(vNode, nFileName)
	local nOldPath = nLoadedState.path
	if nOldPath and nOldPath ~= vPath then
		self:nodeWarn(vNode, "mixing path:'"..nOldPath.."','"..vPath.."'")
	end
	nLoadedState.path = vPath
	do return nLoadedState
 end end

function BaseRuntime:require(vNode, vPath) 
	local nLoadedState = self:_cacheLoadPath(vNode, vPath)
	local nTerm = nLoadedState.term
	if not nTerm then
		error(Exception.new("recursive require:"..vPath, vNode))
	end
	do return nTerm, nLoadedState.openFn
 end end

function BaseRuntime:TreeNamespace(vNode)
	local nSpace = Namespace.new(self._manager, vNode)
	do return nSpace
 end end

function BaseRuntime:buildSimpleGlobal() 
	local nGlobal = {}
	for k,v in pairs(self._manager.type) do
		nGlobal[k] = v
	::continue:: end
	for k,v in pairs(self._manager.generic) do
		nGlobal[k] = v
	::continue:: end
	local l = {
		Enum="buildEnum",
		Union="buildUnion",
		Struct="buildStruct",
		Interface="buildInterface",
		ExtendInterface="buildExtendInterface",
		ExtendStruct="buildExtendStruct",
		Template="buildTemplate",
		
		
		
		
		OrNil="buildOrNil",
		OrFalse="buildOrFalse",
		Fn="buildFn",
		Pfn="buildPfn",
		Mfn="buildMfn",
	}
	local nManager = self._manager
	for k,v in pairs(l) do
		nGlobal[k]=SpaceBuiltin.new(function(vNode, ...)
			do return nManager[v](nManager, vNode, ...)
		 end end, k)
	::continue:: end
	nGlobal.Literal=SpaceBuiltin.new(function(vNode, v)
		do return nManager:Literal(v)
	 end end, "Literal")
	nGlobal.enum=SpaceBuiltin.new(function(vNode, vEnumType, ...)
		do return nManager:addEnum(vNode, vEnumType, ...)
	 end end, "enum")
	nGlobal.namespace=SpaceBuiltin.new(function(vNode)
		do return self:TreeNamespace(vNode):getLocalTable()
	 end end, "namespace")
	nGlobal.lock=SpaceBuiltin.new(function(vNode, vType)
		vType:foreach(function(vAtom)
			vAtom:setLocked()
		end)
	end, "lock")
	nGlobal.import=SpaceBuiltin.new(function(vNode, vPath)
		do return self:import(vPath)
	 end end, "import")
	nGlobal.setPath=SpaceBuiltin.new(function(vNode, vPath)
		self._searchPath = vPath
	end, "setPath")
	nGlobal.foreachPair=SpaceBuiltin.new(function(vNode, vObject, vFunc)
		local vObject = vObject:checkAtomUnion()
		local d = vObject:copyValueDict(vObject)
		for k,v in pairs(d) do
			vFunc(k,v)
		::continue:: end
	end, "foreachPair")
	nGlobal.literal=SpaceBuiltin.new(function(vNode, vType)
		vType = vType:checkAtomUnion()
		if vType:isUnion() then
			do return nil
		 end else
			if self._manager:isLiteral(vType) then
				do return vType:getLiteral()
			 end else
				do return nil
			 end end
		end
	end, "literal")
	nGlobal.same=SpaceBuiltin.new(function(vNode, vType1, vType2)
		do return vType1:includeAll(vType2) and vType2:includeAll(vType1) and true or false
	 end end, "same")
	nGlobal.print=SpaceBuiltin.new(function(vNode, ...)
		self:nodeInfo(vNode, ...)
	end, "print")
	local nRetGlobal = {}
	for k,v in pairs(nGlobal) do
		nRetGlobal[self._manager:Literal(k)] = v
	::continue:: end
	do return nRetGlobal
 end end

function BaseRuntime:RootNamespace()
	local nSpace = Namespace.new(self._manager, self._node, self:buildSimpleGlobal())
	nSpace:trySetKey("")
	nSpace:close()
	do return nSpace
 end end

function BaseRuntime:LetNamespace(vParentLet, vRegionNode)
	local nSpace = Letspace.new(self._manager, vRegionNode, nil, vParentLet)
	nSpace:trySetKey("")
	do return nSpace
 end end

function BaseRuntime:makeGlobalTerm()
	local nHeadContext = self._rootStack:inplaceOper()
	do return nHeadContext:RefineTerm(self._globalTable)
 end end

function BaseRuntime:_save(vSeverity, vNode, ...)
	 
end

function BaseRuntime:stackNodeError(vStack, vNode, ...)
	print("[ERROR] "..tostring(vNode), ...)
	self:_save(1, vNode, ...)
	local nPrefix = "(open)"
	while OpenStack.is(vStack) do
		local nStackNode = vStack:getNode()
		if nStackNode ~= vNode and not vStack:isRequire() then
			print("[ERROR] "..tostring(nStackNode), nPrefix, ...)
			self:_save(1, nStackNode, nPrefix, ...)
		end
		vStack = vStack:getApplyStack()
	::continue:: end
end

function BaseRuntime:nodeError(vNode, ...)
	print("[ERROR] "..tostring(vNode), ...)
	self:_save(1, vNode, ...)
end

function BaseRuntime:nodeWarn(vNode, ...)
	print("[WARN] "..tostring(vNode), ...)
	self:_save(2, vNode, ...)
end

function BaseRuntime:nodeInfo(vNode, ...)
	print("[INFO] "..tostring(vNode), ...)
	self:_save(3, vNode, ...)
end

function BaseRuntime:getNode()
	do return self._node
 end end

function BaseRuntime:makeException(vNode, vMsg)
	do return Exception.new(vMsg, vNode)
 end end

function BaseRuntime:getTypeManager()
	do return self._manager
 end end

function BaseRuntime:getScheduleManager()
	do return self._scheduleManager
 end end

function BaseRuntime:getRootStack()
	do return self._rootStack
 end end

function BaseRuntime:getSearchPath()
	do return self._searchPath
 end end

do return BaseRuntime
 end 
end end
--thlua.runtime.BaseRuntime end ==========)

--thlua.runtime.BaseStack begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.BaseStack'] = function (...)

local OpenTable = require "thlua.type.object.OpenTable"
local DoBuilder = require "thlua.builder.DoBuilder"
local Branch = require "thlua.runtime.Branch"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"
local AutoHolder = require "thlua.auto.AutoHolder"
local AutoFlag = require "thlua.auto.AutoFlag"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"
local Reference = require "thlua.refer.Reference"
local Node = require "thlua.code.Node"
local LocalSymbol = require "thlua.term.LocalSymbol"
local ImmutVariable = require "thlua.term.ImmutVariable"

local ClassFactory = require "thlua.type.func.ClassFactory"
local AutoFunction = require "thlua.type.func.AutoFunction"
local OpenFunction = require "thlua.type.func.OpenFunction"
local BaseFunction = require "thlua.type.func.BaseFunction"
local TypedObject = require "thlua.type.object.TypedObject"
local Truth = require "thlua.type.basic.Truth"

local FunctionBuilder = require "thlua.builder.FunctionBuilder"
local TableBuilder = require "thlua.builder.TableBuilder"
local class = require "thlua.class"

local OperContext = require "thlua.context.OperContext"
local ApplyContext = require "thlua.context.ApplyContext"
local ReturnContext = require "thlua.context.ReturnContext"
local AssignContext = require "thlua.context.AssignContext"
local MorePushContext = require "thlua.context.MorePushContext"
local OnePushContext = require "thlua.context.OnePushContext"
local NoPushContext = require "thlua.context.NoPushContext"
local LogicContext = require "thlua.context.LogicContext"


	  
	  

	   
		
		
	


local BaseStack = class ()

function BaseStack:ctor(
	vRuntime,
	vNode,
	vUpState,
	...
)
	local nManager = vRuntime:getTypeManager()
	self._runtime=vRuntime
	self._manager=nManager
	self._node=vNode
	self._letspace=false
	self._headContext=AssignContext.new(vNode, self, nManager)
	self._fastOper=OperContext.new(vNode, self, nManager)
	self._lexCapture = vUpState
	local nTempBranch = Branch.new(self, vUpState and vUpState.uvCase or VariableCase.new(), vUpState and vUpState.branch or false)
	self._branchStack={nTempBranch}
	self._bodyFn=nil
	self._retList={}  
end

function BaseStack:RAISE_ERROR(vContext, vType)
	error("check error in OpenStack or SealStack")
end

function BaseStack:anyNodeMetaGet(vNode, vSelfTerm, vKeyTerm, vNotnil)
	do return self:withOnePushContext(vNode, function(vContext)
		vSelfTerm:foreach(function(vSelfType, vVariableCase)
			vKeyTerm:foreach(function(vKeyType, vKeyVariableCase)
				vContext:withCase(vVariableCase & vKeyVariableCase, function()
					if not vSelfType:meta_get(vContext, vKeyType) then
						if not OpenTable.is(vSelfType) then
							vContext:error("index error, key="..tostring(vKeyType))
						end
					end
				end)
			end)
		end)
	end, vNotnil):mergeFirst()
 end end

function BaseStack:prepareMetaCall(
	vNode,
	vFuncTerm,
	vLazyFunc
)
	local nNil = self._manager.type.Nil
	do return self:withMorePushContextWithCase(vNode, vFuncTerm, function(vContext, vFuncType, vCase)
		local nArgTermTuple = nil
		self:_withBranch(vCase, function()
			nArgTermTuple = vLazyFunc()
		end)
		if vFuncType == nNil then
			vContext:error("nil as call func")
		elseif BaseFunction.is(vFuncType) or Truth.is(vFuncType) then
			vFuncType:meta_call(vContext, assert(nArgTermTuple))
		else
			vContext:error("TODO call by a non-function value, type="..tostring(vFuncType))
		end
	end)
 end end

   
	      
		  
			 
		
			  
			
			  
		
	 
	   
		
	
	  


function BaseStack:getClassTable()
	do return self:getSealStack():getClassTable()
 end end

function BaseStack:newAutoFunction(vNode , ...)
	local nAutoFn = AutoFunction.new(self._manager, vNode, ...)
	do return nAutoFn
 end end

function BaseStack:newClassFactory(vNode, ...)
	local nFactory = ClassFactory.new(self._manager, vNode, ...)
	do return nFactory
 end end

function BaseStack:newOpenFunction(vNode, vUpState )
	local nOpenFn = OpenFunction.new(self._manager, vNode, vUpState)
	do return nOpenFn
 end end

function BaseStack:withOnePushContext(vNode, vFunc, vNotnil)
	local nCtx = OnePushContext.new(vNode, self, self._manager, vNotnil or false)
	vFunc(nCtx)
	do return nCtx
 end end

function BaseStack:withMorePushContext(vNode, vFunc)
	local nCtx = MorePushContext.new(vNode, self, self._manager)
	vFunc(nCtx)
	do return nCtx
 end end

function BaseStack:withMorePushContextWithCase(vNode, vTermOrTuple , vFunc  )
	local nCtx = MorePushContext.new(vNode, self, self._manager)
	local nTerm = TermTuple.isFixed(vTermOrTuple) and vTermOrTuple:checkFixed(nCtx, 1) or vTermOrTuple
	nTerm:foreach(function(vType, vCase)
		nCtx:withCase(vCase, function()
			vFunc(nCtx, vType, vCase)
		end)
	end)
	do return nCtx
 end end

function BaseStack:newNoPushContext(vNode)
	do return NoPushContext.new(vNode, self, self._manager)
 end end

function BaseStack:newLogicContext(vNode)
	do return LogicContext.new(vNode, self, self._manager)
 end end

function BaseStack:newOperContext(vNode)
	do return OperContext.new(vNode, self, self._manager)
 end end

function BaseStack:newReturnContext(vNode)
	do return ReturnContext.new(vNode, self, self._manager)
 end end

function BaseStack:newAssignContext(vNode)
	do return AssignContext.new(vNode, self, self._manager)
 end end

function BaseStack:getSealStack()
	error("getSealStack not implement in BaseStack")
end

function BaseStack:seal()
end

function BaseStack:_nodeTerm(vNode, vType)
	do return RefineTerm.new(vNode, vType:checkAtomUnion())
 end end

function BaseStack:inplaceOper()
	do return self._fastOper
 end end

function BaseStack:getNamespace()
	local nSpace = self._letspace
	do return assert(nSpace, "space is false when get")
 end end

function BaseStack:getNode()
	do return self._node
 end end

function BaseStack:getRuntime()
	do return self._runtime
 end end

function BaseStack:getTypeManager()
	do return self._manager
 end end

function BaseStack:_withBranch(vVariableCase, vFunc, vNode)
	local nStack = self._branchStack
	local nLen = #nStack
	local nNewLen = nLen + 1
	local nOldBranch = nStack[nLen]
	local nNewBranch = Branch.new(self, vVariableCase & nOldBranch:getCase(), nOldBranch, vNode)
	nStack[nNewLen] = nNewBranch
	vFunc()
	nStack[nNewLen] = nil
	do return nNewBranch
 end end

function BaseStack:topBranch()
	local nStack = self._branchStack
	do return nStack[#nStack]
 end end

function BaseStack:nativeError(vContext, vTerm)
	self:RAISE_ERROR(vContext, vTerm:getType())
	self:topBranch():setStop()
end

function BaseStack:nativeAssert(vContext, vFirstTerm, vSecondTerm)
	if vSecondTerm then
		self:RAISE_ERROR(vContext, vSecondTerm:getType())
	end
	local nTrueCase = vFirstTerm:caseTrue()
	if nTrueCase then
		self:topBranch():assertCase(nTrueCase)
	end
end

function BaseStack:findRequireStack()
	do return false
 end end

do return BaseStack
 end 
end end
--thlua.runtime.BaseStack end ==========)

--thlua.runtime.Branch begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.Branch'] = function (...)

local ImmutVariable = require "thlua.term.ImmutVariable"
local LocalSymbol = require "thlua.term.LocalSymbol"
local VariableCase = require "thlua.term.VariableCase"
local RefineTerm = require "thlua.term.RefineTerm"

local Branch = {}


	  
	  


Branch.__index = Branch
Branch.__tostring = function(self)
	do return "Branch@"..tostring(self._node)
 end end

function Branch.new(vStack, vVariableCase, vPreBranch, vNode)
	   
	   
	local self = setmetatable({
		_stack=vStack,
		_node=vNode or false,
		_stop=false,
		_nodeToSymbol={},
		symbolToVariable={},
		_curCase=vVariableCase,     
		_headCase=vVariableCase,      
	}, Branch)
	if vPreBranch then
		if vPreBranch:getStack() == vStack then
			self.symbolToVariable = (setmetatable({}, {__index=vPreBranch.symbolToVariable}) ) 
		end
		self._nodeToSymbol = setmetatable({}, {__index=vPreBranch._nodeToSymbol})
	end
	if vNode then
		assert(vNode.tag == "Block")
		vStack:getRuntime():recordBranch(vNode, self)
	end
	do return self
 end end

function Branch:immutGet(vContext, vImmutVariable, vNotnil)
	local nTerm = vImmutVariable:filterTerm(vContext, self._curCase)
	if vNotnil then
		do return nTerm:notnilTerm()
	 end else
		do return nTerm
	 end end
end

function Branch:mutGet(vContext, vLocalSymbol, vNotnil)
	local nImmutVariable = self.symbolToVariable[vLocalSymbol]
	if not nImmutVariable then
		    
		nImmutVariable = vLocalSymbol:makeVariable()
		self.symbolToVariable[vLocalSymbol] = nImmutVariable
	end
	do return self:immutGet(vContext, nImmutVariable, vNotnil)
 end end

function Branch:SYMBOL_GET(vNode, vDefineNode, vAllowAuto)
	local nSymbolContext = self._stack:newOperContext(vNode)
	local nSymbol = self:getSymbolByNode(vDefineNode)
	if LocalSymbol.is(nSymbol) then
		do return self:mutGet(nSymbolContext, nSymbol, vNode.notnil or false)
	 end elseif ImmutVariable.is(nSymbol) then
		do return self:immutGet(nSymbolContext, nSymbol, vNode.notnil or false)
	 end else
		    
		local nTerm = nSymbol:getRefineTerm()
		if nTerm then
			do return self:immutGet(nSymbolContext, nTerm:attachImmutVariable(), vNode.notnil or false)
		 end else
			if not vAllowAuto then
				error(nSymbolContext:newException("auto term can't be used when it's undeduced:"..tostring(nSymbol)))
			else
				if vNode.notnil then
					error(nSymbolContext:newException("auto term can't take notnil cast "..tostring(nSymbol)))
				end
				do return nSymbol
			 end end
		end
	end
end

function Branch:setSymbolByNode(vNode, vSymbol)
	self._nodeToSymbol[vNode] = vSymbol
	do return vSymbol
 end end

function Branch:getSymbolByNode(vNode)
	do return self._nodeToSymbol[vNode]
 end end

function Branch:mutMark(vSymbol, vImmutVariable)
	self.symbolToVariable[vSymbol] = vImmutVariable
	vImmutVariable:addSymbol(vSymbol)
end

function Branch:mutSet(vContext, vSymbol, vValueTerm)
	local nValueType = vValueTerm:getType()
	local nDstType = vSymbol:getType()
	local nSetType = vContext:includeAndCast(nDstType, nValueType, "assign") or nDstType
	local nCastTerm = vContext:RefineTerm(nSetType)
	local nImmutVariable = nCastTerm:attachImmutVariable()
	self.symbolToVariable[vSymbol] = nImmutVariable
	nImmutVariable:addSymbol(vSymbol)
end

function Branch:mergeOneBranch(vContext, vOneBranch, vOtherCase)
	if vOneBranch:getStop() then
		if vOtherCase then
			self._curCase = self._curCase & vOtherCase
			self._headCase = self._headCase & vOtherCase
		end
	else
		local nSymbolToVariable = self.symbolToVariable
		for nLocalSymbol, nOneVariable in pairs(vOneBranch.symbolToVariable) do
			local nBeforeVariable = nSymbolToVariable[nLocalSymbol]
			if nBeforeVariable then
				local nOneType = vOneBranch:mutGet(vContext, nLocalSymbol, false):getType()
				if not vOtherCase then
					nSymbolToVariable[nLocalSymbol] = nLocalSymbol:makeVariable(nOneType)
				else
					local nOtherType = vOtherCase[nBeforeVariable] or self._curCase[nBeforeVariable] or nBeforeVariable:getType()
					local nMergeType = nOneType | nOtherType
					nSymbolToVariable[nLocalSymbol] = nLocalSymbol:makeVariable(nMergeType)
				end
			end
		::continue:: end
	end
end

function Branch:mergeTwoBranch(vContext, vTrueBranch, vFalseBranch)
	local nTrueStop = vTrueBranch:getStop()
	local nFalseStop = vFalseBranch:getStop()
	if nTrueStop and nFalseStop then
		self._stop = true
		do return
	 end end
	local nModLocalSymbolDict  = {}
	for nLocalSymbol, _ in pairs(vTrueBranch.symbolToVariable) do
		nModLocalSymbolDict[nLocalSymbol] = true
	::continue:: end
	for nLocalSymbol, _ in pairs(vFalseBranch.symbolToVariable) do
		nModLocalSymbolDict[nLocalSymbol] = true
	::continue:: end
	for nLocalSymbol, _ in pairs(nModLocalSymbolDict) do
		if self.symbolToVariable[nLocalSymbol] then
			local nType
			if nFalseStop then
				nType = vTrueBranch:mutGet(vContext, nLocalSymbol, false):getType()
			elseif nTrueStop then
				nType = vFalseBranch:mutGet(vContext, nLocalSymbol, false):getType()
			else
				local nTrueType = vTrueBranch:mutGet(vContext, nLocalSymbol, false):getType()
				local nFalseType = vFalseBranch:mutGet(vContext, nLocalSymbol, false):getType()
				nType = nTrueType | nFalseType
			end
			local nImmutVariable = nLocalSymbol:makeVariable(nType)
			self.symbolToVariable[nLocalSymbol] = nImmutVariable
		end
	::continue:: end
	local nAndCase
	if nFalseStop then
		nAndCase = vTrueBranch._headCase
	elseif nTrueStop then
		nAndCase = vFalseBranch._headCase
	end
	if nAndCase then
		self._curCase = self._curCase & nAndCase
		self._headCase = self._headCase & nAndCase
	end
end

function Branch:assertCase(vVariableCase)
	self._curCase = self._curCase & vVariableCase
	self._headCase = self._headCase & vVariableCase
end

function Branch:setStop()
	self._stop = true
end

function Branch:getCase()
	do return self._curCase
 end end

function Branch:getStop()
	do return self._stop
 end end

function Branch:getStack()
	do return self._stack  
 end end

do return Branch
 end 
end end
--thlua.runtime.Branch end ==========)

--thlua.runtime.CompletionRuntime begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.CompletionRuntime'] = function (...)

local CodeEnv = require "thlua.code.CodeEnv"
local FieldCompletion = require "thlua.context.FieldCompletion"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local BaseRuntime = require "thlua.runtime.BaseRuntime"
local Namespace = require "thlua.refer.Namespace"
local SpaceTable = require "thlua.refer.SpaceTable"
local ListDict = require "thlua.manager.ListDict"
local TypeReference = require "thlua.refer.Reference"
local BaseUnionType = require "thlua.type.union.BaseUnionType"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"


	
	  
	  


local CompletionRuntime = class (BaseRuntime)

function CompletionRuntime:ctor(...)
	self._focusNodeSet = {}   
	self._nodeToAutoFnList = ListDict ()
	self._nodeToBranchList = ListDict ()
	self._nodeToApplyContextList = ListDict ()
end

function CompletionRuntime:lateSchedule(vAutoFn)
	if self._focusNodeSet[vAutoFn:getNode()] then
		vAutoFn:startLateBuild()
	else
		self._nodeToAutoFnList:putOne(vAutoFn:getNode(), vAutoFn)
	end
end

function CompletionRuntime:_save(vSeverity, vNode, ...)
	   
	 
end

function CompletionRuntime:recordBranch(vNode, vBranch)
	self._nodeToBranchList:putOne(vNode, vBranch)
end

function CompletionRuntime:recordApplyContext(vNode, vContext)
	self._nodeToApplyContextList:putOne(vNode, vContext)
end

function CompletionRuntime:focusSchedule(vFuncList)
	    
	local nSet = self._focusNodeSet
	local nAutoFnList = {}
	for _,nNode in pairs(vFuncList) do
		nSet[nNode] = true
		local nList = self._nodeToAutoFnList:pop(nNode)
		if nList then
			for i=1,#nList do
				nAutoFnList[#nAutoFnList + 1] = nList[i]
			::continue:: end
		end
	::continue:: end
	for _, nAutoFn in ipairs(nAutoFnList) do
		nAutoFn:startLateBuild()
	::continue:: end
end

function CompletionRuntime:_injectForeach(vTracePos, vBlockNode, vFn, vCallback  )
	local nBranchList = self._nodeToBranchList:get(vBlockNode)
	if not nBranchList then
		do return
	 end end
	       
	for _, nBranch in pairs(nBranchList) do
		local nStack = nBranch:getStack()
		local nResult = vFn(nStack, function(vIdent)
			    
			local nName = vIdent[1]
			local nDefineIdent = vBlockNode.symbolTable[nName]
			while nDefineIdent and nDefineIdent.pos > vTracePos do
				nDefineIdent = nDefineIdent.lookupIdent
			::continue:: end
			if nDefineIdent then
				local nAutoTerm = nBranch:SYMBOL_GET(vIdent, nDefineIdent, false)
				if RefineTerm.is(nAutoTerm) then
					do return nAutoTerm
				 end else
					do return nStack:NIL_TERM(vIdent)
				 end end
			end
			    
			local nName = "_ENV"
			local nDefineIdent = vBlockNode.symbolTable[nName]
			while nDefineIdent and nDefineIdent.pos > vTracePos do
				nDefineIdent = nDefineIdent.lookupIdent
			::continue:: end
			if nDefineIdent then
				local nEnvTerm = nBranch:SYMBOL_GET(vIdent, nDefineIdent, false)
				assert(RefineTerm.is(nEnvTerm), "auto can't be used here")
				local nAutoTerm = nStack:META_GET(vIdent, nEnvTerm, nStack:LITERAL_TERM(vIdent, vIdent[1]), false)
				if RefineTerm.is(nAutoTerm) then
					do return nAutoTerm
				 end else
					do return nStack:NIL_TERM(vIdent)
				 end end
			else
				do return nStack:NIL_TERM(vIdent)
			 end end
		end)
		if RefineTerm.is(nResult) then
			vCallback(nResult)
		else
			if TypeReference.is(nResult) then
				vCallback(nResult)
			elseif BaseAtomType.is(nResult) or BaseUnionType.is(nResult) then
				vCallback(nResult)
			else
				if SpaceTable.checkSpace(nResult) then
					vCallback(nResult)
				end
			end
		end
	::continue:: end
end

function CompletionRuntime:injectCompletion(vTracePos, vBlockNode, vFn, vServer)
	local nFieldCompletion = FieldCompletion.new()
	self:_injectForeach(vTracePos, vBlockNode, vFn, function(vResult)
		if RefineTerm.is(vResult) then
			vResult:getType():putCompletion(nFieldCompletion)
		else
			local nNamespace = SpaceTable.checkSpace(vResult)
			if nNamespace then
				nNamespace:spaceTablePutCompletion(vResult, nFieldCompletion)
			end
		end
	end)
	do return nFieldCompletion
 end end

function CompletionRuntime:gotoNodeByParams(vIsLookup, vFileUri, vDirtySplitCode, vLine, vColumn)  
	local nSuccEnv = self:getCodeEnv(vFileUri)
	if not nSuccEnv then
		do return false, "goto failed, success compiled code not found"
	 end end
	local nSuccSplitCode = nSuccEnv:getSplitCode()
	local nPos = nSuccSplitCode:lcToPos(vLine, vColumn)
	if nSuccSplitCode:getLine(vLine) ~= vDirtySplitCode:getLine(vLine) or nPos ~= vDirtySplitCode:lcToPos(vLine, vColumn) then
		do return false, "goto failed, code is dirty before pos"
	 end end
	     
	local nIdentNode = nSuccEnv:searchIdent(nPos)
	if nIdentNode then
		if vIsLookup then
			if nIdentNode.kind == "def" then
				do return false, "goto failed, lookup not work for Ident_def"
			 end end
			local nDefineNode = nIdentNode.defineIdent
			if nDefineNode then
				do return {[nDefineNode]=true}
			      
			 end end
		else
			if nIdentNode.kind == "use" and nIdentNode.defineIdent then
				do return false, "goto failed, lookdown not work for Ident_use"
			 end end
			if nIdentNode.kind == "def" then
				do return false, "symbol find reference TODO"
			 end end
		end
	end
	   
	local nExprNode, nFocusList = nSuccEnv:searchExprBySuffix(nPos)
	if nExprNode then
		self:focusSchedule(nFocusList)
		local nNodeSet = vIsLookup and self:exprLookup(nExprNode) or self:exprLookdown(nExprNode)
		if not next(nNodeSet) then
			do return false, "no lookup or lookdown expr node searched, node="..tostring(nExprNode)..",tag="..(nExprNode.tag)
		 end end
		do return nNodeSet
	 end end
	    
	local nHintExprNode, nBlockNode, nFocusList = nSuccEnv:searchHintExprBySuffix(nPos)
	if not nHintExprNode then
		do return false, "no target expr"
	 end end
	local nExprContent = nSuccSplitCode:getContent():sub(nHintExprNode.pos, nHintExprNode.posEnd - 1)
	local nWrongContent = string.rep(" ", nHintExprNode.pos) .. "(@" .. nExprContent .. "."
	local nInjectFn, nInjectTrace = CodeEnv.genInjectFnByError(nSuccSplitCode, vFileUri, nWrongContent)
	if not nInjectFn then
		do return false, "gen inject fn fail"
	 end end
	self:focusSchedule(nFocusList)
	      
	do return vIsLookup
		and self:injectLookup(nInjectTrace.pos, nBlockNode, nInjectFn)
		or self:injectLookdown(nInjectTrace.pos, nBlockNode, nInjectFn)
 end end

function CompletionRuntime:injectLookup(vTracePos, vBlockNode, vFn) 
	local nNodeSet  = {}
	self:_injectForeach(vTracePos, vBlockNode, vFn, function(vResult)
		if TypeReference.is(vResult) then
			local nAssignNode = vResult:getAssignNode()
			if nAssignNode then
				nNodeSet[nAssignNode] = true
			end
		else
			local nNamespace = SpaceTable.checkSpace(vResult)
			if nNamespace then
				nNodeSet[nNamespace:getNode()] = true
			end
		end
	end)
	do return nNodeSet
 end end

function CompletionRuntime:injectLookdown(vTracePos, vBlockNode, vFn) 
	    
	do return {}
 end end

function CompletionRuntime:exprLookup(vNode) 
	local nNodeSet  = {}
	local nCtxList = self._nodeToApplyContextList:get(vNode) or {}
	for _, nContext in ipairs(nCtxList) do
		nContext:outLookupNode(nNodeSet)
	::continue:: end
	do return nNodeSet
 end end

function CompletionRuntime:exprLookdown(vNode) 
	    
	do return {}
 end end

do return CompletionRuntime
 end 
end end
--thlua.runtime.CompletionRuntime end ==========)

--thlua.runtime.DiagnosticRuntime begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.DiagnosticRuntime'] = function (...)

local BaseRuntime = require "thlua.runtime.BaseRuntime"
local CompletionRuntime = require "thlua.runtime.CompletionRuntime"
local ListDict = require "thlua.manager.ListDict"
local class = require "thlua.class"


	
	


local DiagnosticRuntime = class (CompletionRuntime)

function DiagnosticRuntime:ctor(...)
	self._diaList={}
end

function DiagnosticRuntime:lateSchedule(vAutoFn)
	vAutoFn:startLateBuild()
end

function DiagnosticRuntime:exprLookdown(vNode) 
	local nNodeSet  = {}
	local nCtxList = self._nodeToApplyContextList:get(vNode) or {}
	for _, nContext in ipairs(nCtxList) do
		nContext:outLookdownNode(nNodeSet)
	::continue:: end
	do return nNodeSet
 end end

function DiagnosticRuntime:focusSchedule(vFuncList)
	  
end

function DiagnosticRuntime:_save(vSeverity, vNode, ...)
	local l = {}
	for i=1, select("#", ...) do
		l[i] = tostring(select(i, ...))
	::continue:: end
	local nMsg = table.concat(l, " ")
	local nDiaList = self._diaList
	nDiaList[#nDiaList + 1] = {
		msg=nMsg,
		node=vNode,
		severity=vSeverity,
	}
end

function DiagnosticRuntime:getAllDiagnostic() 
	local nFileToDiaList  = {}
	for _, nDia in pairs(self._diaList) do
		local nPath = nDia.node.path
		local nList = nFileToDiaList[nPath]
		if not nList then
			nList = {}
			nFileToDiaList[nPath] = nList
		end
		nList[#nList + 1] = nDia
	::continue:: end
	do return nFileToDiaList
 end end

do return DiagnosticRuntime
 end 
end end
--thlua.runtime.DiagnosticRuntime end ==========)

--thlua.runtime.InstStack begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.InstStack'] = function (...)

local DoBuilder = require "thlua.builder.DoBuilder"
local Branch = require "thlua.runtime.Branch"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"
local AutoHolder = require "thlua.auto.AutoHolder"
local AutoFlag = require "thlua.auto.AutoFlag"
local TermTuple = require "thlua.tuple.TermTuple"
local RefineTerm = require "thlua.term.RefineTerm"
local VariableCase = require "thlua.term.VariableCase"
local Exception = require "thlua.Exception"
local Reference = require "thlua.refer.Reference"
local Node = require "thlua.code.Node"
local Enum = require "thlua.Enum"
local LocalSymbol = require "thlua.term.LocalSymbol"
local ImmutVariable = require "thlua.term.ImmutVariable"

local BaseFunction = require "thlua.type.func.BaseFunction"
local TypedObject = require "thlua.type.object.TypedObject"
local OpenTable = require "thlua.type.object.OpenTable"
local Truth = require "thlua.type.basic.Truth"

local FunctionBuilder = require "thlua.builder.FunctionBuilder"
local TableBuilder = require "thlua.builder.TableBuilder"
local class = require "thlua.class"
local BaseStack = require "thlua.runtime.BaseStack"

local OperContext = require "thlua.context.OperContext"
local ApplyContext = require "thlua.context.ApplyContext"
local LogicContext = require "thlua.context.LogicContext"


	  
	  


  
local InstStack = class (BaseStack)

function InstStack:AUTO(vNode)
	do return AutoFlag
 end end

function InstStack:BEGIN(vLexStack, vBlockNode)  
	assert(not self._letspace, "context can only begin once")
	local nUpState = self._lexCapture
	local nRootBranch = Branch.new(self, nUpState and nUpState.uvCase or VariableCase.new(), nUpState and nUpState.branch or false, vBlockNode)
	self._branchStack[1]=nRootBranch
	local nSpace = self._runtime:LetNamespace(vLexStack:getNamespace(), vBlockNode)
	self._letspace = nSpace
	do return nSpace:export()
 end end

      
function InstStack:EXPRLIST_REPACK(
	vNode,
	vLazy,
	l  
)
	local nPackContext = self:newOperContext(vNode)
	local reFunc
	local nLastIndex = #l
	local nLast = l[nLastIndex]
	if not nLast then
		reFunc = function()
			do return nPackContext:FixedTermTuple({})
		 end end
	else
		local repackWithoutLast = function()
			local nTermList = {}
			for i=1, #l-1 do
				local cur = l[i]
				if TermTuple.is(cur) then
					if #cur ~= 1 then
						        
					end
					nTermList[i] = cur:get(nPackContext, 1)
				elseif RefineTerm.is(cur) or AutoHolder.is(cur) then
					nTermList[i] = cur
				elseif type(cur) == "function" then
					nTermList[i] = cur()
				else
					error("unexcept branch")
				end
			::continue:: end
			do return nTermList
		 end end
		  
		if TermTuple.is(nLast) then
			reFunc = function()
				do return nPackContext:UTermTupleByAppend(repackWithoutLast(), nLast)
			 end end
		else
			reFunc = function()
				local nTermList = repackWithoutLast()
				if RefineTerm.is(nLast) or AutoHolder.is(nLast) then
					nTermList[#nTermList + 1] = nLast
				elseif type(nLast) == "function" then
					nTermList[#nTermList + 1] = nLast()
				else
					error("unexcept branch")
				end
				do return nPackContext:UTermTupleByAppend(nTermList, false)
			 end end
		end
	end
	if vLazy then
		do return reFunc
	 end else
		do return reFunc()
	 end end
end

       
function InstStack:EXPRLIST_UNPACK(
	vNode,
	vNum,
	... 
)
	local nUnpackContext = self:newOperContext(vNode)
	local l  = {...}
	local re = {}
	for i=1, vNum do
		if i > #l then
			local last = l[#l]
			if TermTuple.is(last) then
				local nIndex = i - #l + 1
				re[i] = last:get(nUnpackContext, nIndex)
				       
					        
				 
			else
				nUnpackContext:error("exprlist_unpack but right value not enough")
				re[i] = nUnpackContext:RefineTerm(self._manager.type.Nil)
			end
		else
			local cur = l[i]
			if TermTuple.is(cur) then
				re[i] = cur:get(nUnpackContext, 1)
			else
				re[i] = cur
			end
		end
	::continue:: end
	do return table.unpack(re)
 end end

  
function InstStack:META_GET(
	vNode  ,
	vSelfTerm,
	vKeyTerm,
	vNotnil
)
	do return self:anyNodeMetaGet(vNode, vSelfTerm, vKeyTerm, vNode.notnil or false)
 end end

function InstStack:META_SET(
	vNode ,
	vSelfTerm,
	vKeyTerm,
	vValueTerm
)
	local nNil = self._manager.type.Nil
	local vContext = self:newNoPushContext(vNode)
	vSelfTerm:foreach(function(vSelfType, _)
		vKeyTerm:foreach(function(vKeyType, _)
			vSelfType:meta_set(vContext, vKeyType, vValueTerm)
		end)
	end)
end

function InstStack:META_CALL(
	vNode,
	vFuncTerm,
	vLazyFunc
)
	local nCtx = self:prepareMetaCall(vNode, vFuncTerm, vLazyFunc)
	do return nCtx:mergeReturn()
 end end

function InstStack:META_INVOKE(
	vNode,
	vSelfTerm,
	vName,
	vPolyArgs,
	vArgTuple
)
	assert(vPolyArgs, "poly args can't be nil here")
	local nNil = self._manager.type.Nil
	do return self:withMorePushContextWithCase(vNode, vSelfTerm, function(vContext, vSelfType, vCase)
		if vSelfType == nNil then
			vContext:error("nil as invoke self")
		else
			local nFilterSelfTerm = vContext:RefineTerm(vSelfType)
			local nNewArgTuple = vContext:UTermTupleByAppend({nFilterSelfTerm}, vArgTuple)
			local nFuncTerm = self:META_GET(vNode, nFilterSelfTerm, vContext:RefineTerm(self._manager:Literal(vName)), false)
			nFuncTerm:foreach(function(vSingleFuncType, _)
				if vSingleFuncType == nNil then
					vContext:error("nil as invoke func")
				elseif Truth.is(vSingleFuncType) or BaseFunction.is(vSingleFuncType) then
					vSingleFuncType:meta_invoke(vContext, vSelfType, vPolyArgs, nNewArgTuple)
				else
					vContext:error("TODO non-function type called "..tostring(vSingleFuncType))
				end
			end)
		end
	end):mergeReturn()
 end end

function InstStack:META_EQ_NE(
	vNode,
	vIsEq,
	vLeftTerm,
	vRightTerm
)
	local nCmpContext = self:newOperContext(vNode)
	local nTypeCaseList = {}
	vLeftTerm:foreach(function(vLeftType, vLeftVariableCase)
		vRightTerm:foreach(function(vRightType, vRightVariableCase)
			local nReType = nil
			if vLeftType:isSingleton() and vRightType:isSingleton() then
				     
				local nTypeIsEq = vLeftType == vRightType
				if vIsEq == nTypeIsEq then
					nReType = self._manager.type.True
				else
					nReType = self._manager.type.False
				end
			elseif not (vLeftType & vRightType):isNever() then
				nReType = self._manager.type.Boolean:checkAtomUnion()
			else
				if vIsEq then
					nReType = self._manager.type.False
				else
					nReType = self._manager.type.True
				end
			end
			nTypeCaseList[#nTypeCaseList + 1] = {nReType, vLeftVariableCase & vRightVariableCase}
		end)
	end)
	do return nCmpContext:mergeToRefineTerm(nTypeCaseList)
 end end

function InstStack:META_BOP_SOME(
	vNode,
	vOper,
	vLeftTerm,
	vRightTerm
)
	do return self:withOnePushContext(vNode, function(vContext)
		vLeftTerm:foreach(function(vLeftType, vLeftVariableCase)
			local nLeftHigh, nLeftFunc = vLeftType:meta_bop_func(vContext, vOper)
			if nLeftHigh then
				local nRightType = vRightTerm:getType()
				local nTermTuple = vContext:FixedTermTuple({
					vLeftTerm:filter(vContext, vLeftType), vRightTerm
				})
				vContext:withCase(vLeftVariableCase, function()
					nLeftFunc:meta_call(vContext, nTermTuple)
				end)
			else
				vRightTerm:foreach(function(vRightType, vRightVariableCase)
					local nRightHigh, nRightFunc = vRightType:meta_bop_func(vContext, vOper)
					if nRightHigh then
						local nTermTuple = vContext:FixedTermTuple({
							vLeftTerm:filter(vContext, vLeftType),
							vRightTerm:filter(vContext, vRightType)
						})
						vContext:withCase(vLeftVariableCase & vRightVariableCase, function()
							nRightFunc:meta_call(vContext, nTermTuple)
						end)
					else
						if nLeftFunc and nRightFunc and nLeftFunc == nRightFunc then
							local nTermTuple = vContext:FixedTermTuple({
								vLeftTerm:filter(vContext, vLeftType),
								vRightTerm:filter(vContext, vRightType)
							})
							vContext:withCase(vLeftVariableCase & vRightVariableCase, function()
								nRightFunc:meta_call(vContext, nTermTuple)
							end)
						else
							vContext:error("invalid bop:"..vOper)
						end
					end
				end)
			end
		end)
	end):mergeFirst()
 end end

function InstStack:META_UOP(
	vNode,
	vOper,
	vData
)
	local nUopContext = self:newOperContext(vNode)
	local nTypeCaseList = {}
	if vOper == "#" then
		vData:foreach(function(vType, vVariableCase)
			nTypeCaseList[#nTypeCaseList + 1] = {
				vType:meta_len(nUopContext),
				vVariableCase
			}
		end)
	else
		vData:foreach(function(vType, vVariableCase)
			nTypeCaseList[#nTypeCaseList + 1] = {
				vType:meta_uop_some(nUopContext, vOper),
				vVariableCase
			}
		end)
	end
	do return nUopContext:mergeToRefineTerm(nTypeCaseList)
 end end

function InstStack:CHUNK_TYPE(vNode, vTerm)
	do return vTerm:getType()
 end end

function InstStack:FUNC_NEW(vNode ,
	vFnNewInfo,
	vPrefixHint,
	vParRetMaker
)
	local nBranch = self:topBranch()
	local nFnType = FunctionBuilder.new(self, vNode, {
		branch=nBranch,
		uvCase=nBranch:getCase(),
	}, vFnNewInfo, vPrefixHint, vParRetMaker):build()
	do return self:_nodeTerm(vNode, nFnType)
 end end

  
function InstStack:TABLE_NEW(vNode, vHintInfo, vPairMaker)
	local nBuilder = TableBuilder.new(self, vNode, vHintInfo, vPairMaker)
	local nTableType = nBuilder:build()
	do return self:_nodeTerm(vNode, nTableType)
 end end

function InstStack:EVAL(vNode, vTerm)
	if RefineTerm.is(vTerm) then
		do return vTerm:getType()
	 end else
		error(vNode:toExc("hint eval fail"))
	end
end

function InstStack:CAST_HINT(vNode, vTerm, vCastKind, ...)
	local nCastContext = self:newAssignContext(vNode)
	    
	if vCastKind == Enum.CastKind_POLY then
		local nTypeCaseList = {}
		local nTemplateList = self._manager:getDirtyProcessor():easyToTypeList(vNode, ...)
		vTerm:foreach(function(vType, vVariableCase)
			local nAfterType = vType:castPoly(nCastContext, nTemplateList)
			if nAfterType then
				nTypeCaseList[#nTypeCaseList + 1] = {nAfterType, vVariableCase}
			else
				nTypeCaseList[#nTypeCaseList + 1] = {vType, vVariableCase}
			end
		end)
		do return nCastContext:mergeToRefineTerm(nTypeCaseList)
	 end else
		local nDst = assert(..., "hint type can't be nil")
		local nDstType = self._manager:getDirtyProcessor():easyToType(vNode, nDst):checkAtomUnion()
		local nSrcType = vTerm:getType()
		if vCastKind == Enum.CastKind_CONIL then
			nCastContext:includeAndCast(nDstType, nSrcType:notnilType(), Enum.CastKind_CONIL)
		elseif vCastKind == Enum.CastKind_COVAR then
			nCastContext:includeAndCast(nDstType, nSrcType, Enum.CastKind_COVAR)
		elseif vCastKind == Enum.CastKind_CONTRA then
			if not (nSrcType:includeAll(nDstType) or nDstType:includeAll(nSrcType)) then
				nCastContext:error("@> cast fail")
			end
		elseif vCastKind ~= Enum.CastKind_FORCE then
			vContext:error("unexcepted castkind:"..tostring(vCastKind))
		end
		do return nCastContext:RefineTerm(nDstType)
	 end end
end

function InstStack:NIL_TERM(vNode)
	do return self:_nodeTerm(vNode, self._manager.type.Nil)
 end end

function InstStack:HINT_TERM(vNode, vType)
	do return self:_nodeTerm(vNode, vType:checkAtomUnion())
 end end

function InstStack:LITERAL_TERM(vNode, vValue  )
	local nType = self._manager:Literal(vValue)
	do return self:_nodeTerm(vNode, nType)
 end end

function InstStack:SYMBOL_SET(vNode, vDefineNode, vTerm)
	local nBranch = self:topBranch()
	local nSymbol = nBranch:getSymbolByNode(vDefineNode)
	local nSymbolContext = self:newAssignContext(vNode)
	assert(not ImmutVariable.is(nSymbol), nSymbolContext:newException("immutable symbol can't set "))
	assert(not AutoHolder.is(nSymbol), nSymbolContext:newException("auto symbol can't set "))
	assert(not AutoHolder.is(vTerm), nSymbolContext:newException("TODO.. auto term assign"))
	nBranch:mutSet(nSymbolContext, nSymbol, vTerm)
end

function InstStack:SYMBOL_GET(vNode, vDefineNode, vAllowAuto)
	do return self:topBranch():SYMBOL_GET(vNode, vDefineNode, vAllowAuto)
 end end

function InstStack:PARAM_PACKOUT(
	vNode,
	vList,
	vDots
)
	do return self._headContext:UTermTupleByAppend(vList, vDots)
 end end

function InstStack:PARAM_UNPACK(
	vNode,
	vTermTuple,        
	vIndex,
	vHintType 
)
	local nHeadContext = self._headContext
	if vHintType == AutoFlag then
		if vTermTuple then
			do return vTermTuple:get(nHeadContext, vIndex)
		 end else
			do return AutoHolder.new(vNode, nHeadContext)
		 end end
	else
		if vTermTuple then
			local nAutoTerm = vTermTuple:get(nHeadContext, vIndex)
			nHeadContext:assignTermToType(nAutoTerm, vHintType)
		end
		     
		do return nHeadContext:RefineTerm(vHintType)
	 end end
end

function InstStack:PARAM_NODOTS_UNPACK(
	vNode,
	vTermTuple,
	vParNum
)
	if vTermTuple then
		self._headContext:matchArgsToNoDots(vNode, vTermTuple, vParNum)
	end
end

function InstStack:PARAM_DOTS_UNPACK(
	vNode,
	vTermTuple,
	vParNum,
	vHintDots 
)
	if vTermTuple then
		if vHintDots == AutoFlag then
			do return self._headContext:matchArgsToAutoDots(vNode, vTermTuple, vParNum)
		 end else
			do return self._headContext:matchArgsToTypeDots(vNode, vTermTuple, vParNum, vHintDots)
		 end end
	else
		if vHintDots == AutoFlag then
			do return self._headContext:UTermTupleByTail({}, AutoTail.new(vNode, self._headContext))
		 end else
			do return self._headContext:UTermTupleByTail({}, DotsTail.new(self._headContext, vHintDots))
		 end end
	end
end

function InstStack:SYMBOL_NEW(vNode, vKind, vModify, vTermOrNil, vHintType, vAutoPrimitive)
	local nTopBranch = self:topBranch()
	local nSymbolContext = self:newAssignContext(vNode)
	local nTerm = vTermOrNil or nSymbolContext:NilTerm()
	if not vTermOrNil and not vHintType and vKind == Enum.SymbolKind_LOCAL then
		nSymbolContext:warn("define a symbol without any type")
	end
	if vHintType then
		nTerm = nSymbolContext:assignTermToType(nTerm, vHintType)
	else
		local nTermInHolder = nTerm:getRefineTerm()
		if not nTermInHolder then
			if vModify then
				error(nSymbolContext:newException("auto variable can't be modified"))
			elseif vKind == Enum.SymbolKind_LOCAL then
				error(nSymbolContext:newException("auto variable can't be defined as local"))
			end
			do return nTopBranch:setSymbolByNode(vNode, nTerm)
		 end end
		nTerm = nTermInHolder
		local nFromType = nTerm:getType()
		             
		if vKind == Enum.SymbolKind_LOCAL and vAutoPrimitive then
			local nToType = nSymbolContext:getTypeManager():literal2Primitive(nFromType)
			if nFromType ~= nToType then
				nTerm = nSymbolContext:RefineTerm(nToType)
			end
		end
		nFromType:setAssigned(nSymbolContext)
	end
	local nImmutVariable = nTerm:attachImmutVariable()
	if vModify then
		local nLocalSymbol = LocalSymbol.new(nSymbolContext, vNode, nTerm:getType(), nTerm)
		self:topBranch():mutMark(nLocalSymbol, nImmutVariable)
		do return nTopBranch:setSymbolByNode(vNode, nLocalSymbol)
	 end else
		nImmutVariable:setNode(vNode)
		do return nTopBranch:setSymbolByNode(vNode, nImmutVariable)
	 end end
end


function InstStack:IF_ONE(
	vNode,
	vTerm,
	vTrueFunction, vBlockNode
)
	local nIfContext = self:newOperContext(vNode)
	local nTrueCase = vTerm:caseTrue()
	local nFalseCase = vTerm:caseFalse()
	local nBeforeBranch = self:topBranch()
	if nTrueCase then
		local nTrueBranch = self:_withBranch(nTrueCase, vTrueFunction, vBlockNode)
		nBeforeBranch:mergeOneBranch(nIfContext, nTrueBranch, nFalseCase)
	end
end

function InstStack:IF_TWO(
	vNode,
	vTerm,
	vTrueFunction, vTrueBlock,
	vFalseFunction, vFalseBlock
)
	local nIfContext = self:newOperContext(vNode)
	local nTrueCase = vTerm:caseTrue()
	local nFalseCase = vTerm:caseFalse()
	local nBeforeBranch = self:topBranch()
	if nTrueCase then
		local nTrueBranch = self:_withBranch(nTrueCase, vTrueFunction, vTrueBlock)
		if nFalseCase then
			local nFalseBranch = self:_withBranch(nFalseCase, vFalseFunction, vFalseBlock)
			nBeforeBranch:mergeTwoBranch(nIfContext, nTrueBranch, nFalseBranch)
		else
			nBeforeBranch:mergeOneBranch(nIfContext, nTrueBranch, nFalseCase)
		end
	elseif nFalseCase then
		local nFalseBranch = self:_withBranch(nFalseCase, vFalseFunction, vFalseBlock)
		nBeforeBranch:mergeOneBranch(nIfContext, nFalseBranch, nTrueCase)
	end
end

function InstStack:REPEAT(vNode, vFunc, vUntilFn)
	self:_withBranch(VariableCase.new(), function()
		vFunc()
		      
		vUntilFn()
	end, vNode[1])
end

function InstStack:WHILE(vNode, vTerm, vTrueFunction)
	local nTrueCase = vTerm:caseTrue()
	self:_withBranch(nTrueCase or VariableCase.new(), vTrueFunction,  vNode[2])
end

function InstStack:DO(vNode, vHintInfo, vDoFunc)
	local nBuilder = DoBuilder.new(self, vNode)
	nBuilder:build(vHintInfo)
	if not nBuilder.pass then
		self:_withBranch(VariableCase.new(), vDoFunc, vNode[1])
	end
end

function InstStack:FOR_IN(vNode, vFunc, vNextSelfInit)
	local nForContext = self:newOperContext(vNode)
	local nLenNext = #vNextSelfInit
	if nLenNext < 1 or nLenNext > 3 then
		nForContext:error("FOR_IN iterator error, arguments number must be 1 or 2 or 3")
		do return
	 end end
	local nNext = vNextSelfInit:get(nForContext, 1)
	local nTuple = self:META_CALL(vNode, nNext, function ()
		if nLenNext == 1 then
			do return nForContext:FixedTermTuple({})
		 end else
			local nSelf = vNextSelfInit:get(nForContext, 2)
			if nLenNext == 2 then
				do return nForContext:FixedTermTuple({nSelf})
			 end else
				if nLenNext == 3 then
					local nInit = vNextSelfInit:get(nForContext, 3)
					do return nForContext:FixedTermTuple({nSelf, nInit})
				 end else
					error("NextSelfInit tuple must be 3, this branch is impossible")
				end
			end
		end
	end)
	assert(TermTuple.isFixed(nTuple), "iter func can't return auto term")
	local nFirstTerm = nTuple:get(nForContext, 1)
	local nFirstType = nFirstTerm:getType()
	if not nFirstType:isNilable() then
		nForContext:error("FOR_IN must receive function with nilable return")
		do return
	 end end
	if nFirstType:notnilType():isNever() then
		do return
	 end end
	nFirstTerm:foreach(function(vAtomType, vCase)
		if vAtomType:isNilable() then
			do return
		 end end
		local nTermList = {nForContext:RefineTerm(vAtomType)}
		   
			  
		
		for i=2, #nTuple do
			local nTerm = nTuple:get(nForContext, i)
			local nType = vCase[nTerm:attachImmutVariable()]
			if nType then
				nTerm = nForContext:RefineTerm(nType)
			end
			nTermList[i] = nTerm
		::continue:: end
		local nNewTuple = nForContext:FixedTermTuple(nTermList)
		self:_withBranch(vCase, function()
			vFunc(nNewTuple)
		end, vNode[3])
	end)
end

function InstStack:FOR_NUM(
	vNode,
	vStart,
	vStop,
	vStepOrNil,
	vFunc,
	vBlockNode
)
	local nForContext = self:newOperContext(vNode)
	self:_withBranch(VariableCase.new(), function()
		vFunc(nForContext:RefineTerm(self:getTypeManager().type.Integer))
	end, vBlockNode)
end

function InstStack:LOGIC_OR(vNode, vLeftTerm, vRightFunction)
	local nOrContext = self:newLogicContext(vNode)
	local nLeftTrueTerm = nOrContext:logicTrueTerm(vLeftTerm)
	local nLeftFalseCase = vLeftTerm:caseFalse()
	if not nLeftFalseCase then
		do return nLeftTrueTerm
	 end else
		local nRightTerm = nil
		self:_withBranch(nLeftFalseCase, function()
			nRightTerm = vRightFunction()
		end)
		assert(nRightTerm, "term must be true value here")
		do return nOrContext:logicCombineTerm(nLeftTrueTerm, nRightTerm, nLeftFalseCase)
	 end end
end

function InstStack:LOGIC_AND(vNode, vLeftTerm, vRightFunction)
	local nAndContext = self:newLogicContext(vNode)
	local nLeftFalseTerm = nAndContext:logicFalseTerm(vLeftTerm)
	local nLeftTrueCase = vLeftTerm:caseTrue()
	if not nLeftTrueCase then
		do return nLeftFalseTerm
	 end else
		local nRightTerm = nil
		self:_withBranch(nLeftTrueCase, function()
			nRightTerm = vRightFunction()
		end)
		assert(nRightTerm, "term must be true value here")
		do return nAndContext:logicCombineTerm(nLeftFalseTerm, nRightTerm, nLeftTrueCase)
	 end end
end

function InstStack:LOGIC_NOT(vNode, vData)
	local nNotContext = self:newLogicContext(vNode)
	do return nNotContext:logicNotTerm(vData)
 end end

function InstStack:BREAK(vNode)
	self:topBranch():setStop()
end

function InstStack:CONTINUE(vNode)
	self:topBranch():setStop()
end

function InstStack:RETURN(vNode, vTermTuple)
	error("implement RETURN in OpenStack or SealStack")
end

function InstStack:END(vNode) 
	error("implement END in OpenStack or SealStack")
	do return self._fastOper:FixedTermTuple({}), self._manager.type.String
 end end

function InstStack:GLOBAL_GET(vNode, vIdentENV)
	local nEnvTerm = self:SYMBOL_GET(vNode, vIdentENV, false)
	assert(not AutoHolder.is(nEnvTerm), "auto can't be used here")
	do return self:META_GET(vNode, nEnvTerm, self:LITERAL_TERM(vNode, vNode[1]), false)
 end end

function InstStack:GLOBAL_SET(vNode, vIdentENV, vValueTerm)
	local nEnvTerm = self:SYMBOL_GET(vNode, vIdentENV, false)
	assert(not AutoHolder.is(nEnvTerm), "auto can't be used here")
	assert(not AutoHolder.is(vValueTerm), "auto can't be used here")
	self:META_SET(vNode, nEnvTerm, self:LITERAL_TERM(vNode, vNode[1]), vValueTerm)
end

function InstStack:INJECT_GET(
	vNode,
	vInjectGetter
)
	do return vInjectGetter(vNode)
 end end

function InstStack:INJECT_BEGIN(vNode)  
	local nSpace = assert(self._letspace)
	do return nSpace:export()
 end end

do return InstStack
 end 
end end
--thlua.runtime.InstStack end ==========)

--thlua.runtime.OpenStack begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.OpenStack'] = function (...)

local Exception = require "thlua.Exception"
local TermTuple = require "thlua.tuple.TermTuple"
local class = require "thlua.class"
local InstStack = require "thlua.runtime.InstStack"


	  


local OpenStack = class (InstStack)

function OpenStack:ctor(
	vRuntime,
	vNode,
	vUpState,
	vBodyFn,
	vApplyStack,
	vIsRequire
)
	self._applyStack = vApplyStack
	self._bodyFn = vBodyFn
	self._isRequire = vIsRequire
	local nErrCollection = self._manager:TypeCollection()
	nErrCollection:put(self._manager.type.String)
	self._errCollection = nErrCollection
end

function OpenStack:isRequire()
	do return self._isRequire
 end end

function OpenStack:RAISE_ERROR(vContext, vType)
	self._errCollection:put(vType)
end

function OpenStack:RETURN(vNode, vTermTuple)
	assert(TermTuple.isFixed(vTermTuple), Exception.new("can't return auto term", vNode))
	table.insert(self._retList, vTermTuple)
	self:topBranch():setStop()
end

function OpenStack:mergeEndErrType()
	do return self._errCollection:mergeToAtomUnion()
 end end

function OpenStack:END(vNode) 
	self:getNamespace():close()
	local nRetList = self._retList
	local nLen = #nRetList
	if nLen == 0 then
		do return self._fastOper:FixedTermTuple({}), self._errCollection:mergeToAtomUnion()
	 end elseif nLen == 1 then
		do return nRetList[1], self._errCollection:mergeToAtomUnion()
	 end else
		error("TODO : open-function has more than one return")
	end
end

function OpenStack:findRequireStack()
	local nStack = self
	while not nStack:isRequire() do
		local nApplyStack = nStack:getApplyStack()
		if OpenStack.is(nApplyStack) then
			nStack = nApplyStack
		else
			do return false
		 end end
	::continue:: end
	do return nStack
 end end

function OpenStack:getSealStack()
	do return self._applyStack:getSealStack()
 end end

function OpenStack:getApplyStack()
	do return self._applyStack
 end end

do return OpenStack
 end 
end end
--thlua.runtime.OpenStack end ==========)

--thlua.runtime.SealStack begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.SealStack'] = function (...)

local TermTuple = require "thlua.tuple.TermTuple"
local Exception = require "thlua.Exception"
local class = require "thlua.class"
local InstStack = require "thlua.runtime.InstStack"
local ClassFactory = require "thlua.type.func.ClassFactory"
local SealFunction = require "thlua.type.func.SealFunction"
local AutoFunction = require "thlua.type.func.AutoFunction"


	  
	  


local SealStack = class (InstStack)

function SealStack:ctor(
	vRuntime,
	vNode,
	vUpState,
	vBodyFn 
)
	self._classFnSet={}   
	self._autoFnSet={}   
	self._bodyFn = vBodyFn
	self._classTable=false
end

function SealStack:setClassTable(vClassTable)
	self._classTable = vClassTable
end

function SealStack:getClassTable()
	do return self._classTable
 end end

function SealStack:_returnCheck(vContext, vTypeTuple)
	local nBodyFn = self._bodyFn
	if AutoFunction.is(nBodyFn) then
		local nOneOkay = false
		local nRetTuples = nBodyFn:getRetTuples()
		if nRetTuples then
			local nMatchSucc, nCastSucc = vContext:returnMatchTuples(vTypeTuple, nRetTuples)
			if not nMatchSucc then
				vContext:error("return match failed")
			elseif not nCastSucc then
				vContext:error("return cast failed")
			end
		end
	elseif ClassFactory.is(nBodyFn) then
		local nResultType = nBodyFn:getClassTable(true)
		if nResultType ~= vTypeTuple:get(1):checkAtomUnion() or #vTypeTuple ~= 1 or vTypeTuple:getRepeatType() then
			vContext:error("class return not match")
		end
	end
end

function SealStack:RAISE_ERROR(vContext, vRaiseErr)
	local nBodyFn = self._bodyFn
	assert(SealFunction.is(nBodyFn))
	local nRetTuples = nBodyFn:getRetTuples()
	local nString = self._manager.type.String
	if nRetTuples then
		local nHintErr = nRetTuples:getErrType()
		if not nHintErr:includeAll(vRaiseErr) then
			if nString:includeAll(nHintErr) then
				     
			else
				   
			end
		end
	else
		if not nString:includeAll(vRaiseErr) then
			     
		end
	end
end

function SealStack:RETURN(vNode, vTermTuple)
	assert(TermTuple.isFixed(vTermTuple), Exception.new("can't return auto term", vNode))
	local nRetContext = self:newReturnContext(vNode)
	table.insert(self._retList, vTermTuple)
	if #vTermTuple <= 0 or vTermTuple:getTail() then
		self:_returnCheck(nRetContext, vTermTuple:checkTypeTuple())
	else
		local nManager = self:getTypeManager()
		nRetContext:unfoldTermTuple(vTermTuple, function(vFirst, vTypeTuple, _)
			self:_returnCheck(nRetContext, vTypeTuple)
		end)
	end
	self:topBranch():setStop()
end

function SealStack:END(vNode) 
	self:getNamespace():close()
	local nBodyFn = self._bodyFn
	local nRetList = self._retList
	if AutoFunction.is(nBodyFn) and not nBodyFn:getRetTuples() then
		local nLen = #nRetList
		if nLen == 0 then
			do return self._fastOper:FixedTermTuple({}), self._manager.type.String
		 end elseif nLen == 1 then
			do return nRetList[1], self._manager.type.String
		 end else
			local nFirstTuple = nRetList[1]:checkTypeTuple()
			for i=2,#nRetList do
				local nOtherTuple = nRetList[i]:checkTypeTuple()
				if not (nFirstTuple:includeTuple(nOtherTuple) and nOtherTuple:includeTuple(nFirstTuple)) then
					error("auto-function can't implicit return mixing type, explicit hint with :Ret(xxx) ")
				end
			::continue:: end
			do return nRetList[1], self._manager.type.String
		 end end
	else
		do return nil, nil
	 end end
end

function SealStack:seal()
	local nClassFnSet = assert(self._classFnSet, "class set must be true here")
	self._classFnSet = false
	for fn, v in pairs(nClassFnSet) do
		fn:startPreBuild()
		fn:startLateBuild()
	::continue:: end
	local nAutoFnSet = assert(self._autoFnSet, "maker set must be true here")
	self._autoFnSet = false
	for fn, v in pairs(nAutoFnSet) do
		fn:startPreBuild()
		self._runtime:lateSchedule(fn)
	::continue:: end
end

function SealStack:getSealStack()
	do return self
 end end

function SealStack:scheduleSealType(vType)
	if ClassFactory.is(vType) then
		local nSet = self._classFnSet
		if nSet then
			nSet[vType] = true
		else
			vType:startPreBuild()
			vType:startLateBuild()
		end
	elseif AutoFunction.is(vType) then
		local nSet = self._autoFnSet
		if nSet then
			nSet[vType] = true
		else
			vType:startPreBuild()
			self._runtime:lateSchedule(vType)
		end
	end
end

function SealStack:rootSetNamespace(vRootSpace)
	assert(not self._letspace, "namespace has been setted")
	self._letspace = self._runtime:LetNamespace(vRootSpace, self._node)
end

function SealStack:getBodyFn()
	do return self._bodyFn  
 end end

function SealStack:isRoot()
	do return not self._lexCapture
 end end

do return SealStack
 end 
end end
--thlua.runtime.SealStack end ==========)

--thlua.runtime.SeverityEnum begin ==========(
do local _ENV = _ENV
packages['thlua.runtime.SeverityEnum'] = function (...)

do return {
	Error = 1,
	Warn = 2,
	Info = 3,
	Hint = 4,
} end 
end end
--thlua.runtime.SeverityEnum end ==========)

--thlua.server.ApiServer begin ==========(
do local _ENV = _ENV
packages['thlua.server.ApiServer'] = function (...)

local json = require "thlua.server.json"
local BaseServer = require "thlua.server.BaseServer"
local class = require "thlua.class"


	
	

	   
		
		
	

	 
		
		
	

	   
		
	

	   
		
		
	

	   
		
		
	

	   

	   
		
	

	

		   
			
		

		   
			   
				  
			
		   

		   
		   

	

	   
		
		 
			
			
			
		
	

	   
		
		
	

	   
		
	

	   
		   
			
			
			
			
		
	

	  
	 

	  
	 

	   
		  
		
		 
			
			
		
	

	   
		
		
		 
			
			 
			
			 
			 
				
			
			
			
			
			 
			 
		
	

	   
		
		
	

	   
		
		
		
		
		
		
		
		
		
		
		
		
	

	   
		 
		
	



local ApiServer = class (BaseServer)

function ApiServer:ctor(...)
	self._methodHandler = {
		initialize=function(vParam)
			do return self:onInitialize(vParam)
		 end end,
		shutdown=function()
			self:onShutdown()
		end,
		exit=function()
			self:onExit()
		end,
		["textDocument/didOpen"]=function(vParam)
			do return self:onDidOpen(vParam)
		 end end,
		["textDocument/didChange"]=function(vParam)
			do return self:onDidChange(vParam)
		 end end,
		["textDocument/didSave"]=function(vParam)
			do return self:onDidSave(vParam)
		 end end,
		["textDocument/didClose"]=function(vParam)
			do return self:onDidClose(vParam)
		 end end,
		["textDocument/completion"]=function(vParam)
			local ok, ret = pcall(function()
				do return self:onCompletion(vParam)
			 end end)
			if not ok then
				self:error("onCompletion error", tostring(ret))
			end
			do return ok and ret or json.array({})
		 end end,
		["textDocument/definition"]=function(vParam)
			local ok, ret = pcall(function()
				do return self:onDefinition(vParam)
			 end end)
			if not ok then
				self:error("onDefinition error", tostring(ret))
			end
			do return ok and ret or json.array({})
		 end end,
		["textDocument/typeDefinition"]=function(vParam)
			local ok, ret = pcall(function()
				do return self:onTypeDefinition(vParam)
			 end end)
			if not ok then
				self:error("onTypeDefinition error", tostring(ret))
			end
			do return ok and ret or json.array({})
		 end end,
		["textDocument/references"]=function(vParam)
			local ok, ret = pcall(function()
				do return self:onReferences(vParam)
			 end end)
			if not ok then
				self:error("onReferences error", tostring(ret))
			end
			do return ok and ret or json.array({})
		 end end,
		["textDocument/hover"]=function(vParam)
			local ok, ret = pcall(function()
				do return self:onHover(vParam)
			 end end)
			if not ok then
				self:error("onHover error", tostring(ret))
			end
			do return ok and ret or json.array({})
		 end end,
	}
end

function ApiServer:getMethodHandler()
	do return self._methodHandler
 end end

function ApiServer:getInitializeResult()
	error("getInitializeResult not implement in ApiServer")
end

function ApiServer:onInitialize(vParams)
	if self.initialize then
		error("already initialized!")
	else
		self.initialize = true
	end
	local rootUri = vParams.rootUri
	local root  = vParams.rootPath or (rootUri and self:uriToPath(rootUri))
	self:info("Config.root = ", root, vParams.rootPath, vParams.rootUri)
	self:info("Platform = ", self:getPlatform())
	if root then
		self:setRoot(root)
	end
	do return self:getInitializeResult()
 end end

function ApiServer:onShutdown()
	self.shutdown=true
end

function ApiServer:onExit()
	if self.shutdown then
		os.exit()
	else
		os.exit()
	end
end

function ApiServer:onDidChange(vParams)
end

function ApiServer:onDidOpen(vParams)
end

function ApiServer:onDidSave(vParams)
end

function ApiServer:onDidClose(vParams)
end

function ApiServer:onDefinition(vParams)
	do return nil
 end end

function ApiServer:onCompletion(vParams)
	do return {}
 end end

function ApiServer:onHover(vParams)
end

function ApiServer:onReferences(vParams)
	do return nil
 end end

function ApiServer:onTypeDefinition(vParams)
end

do return ApiServer
 end 
end end
--thlua.server.ApiServer end ==========)

--thlua.server.BaseServer begin ==========(
do local _ENV = _ENV
packages['thlua.server.BaseServer'] = function (...)

local json = require "thlua.server.json"
local Exception = require "thlua.Exception"
local lpath = require "path"
local ErrorCodes = require "thlua.server.protocol".ErrorCodes
local CodeEnv = require "thlua.code.CodeEnv"
local FileState = require "thlua.server.FileState"
local class = require "thlua.class"


	
	
	


local BaseServer = class ()

function BaseServer:ctor(vGlobalPath)
	self.initialize=false
	self.shutdown=false
	self._rootPath=""
	self._fileStateDict={} 
	self._globalPath = vGlobalPath or lpath.cwd().."/global"
end

function BaseServer:getMethodHandler()
	error("get method handler is not implement in BaseServer")
end

function BaseServer:attachFileState(vFileUri)
	local nFileState = self._fileStateDict[vFileUri]
	if not nFileState then
		local nNewState = FileState.new(vFileUri)
		self._fileStateDict[vFileUri] = nNewState
		do return nNewState
	 end else
		do return nFileState
	 end end
end

function BaseServer:makeLoader()
	do return {
		thluaSearch=function(vRuntime, vPath)
			local nSearchPath = vRuntime:getSearchPath() or lpath.abs(self._rootPath.."/?.thlua")..";"..lpath.abs(self._rootPath.."/?.d.thlua")
			local nList = {}
			local nSet  = {}
			for nOnePath in nSearchPath:gmatch("[^;]+") do
				local nAbsPath = lpath.abs(nOnePath)
				if not nSet[nAbsPath] then
					nList[#nList + 1] = nAbsPath
				end
			::continue:: end
			local nSearchPath = table.concat(nList, ";")
			local fileName, err1 = package.searchpath(vPath, nSearchPath)
			if not fileName then
				do return false, err1
			 end end
			do return true, self:pathToUri(fileName)
		 end end,
		thluaParseFile=function(vRuntime, vFileUri)
			if not self._fileStateDict[vFileUri] then
				local nFilePath = self:uriToPath(vFileUri)
				local file, err = io.open(nFilePath, "r")
				if not file then
					error(err)
				end
				local nContent = assert(file:read("a"), "file get nothing")
				file:close()
				self:attachFileState(vFileUri):syncContent(nContent, -1)
			end
			do return self._fileStateDict[vFileUri]:checkLatestEnv()
		 end end,
		thluaGlobalFile=function(vRuntime, vPackage)
			local nFilePath = self._globalPath.."/"..vPackage..".d.thlua"
			local nFileUri = self:pathToUri(nFilePath)
			if not self._fileStateDict[nFileUri] then
				local file, err = io.open(nFilePath, "r")
				if not file then
					error(err)
				end
				local nContent = assert(file:read("a"), "global file get nothing")
				file:close()
				self:attachFileState(nFileUri):syncContent(nContent, -1)
            end
			do return self._fileStateDict[nFileUri]:checkLatestEnv(), nFileUri
		 end end,
	}
 end end

function BaseServer:checkFileState(vFileUri)
	do return (assert(self._fileStateDict[vFileUri], "file not existed:"..vFileUri))
 end end

function BaseServer:mainLoop()
	self:notify("$/status/report", {
		text="hello",
		tooltip="hello",
	})
	self:info("global path:", self._globalPath)
	while not self.shutdown do
		self:rpc()
	::continue:: end
end

local function reqToStr(vRequest)
	do return "["..tostring(vRequest.method)..(vRequest.id and ("$"..vRequest.id) or "").."]"
 end end

function BaseServer:rpc()
	local request = self:readRequest()
	local methodName = request.method
	local nId = request.id
	if not methodName then
		if nId then
			self:writeError(nId, ErrorCodes.ParseError, "method name not set", "")
		else
			self:warn(reqToStr(request), "method name not set")
		end
		do return
	 end end
	local handler = self:getMethodHandler()[methodName]
	if not handler then
		if nId then
			self:writeError(nId, ErrorCodes.MethodNotFound, "method not found", "method="..tostring(methodName))
		else
			self:warn(reqToStr(request), "method not found")
		end
		do return
	 end end
	local result = handler(request.params)
	if result then
		if nId then
			self:writeResult(nId, result)
			  
		else
			self:warn(reqToStr(request), "request without id ")
		end
		do return
	 end else
		if nId then
			self:warn(reqToStr(request), "request with id but no resposne")
		end
	end
end

function BaseServer:readRequest()
	   
	local length = -1
	while true do
		local line = io.read("l")
		if not line then
			error("io.read fail")
		end
		line = line:gsub("\13", "")
		if line == "" then
			break
		end
		local key, val = line:match("([^:]+): (.+)")
		if not key or not val then
			error("header format error:"..line)
		end
		if key == "Content-Length" then
			length = assert(math.tointeger(val), "Content-Length can't convert to integer"..tostring(val))
		end
	::continue:: end

	if length < 0 then
		error("Content-Length failed in rpc")
	end

	   
	local data = io.read(length)
	if not data then
		error("read nothing")
	end
	data = data:gsub("\13", "")
	local obj, err = json.decode(data)
	if type(obj) ~= "table" then
		error("json decode error:"..tostring(err))
	end
	local req = obj  
	if req.jsonrpc ~= "2.0" then
		error("json-rpc is not 2.0, "..tostring(req.jsonrpc))
	end
	     
	do return req
 end end

function BaseServer:writeError(vId  , vCode, vMsg, vData)
	self:_write({
		jsonrpc = "2.0",
		id = vId,
		error = {
			code = vCode,
			message = vMsg,
			data = vData,
		}
	})
end

function BaseServer:writeResult(vId  , vResult)
	self:_write({
		jsonrpc = "2.0",
		id = vId,
		result = vResult,
	})
end

function BaseServer:notify(vMethod, vParams)
	self:_write({
		jsonrpc = "2.0",
		method = vMethod,
		params = vParams,
	})
end

function BaseServer:getPlatform()
	if package.config:sub(1,1) == "\\" then
		do return "win"
	 end else
		do return "not-win"
	 end end
end

function BaseServer:_write(vPacket)
	local data = json.encode(vPacket)
	if self:getPlatform() == "win" then
		data = ("Content-Length: %d\n\n%s"):format(#data, data)
	else
		data = ("Content-Length: %d\r\n\r\n%s"):format(#data, data)
	end
	io.write(data)
	io.flush()
end

local MessageType = {}

MessageType.ERROR = 1
MessageType.WARNING = 2
MessageType.INFO = 3
MessageType.DEBUG = 4

function BaseServer:packToString(vDepth, ...)
	local nInfo = debug.getinfo(vDepth)
	local nPrefix = nInfo.source..":"..nInfo.currentline
	local l = {nPrefix}  
	for i=1,select("#", ...) do
		l[#l + 1] = tostring(select(i, ...))
	::continue:: end
	do return table.concat(l, " ")
 end end

function BaseServer:error(...)
	local str = self:packToString(3, ...)
	self:notify("window/logMessage", {
		message = str,
		type = MessageType.ERROR,
	})
end

function BaseServer:warn(...)
	local str = self:packToString(3, ...)
	self:notify("window/logMessage", {
		message = str,
		type = MessageType.WARNING,
	})
end

function BaseServer:info(...)
	local str = self:packToString(3, ...)
	self:notify("window/logMessage", {
		message = str,
		type = MessageType.INFO,
	})
end

function BaseServer:debug(...)
	local str = self:packToString(3, ...)
	self:notify("window/logMessage", {
		message = str,
		type = MessageType.DEBUG,
	})
end

function BaseServer:setRoot(vRoot)
	   
	  
	self._rootPath = vRoot
end

function BaseServer:uriToPath(vUri)
	local nPath = vUri:gsub("+", ""):gsub("%%(..)", function(c)
		local num = (assert(tonumber(c, 16)) ) 
		local char = string.char(num)
		do return char
	 end end)
	if self:getPlatform() == "win" then
		do return (nPath:gsub("^file:///", ""):gsub("/$", ""))
	 end else
		do return (nPath:gsub("^file://", ""):gsub("/$", ""))
	 end end
end

function BaseServer:pathToUri(vPath)
	if self:getPlatform() == "win" then
		local nUri = vPath:gsub("\\", "/"):gsub("([a-zA-Z]):", function(driver)
			do return driver:lower().."%3A"
		 end end)
		do return "file:///"..nUri
	 end else
		do return "file://"..vPath
	 end end
end

do return BaseServer
 end 
end end
--thlua.server.BaseServer end ==========)

--thlua.server.BothServer begin ==========(
do local _ENV = _ENV
packages['thlua.server.BothServer'] = function (...)

local SlowServer = require "thlua.server.SlowServer"
local class = require "thlua.class"


	
	
	

local BothServer = class (SlowServer)

function BothServer:getInitializeResult()
	self:info("slow & fast both server")
	do return {
		capabilities = {
			textDocumentSync = {
				change = 2,       
				openClose = true,
				save = { includeText = true },
			},
			definitionProvider = true,
			referencesProvider = true,
			hoverProvider = true,
			completionProvider = {
				triggerCharacters = {".",":"},
				resolveProvider = false
			},
		},
	}
 end end

do return BothServer end 
end end
--thlua.server.BothServer end ==========)

--thlua.server.FastServer begin ==========(
do local _ENV = _ENV
packages['thlua.server.FastServer'] = function (...)

local lpath = require "path"
local FieldCompletion = require "thlua.context.FieldCompletion"
local json = require "thlua.server.json"
local Exception = require "thlua.Exception"
local SeverityEnum = require "thlua.runtime.SeverityEnum"
local CompletionRuntime = require "thlua.runtime.CompletionRuntime"
local CodeEnv = require "thlua.code.CodeEnv"
local FileState = require "thlua.server.FileState"
local ApiServer = require "thlua.server.ApiServer"
local ParseEnv = require "thlua.code.ParseEnv"
local class = require "thlua.class"


	
	
	


local FastServer = class (ApiServer)

function FastServer:ctor(...)
	self._runtime=nil
end

function FastServer:getInitializeResult()
	self:info("fast server")
	do return {
		capabilities = {
			textDocumentSync = {
				change = 2,       
				openClose = true,
				save = { includeText = true },
			},
			definitionProvider = true,
			hoverProvider = true,
			completionProvider = {
				triggerCharacters = {".",":"},
				resolveProvider = false
			},
			  
			  
			  
			  
			  
			  
			  
			  
		},
	}
 end end

function FastServer:rerun(vFileUri)
	local rootFileUri = lpath.isfile(self._rootPath .. "/throot.thlua")
	if not rootFileUri then
		rootFileUri = vFileUri
		self:info("throot.thlua not found, run single file:", rootFileUri)
	else
		rootFileUri = self:pathToUri(rootFileUri)
		self:info("throot.thlua found:", rootFileUri)
	end
	local nRuntime=CompletionRuntime.new(self:makeLoader())
	local ok, exc = nRuntime:pmain(rootFileUri)
	if not ok then
		if not self._runtime then
			self._runtime = nRuntime
		end
	else
		self._runtime = nRuntime
	end
	collectgarbage()
end

function FastServer:checkRuntime()
	do return assert(self._runtime)
 end end

function FastServer:onDidChange(vParams)
	local nFileUri = vParams.textDocument.uri
	if self:attachFileState(nFileUri):syncChangeMayRerun(vParams) then
		self:rerun(nFileUri)
	end
	for nFileName, nFileState in pairs(self._fileStateDict) do
		local nDiaList = {}
		local nExc = nFileState:getLatestException()
		if nExc then
			local nNode = nExc.node
			nDiaList[1] = {
				range={
					start={
						line=nNode.l-1,
						character=0,
					},
					["end"]={
						line=nNode.l-1,
						character=100,
					}
				},
				message=nExc.msg,
				severity=SeverityEnum.Error,
			}
		end
		self:_write({
			jsonrpc = "2.0",
			method = "textDocument/publishDiagnostics",
			params = {
				uri=nFileName,
				version=nFileState:getVersion(),
				diagnostics=json.array(nDiaList),
			},
		})
	::continue:: end
end

function FastServer:onDidOpen(vParams)
	local nContent = vParams.textDocument.text
	local nFileUri = vParams.textDocument.uri
	local nFileState = self:attachFileState(nFileUri)
	if nFileState:contentMismatch(nContent) then
		if nFileState:syncContent(nContent, vParams.textDocument.version) then
			self:rerun(nFileUri)
		end
	end
end

function FastServer:onDidSave(vParams)
	local nFileUri = vParams.textDocument.uri
	local nContent = vParams.text
	local nFileState = self:attachFileState(nFileUri)
	if nContent then
		if nFileState:contentMismatch(nContent) then
			self:warn("content mismatch when save")
		end
	end
	if nFileState:onSaveAndGetChange() then
		self:rerun(nFileUri)
	end
end

function FastServer:lookup(vParams)  
	do return nil
 end end

function FastServer:onDefinition(vParams)
	local nFileUri = vParams.textDocument.uri
	local nFileState = self:checkFileState(nFileUri)
	local nCompletionRuntime = self:checkRuntime()
	local nNodeSet, nErrMsg = nCompletionRuntime:gotoNodeByParams(
		true, nFileUri, nFileState:getSplitCode(),
		vParams.position.line + 1,
		vParams.position.character + 1
	)
	if not nNodeSet then
		self:info("goto definition fail:", nErrMsg)
		do return nil
	 end else
		local nRetList = {}
		for nLookupNode, _ in pairs(nNodeSet) do
			nRetList[#nRetList + 1] = {
				uri=nLookupNode.path,
				range={
					start={ line=nLookupNode.l - 1, character=nLookupNode.c-1, },
					["end"]={ line=nLookupNode.l - 1, character=nLookupNode.c - 1 },
				}
			}
		::continue:: end
		do return nRetList
	 end end
end

function FastServer:onCompletion(vParams)
	local nCompletionRuntime = self._runtime
	    
	local nFileUri = vParams.textDocument.uri
	local nFileState = self:checkFileState(nFileUri)
	local nSuccEnv = self:checkRuntime():getCodeEnv(nFileUri)
	if not nSuccEnv then
		self:info("completion fail for some code error", nFileUri)
		do return nil
	 end end
	   
	local nSplitCode = nFileState:getSplitCode()
	local nPos = nSplitCode:lcToPos(vParams.position.line+1, vParams.position.character+1)
	local nWrongContent = nSplitCode:getContent():sub(1, nPos-1)
	    
	local nInjectFn, nInjectTrace = CodeEnv.genInjectFnByError(nSplitCode, nFileUri, nWrongContent)
	if not nInjectFn then
		do return nil
	 end end
	             
	local nInjectNode, nTraceList = assert(nInjectTrace.capture.injectNode), nInjectTrace.traceList
	local nBlockNode, nFuncList = nSuccEnv:traceBlockRegion(nTraceList)
	nCompletionRuntime:focusSchedule(nFuncList)
	   
	local nFieldCompletion = nCompletionRuntime:injectCompletion(nInjectNode.pos, nBlockNode, nInjectFn, self)
	if not nFieldCompletion then
		self:info("completion fail for no branch", nBlockNode, nBlockNode.tag)
		do return nil
	 end end
	local nRetList = {}
	nFieldCompletion:foreach(function(vKey, vKind)
		nRetList[#nRetList + 1] = {
			label=vKey,
			kind=vKind,
		}
	end)
	do return json.array(nRetList)
 end end

function FastServer:onHover(vParams)
	
	   
	         
	  
		   
		   
		     
			    
		
		    
		 
			  
				
				
			  
		
	
end

do return FastServer
 end 
end end
--thlua.server.FastServer end ==========)

--thlua.server.FileState begin ==========(
do local _ENV = _ENV
packages['thlua.server.FileState'] = function (...)

local CodeEnv = require "thlua.code.CodeEnv"
local Exception = require "thlua.Exception"
local SplitCode = require "thlua.code.SplitCode"
local class = require "thlua.class"


	
	
	


local FileState = class ()

local CHANGE_ANYTHING = 1
local CHANGE_NONBLANK = 2

function FileState:ctor(vFileName)
	self._rightEnv = false
	self._fileName = vFileName
	self._splitCode = SplitCode.new("")
	self._errOrEnv = nil 
	self._version = (-1) 
	self._changeState = false  
end

function FileState:onSaveAndGetChange()
	if self._changeState then
		self._changeState = false
		do return true
	 end end
	do return false
 end end

function FileState:getWellformedRange(vRange)
	local nStart = vRange.start
	local nEnd = vRange["end"]
	if nStart.line > nEnd.line or (nStart.line == nEnd.line and nStart.character > nEnd.character) then
		do return { start=nEnd, ["end"]=nStart }
	 end else
		do return vRange
	 end end
end

function FileState:syncChangeMayRerun(vParams)
	local nCanRerun = self:syncChangeNoRerun(vParams)
	if nCanRerun then
		self._changeState = false
		do return true
	 end else
		do return false
	 end end
end

function FileState:syncChangeNoRerun(vParams)
	local nChanges = vParams.contentChanges
	local nSplitCode = self._splitCode
	local nLineChange = false
	for _, nChange in ipairs(nChanges) do
		local nRawRange = nChange.range
		if nRawRange then
			local nRange = self:getWellformedRange(nRawRange)
			local nChangeText = nChange.text
			local nContent = nSplitCode:getContent()
			local nRangeStart = nRange.start
			local nRangeEnd = nRange["end"]
			local nStartPos = nSplitCode:lcToPos(nRangeStart.line + 1, nRangeStart.character + 1)
			local nFinishPos = nSplitCode:lcToPos(nRangeEnd.line + 1, nRangeEnd.character + 1)
			local nNewContent = nContent:sub(1, nStartPos - 1) .. nChangeText .. nContent:sub(nFinishPos, #nContent)
			local nRemoveText = nContent:sub(nStartPos, nFinishPos-1)
			if nChangeText:find("[\r\n]") or nRemoveText:find("[\r\n]") then
				nLineChange = true
			end
			if nChangeText:find("[^%s]") or nRemoveText:find("[^%s]") then
				self._changeState = CHANGE_NONBLANK
			end
			nSplitCode = SplitCode.new(nNewContent)
		else
			nSplitCode = SplitCode.new(nChange.text)
		end
		if not self._changeState then
			self._changeState = CHANGE_ANYTHING
		end
	::continue:: end
	self._splitCode = nSplitCode
	self._version = vParams.textDocument.version
	local nRight = self:_checkRight()
	if nRight then
		if self._changeState == CHANGE_NONBLANK and nLineChange then
			do return true
		 end else
			do return false
		 end end
	else
		do return false
	 end end
end

function FileState:_checkRight()
	local nOkay, nCodeEnv = pcall(CodeEnv.new, self._splitCode:getContent(), self._fileName)
	if nOkay then
		self._rightEnv = nCodeEnv
		self._errOrEnv = nCodeEnv
		do return true
	 end else
		if type(nCodeEnv) == "table" then
			self._errOrEnv = nCodeEnv
		end
		do return false
	 end end
end

function FileState:syncContent(vContent, vVersion)
	self._version = vVersion
	self._splitCode = SplitCode.new(vContent)
	self._changeState = false
	do return self:_checkRight()
 end end

function FileState:getRightEnv()
	do return self._rightEnv
 end end

function FileState:contentMismatch(vContent)
	local nSplitCode = self._splitCode
	local nContent = nSplitCode:getContent()
	if nContent ~= vContent then
		do return true
	 end else
		do return false
	 end end
end

function FileState:getLatestException()
	local nLatest = self._errOrEnv
	if Exception.is(nLatest) then
		do return nLatest
	 end end
	do return false
 end end

function FileState:checkLatestEnv()
	local nLatest = self._errOrEnv
	if CodeEnv.is(nLatest) then
		do return nLatest
	 end else
		error(nLatest)
	end
end

function FileState:getSplitCode()
	do return self._splitCode
 end end

function FileState:getVersion()
	do return self._version
 end end

do return FileState
 end 
end end
--thlua.server.FileState end ==========)

--thlua.server.PlayGround begin ==========(
do local _ENV = _ENV
packages['thlua.server.PlayGround'] = function (...)


local class = require "thlua.class"
local json = require "thlua.server.json"

local SeverityEnum = require "thlua.runtime.SeverityEnum"
local SplitCode = require "thlua.code.SplitCode"
local CodeEnv = require "thlua.code.CodeEnv"
local DiagnosticRuntime = require "thlua.runtime.DiagnosticRuntime"


      
       
         
            
            
        
        
    
       
        
        
        
    


local PlayGround = class ()

function PlayGround:ctor()
    self._splitCode = SplitCode.new("")
    self._codeEnv = nil
    self._globalToEnv = {}   
end

function PlayGround:update(vName, vData)
    local nInput = (json.decode(vData) ) 
    local ret = self:_update(vName, nInput)
    do return json.encode(ret)
 end end

function PlayGround:_update(vName, vInput)
    local nContent = vInput.content
    local nCode = SplitCode.new(nContent)
    self._splitCode = nCode
    local nParseOkay, nCodeEnv = pcall(CodeEnv.new, nCode, vName)
    if not nParseOkay then
        local nDia = {
            node={
                path=vName,
                l=1,
                c=1,
            }  ,
            msg=tostring(nCodeEnv),
            severity=SeverityEnum.Error,
        }
        if type(nCodeEnv) == "table" then
            nDia.node = {
                path=nCodeEnv.node.path,
                l=nCodeEnv.node.l,
                c=nCodeEnv.node.c,
            }  
            nDia.msg = nCodeEnv.msg
        end
        do return {
            syntaxErr=true,
            diaList=json.array({nDia} ),
            luaContent=tostring(nCodeEnv),
        }
     end end
    local nRuntime = DiagnosticRuntime.new({
        thluaSearch=function(vRuntime, vPath)
            do return false, "can't use require on playground"
         end end,
        thluaParseFile=function(vRuntime, vFileName)
            do return CodeEnv.new(self._splitCode, vFileName)
         end end,
        thluaGlobalFile=function(vRuntime, vPackage)
            vPackage = vPackage or "global"
            local nCodeEnv = self._globalToEnv[vPackage]
            local nFileName = "@virtual-file:"..vPackage
            if not nCodeEnv then
                local nContent = (require("thlua.global."..vPackage) ) 
                local nCodeEnv = CodeEnv.new(nContent, nFileName)
                self._globalToEnv[vPackage] = nCodeEnv
                do return nCodeEnv, nFileName
             end else
                do return nCodeEnv, nFileName
             end end
        end
    })
    local nRunOkay, nExc = nRuntime:pmain(vName)
    local nDiaList = nRuntime:getAllDiagnostic()[vName] or {}
    local nAfterDiaList = {}
    for i, dia in ipairs(nDiaList) do
        nAfterDiaList[i] = {
            msg = dia.msg,
            severity = dia.severity,
            node = {
                l=dia.node.l,
                c=dia.node.c,
                path=dia.node.path
            }  ,
        }
    ::continue:: end
    do return {
        syntaxErr=false,
        diaList=json.array(nAfterDiaList),
        luaContent=nCodeEnv:getLuaCode()
    }
 end end

do return PlayGround
 end 
end end
--thlua.server.PlayGround end ==========)

--thlua.server.SlowServer begin ==========(
do local _ENV = _ENV
packages['thlua.server.SlowServer'] = function (...)

local lpath = require "path"
local json = require "thlua.server.json"
local Exception = require "thlua.Exception"
local ErrorCodes = require "thlua.server.protocol".ErrorCodes
local DiagnosticRuntime = require "thlua.runtime.DiagnosticRuntime"
local CodeEnv = require "thlua.code.CodeEnv"
local FileState = require "thlua.server.FileState"
local ApiServer = require "thlua.server.ApiServer"
local FastServer = require "thlua.server.FastServer"
local class = require "thlua.class"


	
	
	


local SlowServer = class (FastServer)

function SlowServer:checkDiagnosticRuntime()
	do return (assert(self._runtime) ) 
 end end

function SlowServer:getInitializeResult()
	self:info("slow server")
	do return {
		capabilities = {
			textDocumentSync = {
				change = 2,       
				openClose = true,
				save = { includeText = true },
			},
			referencesProvider = true,
		},
	}
 end end

function SlowServer:publishNormal()
	local nRuntime = self:checkDiagnosticRuntime()
	local nFileToList = nRuntime:getAllDiagnostic()
	for nFileName, nFileState in pairs(self._fileStateDict) do
		local nRawDiaList = nFileToList[nFileName] or {}
		local nVersion = nFileState:getVersion()
		local nDiaList = {}
		local nSplitCode = nFileState:getSplitCode()
		for _, dia in ipairs(nRawDiaList) do
			local nNode = dia.node
			local nLineContent = nSplitCode:getLine(nNode.l)
			local nRangeEnd = nNode.pos == nNode.posEnd and {
				nNode.l, nNode.c + (nLineContent and #nLineContent + 10 or 100)
			} or {nSplitCode:fixupPos(nNode.posEnd)}
			local nMsg = dia.msg
			nDiaList[#nDiaList + 1] = {
				range={
					start={
						line=nNode.l-1,
						character=nNode.c-1,
					},
					["end"]={
						line=nRangeEnd[1]-1,
						character=nRangeEnd[2]-1,
					}
				},
				message=nMsg,
				severity=dia.severity,
			}
		::continue:: end
		self:_write({
			jsonrpc = "2.0",
			method = "textDocument/publishDiagnostics",
			params = {
				uri=nFileName,
				version=nVersion,
				diagnostics=json.array(nDiaList),
			},
		})
	::continue:: end
end

function SlowServer:publishException(vException )
	local nNode = nil
	local nMsg = ""
	if Exception.is(vException) then
		nNode = vException.node or self._runtime:getNode()
		nMsg = vException.msg or "exception's msg field is missing"
	else
		nNode = self._runtime:getNode()
		nMsg = "root error:"..tostring(vException)
	end
	local nFileState = self._fileStateDict[nNode.path]
	if not nFileState then
		self:error("exception in unknown file:", nNode.path)
		do return
	 end end
	self:_write({
		jsonrpc = "2.0",
		method = "textDocument/publishDiagnostics",
		params = {
			uri=nNode.path,
			version=nFileState:getVersion(),
			diagnostics={ {
				range={
					start={
						line=nNode.l-1,
						character=0,
					},
					["end"]={
						line=nNode.l-1,
						character=100,
					}
				},
				message=nMsg,
			} }
		},
	})
end

function SlowServer:rerun(vFileUri)
	local rootFileUri = lpath.isfile(self._rootPath .. "/throot.thlua")
	if not rootFileUri then
		rootFileUri = vFileUri
		self:info("throot.thlua not found, run single file:", rootFileUri)
	else
		rootFileUri = self:pathToUri(rootFileUri)
		self:info("throot.thlua found:", rootFileUri)
	end
	local nRuntime=DiagnosticRuntime.new(self:makeLoader())
	local ok, exc = nRuntime:pmain(rootFileUri)
	if not ok then
		if not self._runtime then
			self._runtime = nRuntime
		end
		self:publishException(exc   )
		do return
	 end else
		self._runtime = nRuntime
		collectgarbage()
		self:publishNormal()
	end
end

function SlowServer:onDidChange(vParams)
	self:attachFileState(vParams.textDocument.uri):syncChangeNoRerun(vParams)
end

function SlowServer:onDidOpen(vParams)
	local nContent = vParams.textDocument.text
	local nFileUri = vParams.textDocument.uri
	local nFileState = self:attachFileState(nFileUri)
	if nFileState:contentMismatch(nContent) then
		nFileState:syncContent(nContent, vParams.textDocument.version)
		self:rerun(nFileUri)
	end
end

function SlowServer:onDidSave(vParams)
	local nFileUri = vParams.textDocument.uri
	local nContent = vParams.text
	local nFileState = self:attachFileState(nFileUri)
	nFileState:onSaveAndGetChange()
	self:rerun(nFileUri)
end

function SlowServer:onReferences(vParams)
	local nFileUri = vParams.textDocument.uri
	local nFileState = self:checkFileState(nFileUri)
	local nDiagnosticRuntime = self:checkDiagnosticRuntime()
	local nNodeSet, nErrMsg = nDiagnosticRuntime:gotoNodeByParams(
		false, nFileUri, nFileState:getSplitCode(),
		vParams.position.line + 1,
		vParams.position.character + 1
	)
	if not nNodeSet then
		self:info("find references fail:", nErrMsg)
		do return nil
	 end else
		local nRetList = {}
		for nLookupNode, _ in pairs(nNodeSet) do
			nRetList[#nRetList + 1] = {
				uri=nLookupNode.path,
				range={
					start={ line=nLookupNode.l - 1, character=nLookupNode.c-1, },
					["end"]={ line=nLookupNode.l - 1, character=nLookupNode.c + 10 },
				}
			}
		::continue:: end
		do return nRetList
	 end end
end

do return SlowServer
 end 
end end
--thlua.server.SlowServer end ==========)

--thlua.server.json begin ==========(
do local _ENV = _ENV
packages['thlua.server.json'] = function (...)
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

end end
--thlua.server.json end ==========)

--thlua.server.protocol begin ==========(
do local _ENV = _ENV
packages['thlua.server.protocol'] = function (...)

local SeverityEnum = require "thlua.runtime.SeverityEnum"

local ErrorCodes = {
	ParseError = -32700;
	InvalidRequest = -32600;
	MethodNotFound = -32601;
	InvalidParams = -32602;
	InternalError = -32603;

	   
	jsonrpcReservedErrorRangeStart = -32099;


	
	           
	          
	 
	ServerNotInitialized = -32002;
	UnknownErrorCode = -32001;

	   
	jsonrpcReservedErrorRangeEnd = -32000;

	   
	lspReservedErrorRangeStart = -32899;

	
	           
	            
	         
	    
	 
	   
	 
	RequestFailed = -32803;

	
	          
	          
	   
	 
	   
	 
	ServerCancelled = -32802;

	
	           
	        
	            
	         
	            
	 
	              
	       
	 
	ContentModified = -32801;

	
	            
	   
	 
	RequestCancelled = -32800;

	   
	lspReservedErrorRangeEnd = -32800;
}





  

   
	  
	  
	  
	  


   
	  
	  
	  
	  


   
	  
	  
	  


   
	
	
		
		
	
	
	
	
	
		
		
		
		
		
		
	
	
	   


   
	
		
			
			
		
		
		
			
			       
			
				
			
		
		  
		  
		  
	
	 
		
		
	


    

   
	
	
	 
	 
		
	
	
	




do return {
	ErrorCodes=ErrorCodes,
	SeverityEnum=SeverityEnum,
}
 end 
end end
--thlua.server.protocol end ==========)

--thlua.term.ImmutVariable begin ==========(
do local _ENV = _ENV
packages['thlua.term.ImmutVariable'] = function (...)

local ImmutVariable = {}
ImmutVariable.__index=ImmutVariable
ImmutVariable.__tostring=function(self)
	do return "const-"..tostring(next(self._symbolSet) or self._node)
 end end

  

function ImmutVariable.new(vTerm)
	do return setmetatable({
		_originTerm=vTerm,
		_termByFilter={} ,
		_symbolSet={}  ,
		_node=false
	}, ImmutVariable)
 end end

function ImmutVariable:setNode(vNode)
	self._node = vNode
end

function ImmutVariable:addSymbol(vSymbol)
	self._symbolSet[vSymbol] = true
end

function ImmutVariable:getType()
	do return self._originTerm:getType()
 end end

function ImmutVariable:filterTerm(vContext, vCase)
	local nOriginTerm = self._originTerm
	local nType = vCase[self]
	if nType then
		if not nType:isNever() then
			local nTermByFilter = self._termByFilter
			local nTerm = nTermByFilter[nType]
			if nTerm then
				do return nTerm
			 end end
			local nTerm = nOriginTerm:filter(vContext, nType)
			nTerm:initVariable(self)
			nTermByFilter[nType] = nTerm
			do return nTerm
		 end else
			vContext:error("TODO type is never when get symbol"..tostring(self))
			do return vContext:NeverTerm()
		 end end
	else
		do return nOriginTerm
	 end end
end

function ImmutVariable.is(v)
	do return getmetatable(v) == ImmutVariable
 end end

do return ImmutVariable
 end 
end end
--thlua.term.ImmutVariable end ==========)

--thlua.term.LocalSymbol begin ==========(
do local _ENV = _ENV
packages['thlua.term.LocalSymbol'] = function (...)

local RefineTerm = require "thlua.term.RefineTerm"
local ImmutVariable = require "thlua.term.ImmutVariable"

  

local LocalSymbol = {}
LocalSymbol.__index=LocalSymbol
LocalSymbol.__tostring=function(self)
	do return "LocalSymbol-"..tostring(self._node).."-"..tostring(self._type)
 end end

function LocalSymbol.new(vContext,
		vNode, vType, vRawTerm)
	do return setmetatable({
		_context=vContext,
		_node=vNode,
		_type=vType,
		_rawTerm=vRawTerm,
	}, LocalSymbol)
 end end

function LocalSymbol:makeVariable(vType)
	local nTerm = self._context:RefineTerm(vType or self._type)
	local nVariable = nTerm:attachImmutVariable()
	nVariable:addSymbol(self)
	do return nVariable
 end end

function LocalSymbol:getType()
	do return self._type
 end end

function LocalSymbol:getNode()
	do return self._node
 end end

function LocalSymbol:getName()
	do return tostring(self._node)
 end end

function LocalSymbol.is(v)
	do return getmetatable(v) == LocalSymbol
 end end

do return LocalSymbol
 end 
end end
--thlua.term.LocalSymbol end ==========)

--thlua.term.RefineTerm begin ==========(
do local _ENV = _ENV
packages['thlua.term.RefineTerm'] = function (...)

local ImmutVariable = require "thlua.term.ImmutVariable"
local VariableCase = require "thlua.term.VariableCase"
local Nil = require "thlua.type.basic.Nil"

  

local RefineTerm = {}
RefineTerm.__index=RefineTerm
RefineTerm.__tostring=function(self)
	local l = {}
	for nType, nVariableCase in pairs(self._typeToCase) do
		l[#l + 1] = tostring(nType) .."=>"..tostring(nVariableCase)
	::continue:: end
	do return "RefineTerm("..table.concat(l, ",")..")"
 end end

function RefineTerm.new(
	vNode,
	vType,
	vTypeToCase )
	local self = setmetatable({
		_node=vNode,
		_typeToCase=vTypeToCase or {} ,
		_type=vType,
		_notnilTerm=false,
		_symbolVariable=false   ,
	}, RefineTerm)
	vType:foreach(function(vType)
		if not self._typeToCase[vType] then
			self._typeToCase[vType] = VariableCase.new()
		end
	end)
	do return self
 end end

function RefineTerm:checkRefineTerm(vContext)
	do return self
 end end

function RefineTerm:foreach(func )
	for nType, nVariableCase in pairs(self._typeToCase) do
		func(nType, nVariableCase)
	::continue:: end
end

function RefineTerm.is(v)
	do return getmetatable(v) == RefineTerm
 end end

function RefineTerm:caseTrue()
	local reCase = nil
	self._type:trueType():foreach(function(vType)
		local nCase = self._typeToCase[vType]
		if not reCase then
			reCase = nCase
		else
			reCase = reCase | nCase
		end
	end)
	do return reCase
 end end

function RefineTerm:caseNotnil()
	local reCase = nil
	self._type:foreach(function(vType)
		if not Nil.is(vType) then
			local nCase = self._typeToCase[vType]
			if not reCase then
				reCase = nCase
			else
				reCase = reCase | nCase
			end
		end
	end)
	do return reCase
 end end

    
function RefineTerm:caseFalse()
	local reCase = nil
	self._type:falseType():foreach(function(vType)
		local nCase = self._typeToCase[vType]
		if not reCase then
			reCase = nCase
		else
			reCase = reCase | nCase
		end
	end)
	do return reCase
 end end

function RefineTerm:falseEach(vFunc )
	local nTypeToCase = self._typeToCase
	self._type:falseType():foreach(function(vType)
		vFunc(vType, nTypeToCase[vType])
	end)
end

function RefineTerm:trueEach(vFunc )
	local nTypeToCase = self._typeToCase
	self._type:trueType():foreach(function(vType)
		vFunc(vType, nTypeToCase[vType])
	end)
end

function RefineTerm:getRefineTerm()
	do return self
 end end

function RefineTerm:getType()
	do return self._type
 end end

function RefineTerm:initVariable(vImmutVariable)
	assert(not self._symbolVariable, "term can only set symbolvariable once")
	self._symbolVariable = vImmutVariable
	for nType, nVariableCase in pairs(self._typeToCase) do
		local nNewVariableCase = VariableCase.new() & nVariableCase
		local nImmutVariable = self._symbolVariable
		if nImmutVariable then
			nNewVariableCase:put_and(nImmutVariable, nType)
		end
		self._typeToCase[nType] = nNewVariableCase
	::continue:: end
end

function RefineTerm:includeAtomCase(vType)  
	local nIncludeType = self._type:includeAtom(vType)
	if nIncludeType then
		do return nIncludeType, self._typeToCase[nIncludeType]
	 end else
		do return false, nil
	 end end
end

function RefineTerm:filter(vContext, vType)
	local nTypeCaseList = {}
	vType:foreach(function(vSubType)
		local nIncludeType = self._type:includeAtom(vSubType)
		if nIncludeType then
			local nCase = self._typeToCase[nIncludeType]
			nTypeCaseList[#nTypeCaseList + 1] = {vSubType, nCase}
		else
			nTypeCaseList[#nTypeCaseList + 1] = {vSubType, VariableCase.new()}
		end
	end)
	do return vContext:mergeToRefineTerm(nTypeCaseList)
 end end

function RefineTerm:attachImmutVariable()
	local nImmutVariable = self._symbolVariable
	if not nImmutVariable then
		nImmutVariable = ImmutVariable.new(self)
		self:initVariable(nImmutVariable)
	end
	do return nImmutVariable
 end end

function RefineTerm:notnilTerm()
	local nNotnilTerm = self._notnilTerm
	if nNotnilTerm then
		do return nNotnilTerm
	 end end
	local nType = self._type
	if not nType:isNilable() then
		self._notnilTerm = self
		do return self
	 end end
	local nTypeToCase  = {}
	nType:foreach(function(vAtomType)
		if not Nil.is(vAtomType) then
			nTypeToCase[vAtomType] = self._typeToCase[vAtomType]
		end
	end)
	local nTerm = RefineTerm.new(self._node, nType:notnilType(), nTypeToCase)
	self._notnilTerm = nTerm
	do return nTerm
 end end

do return RefineTerm
 end 
end end
--thlua.term.RefineTerm end ==========)

--thlua.term.VariableCase begin ==========(
do local _ENV = _ENV
packages['thlua.term.VariableCase'] = function (...)


local VariableCase = {}

  

VariableCase.__index = VariableCase
VariableCase.__bor=function(vLeftVariableCase, vRightVariableCase)
	local nNewVariableCase = VariableCase.new()
	for nImmutVariable, nLeftType in pairs(vLeftVariableCase) do
		local nRightType = vRightVariableCase[nImmutVariable]
		if nRightType then
			nNewVariableCase[nImmutVariable] = nLeftType | nRightType
		end
	::continue:: end
	do return nNewVariableCase
 end end
VariableCase.__band=function(vLeftVariableCase, vRightVariableCase)
	local nNewVariableCase = VariableCase.new()
	for nImmutVariable, nLeftType in pairs(vLeftVariableCase) do
		local nRightType = vRightVariableCase[nImmutVariable]
		if nRightType then
			nNewVariableCase[nImmutVariable] = nLeftType & nRightType
		else
			nNewVariableCase[nImmutVariable] = nLeftType
		end
	::continue:: end
	for nImmutVariable, nRightType in pairs(vRightVariableCase) do
		if not vLeftVariableCase[nImmutVariable] then
			nNewVariableCase[nImmutVariable] = nRightType
		end
	::continue:: end
	do return nNewVariableCase
 end end
VariableCase.__tostring=function(self)
	local l={"VariableCase("}
	for nImmutVariable, vType in pairs(self) do
		l[#l + 1] = tostring(nImmutVariable).."->"..tostring(vType)
	::continue:: end
	l[#l + 1] = ")"
	do return table.concat(l,"|")
 end end

function VariableCase.new()
	do return setmetatable({
		
	
	}, VariableCase)
 end end

function VariableCase:put_and(vImmutVariable, vType)
	local nCurType = self[vImmutVariable]
	if not nCurType then
		self[vImmutVariable] = vType
	else
		self[vImmutVariable] = nCurType & vType
	end
end

function VariableCase:copy()
	local nCopy = VariableCase.new()
	for k,v in pairs(self) do
		nCopy:put_and(k, v)
	::continue:: end
	do return nCopy
 end end

function VariableCase:empty()
	if next(self) then
		do return true
	 end else
		do return false
	 end end
end

function VariableCase.is(t)
	do return getmetatable(t) == VariableCase
 end end

do return VariableCase
 end 
end end
--thlua.term.VariableCase end ==========)

--thlua.tuple.DotsTail begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.DotsTail'] = function (...)

  

local DotsTail = {}
DotsTail.__index=DotsTail

function DotsTail.new(vContext, vRepeatType)
	local self = setmetatable({
		_context=vContext,
		_manager=vContext:getTypeManager(),
		_termList={},
		_repeatType=vRepeatType,
	}, DotsTail)
	do return self
 end end

function DotsTail:getRepeatType()
	do return self._repeatType
 end end

function DotsTail:getMore(vContext, vMore)
	local nTermList = self._termList
	local nTerm = nTermList[vMore]
	if nTerm then
		do return nTerm
	 end else
		for i=#nTermList + 1, vMore do
			nTermList[i] = vContext:RefineTerm(self._repeatType:checkAtomUnion():withnilType())
		::continue:: end
		do return nTermList[vMore]
	 end end
end

function DotsTail.is(t)
	do return getmetatable(t) == DotsTail
 end end

do return DotsTail
 end 
end end
--thlua.tuple.DotsTail end ==========)

--thlua.tuple.RetBuilder begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.RetBuilder'] = function (...)

local RetTuples = require "thlua.tuple.RetTuples"
local class = require "thlua.class"

  

local RetBuilder = class ()

function RetBuilder:ctor(vManager, vNode)
	self._manager = vManager
	self._dirtyProcessor = vManager:getDirtyProcessor()
	self._tupleList = {}  
	self._errType = false
	self._node=vNode
end

function RetBuilder:chainRetDots(vNode, ...)
	local nTypeList = self._dirtyProcessor:easyToTypeList(vNode, ...)
	local nLen = #nTypeList
	assert(nLen > 0, vNode:toExc("RetDots must take at least 1 value"))
	local nDotsType = nTypeList[nLen]
	nTypeList[#nTypeList] = nil
	local nTypeTuple = self._manager:TypeTuple(self._node, nTypeList):withDots(nDotsType)
	local nTupleList = self._tupleList
	nTupleList[#nTupleList + 1] = nTypeTuple
end

function RetBuilder:chainRet(vNode, ...)
	local nTypeList = self._dirtyProcessor:easyToTypeList(vNode, ...)
	local nTypeTuple = self._manager:TypeTuple(self._node, nTypeList)
	local nTupleList = self._tupleList
	nTupleList[#nTupleList + 1] = nTypeTuple
end

function RetBuilder:chainErr(vNode, vErrType)
	self._errType = self._dirtyProcessor:easyToType(vNode, vErrType)
end

function RetBuilder:isEmpty()
	do return #self._tupleList == 0 and not self._errType
 end end

function RetBuilder:build()
	local nTupleList = self._tupleList
	if #nTupleList == 0 then
		do return self._manager:VoidRetTuples(self._node, self._errType or nil)
	 end else
		do return RetTuples.new(self._manager, self._node, nTupleList, self._errType)
	 end end
end

do return RetBuilder
 end 
end end
--thlua.tuple.RetBuilder end ==========)

--thlua.tuple.RetTuples begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.RetTuples'] = function (...)

local class = require "thlua.class"

  

local RetTuples = class ()

RetTuples.__tostring=function(self)
	do return self:detailString({}, false)
 end end

function RetTuples:ctor(
	vManager,
	vNode,
	vTupleList,
	vErrType
)
	assert(#vTupleList > 0, "length of tuple list must be bigger than 0 when pass to RetTuples' constructor")
	local nFirstToTuple  = {}
	for _, nTuple in ipairs(vTupleList) do
		local nFirst = nTuple:get(1)
		nFirstToTuple[nFirst] = nTuple
	::continue:: end
	local nTask = vManager:getScheduleManager():newTask()
	local nAsyncFirstType = vManager:AsyncUnion(nTask)
	self._node=vNode
	self._task = nTask
	self._manager=vManager
	self._firstType=nAsyncFirstType
	self._firstToTuple=nFirstToTuple
	self._errType = vErrType and self._manager:buildUnion(vNode, self._manager.type.String, vErrType) or self._manager.type.String
	nTask:runAsync(function()
		local nIndependentList = {}
		local nFirstAtomList = {}
		for _, nTuple in ipairs(vTupleList) do
			local nFirst = nTuple:get(1):checkAtomUnion()
			assert(not nFirst:isNever(), "can't return never")
			nIndependentList[#nIndependentList + 1] = nFirst
			nFirst:foreach(function(vAtomType)
				nFirstAtomList[#nFirstAtomList + 1] = vAtomType
			end)
		::continue:: end
		local nAtomUnion = nAsyncFirstType:setAtomList(nFirstAtomList)
		if not vManager:typeCheckIndependent(nIndependentList, nAtomUnion) then
			error("return tuples' first type must be independent")
		end
	end)
end

function RetTuples:detailString(vCache , vVerbose)
	local re = {}
	for _, t in pairs(self._firstToTuple) do
		re[#re+1] = t:detailString(vCache, vVerbose)
	::continue:: end
	do return "("..table.concat(re, "|")..")"
 end end

function RetTuples:assumeIncludeTuples(vAssumeSet , vRetTuples)
	for _, t in pairs(vRetTuples._firstToTuple) do
		if not self:assumeIncludeTuple(vAssumeSet, t) then
			do return false
		 end end
	::continue:: end
	if not self._errType:assumeIncludeAll(vAssumeSet, vRetTuples._errType) then
		do return false
	 end end
	do return true
 end end

function RetTuples:includeTuples(vRetTuples)
	do return self:assumeIncludeTuples(nil, vRetTuples)
 end end

function RetTuples:assumeIncludeTuple(vAssumeSet , vRightTypeTuple)
	for _, t in pairs(self._firstToTuple) do
		if t:assumeIncludeTuple(vAssumeSet, vRightTypeTuple) then
			do return true
		 end end
	::continue:: end
	do return false
 end end

function RetTuples:includeTuple(vRightTypeTuple)
	do return self:assumeIncludeTuple(nil, vRightTypeTuple)
 end end

function RetTuples:foreachWithFirst(vFunc )
	for nFirst, nTuple in pairs(self._firstToTuple) do
		vFunc(nTuple, nFirst)
	::continue:: end
end

function RetTuples:getFirstType()
	do return self._firstType:getTypeAwait()
 end end

function RetTuples:getErrType()
	do return self._errType:checkAtomUnion()
 end end

do return RetTuples
 end 
end end
--thlua.tuple.RetTuples end ==========)

--thlua.tuple.TermTuple begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.TermTuple'] = function (...)

local Exception = require "thlua.Exception"
local AutoHolder = require "thlua.auto.AutoHolder"
local DotsTail = require "thlua.tuple.DotsTail"
local AutoTail = require "thlua.auto.AutoTail"


	  
	  
	  
	   


local TermTuple = {}

TermTuple.__index=TermTuple
function TermTuple:__tostring()
	local re = {}
	for i=1, #self do
		re[i] = tostring(self._list[i]:getType())
	::continue:: end
	local nTail = self._tail
	if nTail then
		re[#re + 1] = tostring(nTail) .."*"
	end
	if self._auto then
		do return "AutoTermTuple("..table.concat(re, ",")..")"
	 end else
		do return "FixedTermTuple("..table.concat(re, ",")..")"
	 end end
end

function TermTuple:__len()
	do return #self._list
 end end

function TermTuple.new(
	vContext,
	vAuto,
	vTermList  ,
	vTail   ,
	vTypeTuple
)
	local self = setmetatable({
		_context=vContext,
		_manager=vContext:getTypeManager(),
		_list=vTermList,
		_tail=vTail,
		_typeTuple=vTypeTuple,
		_auto=vAuto,
	}, TermTuple)
	do return self
 end end

function TermTuple:select(vContext, i) 
	local nList = {}
	for n=i,#self._list do
		nList[#nList + 1] = self._list[n]
	::continue:: end
	     
	if self._auto then
		do return self._context:UTermTupleByTail(nList, self._tail)
	 end else
		do return self._context:FixedTermTuple(nList, self:getRepeatType())
	 end end
end

function TermTuple:rawget(i)
	do return self._list[i]
 end end

function TermTuple:checkFixed(vContext, i)
	local nTerm = self:get(vContext, i)
	do return nTerm:checkRefineTerm(vContext)
 end end

function TermTuple:get(vContext, i)
	local nMore = i - #self
	if nMore <= 0 then
		do return self._list[i]
	 end else
		local nTail = self._tail
		if nTail then
			do return nTail:getMore(vContext, nMore)
		 end else
			do return vContext:RefineTerm(self._manager.type.Nil)
		 end end
	end
end

function TermTuple:getContext()
	do return self._context
 end end

function TermTuple:checkTypeTuple(vSeal)  
	if self._auto then
		local nTypeList = {}
		for i,v in ipairs(self._list) do
			local nType = v:getType()
			if not nType then
				do return false
			 end end
			nTypeList[i] = nType
		::continue:: end
		local nTail = self._tail
		if AutoTail.is(nTail) then
			local nTailTuple = nTail:checkTypeTuple(vSeal)
			if not nTailTuple then
				do return false
			 end else
				for i=1,#nTailTuple do
					nTypeList[#nTypeList + 1] = nTailTuple:get(i)
				::continue:: end
				local nFinalTuple = self._manager:TypeTuple(self._context:getNode(), nTypeList)
				local nRepeatType = nTailTuple:getRepeatType()
				if nRepeatType then
					do return nFinalTuple:withDots(nRepeatType)
				 end else
					do return nFinalTuple
				 end end
			end
		else
			local nTuple = self._manager:TypeTuple(self._context:getNode(), nTypeList)
			if not nTail then
				do return nTuple
			 end else
				do return nTuple:withDots(nTail:getRepeatType())
			 end end
		end
	else
		local nTypeTuple = self._typeTuple
		if not nTypeTuple then
			local nList = {}
			for i,v in ipairs(self._list) do
				nList[i] = v:getType()
			::continue:: end
			nTypeTuple = self._manager:TypeTuple(self._context:getNode(), nList)
			local nTail = self._tail
			if nTail then
				nTypeTuple = nTypeTuple:withDots(nTail:getRepeatType())
			end
			self._typeTuple = nTypeTuple
			do return nTypeTuple
		 end else
			do return nTypeTuple
		 end end
	end
end

function TermTuple:getTail()
	do return self._tail
 end end

function TermTuple:getRepeatType()
	local nTail = self._tail
	if DotsTail.is(nTail) then
		do return nTail:getRepeatType()
	 end else
		do return false
	 end end
end

function TermTuple.is(t)
	do return getmetatable(t) == TermTuple
 end end

function TermTuple.isAuto(t)
	do return getmetatable(t) == TermTuple and t._auto
 end end

function TermTuple.isFixed(t)
	do return getmetatable(t) == TermTuple and not t._auto
 end end

do return TermTuple
 end 
end end
--thlua.tuple.TermTuple end ==========)

--thlua.tuple.TupleClass begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.TupleClass'] = function (...)

local TermTuple = require "thlua.tuple.TermTuple"


	  
	   


local function TupleClass()
	local t = {}
	t.__index=t
	t.__tostring=function(self)
		do return self:detailString({}, false)
	 end end
	function t.__len(self)
		do return #self._list
	 end end
	function t:detailStringIfFirst(vCache , vVerbose, vHasFirst)
		local re = {}
		local nStartIndex = vHasFirst and 1 or 2
		for i=nStartIndex, #self do
			re[#re + 1] = self._list[i]:detailString(vCache, vVerbose)
		::continue:: end
		local nRepeatType = self:getRepeatType()
		if nRepeatType then
			re[#re + 1] = nRepeatType:detailString(vCache, vVerbose) .."*"
		end
		do return "Tuple("..table.concat(re, ",")..")"
	 end end
	function t:detailString(vCache , vVerbose)
		do return self:detailStringIfFirst(vCache, vVerbose, true)
	 end end
	function t:makeTermTuple(vContext)
		local nTermList = {}
		for i=1, #self do
			nTermList[i] = vContext:RefineTerm(self._list[i])
		::continue:: end
		do return vContext:FixedTermTuple(nTermList, self:getRepeatType(), self)
	 end end
	function t:assumeIncludeTuple(vAssumeSet , vRightTypeTuple)
		local nLeftRepeatType = self:getRepeatType()
		local nRightRepeatType = vRightTypeTuple:getRepeatType()
		if (not nLeftRepeatType) and nRightRepeatType then
			do return false
		 end end
		if nLeftRepeatType and nRightRepeatType then
			if not nLeftRepeatType:assumeIncludeAll(vAssumeSet, nRightRepeatType) then
				do return false
			 end end
		end
		     
		for i=1, #vRightTypeTuple do
			local nLeftType = self._list[i] or nLeftRepeatType
			if not nLeftType then
				do return false
			 end end
			if not nLeftType:assumeIncludeAll(vAssumeSet, vRightTypeTuple:get(i)) then
				do return false
			 end end
		::continue:: end
		for i=#vRightTypeTuple + 1, #self do
			local nLeftType = self._list[i]:checkAtomUnion()
			if not nLeftType:isNilable() then
				do return false
			 end end
			if nRightRepeatType then
				if not nLeftType:assumeIncludeAll(vAssumeSet, nRightRepeatType) then
					do return false
				 end end
			end
		::continue:: end
		do return true
	 end end
	function t:includeTuple(vRightTypeTuple)
		do return self:assumeIncludeTuple(nil, vRightTypeTuple)
	 end end
	do return t
 end end

do return TupleClass
 end 
end end
--thlua.tuple.TupleClass end ==========)

--thlua.tuple.TypeTuple begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.TypeTuple'] = function (...)

local Reference = require "thlua.refer.Reference"
local TupleClass = require "thlua.tuple.TupleClass"
local TypeTupleDots = require "thlua.tuple.TypeTupleDots"
local Nil = require "thlua.type.basic.Nil"
local TypeTuple = TupleClass()

  

function TypeTuple.new(vManager, vNode, vList)
	local self = setmetatable({
		_manager=vManager,
		_node=vNode,
		_list=vList,
	}, TypeTuple)
	do return self
 end end

function TypeTuple:getRepeatType()
	do return false
 end end

function TypeTuple:withDots(vType)
	local nWithNil = self._manager:buildUnion(self._node, vType, self._manager.type.Nil)
	do return TypeTupleDots.new(self._manager, self._node, self._list, vType, nWithNil)
 end end

function TypeTuple:leftAppend(vType)
	do return TypeTuple.new(self._manager, self._node, {vType, table.unpack(self._list)})
 end end

function TypeTuple:get(i)
	do return self._list[i] or self._manager.type.Nil
 end end

function TypeTuple:select(i)
	do return self._manager:TypeTuple(self._node, {table.unpack(self._list, i)})
 end end

function TypeTuple.is(t)
	do return getmetatable(t) == TypeTuple
 end end

do return TypeTuple
 end 
end end
--thlua.tuple.TypeTuple end ==========)

--thlua.tuple.TypeTupleDots begin ==========(
do local _ENV = _ENV
packages['thlua.tuple.TypeTupleDots'] = function (...)

local TupleClass = require "thlua.tuple.TupleClass"
local TypeTupleDots = TupleClass()

  

function TypeTupleDots.new(
	vManager,
	vNode,
	vList,
	vRepeatType,
	vRepeatTypeWithNil
)
	local self = setmetatable({
		_manager=vManager,
		_node=vNode,
		_list=vList,
		_repeatType=vRepeatType,
		_repeatTypeWithNil=vRepeatTypeWithNil,
	}, TypeTupleDots)
	do return self
 end end

function TypeTupleDots:getRepeatType()
	do return self._repeatType
 end end

function TypeTupleDots:leftAppend(vType)
	do return TypeTupleDots.new(self._manager, self._node, {vType, table.unpack(self._list)}, self._repeatType, self._repeatTypeWithNil)
 end end

function TypeTupleDots:get(i)
	if i <= #self then
		do return self._list[i]
	 end else
		do return self._repeatTypeWithNil
	 end end
end

function TypeTupleDots:select(i)
	local nList  = {table.unpack(self._list, i)}
	do return TypeTupleDots.new(self._manager, self._node, nList, self._repeatType, self._repeatTypeWithNil)
 end end

function TypeTupleDots.is(t)
	do return getmetatable(t) == TypeTupleDots
 end end

do return TypeTupleDots
 end 
end end
--thlua.tuple.TypeTupleDots end ==========)

--thlua.type.OPER_ENUM begin ==========(
do local _ENV = _ENV
packages['thlua.type.OPER_ENUM'] = function (...)

    

local comparison = {
	[">"]="__lt",
	["<"]="__lt",
	[">="]="__le",
	["<="]="__le",
}

local mathematic = {
	["+"]="__add",
	["-"]="__sub",
	["*"]="__mul",
	["/"]="__div",
	["//"]="__idiv",
	["%"]="__mod",
	["^"]="__pow",
}

local bitwise = {
	["&"]="__band",
	["|"]="__bor",
	["~"]="__bxor",
	["<<"]="__shr",
	[">>"]="__shl",
}

local uopNoLen = {
	["-"]="__unm",
	["~"]="__bnot"
}

local bopNoEq = {
	[".."]="__concat"
}

for k,v in pairs(comparison) do
	bopNoEq[k] = v
::continue:: end

for k,v in pairs(bitwise) do
	bopNoEq[k] = v
::continue:: end

for k,v in pairs(mathematic) do
	bopNoEq[k] = v
::continue:: end

do return {
	bitwise=bitwise,
	mathematic=mathematic,
	comparison=comparison,
	bopNoEq=bopNoEq,
	uopNoLen=uopNoLen,
}
 end 
end end
--thlua.type.OPER_ENUM end ==========)

--thlua.type.TYPE_BITS begin ==========(
do local _ENV = _ENV
packages['thlua.type.TYPE_BITS'] = function (...)

local TYPE_BITS = {
	NEVER = 0,
	NIL = 1,
	FALSE = 1 << 1,
	TRUE = 1 << 2,
	NUMBER = 1 << 3,
	STRING = 1 << 4,
	OBJECT = 1 << 5,
	FUNCTION = 1 << 6,
	THREAD = 1 << 7,
	LIGHTUSERDATA = 1 << 8,
	TRUTH = 0x1FF-3,        
}

do return TYPE_BITS
 end 
end end
--thlua.type.TYPE_BITS end ==========)

--thlua.type.TypeClass begin ==========(
do local _ENV = _ENV
packages['thlua.type.TypeClass'] = function (...)



  

  

  
	  
		   
		  
	


  
  
  

   
    
    
   

    

   
	
	
	

	

	  

	
	
	  
	 

	
	   
	

	


 
	 
	 


    
	
	
	
	
	
	
	
	
	
	
	
	   
	   
	
	


    
	
	

	
	

	

	  

	 
	   
	 
	  

	
	
	
	 
	    

	 
	  
	   
	
	  

	
	


    
	
	

	

	

	


   
    



do return {}
 end 
end end
--thlua.type.TypeClass end ==========)

--thlua.type.basic.BaseAtomType begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.BaseAtomType'] = function (...)


local Exception = require "thlua.Exception"
local OPER_ENUM = require "thlua.type.OPER_ENUM"

local class = require "thlua.class"
local BaseReadyType = require "thlua.type.basic.BaseReadyType"

  

local BaseAtomType = class (BaseReadyType)

function BaseAtomType:ctor(vManager, ...)
	self.id = vManager:genTypeId()
	self.bits = false  
	self._manager:atomRecordTypeUnionSign(self)
end

function BaseAtomType.__bor(vLeft, vRight)
	do return vLeft._manager:checkedUnion(vLeft, vRight)
 end end

function BaseAtomType:foreach(vFunc)
	vFunc(self)
end

function BaseAtomType:isSingleton()
	error(tostring(self).."is singleton TODO")
	do return false
 end end

   
function BaseAtomType:meta_ipairs(vContext)
	vContext:error(tostring(self).."'s meta_ipairs not implement")
	do return false
 end end

function BaseAtomType:meta_pairs(vContext)
	vContext:error(tostring(self).."'s meta_pairs not implement")
	do return false
 end end

function BaseAtomType:meta_set(vContext, vKeyType, vValueType)
	vContext:error(tostring(self).." can't take set index")
end

function BaseAtomType:meta_get(vContext, vKeyType)
	vContext:error(tostring(self).." can't take get index")
	do return false
 end end

function BaseAtomType:meta_call(vContext, vTypeTuple)
	vContext:error(tostring(self).." can't take call")
	vContext:pushRetTuples(self._manager:VoidRetTuples(vContext:getNode()))
end

function BaseAtomType:meta_invoke(vContext, vSelfType, vPolyArgs, vTypeTuple)
	if #vPolyArgs > 0 then
		local nCast = self:castPoly(vContext, vPolyArgs) or self
		nCast:meta_call(vContext, vTypeTuple)
	else
		self:meta_call(vContext, vTypeTuple)
	end
end

function BaseAtomType:meta_bop_func(vContext, vOper)
	if OPER_ENUM.mathematic[vOper] then
		if vOper == "/" then
			do return false, self._manager.builtin.bop.mathematic_divide
		 end else
			do return false, self._manager.builtin.bop.mathematic_notdiv
		 end end
	elseif OPER_ENUM.bitwise[vOper] then
		do return false, self._manager.builtin.bop.bitwise
	 end elseif OPER_ENUM.comparison[vOper] then
		do return false, self._manager.builtin.bop.comparison
	 end elseif vOper == ".." then
		do return false, self._manager.builtin.bop.concat
	 end else
		vContext:error("invalid bop:"..tostring(vOper))
		do return false, nil
	 end end
end

function BaseAtomType:meta_len(vContext)
	vContext:error(tostring(self).." can't take len oper")
	do return self._manager.type.Integer
 end end

function BaseAtomType:meta_uop_some(vContext, vOper)
	vContext:error(tostring(self).." can't take uop :"..vOper)
	do return self._manager.type.Integer
 end end

   
function BaseAtomType:native_next(vContext, vInitType)
	error("native_next not implement")
end

function BaseAtomType:native_tostring()
	do return self._manager.type.String
 end end

function BaseAtomType:native_rawget(vContext, vKeyType)
	vContext:error(tostring(self).." rawget not implement")
	do return self._manager.type.Nil
 end end

function BaseAtomType:native_rawset(vContext, vKeyType, vValueType)
	vContext:error(tostring(self).." rawset not implement")
end

function BaseAtomType:castPoly(vContext, vTypeArgsList)
	vContext:error("poly cast can't work on this type:"..tostring(self))
	do return false
 end end

function BaseAtomType:native_type()
	print("native_type not implement ")
	do return self._manager.type.String
 end end

function BaseAtomType:native_getmetatable(vContext)
	do return self._manager.type.Nil
 end end

function BaseAtomType:native_setmetatable(vContext, vTable)
	vContext:error("this type setmetatable not implement")
end

function BaseAtomType:checkTypedObject()
	do return false
 end end

function BaseAtomType:isUnion()
	do return false
 end end

function BaseAtomType:checkAtomUnion()
	do return self
 end end

function BaseAtomType:isNever()
	do return false
 end end

function BaseAtomType:isNilable()
	do return false
 end end

function BaseAtomType:assumeIncludeAtom(vAssumeSet, vRightType, vSelfType)
	if self == vRightType then
		do return self
	 end else
		do return false
	 end end
end

function BaseAtomType:assumeIntersectAtom(vAssumeSet, vRightType)
	if self == vRightType then
		do return self
	 end elseif vRightType:assumeIncludeAtom(nil, self) then
		do return self
	 end elseif self:assumeIncludeAtom(nil, vRightType) then
		do return vRightType
	 end else
		do return false
	 end end
end

function BaseAtomType:putCompletion(vCompletion)
end

function BaseAtomType:setLocked()
	  
end

function BaseAtomType:findRequireStack()
	do return false
 end end

do return BaseAtomType
 end 
end end
--thlua.type.basic.BaseAtomType end ==========)

--thlua.type.basic.BaseReadyType begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.BaseReadyType'] = function (...)


local Exception = require "thlua.Exception"
local OPER_ENUM = require "thlua.type.OPER_ENUM"

local class = require "thlua.class"

  

local BaseReadyType = class ()

function BaseReadyType:ctor(vManager, ...)
	self._manager = vManager
	self._withnilType = false  
	self.id = 0  
end

function BaseReadyType:detailString(_, _)
	do return "detailString not implement"
 end end

function BaseReadyType:__tostring()
	do return self:detailString({}, false)
 end end

function BaseReadyType.__bor(vLeft, vRight)
	do return vLeft._manager:checkedUnion(vLeft, vRight)
 end end

function BaseReadyType.__band(vLeft, vRight)
	local nTypeOrFalse = vLeft:safeIntersect(vRight)
	if nTypeOrFalse then
		do return nTypeOrFalse
	 end else
		error("unexpected intersect")
	end
end

function BaseReadyType:unionSign()
	do return tostring(self.id)
 end end

function BaseReadyType:mayRecursive()
	do return false
 end end

function BaseReadyType:putCompletion(vCompletion)
end

function BaseReadyType:foreach(vFunc)
	error("foreach not implement")
end

function BaseReadyType:foreachAwait(vFunc)
	self:foreach(vFunc)
end

function BaseReadyType:isReference()
	do return false
 end end



   



function BaseReadyType:intersectAtom(vRight)
	do return self:assumeIntersectAtom(nil, vRight)
 end end

function BaseReadyType:includeAtom(vRight)
	do return self:assumeIncludeAtom(nil, vRight)
 end end

function BaseReadyType:assumeIntersectSome(vAssumeSet, vRight)
	local nSomeIntersect = false
	vRight:foreachAwait(function(vSubType)
		if not nSomeIntersect and self:assumeIntersectAtom(vAssumeSet, vSubType) then
			nSomeIntersect = true
		end
	end)
	do return nSomeIntersect
 end end

function BaseReadyType:assumeIncludeAll(vAssumeSet, vRight, vSelfType)
	local nAllInclude = true
	vRight:foreachAwait(function(vSubType)
		if nAllInclude and not self:assumeIncludeAtom(vAssumeSet, vSubType, vSelfType) then
			nAllInclude = false
		end
	end)
	do return nAllInclude
 end end

function BaseReadyType:intersectSome(vRight)
	do return self:assumeIntersectSome(nil, vRight)
 end end

function BaseReadyType:includeAll(vRight)
	do return self:assumeIncludeAll(nil, vRight)
 end end

function BaseReadyType:safeIntersect(vRight)
	local nLeft = self
	local nRight = vRight:isReference() and vRight:checkAtomUnion() or vRight
	if not nRight:isUnion() then
		local nIntersect = nLeft:assumeIntersectAtom(nil, nRight)
		if nIntersect == true then
			do return false
		 end else
			do return nIntersect or self._manager.type.Never
		 end end
	else
		local nCollection = self._manager:TypeCollection()
		nRight:foreach(function(vSubType)
			local nIntersect = nLeft:assumeIntersectAtom(nil, vSubType)
			if nIntersect then
				if nIntersect == true then
					do return
				 end else
					nCollection:put(nIntersect)
				end
			end
		end)
		do return nCollection:mergeToAtomUnion()
	 end end
end

function BaseReadyType:assumeIncludeAtom(_, _, _)
	error("not implement")
	do return false
 end end

function BaseReadyType:assumeIntersectAtom(_, _)
	error("not implement")
	do return false
 end end



    


function BaseReadyType:isNever()
	do return false
 end end

function BaseReadyType:notnilType()
	do return self
 end end

function BaseReadyType:isNilable()
	do return false
 end end

function BaseReadyType:partTypedObject()
	do return self._manager.type.Never
 end end

function BaseReadyType:partTypedFunction()
	do return self._manager.type.Never
 end end

function BaseReadyType:falseType()
	do return self._manager.type.Never
 end end

function BaseReadyType:trueType()
	do return self
 end end

function BaseReadyType:withnilType()
	local nWithNilType = self._withnilType
	if not nWithNilType then
		local nCollection = self._manager:TypeCollection()
		nCollection:put(self  )
		nCollection:put(self._manager.type.Nil)
		nWithNilType = nCollection:mergeToAtomUnion()
		self._withnilType = nWithNilType
	end
	do return nWithNilType
 end end

function BaseReadyType:setAssigned(vContext)
end

function BaseReadyType:isAsync()
	do return false
 end end

do return BaseReadyType
 end 
end end
--thlua.type.basic.BaseReadyType end ==========)

--thlua.type.basic.BooleanLiteral begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.BooleanLiteral'] = function (...)

local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local BooleanLiteral = class (BaseAtomType)

function BooleanLiteral:ctor(vManager, vLiteral)
	self.literal=vLiteral
	self.bits=vLiteral and TYPE_BITS.TRUE or TYPE_BITS.FALSE
end

function BooleanLiteral:detailString(v, vVerbose)
	if vVerbose then
		do return "Literal("..tostring(self.literal)..")"
	 end else
		do return self.literal and "True" or "False"
	 end end
end

function BooleanLiteral:isSingleton()
	do return true
 end end

function BooleanLiteral:native_type()
	do return self._manager:Literal("boolean")
 end end

function BooleanLiteral:trueType()
	if self.literal then
		do return self
	 end else
		do return self._manager.type.Never
	 end end
end

function BooleanLiteral:falseType()
	if self.literal then
		do return self._manager.type.Never
	 end else
		do return self
	 end end
end

do return BooleanLiteral
 end 
end end
--thlua.type.basic.BooleanLiteral end ==========)

--thlua.type.basic.Enum begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.Enum'] = function (...)

local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"


  

local Enum = class (BaseAtomType)

function Enum:ctor(vManager, vSuperType)
    self._superType = vSuperType
    self._task = vManager:getScheduleManager():newTask()
    self._set = {}   
    self._toAddList = {}  
    self._addEvent = false  
	self.bits = vSuperType.bits
    self._task:runAsync(function()
        while true do
            local nAddList = self._toAddList
            if #nAddList == 0 then
                local nEvent = vManager:getScheduleManager():makeEvent()
                self._addEvent = nEvent
                nEvent:wait()
                self._addEvent = false
            end
            self._toAddList = {}
            for i=1,#nAddList do
                local nType = nAddList[i]
                nType:foreachAwait(function(vAtomType)
                    self._set[vAtomType] = true
                end)
            ::continue:: end
        ::continue:: end
    end)
end

function Enum:addType(vType)
    local nAddList = self._toAddList
    nAddList[#nAddList + 1] = vType
    local nAddEvent = self._addEvent
    if nAddEvent then
        nAddEvent:wakeup()
    end
end

function Enum:native_type()
    local nSuperType = self._superType
    if nSuperType:isUnion() then
        do return self._manager.type.String
     end else
        do return nSuperType:native_type()
     end end
end

function Enum:detailString(vCache, vVerbose)
    do return "Enum("..self._superType:detailString(vCache, vVerbose)..")"
 end end

function Enum:isSingleton()
	do return false
 end end

do return Enum
 end 
end end
--thlua.type.basic.Enum end ==========)

--thlua.type.basic.FloatLiteral begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.FloatLiteral'] = function (...)

local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"


  

local FloatLiteral = class (BaseAtomType)

function FloatLiteral:ctor(vManager, vLiteral)
	self.literal=vLiteral
	self.bits=TYPE_BITS.NUMBER
end

function FloatLiteral:getLiteral()
	do return self.literal
 end end

function FloatLiteral:native_type()
	do return self._manager:Literal("number")
 end end

function FloatLiteral:meta_uop_some(vContext, vOper)
	if vOper == "-" then
		do return self._manager:Literal(-self.literal)
	 end elseif vOper == "~" then
		do return self._manager:Literal(~self.literal)
	 end else
		do return self._manager.type.Never
	 end end
end

function FloatLiteral:detailString(vCache, vVerbose)
	do return "Literal("..self.literal..")"
 end end

function FloatLiteral:isSingleton()
	do return true
 end end

do return FloatLiteral
 end 
end end
--thlua.type.basic.FloatLiteral end ==========)

--thlua.type.basic.Integer begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.Integer'] = function (...)

local IntegerLiteral = require "thlua.type.basic.IntegerLiteral"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local Integer = class (BaseAtomType)

function Integer:ctor(vManager)
	self.bits=TYPE_BITS.NUMBER
end

function Integer:detailString(v, vVerbose)
	do return "Integer"
 end end

function Integer:meta_uop_some(vContext, vOper)
	do return self
 end end

function Integer:native_getmetatable(vContext)
	do return self._manager.type.Nil
 end end

function Integer:native_type()
	do return self._manager:Literal("number")
 end end

function Integer:assumeIncludeAtom(vAssumetSet, vType, _)
	if IntegerLiteral.is(vType) then
		do return self
	 end elseif self == vType then
		do return self
	 end else
		do return false
	 end end
end

function Integer:isSingleton()
	do return false
 end end

do return Integer
 end 
end end
--thlua.type.basic.Integer end ==========)

--thlua.type.basic.IntegerLiteral begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.IntegerLiteral'] = function (...)

local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"


  

local IntegerLiteral = class (BaseAtomType)

function IntegerLiteral:ctor(vManager, vLiteral)
	self.literal=vLiteral
	self.bits=TYPE_BITS.NUMBER
end

function IntegerLiteral:getLiteral()
	do return self.literal
 end end

function IntegerLiteral:native_type()
	do return self._manager:Literal("number")
 end end

function IntegerLiteral:meta_uop_some(vContext, vOper)
	if vOper == "-" then
		do return self._manager:Literal(-self.literal)
	 end elseif vOper == "~" then
		do return self._manager:Literal(~self.literal)
	 end else
		do return self._manager.type.Never
	 end end
end

function IntegerLiteral:detailString(vCache, vVerbose)
	do return "Literal("..self.literal..")"
 end end

function IntegerLiteral:isSingleton()
	do return true
 end end

do return IntegerLiteral
 end 
end end
--thlua.type.basic.IntegerLiteral end ==========)

--thlua.type.basic.LightUserdata begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.LightUserdata'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local LightUserdata = class (BaseAtomType)

function LightUserdata:ctor(vManager)
	self.bits = TYPE_BITS.LIGHTUSERDATA
end

function LightUserdata:detailString(vToStringCache, vVerbose)
	do return "LightUserdata"
 end end

function LightUserdata:native_getmetatable(vContext)
	do return self._manager.type.Nil
 end end

function LightUserdata:native_type()
	do return self._manager:Literal("userdata")
 end end

function LightUserdata:isSingleton()
	do return false
 end end

do return LightUserdata
 end 
end end
--thlua.type.basic.LightUserdata end ==========)

--thlua.type.basic.Nil begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.Nil'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local Nil = class (BaseAtomType)

function Nil:ctor(vManager)
	self.bits=TYPE_BITS.NIL
end

function Nil:detailString(v, vVerbose)
	do return "Nil"
 end end

function Nil:native_getmetatable(vContext)
	do return self._manager.type.Nil
 end end

function Nil:native_type()
	do return self._manager:Literal("nil")
 end end

function Nil:isSingleton()
	do return true
 end end

function Nil:trueType()
	do return self._manager.type.Never
 end end

function Nil:falseType()
	do return self
 end end

function Nil:isNilable()
	do return true
 end end

function Nil:notnilType()
	do return self._manager.type.Never
 end end

do return Nil
 end 
end end
--thlua.type.basic.Nil end ==========)

--thlua.type.basic.Number begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.Number'] = function (...)

local FloatLiteral = require "thlua.type.basic.FloatLiteral"
local IntegerLiteral = require "thlua.type.basic.IntegerLiteral"
local Integer = require "thlua.type.basic.Integer"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local Number = class (BaseAtomType)

function Number:ctor(vManager)
	self.bits=TYPE_BITS.NUMBER
end

function Number:detailString(v, vVerbose)
	do return "Number"
 end end

function Number:meta_uop_some(vContext, vOper)
	do return self
 end end

function Number:native_getmetatable(vContext)
	do return self._manager.type.Nil
 end end

function Number:native_type()
	do return self._manager:Literal("number")
 end end

function Number:assumeIncludeAtom(vAssumetSet, vType, _)
	if FloatLiteral.is(vType) then
		do return self
	 end elseif IntegerLiteral.is(vType) then
		do return self
	 end elseif Integer.is(vType) then
		do return self
	 end elseif self == vType then
		do return self
	 end else
		do return false
	 end end
end

function Number:isSingleton()
	do return false
 end end

do return Number
 end 
end end
--thlua.type.basic.Number end ==========)

--thlua.type.basic.String begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.String'] = function (...)

local StringLiteral = require "thlua.type.basic.StringLiteral"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local String = class (BaseAtomType)

function String:ctor(vManager)
	self.bits=TYPE_BITS.STRING
end

function String:detailString(v, vVerbose)
	do return "String"
 end end

function String:native_getmetatable(vContext)
	do return self._manager.builtin.string
 end end

function String:native_type()
	do return self._manager:Literal("string")
 end end

function String:meta_len(vContext)
	do return self._manager.type.Integer
 end end

function String:meta_get(vContext, vKeyType)
	do return self._manager.builtin.string:meta_get(vContext, vKeyType)
 end end

function String:assumeIncludeAtom(vAssumeSet, vType, _)
	if StringLiteral.is(vType) then
		do return self
	 end elseif self == vType then
		do return self
	 end else
		do return false
	 end end
end

function String:isSingleton()
	do return false
 end end

function String:putCompletion(vFieldCompletion)
	self._manager.builtin.string:putCompletion(vFieldCompletion)
end

do return String
 end 
end end
--thlua.type.basic.String end ==========)

--thlua.type.basic.StringLiteral begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.StringLiteral'] = function (...)

local OPER_ENUM = require "thlua.type.OPER_ENUM"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local StringLiteral = class (BaseAtomType)

function StringLiteral:ctor(vManager, vLiteral)
	self.literal=vLiteral
	self.bits=TYPE_BITS.STRING
end

function StringLiteral:getLiteral()
	do return self.literal
 end end

function StringLiteral:detailString(v, vVerbose)
	do return "Literal('"..self.literal.."')"
 end end

function StringLiteral:isSingleton()
	do return true
 end end

function StringLiteral:meta_len(vContext)
	do return self._manager.type.Integer
 end end

function StringLiteral:meta_get(vContext, vKeyType)
	do return self._manager.builtin.string:meta_get(vContext, vKeyType)
 end end

function StringLiteral:putCompletion(vFieldCompletion)
	self._manager.builtin.string:putCompletion(vFieldCompletion)
end

do return StringLiteral
 end 
end end
--thlua.type.basic.StringLiteral end ==========)

--thlua.type.basic.Thread begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.Thread'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local Thread = class (BaseAtomType)

function Thread:ctor(vManager)
	self.bits = TYPE_BITS.THREAD
end

function Thread:detailString(vToStringCache, vVerbose)
	do return "Thread"
 end end

function Thread:native_getmetatable(vContext)
	do return self._manager.type.Nil
 end end

function Thread:native_type()
	do return self._manager:Literal("thread")
 end end

function Thread:isSingleton()
	do return false
 end end

do return Thread
 end 
end end
--thlua.type.basic.Thread end ==========)

--thlua.type.basic.Truth begin ==========(
do local _ENV = _ENV
packages['thlua.type.basic.Truth'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local Truth = class (BaseAtomType)

function Truth:ctor(vManager)
	self.bits = TYPE_BITS.TRUTH
end

function Truth:detailString(vToStringCache, vVerbose)
	do return "Truth"
 end end

function Truth:native_setmetatable(vContext, vMetaTableType)
end

function Truth:native_getmetatable(vContext)
	do return self
 end end

function Truth:native_type()
	   
	do return self._manager.type.String
 end end

function Truth:native_rawget(vContext, vKeyType)
	do return self
 end end

function Truth:native_rawset(vContext, vKeyType, vValueTypeSet)
end

function Truth:meta_get(vContext, vKeyType)
	vContext:pushFirstAndTuple(self)
	do return true
 end end

function Truth:meta_set(vContext, vKeyType, vValueTerm)
end

function Truth:meta_call(vContext, vTypeTuple)
	vContext:pushRetTuples(self._manager:VoidRetTuples(vContext:getNode()))
end

function Truth:meta_pairs(vContext)
	do return false
 end end

function Truth:meta_ipairs(vContext)
	do return false
 end end

function Truth:native_next(vContext, vInitType)
	do return self._manager.type.Never, {}
 end end

function Truth:isSingleton()
	do return false
 end end

function Truth:assumeIncludeAtom(vAssumeSet, vType, _)
	local nManagerType = self._manager.type
	if vType == nManagerType.Nil then
		do return false
	 end elseif vType == nManagerType.False then
		do return false
	 end else
		do return self
	 end end
end

do return Truth
 end 
end end
--thlua.type.basic.Truth end ==========)

--thlua.type.func.AnyFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.AnyFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"
local TypedFunction = require "thlua.type.func.TypedFunction"
local PolyFunction = require "thlua.type.func.PolyFunction"

local BaseFunction = require "thlua.type.func.BaseFunction"
local class = require "thlua.class"

  

local AnyFunction = class (BaseFunction)

function AnyFunction:detailString(vToStringCache , vVerbose)
	do return "AnyFunction"
 end end

function AnyFunction:meta_call(vContext, vTypeTuple)
	vContext:pushRetTuples(self._manager:VoidRetTuples(vContext:getNode()))
end

function AnyFunction:assumeIncludeAtom(vAssumeSet, vRight, _)
	if BaseFunction.is(vRight) then
		do return self
	 end else
		do return false
	 end end
end

function AnyFunction:mayRecursive()
	do return false
 end end

do return AnyFunction
 end 
end end
--thlua.type.func.AnyFunction end ==========)

--thlua.type.func.AutoFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.AutoFunction'] = function (...)

local TypedFunction = require "thlua.type.func.TypedFunction"
local SealFunction = require "thlua.type.func.SealFunction"
local Exception = require "thlua.Exception"

local class = require "thlua.class"


	  


local AutoFunction = class (SealFunction)
AutoFunction.__tostring=function(self)
	do return "autofn@"..tostring(self._node)
 end end

function AutoFunction:ctor(...)
	self._castTypeFn=false
	self._firstCallCtx = false 
end

function AutoFunction:meta_call(vContext, vTermTuple)
	self._firstCallCtx = vContext
	local nTypeFn = self:getFnAwait()
	do return nTypeFn:meta_call(vContext, vTermTuple)
 end end

function AutoFunction:isCastable()
	do return not self._firstCallCtx
 end end

function AutoFunction:checkWhenCast(vContext, vTypeFn)
	if self._builderFn then
		local nOldTypeFn = self._castTypeFn
		if not nOldTypeFn then
			self._castTypeFn = vTypeFn
		else
			if vTypeFn:includeAll(nOldTypeFn) then
				self._castTypeFn = vTypeFn
			elseif nOldTypeFn:includeAll(vTypeFn) then
				 
			else
				vContext:error("auto-function cast to multi type", self._node)
			end
		end
		do return true
	 end else
		vContext:error("TODO, auto-function cast after building start", self._node)
		do return false
	 end end
end

function AutoFunction:pickCastTypeFn()
	do return self._castTypeFn
 end end

do return AutoFunction
 end 
end end
--thlua.type.func.AutoFunction end ==========)

--thlua.type.func.AutoMemberFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.AutoMemberFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local TypedFunction = require "thlua.type.func.TypedFunction"
local PolyFunction = require "thlua.type.func.PolyFunction"
local AutoFunction = require "thlua.type.func.AutoFunction"
local MemberFunction = require "thlua.type.func.MemberFunction"
local class = require "thlua.class"


	  


local AutoMemberFunction = class (MemberFunction)

function AutoMemberFunction:ctor(_, _, vPolyFn)
	self._polyFn = vPolyFn
	self._useNodeSet = {}
end

function AutoMemberFunction:detailString(vToStringCache , vVerbose)
	do return "AutoMemberFunction@"..tostring(self._node)
 end end

function AutoMemberFunction:meta_invoke(vContext, vSelfType, vPolyArgs, vTypeTuple)
	if #vPolyArgs == 0 and self:needPolyArgs() then
		vContext:error("TODO poly member function called without poly args")
	end
	local nTypeFn = self._polyFn:noCtxCastPoly({vSelfType, table.unpack(vPolyArgs)})
	nTypeFn:meta_call(vContext, vTypeTuple)
end

function AutoMemberFunction:needPolyArgs()
	do return self._polyFn:getPolyParNum() > 1
 end end

function AutoMemberFunction:indexAutoFn(vType)
	local nFn = self._polyFn:noCtxCastPoly({vType})
	if AutoFunction.is(nFn) then
		do return nFn
	 end else
		error("auto function is expected here")
	end
end

function AutoMemberFunction:indexTypeFn(vType)
	local nFn = self._polyFn:noCtxCastPoly({vType})
	if AutoFunction.is(nFn) then
		do return nFn:getFnAwait()
	 end elseif TypedFunction.is(nFn) then
		do return nFn
	 end else
		error("class factory can't member function")
	end
end

do return AutoMemberFunction
 end 
end end
--thlua.type.func.AutoMemberFunction end ==========)

--thlua.type.func.BaseFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.BaseFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"

  

local BaseFunction = class (BaseAtomType)

function BaseFunction:ctor(vManager, vNode, ...)
	self.bits=TYPE_BITS.FUNCTION
	self._node = vNode
	self._useNodeSet = false   
end

function BaseFunction:native_type()
	do return self._manager:Literal("function")
 end end

function BaseFunction:detailString(vToStringCache, vVerbose)
	do return "BaseFunction"
 end end

function BaseFunction:meta_call(vContext, vTermTuple)
	error("function "..tostring(self).." can't apply as call")
end

function BaseFunction:isSingleton()
	do return false
 end end

function BaseFunction:getNode()
	do return self._node
 end end

function BaseFunction:getUseNodeSet()
	do return self._useNodeSet
 end end

do return BaseFunction
 end 
end end
--thlua.type.func.BaseFunction end ==========)

--thlua.type.func.ClassFactory begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.ClassFactory'] = function (...)

local ClassTable = require "thlua.type.object.ClassTable"
local SealFunction = require "thlua.type.func.SealFunction"
local Exception = require "thlua.Exception"

local class = require "thlua.class"


	  


local ClassFactory = class (SealFunction)
function ClassFactory.__tostring(self)
	do return "class@"..tostring(self._node)
 end end

function ClassFactory:ctor(vManager, ...)
	local nTask = self._task
	self._classBuildEvent=nTask:makeEvent()
	self._classTable=ClassTable.new(self._manager, self._node, self._buildStack, self)
end

function ClassFactory:getClassTable(vWaitInit)
	local nTable = self._classTable
	if vWaitInit then
		nTable:waitInit()
	end
	do return nTable
 end end

function ClassFactory:wakeupTableBuild()
	self._classBuildEvent:wakeup()
end

function ClassFactory:waitTableBuild()
	self:startPreBuild()
	self:startLateBuild()
	if coroutine.running() ~= self._task:getSelfCo() then
		self._classBuildEvent:wait()
	end
end

do return ClassFactory
 end 
end end
--thlua.type.func.ClassFactory end ==========)

--thlua.type.func.MemberFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.MemberFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local TypedFunction = require "thlua.type.func.TypedFunction"
local PolyFunction = require "thlua.type.func.PolyFunction"
local AutoFunction = require "thlua.type.func.AutoFunction"
local BaseFunction = require "thlua.type.func.BaseFunction"
local class = require "thlua.class"


	  


local MemberFunction = class (BaseFunction)

function MemberFunction:detailString(vToStringCache , vVerbose)
	do return ""
 end end

do return MemberFunction
 end 
end end
--thlua.type.func.MemberFunction end ==========)

--thlua.type.func.OpenFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.OpenFunction'] = function (...)

local VariableCase = require "thlua.term.VariableCase"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local TermTuple = require "thlua.tuple.TermTuple"
local Exception = require "thlua.Exception"
local ClassTable = require "thlua.type.object.ClassTable"
local SealTable = require "thlua.type.object.SealTable"

local BaseFunction = require "thlua.type.func.BaseFunction"
local class = require "thlua.class"

  

local OpenFunction = class (BaseFunction)

function OpenFunction:ctor(vManager, vNode, vUpState )
	self._func=nil
	self._polyWrapper=false
	self._lexCapture = vUpState or false
	self._useNodeSet = {}
end

function OpenFunction:lateInitFromAutoNative(vNativeFunc)
	self._func = vNativeFunc
	do return self
 end end

function OpenFunction:lateInitFromMetaNative(
	vNativeFunc 
)
	local nFn = function(vStack, vTermTuple)
		assert(TermTuple.isFixed(vTermTuple), Exception.new("auto term can't be used here", vStack:getNode()))
		do return vStack:withMorePushContextWithCase(vStack:getNode(), vTermTuple, function(vContext, vType, vCase)
			vNativeFunc(vContext, vType)
		end):mergeReturn(), vStack:mergeEndErrType()
	 end end
	self._func = nFn
	do return self
 end end

function OpenFunction:lateInitFromOperNative(
	vNativeFunc   
)
	local nFn = function(vStack, vTermTuple)
		assert(TermTuple.isFixed(vTermTuple), Exception.new("auto term can't be used here", vStack:getNode()))
		do return vNativeFunc(vStack:inplaceOper(), vTermTuple)
	 end end
	self._func = nFn
	do return self
 end end

function OpenFunction:castPoly(vContext, vTypeList)
	local nPolyWrapper = self._polyWrapper
	if nPolyWrapper then
		do return nPolyWrapper(vTypeList)
	 end else
		vContext:error("this open function can't cast poly")
		do return self
	 end end
end

function OpenFunction:lateInitFromBuilder(vPolyParNum, vFunc    )
	local nNoPolyFn = function(vStack, vTermTuple)
		if vPolyParNum == 0 then
			do return vFunc(self, vStack, {}, vTermTuple)
		 end else
			vStack:inplaceOper():error("this open function need poly args")
		end
	end
	local nPolyWrapper = function(vList)
		do return OpenFunction.new(self._manager, self._node, self._lexCapture):lateInitFromAutoNative(function(vStack, vTermTuple)
			if #vList ~= vPolyParNum then
				vStack:inplaceOper():error("poly args number not match")
			end
			do return vFunc(self, vStack, vList, vTermTuple)
		 end end)
	 end end
	self._func = nNoPolyFn
	self._polyWrapper = nPolyWrapper
	do return self
 end end

function OpenFunction:lateInitFromMapGuard(vMapObject)
	local nNil = self._manager.type.Nil
	local nFalse = self._manager.type.False
	local nFn = function(vStack, vTermTuple)
		assert(TermTuple.isFixed(vTermTuple), "guard function can't take auto term")
		do return vStack:withOnePushContext(vStack:getNode(), function(vContext)
			local nTerm = vTermTuple:get(vContext, 1)
			nTerm:foreach(function(vType, vCase)
				vContext:withCase(vCase, function()
					for nMapType, nGuardType in pairs(vMapObject:getValueDict()) do
						nGuardType = nGuardType:checkAtomUnion():notnilType()
						if vType:intersectSome(nGuardType) then
							local nGuardCase = VariableCase.new()
							nGuardCase:put_and(nTerm:attachImmutVariable(), nGuardType)
							vContext:pushFirstAndTuple(nMapType, nil, nGuardCase)
							if not nGuardType:includeAll(vType) then
								vContext:pushFirstAndTuple(nNil)
							end
						else
							vContext:pushFirstAndTuple(nNil)
						end
					::continue:: end
				end)
			end)
		end):mergeFirst(), vStack:mergeEndErrType()
	 end end
	self._func = nFn
	do return self
 end end

function OpenFunction:lateInitFromIsGuard(vType)
	local nTrue = self._manager.type.True
	local nFalse = self._manager.type.False
	local nFn = function(vStack, vTermTuple)
		local nGuardType = vType:checkAtomUnion()
		assert(TermTuple.isFixed(vTermTuple), "guard function can't take auto term")
		do return vStack:withOnePushContext(vStack:getNode(), function(vContext)
			local nTerm = vTermTuple:get(vContext, 1)
			nTerm:foreach(function(vType, vCase)
				vContext:withCase(vCase, function()
					if vType:intersectSome(nGuardType) then
						local nGuardCase = VariableCase.new()
						nGuardCase:put_and(nTerm:attachImmutVariable(), nGuardType)
						vContext:pushFirstAndTuple(nTrue, nil, nGuardCase)
						if not nGuardType:includeAll(vType) then
							vContext:pushFirstAndTuple(nFalse)
						end
					else
						vContext:pushFirstAndTuple(nFalse)
					end
				end)
			end)
		end):mergeFirst(), vStack:mergeEndErrType()
	 end end
	self._func = nFn
	do return self
 end end

function OpenFunction:detailString(v, vVerbose)
	do return "OpenFunction@"..tostring(self._node)
 end end

function OpenFunction:newStack(vNode, vApplyStack)
	do return self._manager:getRuntime():OpenStack(vNode, self._lexCapture, self, vApplyStack, false)
 end end

function OpenFunction:meta_call(vContext, vTermTuple)
	local nRet, nStack = self:meta_open_call(vContext, vTermTuple, false)
	vContext:raiseError(nStack:mergeEndErrType())
	vContext:pushOpenReturn(nRet)
end

function OpenFunction:meta_open_call(vContext, vTermTuple, vIsRequire) 
	local nNewStack = self._manager:getRuntime():OpenStack(vContext:getNode(), self._lexCapture, self, vContext:getStack(), vIsRequire)
	do return self._func(nNewStack, vTermTuple), nNewStack
 end end

function OpenFunction:findRequireStack()
	local nLexCapture = self._lexCapture
	if not nLexCapture then
		do return false
	 end end
	do return nLexCapture.branch:getStack():findRequireStack()
 end end

function OpenFunction:isSingleton()
	do return true
 end end

function OpenFunction:mayRecursive()
	do return false
 end end

do return OpenFunction
 end 
end end
--thlua.type.func.OpenFunction end ==========)

--thlua.type.func.PolyFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.PolyFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local SealFunction = require "thlua.type.func.SealFunction"
local TypedFunction = require "thlua.type.func.TypedFunction"
local BaseFunction = require "thlua.type.func.BaseFunction"
local class = require "thlua.class"

  

local PolyFunction = class (BaseFunction)

function PolyFunction:ctor(vManager, vNode, vFunc, vPolyParNum, ...)
	self._polyParNum=vPolyParNum
	self._makerFn=vFunc
end

function PolyFunction:detailString(vToStringCache , vVerbose)
	do return "PolyFunction@"..tostring(self._node)
 end end

function PolyFunction:getPolyParNum()
	do return self._polyParNum
 end end

function PolyFunction:makeFn(vTemplateSign, vTypeList) 
	error("not implement")
end

function PolyFunction:noCtxCastPoly(vTypeList) 
	assert(#vTypeList == self._polyParNum, "PolyFunction type args num not match")
	local nAtomUnionList = {}
	for i=1, #vTypeList do
		nAtomUnionList[i] = vTypeList[i]:checkAtomUnion()
	::continue:: end
	local nKey = self._manager:signTemplateArgs(nAtomUnionList)
	do return self:makeFn(nKey, nAtomUnionList)
 end end

function PolyFunction:castPoly(vContext, vTypeList)
	local nFn = self:noCtxCastPoly(vTypeList)
	do return nFn:getFnAwait()
 end end

function PolyFunction:native_type()
	do return self._manager:Literal("function")
 end end

function PolyFunction:meta_call(vContext, vTypeTuple)
	error("poly function meta_call TODO")
	 
end

function PolyFunction:mayRecursive()
	do return false
 end end

function PolyFunction:isSingleton()
	do return false
 end end

do return PolyFunction
 end 
end end
--thlua.type.func.PolyFunction end ==========)

--thlua.type.func.SealFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.SealFunction'] = function (...)

local ScheduleTask = require "thlua.manager.ScheduleTask"
local Exception = require "thlua.Exception"

local BaseFunction = require "thlua.type.func.BaseFunction"

local ScheduleEvent = require "thlua.manager.ScheduleEvent"
local class = require "thlua.class"


	  
	  
	  
		 
		
			 
		
	


local SealFunction = class (BaseFunction)

function SealFunction:ctor(
	vManager,
	vNode,
	vLexCapture
)
	local nNewStack = vManager:getRuntime():SealStack(vNode, vLexCapture, self   )
	self._lexStack = vLexCapture and vLexCapture.branch:getStack() or false
	self._buildStack = nNewStack
	local nTask = vManager:getScheduleManager():newTask(nNewStack)
	self._task = nTask
	self._preBuildEvent=nTask:makeEvent()
	self._lateStartEvent=nTask:makeWildEvent()
	self._lateBuildEvent=nTask:makeEvent()
	self._typeFn=false
	self._retTuples=false
	self._builderFn=false
	self._useNodeSet = {}
end

function SealFunction:meta_call(vContext, vTermTuple)
	local nTypeFn = self:getFnAwait()
	do return nTypeFn:meta_call(vContext, vTermTuple)
 end end

function SealFunction:getFnAwait()
	if not self._typeFn then
		self:startPreBuild()
		self._preBuildEvent:wait()
		if not self._typeFn then
			self._lateStartEvent:wakeup()
			self._lateBuildEvent:wait()
		end
	end
	do return (assert(self._typeFn, "_typeFn must existed here"))
 end end

function SealFunction:getBuildStack()
	do return self._buildStack
 end end

function SealFunction:findRequireStack()
	local nLexCapture = self._lexCapture
	if not nLexCapture then
		do return false
	 end end
	do return nLexCapture.branch:getStack():findRequireStack()
 end end

function SealFunction:getRetTuples()
	do return self._retTuples
 end end

function SealFunction:startPreBuild()
	local nBuilderFn = self._builderFn
	if not nBuilderFn then
		do return
	 end end
	self._builderFn = false
	self._task:runAsync(function()
		local nParTuple, nRetTuples, nLateRunner = nBuilderFn()
		self._retTuples = nRetTuples
		if nParTuple and nRetTuples then
			self._typeFn = self._manager:TypedFunction(self._node, nParTuple, nRetTuples)
		end
		self._preBuildEvent:wakeup()
		self._lateStartEvent:wait()
		local nParTuple, nRetTuples = nLateRunner()
		self._typeFn = self._typeFn or self._manager:TypedFunction(self._node, nParTuple, nRetTuples)
		self._buildStack:seal()
		self._lateBuildEvent:wakeup()
	end)
end

function SealFunction:waitSeal()
	self._lateBuildEvent:wait()
end

function SealFunction:initAsync(vRunner)
	self._builderFn=vRunner
end

function SealFunction:startLateBuild()
	self._lateStartEvent:wakeup()
end

function SealFunction:findRequireStack()
	local nLexStack = self._lexStack
	do return nLexStack and nLexStack:findRequireStack() or false
 end end

do return SealFunction
 end 
end end
--thlua.type.func.SealFunction end ==========)

--thlua.type.func.SealPolyFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.SealPolyFunction'] = function (...)

local class = require "thlua.class"
local PolyFunction = require "thlua.type.func.PolyFunction"
local SealFunction = require "thlua.type.func.SealFunction"

  

local SealPolyFunction = class (PolyFunction)

function SealPolyFunction:ctor(_,_,_,_, vLexStack)
	self._fnDict = {}   
	self._lexStack = vLexStack
	self._useNodeSet = {}
end

function SealPolyFunction:makeFn(vTemplateSign, vTypeList)
	local nFn = self._fnDict[vTemplateSign]
	if not nFn then
		local nResult = (self._makerFn(table.unpack(vTypeList)) ) 
		if SealFunction.is(nResult) then
			self._fnDict[vTemplateSign] = nResult
            self._lexStack:getSealStack():scheduleSealType(nResult)
			do return nResult
		 end else
			error("poly function must return mono-function type but got:"..tostring(nResult))
		end
	else
		do return nFn
	 end end
end

do return SealPolyFunction end 
end end
--thlua.type.func.SealPolyFunction end ==========)

--thlua.type.func.TypedFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.TypedFunction'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local TypeTupleDots = require "thlua.tuple.TypeTupleDots"
local Exception = require "thlua.Exception"
local TermTuple = require "thlua.tuple.TermTuple"
local RetBuilder = require "thlua.tuple.RetBuilder"
local Node = require "thlua.code.Node"

local BaseFunction = require "thlua.type.func.BaseFunction"
local class = require "thlua.class"

  

local TypedFunction = class (BaseFunction)

function TypedFunction:ctor(vManager, vNode,
	vParTuple, vRetTuples
)
	self._dirtyProcessor = vManager:getDirtyProcessor()
	self._retBuilder=false    
	self._parTuple=vParTuple
	self._retTuples=vRetTuples
end

function TypedFunction:attachRetBuilder()
	local nRetBuilder = self._retBuilder
	if not nRetBuilder then
		nRetBuilder = RetBuilder.new(self._manager, self._node)
		self._retBuilder = nRetBuilder
	end
	do return nRetBuilder
 end end

function TypedFunction:chainDots(vDebugNode, vType)
	if self._retTuples then
		error(vDebugNode:toExc("fn building is finish, can't call Dots(...)"))
	end
	if self._retBuilder then
		error(vDebugNode:toExc("fn can't call Dots after Ret(...) or RetDots(...)"))
	end
	local nParTuple = self._parTuple
	if TypeTupleDots.is(nParTuple) then
		error(vDebugNode:toExc("use Dots but tuple has dots"))
	end
	local nType = self._dirtyProcessor:easyToType(vDebugNode, vType)
	self._parTuple = nParTuple:withDots(nType)
end

function TypedFunction:Dots(vType)
	local nDebugNode = Node.newDebugNode()
	self:chainDots(nDebugNode, vType)
	do return self
 end end

function TypedFunction:RetDots(...)
	local nDebugNode = Node.newDebugNode()
	     
	assert(not self._retTuples, nDebugNode:toExc("fn building is finish, can't call RetDots"))
	self:attachRetBuilder():chainRetDots(nDebugNode, ...)
	do return self
 end end

function TypedFunction:Ret(...)
	local nDebugNode = Node.newDebugNode()
	assert(not self._retTuples, nDebugNode:toExc("fn building is finish, can't call Ret"))
	self:attachRetBuilder():chainRet(nDebugNode, ...)
	do return self
 end end

function TypedFunction:Err(...)
	local nDebugNode = Node.newDebugNode()
	assert(not self._retTuples, nDebugNode:toExc("fn building is finish, can't call Err"))
	self:attachRetBuilder():chainErr(nDebugNode, ...)
	do return self
 end end

function TypedFunction:finish()
	self:_buildRetTuples()
	do return self
 end end

function TypedFunction:_buildRetTuples()
	local nRetTuples = self._retTuples
	if not nRetTuples then
		nRetTuples = self:attachRetBuilder():build()
		self._retTuples = nRetTuples
	end
	do return nRetTuples
 end end

function TypedFunction:native_type()
	do return self._manager:Literal("function")
 end end

function TypedFunction:detailString(vToStringCache, vVerbose)
	local nRetTuples = self:_buildRetTuples()
	local nCache = vToStringCache[self]
	if nCache then
		do return nCache
	 end end
	vToStringCache[self] = "fn-..."
	local nResult = "fn-" .. self._parTuple:detailString(vToStringCache, vVerbose)..
									"->"..nRetTuples:detailString(vToStringCache, vVerbose)
	vToStringCache[self] = nResult
	do return nResult
 end end

function TypedFunction:meta_call(vContext, vTermTuple)
	local nRetTuples = self:_buildRetTuples()
	local nTypeTuple = self._parTuple
	vContext:matchArgsToTypeTuple(vContext:getNode(), vTermTuple, nTypeTuple)
	vContext:pushRetTuples(nRetTuples)
end

function TypedFunction:assumeIncludeFn(vAssumeSet , vRight)
	local nLeftRetTuples = self:_buildRetTuples()
	local nRightRetTuples = vRight:_buildRetTuples()
	if not vRight:getParTuple():assumeIncludeTuple(vAssumeSet, self._parTuple) then
		do return false
	 end end
	if not nLeftRetTuples:assumeIncludeTuples(vAssumeSet, nRightRetTuples) then
		do return false
	 end end
	do return true
 end end

function TypedFunction:assumeIncludeAtom(vAssumeSet, vRight, _)
	if self == vRight then
		do return self
	 end end
	if not TypedFunction.is(vRight) then
		do return false
	 end end
	local nMgr = self._manager
	local nPair = self._manager:makePair(self, vRight)
	if not vAssumeSet then
		do return self:assumeIncludeFn({[nPair]=true}, vRight) and self
	 end end
	local nAssumeResult = vAssumeSet[nPair]
	if nAssumeResult ~= nil then
		do return nAssumeResult and self
	 end end
	vAssumeSet[nPair] = true
	local nAssumeInclude = self:assumeIncludeFn(vAssumeSet, vRight)
	if not nAssumeInclude then
		vAssumeSet[nPair] = false
		do return false
	 end else
		do return self
	 end end
end

function TypedFunction:getParTuple()
	self:_buildRetTuples()
	do return self._parTuple
 end end

function TypedFunction:getRetTuples()
	do return self:_buildRetTuples()
 end end

function TypedFunction:partTypedFunction()
	do return self
 end end

function TypedFunction:mayRecursive()
	do return true
 end end

function TypedFunction:getFnAwait()
	do return self
 end end

do return TypedFunction
 end 
end end
--thlua.type.func.TypedFunction end ==========)

--thlua.type.func.TypedMemberFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.TypedMemberFunction'] = function (...)

local Node = require "thlua.code.Node"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Exception = require "thlua.Exception"

local TypedFunction = require "thlua.type.func.TypedFunction"
local MemberFunction = require "thlua.type.func.MemberFunction"
local class = require "thlua.class"


	  


local TypedMemberFunction = class (MemberFunction)

function TypedMemberFunction:ctor(_,_,vHeadlessFn)
	self._headlessFn = vHeadlessFn
	self._typeFnDict = {} 
end

function TypedMemberFunction:detailString(vToStringCache , vVerbose)
	local nHeadlessFn = self._headlessFn
	local nCache = vToStringCache[self]
	if nCache then
		do return nCache
	 end end
	local nParTuple = nHeadlessFn:getParTuple()
	local nRetTuples = nHeadlessFn:getRetTuples()
	vToStringCache[self] = "member:fn-..."
	local nResult = "member:fn-" .. nParTuple:detailStringIfFirst(vToStringCache, vVerbose, false)..
									"->"..nRetTuples:detailString(vToStringCache, vVerbose)
	vToStringCache[self] = nResult
	do return nResult
 end end

function TypedMemberFunction:Dots(vType)
	self._headlessFn:chainDots(Node.newDebugNode(), vType)
	do return self
 end end

function TypedMemberFunction:RetDots(...)
	self._headlessFn:attachRetBuilder():chainRetDots(Node.newDebugNode(), ...)
	do return self
 end end

function TypedMemberFunction:Ret(...)
	self._headlessFn:attachRetBuilder():chainRet(Node.newDebugNode(), ...)
	do return self
 end end

function TypedMemberFunction:Err(...)
	self._headlessFn:attachRetBuilder():chainErr(Node.newDebugNode(), ...)
	do return self
 end end

function TypedMemberFunction:meta_invoke(vContext, vSelfType, vPolyArgs, vTypeTuple)
	local nTypeFn = self:indexTypeFn(vSelfType)
	nTypeFn:meta_call(vContext, vTypeTuple)
end

function TypedMemberFunction:needPolyArgs()
	do return false
 end end

function TypedMemberFunction:getHeadlessFn()
	do return self._headlessFn
 end end

function TypedMemberFunction:assumeIncludeAtom(vAssumeSet, vRight, vSelfType)
	 
	if self == vRight then
		do return self
	 end end
	if TypedMemberFunction.is(vRight) then
		do return self._headlessFn:assumeIncludeAtom(vAssumeSet, vRight:getHeadlessFn()) and self
	 end elseif TypedFunction.is(vRight) then
		if vSelfType then
			do return self:indexTypeFn(vSelfType):assumeIncludeAtom(vAssumeSet, vRight) and self
		 end else
			do return false
		 end end
	end
end

function TypedMemberFunction:indexTypeFn(vSelfType)
	local nDict = self._typeFnDict
	local nFn = nDict[vSelfType]
	if nFn then
		do return nFn
	 end else
		local nHeadlessFn = self._headlessFn
		local nRetTuples = nHeadlessFn:getRetTuples()
		local nParTuple = nHeadlessFn:getParTuple():leftAppend(vSelfType)
		local nFn = self._manager:TypedFunction(self._node, nParTuple, nRetTuples)
		nDict[vSelfType] = nFn
		do return nFn
	 end end
end

function TypedMemberFunction:mayRecursive()
	do return true
 end end

do return TypedMemberFunction
 end 
end end
--thlua.type.func.TypedMemberFunction end ==========)

--thlua.type.func.TypedPolyFunction begin ==========(
do local _ENV = _ENV
packages['thlua.type.func.TypedPolyFunction'] = function (...)

local class = require "thlua.class"
local PolyFunction = require "thlua.type.func.PolyFunction"
local TypedFunction = require "thlua.type.func.TypedFunction"

  

local TypedPolyFunction = class (PolyFunction)

function TypedPolyFunction:ctor(...)
	self._fnDict = {}   
end

function TypedPolyFunction:makeFn(vTemplateSign, vTypeList)
	local nFn = self._fnDict[vTemplateSign]
	if not nFn then
		local nResult = (self._makerFn(table.unpack(vTypeList)) ) 
		if TypedFunction.is(nResult) then
			self._fnDict[vTemplateSign] = nResult
			do return nResult
		 end else
			error("poly function must return mono-function type but got:"..tostring(nResult))
		end
	else
		do return nFn
	 end end
end

do return TypedPolyFunction end 
end end
--thlua.type.func.TypedPolyFunction end ==========)

--thlua.type.object.AutoTable begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.AutoTable'] = function (...)

local StringLiteral = require "thlua.type.basic.StringLiteral"
local TypedObject = require "thlua.type.object.TypedObject"
local Struct = require "thlua.type.object.Struct"
local TypedFunction = require "thlua.type.func.TypedFunction"
local TypedMemberFunction = require "thlua.type.func.TypedMemberFunction"
local AutoFunction = require "thlua.type.func.AutoFunction"
local BaseFunction = require "thlua.type.func.BaseFunction"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local Nil = require "thlua.type.basic.Nil"

local SealTable = require "thlua.type.object.SealTable"
local class = require "thlua.class"


	  


local AutoTable = class (SealTable)

function AutoTable:ctor(vManager, ...)
	self._name = false 
	self._firstAssign = false
	self._castDict = {}   
	self._locked = false
end

function AutoTable:detailString(v, vVerbose)
	if not self._firstAssign then
		do return "AutoTable@castable@"..tostring(self._node)
	 end elseif next(self._castDict) then
		do return "AutoTable@casted@"..tostring(self._node)
	 end else
		do return "AutoTable@"..tostring(self._node)
	 end end
end

function AutoTable:setName(vName)
	self._name = vName
end

function AutoTable:castMatchOne(
	vContext,
	vStruct
)
	local nAutoFnCastDict = vContext:newAutoFnCastDict()
	local nCopyValueDict = vStruct:copyValueDict(self)
	local nMatchSucc = true
	self._keyType:foreach(function(vTableKey)
		local vTableValue = self._fieldDict[vTableKey]:getValueType()
		if not nMatchSucc then
			do return
		 end end
		local nMatchKey, nMatchValue = vStruct:indexKeyValue(vTableKey)
		if not nMatchKey then
			nMatchSucc = false
			do return
		 end end
		nMatchValue = nMatchValue:checkAtomUnion()
		if TypedMemberFunction.is(nMatchValue) then
			        
			nMatchValue=nMatchValue:indexTypeFn(vStruct)
		end
		local nIncludeType, nCastSucc = vContext:tryIncludeCast(nAutoFnCastDict, nMatchValue, vTableValue)
		if not nIncludeType or not nCastSucc then
			nMatchSucc = false
			do return
		 end end
		nCopyValueDict[nMatchKey] = nil
	end)
	if not nMatchSucc then
		do return false
	 end end
	for k,v in pairs(nCopyValueDict) do
		if not v:checkAtomUnion():isNilable() then
			do return false
		 end end
	::continue:: end
	do return nAutoFnCastDict
 end end

function AutoTable:checkTypedObject()
	do return self._manager.type.AnyObject
 end end

function AutoTable:isCastable()
	do return not self._firstAssign
 end end

function AutoTable:setAssigned(vContext)
	if not self._firstAssign then
		if next(self._castDict) then
			vContext:error("AutoTable is casted to some TypedObject")
		end
		self._firstAssign = vContext
		for k, v in pairs(self._fieldDict) do
			v:getValueType():setAssigned(vContext)
		::continue:: end
	end
end

function AutoTable:findRequireStack()
	do return self._lexStack:findRequireStack()
 end end

function AutoTable:setLocked()
	self._locked = true
end

function AutoTable:isLocked()
	do return self._locked
 end end

do return AutoTable
 end 
end end
--thlua.type.object.AutoTable end ==========)

--thlua.type.object.BaseObject begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.BaseObject'] = function (...)

local Exception = require "thlua.Exception"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local StringLiteral = require "thlua.type.basic.StringLiteral"
local Nil = require "thlua.type.basic.Nil"
local TypedFunction = require "thlua.type.func.TypedFunction"

local BaseAtomType = require "thlua.type.basic.BaseAtomType"
local class = require "thlua.class"


	  


local BaseObject = class (BaseAtomType)

function BaseObject:ctor(vManager, vNode, ...)
	self.bits=TYPE_BITS.OBJECT
	self._metaEventCom=false
	self._node=vNode
end

function BaseObject:getMetaEventCom()
	do return self._metaEventCom
 end end

function BaseObject:detailString(v, vVerbose)
	do return "BaseObject..."
 end end

function BaseObject:meta_uop_some(vContext, vOper)
	vContext:error("meta uop not implement:")
	do return self._manager.type.Never
 end end

function BaseObject:meta_bop_func(vContext, vOper)
	vContext:error("meta bop not implement:")
	do return false, nil
 end end

function BaseObject:isSingleton()
	do return false
 end end

function BaseObject:native_type()
	do return self._manager:Literal("table")
 end end

function BaseObject:getValueDict() 
	error("not implement")
end

function BaseObject:memberFunctionFillSelf(vChain, vSelfTable)
	error("TODO base object as __index")
end

do return BaseObject
 end 
end end
--thlua.type.object.BaseObject end ==========)

--thlua.type.object.ClassTable begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.ClassTable'] = function (...)

local VariableCase = require "thlua.term.VariableCase"
local StringLiteral = require "thlua.type.basic.StringLiteral"
local TypedFunction = require "thlua.type.func.TypedFunction"
local AutoMemberFunction = require "thlua.type.func.AutoMemberFunction"
local AutoFunction = require "thlua.type.func.AutoFunction"
local BaseFunction = require "thlua.type.func.BaseFunction"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local RecurChain = require "thlua.context.RecurChain"
local Nil = require "thlua.type.basic.Nil"

local SealTable = require "thlua.type.object.SealTable"
local class = require "thlua.class"


	  


local ClassTable = class (SealTable)

function ClassTable:ctor(
	vManager,
	vNode,
	vLexStack,
	vFactory
)
	self._factory = vFactory
	local nTask = self._manager:getScheduleManager():newTask()
	self._task = nTask
	self._initEvent = nTask:makeEvent()
	self._baseClass = false
	self._interface = nil
	self._buildFinish = false
end

function ClassTable:detailString(v, vVerbose)
	do return "ClassTable@"..tostring(self._node)
 end end

function ClassTable:waitInit()
	self._initEvent:wait()
end

function ClassTable:initAsync(vBaseGetter )
	self._task:runAsync(function()
		self._baseClass, self._interface = vBaseGetter()
		self._initEvent:wakeup()
	end)
end

function ClassTable:onSetMetaTable(vContext)
	self._factory:wakeupTableBuild()
	self:onBuildFinish()
end

function ClassTable:onBuildFinish()
	if not self._buildFinish then
		self._buildFinish = true
		self:implInterface()
		local nRecurChain = RecurChain.new()
		self:memberFunctionFillSelf(nRecurChain, self)
		self._factory:wakeupTableBuild()
	end
end

function ClassTable:implInterface()
	local nInterfaceKeyValue = self._interface:copyValueDict(self)
	local nSelfKey = self._keyType
	for nKeyAtom, nValue in pairs(nInterfaceKeyValue) do
		local nContext = self._factory:getBuildStack():withOnePushContext(self._factory:getNode(), function(vSubContext)
			vSubContext:withCase(VariableCase.new(), function()
				self:meta_get(vSubContext, nKeyAtom)
			end)
		end)
		local nSelfValue = nContext:mergeFirst():getType()
		if AutoMemberFunction.is(nSelfValue) then
			if TypedFunction.is(nValue) then
				nSelfValue:indexAutoFn(self):checkWhenCast(nContext, nValue)
			end
		else
			if not nValue:includeAll(nSelfValue) then
				nContext:error("interface's field must be supertype for table's field, key="..tostring(nKeyAtom))
			end
		end
	::continue:: end
end

function ClassTable:ctxWait(vContext)
	self._factory:waitTableBuild()
end

function ClassTable:getBaseClass()
	do return self._baseClass
 end end

function ClassTable:getInterface()
	do return self._interface
 end end

function ClassTable:checkTypedObject()
	do return self._interface
 end end

function ClassTable:assumeIncludeAtom(vAssumeSet, vType, _)
	if ClassTable.is(vType) then
		local nMatchTable = vType
		while nMatchTable ~= self do
			local nBaseClass = nMatchTable:getBaseClass()
			if not nBaseClass then
				break
			else
				nMatchTable = nBaseClass
			end
		::continue:: end
		do return nMatchTable == self and self or false
	 end else
		   
		do return false
	 end end
end

function ClassTable:isLocked()
	do return self._buildFinish
 end end

do return ClassTable
 end 
end end
--thlua.type.object.ClassTable end ==========)

--thlua.type.object.Interface begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.Interface'] = function (...)

local TypedObject = require "thlua.type.object.TypedObject"
local class = require "thlua.class"


	  


local Interface = class (TypedObject)

function Interface:ctor(...)
end

function Interface:detailString(vToStringCache, vVerbose)
	do return "interface@"..tostring(self._node)
 end end

function Interface:assumeIncludeObject(vAssumeSet , vRightObject)
	if vRightObject._intersectSet[self] then
		do return true
	 end end
	local nRightKeyRefer, nRightNextKey = vRightObject:getKeyTypes()
	local nLeftNextKey = self._nextKey
	if nLeftNextKey then
		if not nRightNextKey then
			do return false
		 end end
		if not nLeftNextKey:assumeIncludeAll(vAssumeSet, nRightNextKey) then
			do return false
		 end end
	end
	local nRightValueDict = vRightObject:getValueDict()
	local nRightResultType = nRightKeyRefer:getResultType()
	do return self:_everyWith(vRightObject, function(vLeftKey, vLeftValue)
		if nRightResultType then        
			local nRightKey = nRightResultType:assumeIncludeAtom(vAssumeSet, vLeftKey)
			if not nRightKey then
				do return false
			 end end
			local nRightValue = nRightValueDict[nRightKey]
			if not nRightValue then
				do return false
			 end end
			do return vLeftValue:assumeIncludeAll(vAssumeSet, nRightValue, vRightObject) and true
		 end else         
			for _, nRightMoreKey in ipairs(nRightKeyRefer:getListAwait()) do
				if nRightMoreKey:assumeIncludeAtom(vAssumeSet, vLeftKey) then
					local nRightValue = nRightValueDict[nRightMoreKey]
					if nRightValue and vLeftValue:assumeIncludeAll(vAssumeSet, nRightValue, vRightObject) then
						do return true
					 end end
				end
			::continue:: end
			do return false
		 end end
	end)
 end end

function Interface:assumeIntersectAtom(vAssumeSet, vRightType)
	if not Interface.is(vRightType) then
		if self == vRightType then
			do return self
		 end elseif vRightType:assumeIncludeAtom(nil, self) then
			do return self
		 end elseif self:assumeIncludeAtom(nil, vRightType) then
			do return vRightType
		 end else
			do return false
		 end end
	end
	if self == vRightType then
		do return self
	 end end
	local nRightStruct = vRightType
	local nMgr = self._manager
	local nRelation = nMgr:attachPairRelation(self, nRightStruct, not vAssumeSet)
	if nRelation then
		if nRelation == ">" then
			do return vRightType
		 end elseif nRelation == "<" then
			do return self
		 end elseif nRelation == "=" then
			do return self
		 end elseif nRelation == "&" then
			do return true
		 end else
			do return false
		 end end
	end
	assert(vAssumeSet, "assume set must be existed here")
	local _, nLRPair, nRLPair = self._manager:makeDuPair(self, nRightStruct)
	local nAssumeResult = vAssumeSet[nLRPair]
	if nAssumeResult ~= nil then
		do return nAssumeResult and self
	 end end
	vAssumeSet[nLRPair] = true
	vAssumeSet[nRLPair] = true
	local nAssumeIntersect = self:assumeIntersectInterface(vAssumeSet, nRightStruct)
	if not nAssumeIntersect then
		vAssumeSet[nLRPair] = false
		vAssumeSet[nRLPair] = false
		do return false
	 end else
		do return true
	 end end
end

function Interface:assumeIntersectInterface(vAssumeSet , vRightObject)
	local nRightValueDict = vRightObject:getValueDict()
	local nRightKeyRefer, nRightNextKey = vRightObject:getKeyTypes()
	local nRightResultType = nRightKeyRefer:getResultType()
	do return self:_everyWith(vRightObject, function(vLeftKey, vLeftValue)
		if nRightResultType then        
			local nRightKey = nRightResultType:assumeIncludeAtom(vAssumeSet, vLeftKey)
			if not nRightKey then
				do return true
			 end end
			local nRightValue = nRightValueDict[nRightKey]
			if vLeftValue:assumeIntersectSome(vAssumeSet, nRightValue) then
				do return true
			 end else
				do return false
			 end end
		else
			for _, nRightKey in ipairs(nRightKeyRefer:getListAwait()) do
				if nRightKey:assumeIncludeAtom(vAssumeSet, vLeftKey) then
					local nRightValue = nRightValueDict[nRightKey]
					if vLeftValue:assumeIntersectSome(vAssumeSet, nRightValue) then
						do return true
					 end end
				end
			::continue:: end
			do return false
		 end end
	end)
 end end

function Interface:meta_set(vContext, vKeyType, vValueType)
	vContext:error("interface is readonly")
end

function Interface:native_rawset(vContext, vKeyType, vValueType)
	vContext:error("interface is readonly")
end

do return Interface
 end 
end end
--thlua.type.object.Interface end ==========)

--thlua.type.object.MetaEventCom begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.MetaEventCom'] = function (...)

local Reference = require "thlua.refer.Reference"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local Nil = require "thlua.type.basic.Nil"
local TypedFunction = require "thlua.type.func.TypedFunction"
local AutoFunction = require "thlua.type.func.AutoFunction"
local AutoMemberFunction = require "thlua.type.func.AutoMemberFunction"
local class = require "thlua.class"


	  
	   
		
		
	


local MetaEventCom = {}
MetaEventCom.__index=MetaEventCom

function MetaEventCom.new(vManager, vSelfType )
	local self = setmetatable({
		_manager=vManager,
		_selfType=vSelfType,
		_bopEq=false,
		_bopDict={} ,
		_uopLen=false,
		_uopDict=false,    
		 
		_pairs=false,
		_ipairs=false,
		_tostring=false,
		_mode=false,
		_call=false,   
		_metatable=false,
		_gc=false,
		_name=false,
		_close=false,
	}, MetaEventCom)
	do return self
 end end

function MetaEventCom:getBopFunc(vBopEvent)
	local nField = self._bopDict[vBopEvent]
	do return nField and (nField.typeFn or nField.autoFn:getFnAwait())
 end end

function MetaEventCom:getLenType()
	do return self._uopLen
 end end

function MetaEventCom:getPairsFunc()
	local nField = self._pairs
	do return nField and (nField.typeFn or nField.autoFn:getFnAwait())
 end end

local function buildFieldFromFn(vContext, vEvent, vMethodFn,
	vTypeFnOrNil)
	if vMethodFn:isUnion() then
		vContext:error("meta method can't be union type, event:"..vEvent)
		do return nil
	 end elseif TypedFunction.is(vMethodFn) then
		do return {
			typeFn=vMethodFn
		}
	 end elseif AutoMemberFunction.is(vMethodFn) then
		if vTypeFnOrNil then
			local nSelfType = vTypeFnOrNil:getParTuple():get(1)
			local nAutoFn = vMethodFn:indexAutoFn(nSelfType)
			nAutoFn:checkWhenCast(vContext, vTypeFnOrNil)
			do return {
				typeFn=vTypeFnOrNil,
			}
		 end else
			vContext:error("member function cast to type fn in meta field TODO")
			do return nil
		 end end
	elseif AutoFunction.is(vMethodFn) then
		if vTypeFnOrNil then
			vMethodFn:checkWhenCast(vContext, vTypeFnOrNil)
			do return {
				typeFn=vTypeFnOrNil,
			}
		 end else
			do return {
				autoFn=vMethodFn
			}
		 end end
	elseif not Nil.is(vMethodFn) then
		vContext:error("meta method type must be function or nil, event:"..vEvent)
	end
	do return nil
 end end

function MetaEventCom:initByTable(vContext, vMetaTable )
	local nSelfType = self._selfType
	local nManager = self._manager
	   
	for nOper, nEvent in pairs(OPER_ENUM.bopNoEq) do
		local nMethodType = vMetaTable:native_rawget(vContext, nManager:Literal(nEvent))
		self._bopDict[nEvent] = buildFieldFromFn(vContext, nEvent, nMethodType)
	::continue:: end
	local nEqFn = vMetaTable:native_rawget(vContext, nManager:Literal("__eq"))
	if not Nil.is(nEqFn) then
		vContext:error("TODO meta logic for bop __eq", tostring(nEqFn))
	end
	   
	local nLenFn = vMetaTable:native_rawget(vContext, nManager:Literal("__len"))
	local nLenTypeFn = nManager:checkedFn(nSelfType):Ret(nManager.type.Integer)
	local nLenField = buildFieldFromFn(vContext, "__len", nLenFn, nLenTypeFn)
	if nLenField then
		self._uopLen = nManager.type.Integer
		       
		   
	end
	   
	  
	local nStringTypeFn = nManager:checkedFn(nSelfType):Ret(nManager.type.String)
	local nStringFn = vMetaTable:native_rawget(vContext, nManager:Literal("__tostring"))
	self._tostring = buildFieldFromFn(vContext, "__tostring", nStringFn, nStringTypeFn) or false
	  
	local nPairsFn = vMetaTable:native_rawget(vContext, nManager:Literal("__pairs"))
	self._pairs = buildFieldFromFn(vContext, "__pairs", nPairsFn) or false
end

local function buildFieldFromAllType(vEvent, vTypeFn)
	if not vTypeFn then
		do return nil
	 end end
	if Reference.is(vTypeFn) then
		vTypeFn = vTypeFn:waitTypeCom():getTypeAwait()
	end
	if not TypedFunction.is(vTypeFn) then
		error("meta field "..vEvent.." must be single type-function")
	else
		do return {
			typeFn=vTypeFn
		}
	 end end
end

function MetaEventCom:initByEventDict(vActionDict )
	local nManager = self._manager
	   
	for nOper, nEvent in pairs(OPER_ENUM.bopNoEq) do
		self._bopDict[nEvent] = buildFieldFromAllType(nEvent, vActionDict[nEvent])
	::continue:: end
	if vActionDict["__eq"] then
		print("__eq in action table TODO")
	end
	   
	local nLenType = vActionDict["__len"]
	if nLenType then
		nLenType = nLenType:checkAtomUnion()
		if not nManager.type.Integer:includeAll(nLenType) then
			error("len type must be subtype of Integer")
		end
		self._uopLen = nLenType
	end
	 
	self._pairs = buildFieldFromAllType("__pairs", vActionDict["__pairs"]) or false
	self._ipairs = buildFieldFromAllType("__ipairs", vActionDict["__ipairs"]) or false
end

function MetaEventCom:mergeField(
	vEvent,
	vComList,
	vFieldGetter)
	local nRetField = false
	for _, vCom in ipairs(vComList) do
		local nField = vFieldGetter(vCom)
		if nField then
			if nRetField then
				error("meta field conflict when merge, field:"..vEvent)
			else
				nRetField = nField
			end
		end
	::continue:: end
	do return nRetField
 end end

function MetaEventCom:initByMerge(vComList)
	self._pairs = self:mergeField("__pairs", vComList, function(vCom)
		do return vCom._pairs
	 end end)
	self._ipairs = self:mergeField("__ipairs", vComList, function(vCom)
		do return vCom._ipairs
	 end end)
	for nOper, nEvent in pairs(OPER_ENUM.bopNoEq) do
		self._bopDict[nEvent] = self:mergeField(nEvent, vComList, function(vCom)
			do return vCom._bopDict[nEvent] or false
		 end end) or nil
	::continue:: end
	local nFinalUopLen = false
	for _, vCom in ipairs(vComList) do
		local nUopLen = vCom._uopLen
		if nUopLen then
			if nFinalUopLen then
				error("__len conflict in meta when merge")
			else
				nFinalUopLen = nUopLen
			end
		end
	::continue:: end
	self._uopLen = nFinalUopLen
end

do return MetaEventCom
 end 
end end
--thlua.type.object.MetaEventCom end ==========)

--thlua.type.object.ObjectField begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.ObjectField'] = function (...)

local class = require "thlua.class"


	  


local ObjectField = class ()

function ObjectField:ctor(vInitNode, vObjectType, vKeyType, vValueType, ...)
    self._initNode = vInitNode
    self._objectType = vObjectType
    self._keyType = vKeyType
    self._valueType = vValueType
    self._useNodeSet = {}   
end

function ObjectField:getUseNodeSet()
    do return self._useNodeSet
 end end

function ObjectField:putUseNode(vNode)
    self._useNodeSet[vNode] = true
end

function ObjectField:getObjectType()
    do return self._objectType
 end end

function ObjectField:getKeyType()
    do return self._keyType
 end end

function ObjectField:getInitNode()
    do return self._initNode
 end end

function ObjectField:getValueType()
    do return self._valueType
 end end

do return ObjectField
 end 
end end
--thlua.type.object.ObjectField end ==========)

--thlua.type.object.OpenField begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.OpenField'] = function (...)


local class = require "thlua.class"
local ObjectField = require "thlua.type.object.ObjectField"


	  


local OpenField =class (ObjectField)

function OpenField:ctor(vInitNode,vObject,vKey,vValue,vBranch)
	self._assignNode = vInitNode
	self._branch = vBranch
	self._lockCtx = false  
end

function OpenField:overrideAssign(vValueType, vBranch)
	self._valueType = vValueType
	self._branch = vBranch
end

function OpenField:getAssignNode()
	do return self._assignNode
 end end

function OpenField:getLockCtx()
	do return self._lockCtx
 end end

function OpenField:lock(vContext)
	if not self._lockCtx then
		self._lockCtx = vContext
	end
end

function OpenField:getAssignBranch()
	do return self._branch
 end end

do return OpenField end 
end end
--thlua.type.object.OpenField end ==========)

--thlua.type.object.OpenTable begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.OpenTable'] = function (...)

local StringLiteral = require "thlua.type.basic.StringLiteral"
local TypedObject = require "thlua.type.object.TypedObject"
local BaseFunction = require "thlua.type.func.BaseFunction"
local AutoMemberFunction = require "thlua.type.func.AutoMemberFunction"
local OpenField = require "thlua.type.object.OpenField"
local Nil = require "thlua.type.basic.Nil"

local BaseObject = require "thlua.type.object.BaseObject"
local class = require "thlua.class"


	  


local OpenTable = class (BaseObject)

function OpenTable:ctor(vManager, vNode, vLexStack)
	self._keyType=vManager.type.Never 
	self._lexStack = vLexStack
	self._fieldDict={} 
	self._metaIndex=false 
	self._metaNewIndex=false 
	self._nextValue=false 
	self._nextDict=false  
	self._metaTable=false 
	self._locked=false
end

function OpenTable:detailString(v, vVerbose)
	do return "OpenTable@"..tostring(self._node)
 end end

function OpenTable:meta_len(vContext)
	 
	do return self._manager.type.Integer
 end end

function OpenTable:initByBranchKeyValue(vNode, vBranch, vKeyType, vValueDict )
	self._keyType = vKeyType
	for k,v in pairs(vValueDict) do
		self._fieldDict[k] = OpenField.new(vNode, self, k, v, vBranch)
	::continue:: end
end

function OpenTable:native_getmetatable(vContext)
	do return self._metaTable or self._manager.type.Nil
 end end

function OpenTable:native_setmetatable(vContext, vMetaTableType)
	if self._metaTable then
		vContext:error("can only setmetatable once for one table")
		do return
	 end end
	self._metaTable = vMetaTableType
	             
	      
	   
	 
	  
	     
	local nManager = self._manager
	   
	local nIndexType = vMetaTableType:native_rawget(vContext, nManager:Literal("__index"))
	if nIndexType:isUnion() then
		vContext:error("open table's __index can't be union type")
	else
		if BaseFunction.is(nIndexType) or BaseObject.is(nIndexType) then
			self._metaIndex = nIndexType
		elseif not Nil.is(nIndexType) then
			vContext:error("open table's __index must be object or function or nil")
		end
	end
	   
	local nNewIndexType = vMetaTableType:native_rawget(vContext, nManager:Literal("__newindex"))
	if nNewIndexType:isUnion() then
		vContext:error("open table's __newindex can't be union type")
	else
		if BaseFunction.is(nNewIndexType) or BaseObject.is(nNewIndexType) then
			self._metaNewIndex = nNewIndexType
		elseif not Nil.is(nNewIndexType) then
			vContext:error("open table's __newindex must be object or function or nil")
		end
	end
end

function OpenTable:meta_set(vContext, vKeyType, vValueTerm)
	local nNotRecursive, nOkay = vContext:recursiveChainTestAndRun(self, function()
		if not vKeyType:isSingleton() then
			vContext:error("open table's key must be singleton type")
		elseif vKeyType:isNilable() then
			vContext:error("open table's key can't be nil")
		else
			local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
			if nKeyIncludeType then
				local nField = self._fieldDict[nKeyIncludeType]
				vContext:addLookTarget(nField)
				if nField:getLockCtx() then
					vContext:error("field is locked"..tostring(vKeyType))
				else
					local nTopBranch = vContext:getStack():topBranch()
					if nField:getAssignBranch() == nTopBranch then
						vContext:warn("field:"..tostring(nKeyIncludeType).." multi assign in one scope")
					end
					nField:overrideAssign(vValueTerm:getType(), nTopBranch)
				end
			else
				local nMetaNewIndex = self._metaNewIndex
				if BaseFunction.is(nMetaNewIndex) then
					local nTermTuple = vContext:FixedTermTuple({
						vContext:RefineTerm(self), vContext:RefineTerm(vKeyType), vValueTerm
					})
					nMetaNewIndex:meta_call(vContext, nTermTuple)
					local nType = vValueTerm:getType()
					if BaseFunction.is(nType) then
						vContext:addLookTarget(nType)
					end
				elseif BaseObject.is(nMetaNewIndex) then
					nMetaNewIndex:meta_set(vContext, vKeyType, vValueTerm)
				else
					self:native_rawset(vContext, vKeyType, vValueTerm)
				end
			end
		end
		do return true
	 end end)
	if nNotRecursive then
		  
	else
		error("opentable's __newindex chain recursive")
	end
end

local NIL_TRIGGER = 1
local NONE_TRIGGER = 2
function OpenTable:meta_get(vContext, vKeyType)
	local nNotRecursive, nOkay = vContext:recursiveChainTestAndRun(self, function()
		    
		local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
		local nTrigger = false
		if nKeyIncludeType then
			local nField = self._fieldDict[nKeyIncludeType]
			vContext:addLookTarget(nField)
			local nType = nField:getValueType()
			nField:lock(vContext)
			if nType:isUnion() then
				vContext:warn("open table's field is union")
			end
			vContext:pushFirstAndTuple(nType)
			if nType:isNilable() then
				nTrigger = NIL_TRIGGER
			end
		else
			nTrigger = NONE_TRIGGER
		end
		if nTrigger then
			local nMetaIndex = self._metaIndex
			if BaseFunction.is(nMetaIndex) then
				local nTermTuple = vContext:FixedTermTuple({vContext:RefineTerm(self), vContext:RefineTerm(vKeyType)})
				nMetaIndex:meta_call(vContext, nTermTuple)
				do return true
			 end elseif BaseObject.is(nMetaIndex) then
				local nNextOkay = nMetaIndex:meta_get(vContext, vKeyType)
				do return nTrigger ~= NONE_TRIGGER or nNextOkay
			 end else
				vContext:pushFirstAndTuple(self:native_rawget(vContext, vKeyType))
				do return nTrigger ~= NONE_TRIGGER
			 end end
		else
			do return true
		 end end
	end)
	if nNotRecursive then
		do return nOkay
	 end else
		error("opentable's __index chain recursive")
	end
end

function OpenTable:native_rawset(vContext, vKeyType, vValueTerm)
	vContext:openAssign(vValueTerm:getType())
	local nIncludeType = self._keyType:includeAtom(vKeyType)
	if not nIncludeType then
		if vKeyType:isSingleton() and not vKeyType:isNilable() then
			   
			if self._locked then
				vContext:error("assign to locked open-table")
				do return
			 end end
			self._keyType = self._manager:checkedUnion(self._keyType, vKeyType)
			local nField = OpenField.new(
				vContext:getNode(), self,
				vKeyType, vValueTerm:getType(),
				vContext:getStack():topBranch()
			)
			self._fieldDict[vKeyType] = nField
			vContext:addLookTarget(nField)
		else
			vContext:error("set("..tostring(vKeyType)..","..tostring(vValueTerm:getType())..") error")
		end
	else
		if self._locked then
			vContext:error("assign to locked open-table")
			do return
		 end end
		local nField = self._fieldDict[nIncludeType]
		nField:overrideAssign(vValueTerm:getType(), vContext:getStack():topBranch())
		vContext:addLookTarget(nField)
	end
end

function OpenTable:native_rawget(vContext, vKeyType)
	local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
	if nKeyIncludeType then
		local nField = self._fieldDict[nKeyIncludeType]
		nField:lock(vContext)
		do return nField:getValueType()
	 end else
		local nNil = self._manager.type.Nil
		if not self._locked then
			local nField = OpenField.new(vContext:getNode(), self, vKeyType, nNil, vContext:getStack():topBranch())
			nField:lock(vContext)
			self._fieldDict[vKeyType] = nField
		end
		do return nNil
	 end end
end

function OpenTable:native_next(vContext, vInitType)
	self._locked = true
	local nNextDict = self._nextDict
	local nValueType = self._nextValue
	if not nNextDict or not nValueType then
		nNextDict = {}
		for nKeyAtom, nField in pairs(self._fieldDict) do
			nNextDict[nKeyAtom] = nField:getValueType()
		::continue:: end
		local nNil = self._manager.type.Nil
		local nCollection = self._manager:TypeCollection()
		for nOneKey, nOneField in pairs(self._fieldDict) do
			local nValueType = nOneField:getValueType()
			local nNotnilType = nValueType:notnilType()
			if not nNotnilType:isNever() then
				nNextDict[nOneKey] = nNotnilType
				nCollection:put(nNotnilType)
			end
			nOneField:lock(vContext)
		::continue:: end
		nCollection:put(nNil)
		nValueType = nCollection:mergeToAtomUnion()
		nNextDict[nNil] = nNil
		self._nextValue = nValueType
		self._nextDict = nNextDict
	end
	do return nValueType, nNextDict
 end end

function OpenTable:meta_pairs(vContext)
	
	   
	  
		   
		  
			      
		
	
	do return false
 end end

function OpenTable:meta_ipairs(vContext)
	vContext:error("TODO:open table use __ipairs as meta field")
	do return false
 end end

function OpenTable:memberFunctionFillSelf(vChain, vSelfTable)
	local nNotRecursive = vChain:testAndRun(self, function()
		for _, nField in pairs(self._fieldDict) do
			local nSelfValue = nField:getValueType()
			if AutoMemberFunction.is(nSelfValue) then
				if not nSelfValue:needPolyArgs() then
					nSelfValue:indexAutoFn(vSelfTable)
				end
			end
		::continue:: end
		do return true
	 end end)
	if nNotRecursive then
		local nMetaIndex = self._metaIndex
		if nMetaIndex then
			if BaseObject.is(nMetaIndex) then
				nMetaIndex:memberFunctionFillSelf(vChain, vSelfTable)
			end
		end
	end
end

function OpenTable:getValueDict() 
	local nDict  = {}
	self._keyType:foreach(function(vType)
		nDict[vType] = self._fieldDict[vType]:getValueType()
	end)
	do return nDict
 end end

function OpenTable:putCompletion(vCompletion)
	if vCompletion:testAndSetPass(self) then
		self._keyType:foreach(function(vType)
			if StringLiteral.is(vType) then
				vCompletion:putField(vType:getLiteral(), self._fieldDict[vType]:getValueType())
			end
		end)
		local nMetaIndex = self._metaIndex
		if nMetaIndex then
			nMetaIndex:putCompletion(vCompletion)
		end
	end
end

function OpenTable:findRequireStack()
	do return self._lexStack:findRequireStack()
 end end

function OpenTable:isSingleton()
	do return true
 end end

function OpenTable:setLocked()
	self._locked = true
end

function OpenTable:isLocked()
	do return self._locked
 end end

do return OpenTable
 end 
end end
--thlua.type.object.OpenTable end ==========)

--thlua.type.object.SealTable begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.SealTable'] = function (...)

local StringLiteral = require "thlua.type.basic.StringLiteral"
local TypedObject = require "thlua.type.object.TypedObject"
local TypedFunction = require "thlua.type.func.TypedFunction"
local AutoMemberFunction = require "thlua.type.func.AutoMemberFunction"
local AutoFunction = require "thlua.type.func.AutoFunction"
local BaseFunction = require "thlua.type.func.BaseFunction"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local Nil = require "thlua.type.basic.Nil"

local BaseObject = require "thlua.type.object.BaseObject"
local ObjectField = require "thlua.type.object.ObjectField"
local class = require "thlua.class"


	  
	   
		  
		  
	


local SealTable = class (BaseObject)

function SealTable:ctor(vManager, vNode, vLexStack, ...)
	self._lexStack = vLexStack
	self._keyType=vManager.type.Never 
	self._fieldDict={} 
	self._nextValue=false 
	self._nextDict=false  
	self._metaTable=false 
	self._metaIndex=false
	self._newIndexType=false
end

function SealTable:meta_len(vContext)
	 
	do return self._manager.type.Integer
 end end

function SealTable:ctxWait(vContext)
end

function SealTable:initByKeyValue(vNode, vKeyType, vValueDict )
	self._keyType = vKeyType
	for k,v in pairs(vValueDict) do
		self._fieldDict[k] = ObjectField.new(vNode, self, k, v)
	::continue:: end
end

function SealTable:onSetMetaTable(vContext)
end

function SealTable:native_setmetatable(vContext, vMetaTableType)
	if self._metaTable then
		vContext:error("can only setmetatable once for one table")
		do return
	 end end
	self._metaTable = vMetaTableType
	     
	assert(not self._metaEventCom, "meta event has been setted")
	local nMetaEventCom = self._manager:makeMetaEventCom(self)
	nMetaEventCom:initByTable(vContext, vMetaTableType)
	self._metaEventCom = nMetaEventCom
	     
	local nManager = self._manager
	local nIndexType = vMetaTableType:native_rawget(vContext, nManager:Literal("__index"))
	local nNewIndexType = vMetaTableType:native_rawget(vContext, nManager:Literal("__newindex"))
	    
	self:setMetaIndex(
		vContext,
		not nIndexType:isNever() and nIndexType or false,
		not nNewIndexType:isNever() and nNewIndexType or false)
	    
	self:onSetMetaTable(vContext)
end

function SealTable:meta_set(vContext, vKeyType, vValueTerm)
	self:ctxWait(vContext)
	local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
	if nKeyIncludeType then
		vContext:pushNothing()
		local nField = self._fieldDict[nKeyIncludeType]
		vContext:addLookTarget(nField)
		vContext:includeAndCast(nField:getValueType(), vValueTerm:getType(), "set")
	else
		self:native_rawset(vContext, vKeyType, vValueTerm)
	end
end

local NIL_TRIGGER = 1
local NONE_TRIGGER = 2
function SealTable:meta_get(vContext, vKeyType)
	self:ctxWait(vContext)
	local nNotRecursive, nOkay = vContext:recursiveChainTestAndRun(self, function()
		local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
		local nIndexType = self._metaIndex
		local nTrigger = false
		if nKeyIncludeType then
			local nField = self._fieldDict[nKeyIncludeType]
			local nValueType = nField:getValueType()
			vContext:addLookTarget(nField)
			if nValueType:isNilable() then
				nTrigger = NIL_TRIGGER
				if nIndexType then
					vContext:pushFirstAndTuple(nValueType:notnilType())
				else
					vContext:pushFirstAndTuple(nValueType)
				end
			else
				vContext:pushFirstAndTuple(nValueType)
			end
		else
			nTrigger = NONE_TRIGGER
			local nInterType = self._keyType:safeIntersect(vKeyType)
			if not nInterType then
				vContext:error("unexpected intersect when table get")
			else
				nInterType:foreach(function(vKeyAtom)
					local nField = self._fieldDict[vKeyAtom]
					local nValueType = nField:getValueType()
					vContext:addLookTarget(nField)
					if nIndexType then
						vContext:pushFirstAndTuple(nValueType:notnilType())
					else
						vContext:pushFirstAndTuple(nValueType)
					end
				end)
			end
			if not nIndexType then
				vContext:pushFirstAndTuple(self._manager.type.Nil)
			end
		end
		local nOkay = nTrigger ~= NONE_TRIGGER
		if nTrigger and nIndexType then
			if BaseObject.is(nIndexType) then
				local nNextOkay = nIndexType:meta_get(vContext, vKeyType)
				nOkay = nOkay or nNextOkay
			elseif BaseFunction.is(nIndexType) then
				local nTermTuple = vContext:FixedTermTuple({vContext:RefineTerm(self), vContext:RefineTerm(vKeyType)})
				nIndexType:meta_call(vContext, nTermTuple)
				nOkay = true
			end
		end
		do return nOkay
	 end end)
	if nNotRecursive then
		do return nOkay
	 end else
		vContext:pushFirstAndTuple(self._manager.type.Nil)
		do return false
	 end end
end

function SealTable:native_rawset(vContext, vKeyType, vValueTerm)
	self:ctxWait(vContext)
	vContext:openAssign(vValueTerm:getType())
	local nIncludeType = self._keyType:includeAtom(vKeyType)
	if not nIncludeType then
		if vKeyType:isSingleton() and not vKeyType:isNilable() then
			if self:isLocked() then
				vContext:error("table is locked")
				do return
			 end else
				if self._lexStack:getSealStack() ~= vContext:getStack():getSealStack() then
					vContext:error("table new field in wrong scope")
					do return
				 end end
			end
			      
			self._keyType = self._manager:checkedUnion(self._keyType, vKeyType)
			local nField = ObjectField.new(vContext:getNode(), self, vKeyType, vValueTerm:getType())
			self._fieldDict[vKeyType] = nField
			vContext:addLookTarget(nField)
		else
			vContext:error("set("..tostring(vKeyType)..","..tostring(vValueTerm:getType())..") error")
		end
	else
		local nTableField = self._fieldDict[nIncludeType]
		local nFieldType = nTableField:getValueType()
		vContext:addLookTarget(nTableField)
		if not nFieldType:includeAll(vValueTerm:getType()) then
			vContext:error("wrong value type when set, key:"..tostring(nIncludeType))
		end
	end
end

function SealTable:native_rawget(vContext, vKeyType)
	self:ctxWait(vContext)
	local nKeyIncludeType = self._keyType:includeAtom(vKeyType)
	if nKeyIncludeType then
		local nField = self._fieldDict[nKeyIncludeType]
		local nValueType = nField:getValueType()
		vContext:addLookTarget(nField)
		do return nValueType
	 end else
		do return self._manager.type.Nil
	 end end
end

function SealTable:meta_ipairs(vContext)
	self:ctxWait(vContext)
	do return false
 end end

function SealTable:meta_pairs(vContext)
	self:ctxWait(vContext)
	local nCom = self._metaEventCom
	if nCom then
		local nPairsFn = nCom:getPairsFunc()
		if nPairsFn then
			print("meta_pairs TODO")
		end
	else
		do return false
	 end end
end

function SealTable:setMetaIndex(vContext, vIndexType, vNewIndexType)
	if not vIndexType then
		do return
	 end end
	if vIndexType:isUnion() then
		vContext:info("union type as __index TODO")
		do return
	 end end
	if vIndexType:isNilable() then
		vContext:info("TODO, impl interface if setmetatable without index")
		do return
	 end end
	self._metaIndex = vIndexType
end

function SealTable:native_next(vContext, vInitType)
	self:ctxWait(vContext)
	local nNextDict = self._nextDict
	local nValueType = self._nextValue
	if not nNextDict or not nValueType then
		nNextDict = {}
		for nKeyAtom, nField in pairs(self._fieldDict) do
			nNextDict[nKeyAtom] = nField:getValueType()
		::continue:: end
		local nNil = self._manager.type.Nil
		local nCollection = self._manager:TypeCollection()
		for nOneKey, nOneField in pairs(self._fieldDict) do
			local nValueType = nOneField:getValueType()
			local nNotnilType = nValueType:notnilType()
			nNextDict[nOneKey] = nNotnilType
			nCollection:put(nNotnilType)
		::continue:: end
		nCollection:put(nNil)
		nValueType = nCollection:mergeToAtomUnion()
		nNextDict[nNil] = nNil
		self._nextValue = nValueType
		self._nextDict = nNextDict
	end
	do return nValueType, nNextDict
 end end

function SealTable:native_getmetatable(vContext)
	self:ctxWait(vContext)
	do return self._metaTable or self._manager.type.Nil
 end end

function SealTable:meta_uop_some(vContext, vOper)
	self:ctxWait(vContext)
	vContext:error("meta uop TODO:"..tostring(vOper))
	do return self._manager.type.Never
 end end

function SealTable:meta_bop_func(vContext, vOper)
	self:ctxWait(vContext)
	local nMethodEvent = OPER_ENUM.bopNoEq[vOper]
	local nCom = self._metaEventCom
	if nCom then
		local nMethodFn = nCom:getBopFunc(nMethodEvent)
		if nMethodFn then
			do return true, nMethodFn
		 end end
	end
	do return false, nil
 end end

function SealTable:memberFunctionFillSelf(vChain, vSelfTable)
	local nNotRecursive = vChain:testAndRun(self, function()
		for _, nField in pairs(self._fieldDict) do
			local nSelfValue = nField:getValueType()
			if AutoMemberFunction.is(nSelfValue) then
				if not nSelfValue:needPolyArgs() then
					nSelfValue:indexAutoFn(vSelfTable)
				end
			end
		::continue:: end
		local nMetaIndex = self._metaIndex
		if nMetaIndex then
			if BaseObject.is(nMetaIndex) then
				nMetaIndex:memberFunctionFillSelf(vChain, vSelfTable)
			end
		end
		do return true
	 end end)
end

function SealTable:getValueDict() 
	local nDict  = {}
	self._keyType:foreach(function(vType)
		nDict[vType] = self._fieldDict[vType]:getValueType()
	end)
	do return nDict
 end end

function SealTable:putCompletion(vCompletion)
	if vCompletion:testAndSetPass(self) then
		self._keyType:foreach(function(vAtomType)
			if StringLiteral.is(vAtomType) then
				vCompletion:putField(vAtomType:getLiteral(), self._fieldDict[vAtomType]:getValueType())
			end
		end)
		local nMetaIndex = self._metaIndex
		if nMetaIndex then
			nMetaIndex:putCompletion(vCompletion)
		end
	end
end

function SealTable:isLocked()
	error("isLocked not implement")
	do return false
 end end

do return SealTable
 end 
end end
--thlua.type.object.SealTable end ==========)

--thlua.type.object.Struct begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.Struct'] = function (...)

local MemberFunction = require "thlua.type.func.MemberFunction"
local TypedObject = require "thlua.type.object.TypedObject"
local class = require "thlua.class"


	  


local Struct = class (TypedObject)

function Struct:ctor(...)
end

function Struct:detailString(vToStringCache, vVerbose)
	do return "Struct@"..tostring(self._node)
 end end

function Struct:assumeIncludeObject(vAssumeSet , vRightObject)
	local nAssumeInclude = false
	if not Struct.is(vRightObject) then
		do return false
	 end end
	local nRightValueDict = vRightObject:copyValueDict(self)
	local nRightKeyRefer, nRightNextKey = vRightObject:getKeyTypes()
	local nLeftNextKey = self._nextKey
	if nLeftNextKey and nRightNextKey then
		local nLR = nLeftNextKey:assumeIncludeAll(vAssumeSet, nRightNextKey)
		local nRL = nRightNextKey:assumeIncludeAll(vAssumeSet, nLeftNextKey)
		if not (nLR and nRL) then
			do return false
		 end end
	elseif nLeftNextKey or nRightNextKey then
		do return false
	 end end
	local function isMatchedKeyValue(
		vLeftKey, vLeftValue,
		vRightKey, vRightValue)
		if not vRightValue:assumeIncludeAll(vAssumeSet, vLeftValue) then
			do return false
		 end end
		if not vLeftValue:assumeIncludeAll(vAssumeSet, vRightValue) then
			do return false
		 end end
		if not vLeftKey:assumeIncludeAtom(vAssumeSet, vRightKey) then
			do return false
		 end end
		do return true
	 end end
	local nRightResultType = nRightKeyRefer:getResultType()
	if not self:_everyWith(vRightObject, function(nLeftKey, nLeftValue)
		if nRightResultType then        
			local nRightKey = nRightResultType:assumeIncludeAtom(vAssumeSet, nLeftKey)
			if not nRightKey then
				do return false
			 end end
			local nRightValue = nRightValueDict[nRightKey]
			if not nRightValue then
				do return false
			 end end
			if not isMatchedKeyValue(nLeftKey, nLeftValue, nRightKey, nRightValue) then
				do return false
			 end end
			nRightValueDict[nRightKey] = nil
		else         
			local nMatchedKey = nil
			for _, nRightKey in ipairs(nRightKeyRefer:getListAwait()) do
				if nRightKey:assumeIncludeAtom(vAssumeSet, nLeftKey) then
					local nRightValue = nRightValueDict[nRightKey]
					if nRightValue and isMatchedKeyValue(nLeftKey, nLeftValue, nRightKey, nRightValue) then
						nMatchedKey = nRightKey
						break
					end
				end
			::continue:: end
			if not nMatchedKey then
				do return false
			 end end
			nRightValueDict[nMatchedKey] = nil
		end
		do return true
	 end end) then
		do return false
	 end end
	if next(nRightValueDict) then
		do return false
	 end end
	do return true
 end end

function Struct:meta_set(vContext, vKeyType, vValueTerm)
	vContext:pushNothing()
	local nValueType = vValueTerm:getType()
	local nKey, nField = self:_keyIncludeAtom(vKeyType)
	if nKey then
		local nSetType = nField:getValueType()
		vContext:includeAndCast(nSetType, nValueType, "set")
	else
		vContext:error("error2:set("..tostring(vKeyType)..","..tostring(nValueType)..") in struct, field not exist")
	end
end

do return Struct
 end 
end end
--thlua.type.object.Struct end ==========)

--thlua.type.object.TypedObject begin ==========(
do local _ENV = _ENV
packages['thlua.type.object.TypedObject'] = function (...)

local TypedMemberFunction = require "thlua.type.func.TypedMemberFunction"
local StringLiteral = require "thlua.type.basic.StringLiteral"
local Exception = require "thlua.Exception"
local TYPE_BITS = require "thlua.type.TYPE_BITS"
local OPER_ENUM = require "thlua.type.OPER_ENUM"
local MetaEventCom = require "thlua.type.object.MetaEventCom"
local ObjectField = require "thlua.type.object.ObjectField"

local BaseObject = require "thlua.type.object.BaseObject"
local class = require "thlua.class"


	  


local TypedObject = class (BaseObject)

function TypedObject:ctor(vManager, vNode)
	local nTask = vManager:getScheduleManager():newTask()
	self._task = nTask
	self._keyRefer=vManager:AsyncUnion(nTask)
	self._valueDict=false 
	self._fieldDict={} 
	self._nextKey=false
	self._nextValue=false
	self._nextDict={} 
	self._intersectSet={} 
end

function TypedObject:lateInit(vIntersectSet, vValueDict , vNextKey, vMetaEventCom)
	self._nextKey = vNextKey
	self._intersectSet = vIntersectSet
	self._metaEventCom = vMetaEventCom
	self._valueDict = vValueDict
end

function TypedObject:lateCheck()
	local nNextKey = self._nextKey
	local nValueDict = assert(self._valueDict, "member dict must existed here")
	if nNextKey then
		nNextKey:checkAtomUnion():foreach(function(vKeyAtom)
			local nMember = nValueDict[vKeyAtom]
			if not nMember then
				error("nextKey is not subtype of object's key, missing field:"..tostring(vKeyAtom))
			end
		end)
	end
end

function TypedObject:_everyWith(vRightObject, vFunc )
	local nValueDict = self:getValueDict()
	for nLeftKey, nLeftValue in pairs(nValueDict) do
		if not nLeftValue:mayRecursive() then
			if not vFunc(nLeftKey, nLeftValue) then
				do return false
			 end end
		end
	::continue:: end
	for nLeftKey, nLeftValue in pairs(nValueDict) do
		if nLeftValue:mayRecursive() then
			if not vFunc(nLeftKey, nLeftValue) then
				do return false
			 end end
		end
	::continue:: end
	do return true
 end end

function TypedObject:assumeIncludeObject(vAssumeSet , vRightObject)
	error("assume include Object not implement")
	do return false
 end end

function TypedObject:assumeIncludeAtom(vAssumeSet, vRightType, _)
	local nRightStruct = vRightType:checkTypedObject()
	if not nRightStruct then
		do return false
	 end end
	if self == nRightStruct then
		do return self
	 end end
	local nMgr = self._manager
	local nRelation = nMgr:attachPairRelation(self, nRightStruct, not vAssumeSet)
	if nRelation then
		if nRelation == ">" or nRelation == "=" then
			do return self
		 end else
			do return false
		 end end
	else
		assert(vAssumeSet, "assume set must be existed here")
	end
	local nPair = self._manager:makePair(self, nRightStruct)
	local nAssumeResult = vAssumeSet[nPair]
	if nAssumeResult ~= nil then
		do return nAssumeResult and self
	 end end
	vAssumeSet[nPair] = true
	local nAssumeInclude = self:assumeIncludeObject(vAssumeSet, nRightStruct)
	if not nAssumeInclude then
		vAssumeSet[nPair] = false
		do return false
	 end else
		do return self
	 end end
end

function TypedObject:meta_len(vContext)
	local nCom = self:getMetaEventCom()
	if nCom then
		local nType = nCom:getLenType()
		if nType then
			do return nType
		 end end
	end
	vContext:error(self, "object take # oper, but _len action not setted")
	do return self._manager.type.Integer
 end end

function TypedObject:meta_uop_some(vContext, vOper)
	vContext:error("other oper invalid:"..tostring(vOper))
	do return self._manager.type.Never
 end end

function TypedObject:meta_pairs(vContext)
	do return false
 end end

function TypedObject:meta_ipairs(vContext)
	do return false
 end end

function TypedObject:native_next(vContext, vInitType)
	local nValueDict = self:getValueDict()
	local nNextKey = self._nextKey
	local nNil = self._manager.type.Nil
	if not nNextKey then
		vContext:error("this object can not take next")
		do return nNil, {[nNil]=nNil}
	 end end
	local nNextValue = self._nextValue
	local nNextDict = self._nextDict
	if not nNextValue then
		nNextDict = {}
		local nCollection = self._manager:TypeCollection()
		nNextKey:checkAtomUnion():foreach(function(vKeyAtom)
			local nValue = nValueDict[vKeyAtom]
			local nNotnilValue = nValue:checkAtomUnion():notnilType()
			nNextDict[vKeyAtom] = nNotnilValue
			nCollection:put(nNotnilValue)
		end)
		nCollection:put(nNil)
		nNextValue = nCollection:mergeToAtomUnion()
		nNextDict[nNil] = nNil
		self._nextValue = nNextValue
		self._nextDict = nNextDict
	end
	do return nNextValue, nNextDict
 end end

function TypedObject:isSingleton()
	do return false
 end end

function TypedObject:_keyIncludeAtom(vType) 
	local nKey = self._keyRefer:getTypeAwait():includeAtom(vType)
	if nKey then
		local nField = self._fieldDict[nKey]
		if not nField then
			nField = ObjectField.new(self._node, self, nKey, assert(self._valueDict)[nKey]:checkAtomUnion())
		end
		do return nKey, nField
	 end else
		do return false
	 end end
end

function TypedObject:meta_get(vContext, vType)
	local nKey, nField = self:_keyIncludeAtom(vType)
	if not nKey then
		vContext:error("error get("..tostring(vType)..") in struct")
		vContext:pushFirstAndTuple(self._manager.type.Nil)
	else
		local nType = nField:getValueType()
		vContext:pushFirstAndTuple(nType)
		vContext:addLookTarget(nField)
	end
	do return true
 end end

function TypedObject:meta_bop_func(vContext, vOper)
	local nMethodEvent = OPER_ENUM.bopNoEq[vOper]
	local nCom = self:getMetaEventCom()
	if nCom then
		local nFn = nCom:getBopFunc(nMethodEvent)
		if nFn then
			do return true, nFn
		 end end
	end
	do return false, nil
 end end

function TypedObject:indexKeyValue(vKeyType) 
	local nKey, nField = self:_keyIncludeAtom(vKeyType)
	if nKey then
		do return nKey, nField:getValueType()
	 end else
		do return false
	 end end
end

function TypedObject:buildAsync(vFunc)
	self._task:runAsync(function()
		vFunc(self._keyRefer)
	end)
end

function TypedObject:detailString(vToStringCache, vVerbose)
	do return "TypedObject..."
 end end

function TypedObject:getValueDict() 
	self._keyRefer:getListAwait()
	do return (assert(self._valueDict, "member list is not setted after waiting"))
 end end

function TypedObject:copyValueDict(vSelfObject ) 
	local nValueDict  = {}
	for k,v in pairs(self:getValueDict()) do
		if not TypedMemberFunction.is(v) then
			nValueDict[k] = v
		else
			nValueDict[k] = v:indexTypeFn(vSelfObject)
		end
	::continue:: end
	do return nValueDict
 end end

function TypedObject:getMetaEventCom()
	self._keyRefer:getListAwait()
	do return self._metaEventCom
 end end

function TypedObject:getKeyTypes() 
	do return self._keyRefer, self._nextKey
 end end

function TypedObject:checkTypedObject()
	do return self
 end end

function TypedObject:native_type()
	do return self._manager:Literal("table")
 end end

function TypedObject:partTypedObject()
	do return self
 end end

function TypedObject:mayRecursive()
	do return true
 end end

function TypedObject:getNode()
	do return self._node
 end end

function TypedObject:putCompletion(vCompletion)
	if vCompletion:testAndSetPass(self) then
		self._keyRefer:getTypeAwait():foreach(function(vType)
			if StringLiteral.is(vType) then
				vCompletion:putField(vType:getLiteral(), assert(self._valueDict)[vType])
			end
		end)
	end
end

function TypedObject:native_getmetatable(vContext)
	do return self._manager:checkedUnion(self._manager.type.Nil, self._manager.type.Truth)
 end end

do return TypedObject
 end 
end end
--thlua.type.object.TypedObject end ==========)

--thlua.type.union.BaseUnionType begin ==========(
do local _ENV = _ENV
packages['thlua.type.union.BaseUnionType'] = function (...)

local class = require "thlua.class"
local BaseReadyType = require "thlua.type.basic.BaseReadyType"

  

local BaseUnionType = class (BaseReadyType)

function BaseUnionType:ctor(...)
    self.bits = false  
    self._atomList = {}  
    self._unionSign = false
end

function BaseUnionType:getAtomList()
    do return self._atomList
 end end

function BaseUnionType:detailString(vCache, vVerbose)
    local l = {}
    self:foreach(function(vType)
        l[#l+1] = vType
    end)
    table.sort(l, function(vLeft, vRight)
        do return vLeft.id < vRight.id
     end end)
    local sl = {}
    for i=1, #l do
        sl[i] = l[i]:detailString(vCache, vVerbose)
    ::continue:: end
    do return "Union("..table.concat(sl,",")..")"
 end end

function BaseUnionType:initWithTypeId(vTypeId)
    assert(self.id == 0, "newunion's id must be 0")
    self.id = vTypeId
    local nAtomList = self._atomList
    self:foreach(function(vAtomType)
        nAtomList[#nAtomList + 1] = vAtomType
    end)
end

function BaseUnionType:isUnion()
    do return true
 end end

function BaseUnionType:unionSign()
    local nSign = self._unionSign
    local l = {}
    if not nSign then
        self:foreach(function(vType)
            l[#l + 1] = vType.id
        end)
        table.sort(l)
        nSign = table.concat(l, "-")
        self._unionSign = nSign
    end
    do return nSign
 end end

function BaseUnionType:putAwait(vType)
    error("this union type can't call putAwait to build itself")
end

function BaseUnionType:setAssigned(vContext)
    self:foreach(function(vType)
        vType:setAssigned(vContext)
    end)
end

function BaseUnionType:checkAtomUnion()
	do return self
 end end

function BaseUnionType:putCompletion(v)
    self:foreach(function(vType)
        vType:putCompletion(v)
    end)
end

do return BaseUnionType end 
end end
--thlua.type.union.BaseUnionType end ==========)

--thlua.type.union.ComplexUnion begin ==========(
do local _ENV = _ENV
packages['thlua.type.union.ComplexUnion'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Truth = require "thlua.type.basic.Truth"
local BaseUnionType = require "thlua.type.union.BaseUnionType"
local class = require "thlua.class"

  

local ComplexUnion = class (BaseUnionType)

function ComplexUnion:ctor(vManager, vBits, vBitToType )
	self._bitToType=vBitToType
	self.bits = vBits
end

function ComplexUnion:mayRecursive()
	local nBitToType = self._bitToType
	if nBitToType[TYPE_BITS.OBJECT] or nBitToType[TYPE_BITS.FUNCTION] then
		do return true
	 end else
		do return false
	 end end
end

function ComplexUnion:partTypedObject()
	local re = self._bitToType[TYPE_BITS.OBJECT] or self._manager.type.Never
	do return re:partTypedObject()
 end end

function ComplexUnion:partTypedFunction()
	local re = self._bitToType[TYPE_BITS.FUNCTION] or self._manager.type.Never
	do return re:partTypedFunction()
 end end

function ComplexUnion:foreach(vFunc)
	for nBits, nType in pairs(self._bitToType) do
		nType:foreach(vFunc)
	::continue:: end
end

function ComplexUnion:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	local nSimpleType = self._bitToType[vType.bits]
	if nSimpleType then
		do return nSimpleType:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	 end else
		do return false
	 end end
end

function ComplexUnion:assumeIntersectAtom(vAssumeSet, vType)
	local nSimpleType = self._bitToType[vType.bits]
	if nSimpleType then
		do return nSimpleType:assumeIntersectAtom(vAssumeSet, vType)
	 end elseif Truth.is(vType) then
		do return self
	 end else
		do return false
	 end end
end

function ComplexUnion:isNilable()
	if self._bitToType[TYPE_BITS.NIL] then
		do return true
	 end else
		do return false
	 end end
end

do return ComplexUnion
 end 
end end
--thlua.type.union.ComplexUnion end ==========)

--thlua.type.union.FalsableUnion begin ==========(
do local _ENV = _ENV
packages['thlua.type.union.FalsableUnion'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Truth = require "thlua.type.basic.Truth"
local BaseUnionType = require "thlua.type.union.BaseUnionType"
local class = require "thlua.class"

  

local FalsableUnion = class (BaseUnionType)

function FalsableUnion:ctor(vTypeManager, vTruableType, vFalsableBits)
	local nNil = vTypeManager.type.Nil
	local nFalse = vTypeManager.type.False
	self.bits=vTruableType.bits | vFalsableBits
	self._trueType=vTruableType
	self._notnilType=nil  
	self._nil=vFalsableBits & TYPE_BITS.NIL > 0 and nNil or false
	self._false=vFalsableBits & TYPE_BITS.FALSE > 0 and nFalse or false
	self._falseType=false 
    if self._trueType == vTypeManager.type.Never then
		self._falseType = self
    elseif self._nil and self._false then
		self._falseType = vTypeManager:checkedUnion(nNil, nFalse)
    else
		self._falseType = self._nil or self._false
    end
	if self._false then
		if not self._nil then
			self._notnilType = self
		else
			local nFalse = self._false
			if nFalse then
				self._notnilType = vTypeManager:checkedUnion(self._trueType, nFalse)
			else
				self._notnilType = self._trueType
			end
		end
	else
		self._notnilType = self._trueType
	end
end

function FalsableUnion:foreach(vFunc)
	self._trueType:foreach(vFunc)
	local nNilType = self._nil
	if nNilType then
		vFunc(nNilType)
	end
	local nFalseType = self._false
	if nFalseType then
		vFunc(nFalseType)
	end
end

function FalsableUnion:assumeIntersectAtom(vAssumeSet, vType)
	if Truth.is(vType) then
		local nTrueType = self._trueType
		if nTrueType == self._manager.type.Never then
			do return false
		 end else
			do return nTrueType
		 end end
	else
		local nTrueIntersect = self._trueType:assumeIntersectAtom(vAssumeSet, vType)
		if nTrueIntersect then
			do return nTrueIntersect
		 end else
			if self._nil and vType == self._manager.type.Nil then
				do return self._nil
			 end elseif self._false and vType == self._manager.type.False then
				do return self._false
			 end else
				do return false
			 end end
		end
	end
end

function FalsableUnion:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	local nTrueInclude = self._trueType:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	if nTrueInclude then
		do return nTrueInclude
	 end else
		if self._nil and vType == self._manager.type.Nil then
			do return self._nil
		 end elseif self._false and vType == self._manager.type.False then
			do return self._false
		 end else
			do return false
		 end end
	end
end

function FalsableUnion:isNilable()
	do return self._nil and true
 end end

function FalsableUnion:partTypedObject()
	do return self._trueType:partTypedObject()
 end end

function FalsableUnion:partTypedFunction()
	do return self._trueType:partTypedFunction()
 end end

function FalsableUnion:mayRecursive()
	do return self._trueType:mayRecursive()
 end end

function FalsableUnion:trueType()
	do return self._trueType
 end end

function FalsableUnion:notnilType()
	do return self._notnilType
 end end

function FalsableUnion:falseType()
	do return self._falseType or self._manager.type.Never
 end end

do return FalsableUnion
 end 
end end
--thlua.type.union.FalsableUnion end ==========)

--thlua.type.union.FuncUnion begin ==========(
do local _ENV = _ENV
packages['thlua.type.union.FuncUnion'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local Truth = require "thlua.type.basic.Truth"

local AnyFunction = require "thlua.type.func.AnyFunction"
local OpenFunction = require "thlua.type.func.OpenFunction"
local TypedFunction = require "thlua.type.func.TypedFunction"
local TypedMemberFunction = require "thlua.type.func.TypedMemberFunction"
local BaseFunction = require "thlua.type.func.BaseFunction"

local BaseUnionType = require "thlua.type.union.BaseUnionType"
local class = require "thlua.class"

  

local FuncUnion = class (BaseUnionType)

function FuncUnion:ctor(vManager)
	self._typeFnDict={}  
	self._typeMfnDict={}  
	self._notTypeFnDict={}  
	self._openFnDict={}  
	self._anyFn=false
	self._typedPart=false
	self.bits=TYPE_BITS.FUNCTION
end

function FuncUnion:foreach(vFunc)
	for nType, _ in pairs(self._openFnDict) do
		vFunc(nType)
	::continue:: end
	local nAnyFn = self._anyFn
	if not nAnyFn then
		for nType, _ in pairs(self._typeFnDict) do
			vFunc(nType)
		::continue:: end
		for nType, _ in pairs(self._typeMfnDict) do
			vFunc(nType)
		::continue:: end
		for nType, _ in pairs(self._notTypeFnDict) do
			vFunc(nType)
		::continue:: end
	else
		vFunc(nAnyFn)
	end
end

function FuncUnion:putAwait(vType)
	if self:includeAtom(vType) then
		do return
	 end end
	if OpenFunction.is(vType) then
		self._openFnDict[vType] = true
	elseif AnyFunction.is(vType) then
		self._anyFn = vType
		do
			self._notTypeFnDict = {}
			self._typeFnDict = {}
		end
	              
	elseif TypedFunction.is(vType) then
		   
		local nDeleteList = {}
		for nTypeFn, _ in pairs(self._typeFnDict) do
			if vType:includeAtom(nTypeFn) then
				nDeleteList[#nDeleteList + 1] = nTypeFn
			else
				local nIntersect = vType:intersectAtom(nTypeFn)
				if nIntersect then
					error("unexpected intersect when union function")
				end
			end
		::continue:: end
		for _, nTypeFn in pairs(nDeleteList) do
			self._typeFnDict[nTypeFn] = nil
		::continue:: end
		self._typeFnDict[vType] = true
	elseif TypedMemberFunction.is(vType) then
		   
		local nDeleteList = {}
		for nTypeFn, _ in pairs(self._typeMfnDict) do
			if vType:includeAtom(nTypeFn) then
				nDeleteList[#nDeleteList + 1] = nTypeFn
			else
				local nIntersect = vType:intersectAtom(nTypeFn)
				if nIntersect then
					error("unexpected intersect when union function")
				end
			end
		::continue:: end
		for _, nTypeFn in pairs(nDeleteList) do
			self._typeMfnDict[nTypeFn] = nil
		::continue:: end
		self._typeMfnDict[vType] = true
	elseif BaseFunction.is(vType) then
		self._notTypeFnDict[vType] = true
	else
		error("fn-type unexpected")
	end
end

function FuncUnion:assumeIntersectAtom(vAssumeSet, vType)
	if Truth.is(vType) then
		do return self
	 end end
	if self:includeAtom(vType) then
		do return vType
	 end end
	if TypedFunction.is(vType) or TypedMemberFunction.is(vType) then
		local nCollection = self._manager:TypeCollection()
		self:foreach(function(vSubType)
			if vType:includeAtom(vSubType) then
				nCollection:put(vSubType)
			end
		end)
		do return nCollection:mergeToAtomUnion()
	 end end
	do return false
 end end

function FuncUnion:assumeIncludeAtom(vAssumeSet, vType, vSelfType)
	if OpenFunction.is(vType) then
		if self._openFnDict[vType] then
			do return vType
		 end else
			do return false
		 end end
	elseif TypedFunction.is(vType) then
		for nTypeFn, _ in pairs(self._typeFnDict) do
			if nTypeFn:assumeIncludeAtom(vAssumeSet, vType, vSelfType) then
				do return nTypeFn
			 end end
		::continue:: end
	elseif TypedMemberFunction.is(vType) then
		for nTypeFn, _ in pairs(self._typeMfnDict) do
			if nTypeFn:assumeIncludeAtom(vAssumeSet, vType, vSelfType) then
				do return nTypeFn
			 end end
		::continue:: end
	elseif BaseFunction.is(vType) then
		if self._notTypeFnDict[vType] then
			do return vType
		 end else
			do return false
		 end end
	end
	do return false
 end end

function FuncUnion:partTypedFunction()
	local nTypedPart = self._typedPart
	if nTypedPart then
		do return nTypedPart
	 end else
		if not next(self._notTypeFnDict) and not next(self._openFnDict) and not self._anyFn then
			self._typedPart = self
			do return self
		 end else
			local nCollection = self._manager:TypeCollection()
			for k,v in pairs(self._typeFnDict) do
				nCollection:put(k)
			::continue:: end
			local nTypedPart = nCollection:mergeToAtomUnion()
			self._typedPart = nTypedPart
			do return nTypedPart
		 end end
	end
end

function FuncUnion:mayRecursive()
	do return true
 end end

do return FuncUnion
 end 
end end
--thlua.type.union.FuncUnion end ==========)

--thlua.type.union.IntegerLiteralUnion begin ==========(
do local _ENV = _ENV
packages['thlua.type.union.IntegerLiteralUnion'] = function (...)

local IntegerLiteral = require "thlua.type.basic.IntegerLiteral"
local Integer = require "thlua.type.basic.Integer"
local Number = require "thlua.type.basic.Number"
local Truth = require "thlua.type.basic.Truth"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseUnionType = require "thlua.type.union.BaseUnionType"
local class = require "thlua.class"

  

local IntegerLiteralUnion = class (BaseUnionType)

function IntegerLiteralUnion:ctor(vTypeManager)
	self._literalSet={}  
	self.bits=TYPE_BITS.NUMBER
end

function IntegerLiteralUnion:putAwait(vType)
	if IntegerLiteral.is(vType) then
		self._literalSet[vType] = true
	else
		error("set put wrong")
	end
end

function IntegerLiteralUnion:assumeIntersectAtom(vAssumeSet, vType)
	if Integer.is(vType) or Number.is(vType) or Truth.is(vType) then
		do return self
	 end else
		do return self:assumeIncludeAtom(nil, vType)
	 end end
end

function IntegerLiteralUnion:assumeIncludeAtom(vAssumeSet, vType, _)
	if IntegerLiteral.is(vType) then
		if self._literalSet[vType] then
			do return vType
		 end else
			do return false
		 end end
	else
		do return false
	 end end
end

function IntegerLiteralUnion:foreach(vFunc)
	for nLiteralType, v in pairs(self._literalSet) do
		vFunc(nLiteralType)
	::continue:: end
end

do return IntegerLiteralUnion
 end 
end end
--thlua.type.union.IntegerLiteralUnion end ==========)

--thlua.type.union.MixingNumberUnion begin ==========(
do local _ENV = _ENV
packages['thlua.type.union.MixingNumberUnion'] = function (...)

local FloatLiteral = require "thlua.type.basic.FloatLiteral"
local Number = require "thlua.type.basic.Number"
local IntegerLiteral = require "thlua.type.basic.IntegerLiteral"
local IntegerLiteralUnion = require "thlua.type.union.IntegerLiteralUnion"
local Integer = require "thlua.type.basic.Integer"
local Truth = require "thlua.type.basic.Truth"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseUnionType = require "thlua.type.union.BaseUnionType"
local class = require "thlua.class"

  

local MixingNumberUnion = class (BaseUnionType)

function MixingNumberUnion:ctor(vTypeManager)
	self._floatLiteralSet={}  
	self._integerPart=false  
	self.bits=TYPE_BITS.NUMBER
end

function MixingNumberUnion:updateUnify()
	local nIntegerPart = self._integerPart
	if IntegerLiteralUnion.is(nIntegerPart) then
		self._integerPart = (self._manager:_unifyUnion(nIntegerPart) ) 
	end
end

function MixingNumberUnion:putAwait(vType)
	if FloatLiteral.is(vType) then
		self._floatLiteralSet[vType] = true
	elseif Integer.is(vType) then
		self._integerPart = vType
	elseif IntegerLiteral.is(vType) then
		local nIntegerPart = self._integerPart
		if not nIntegerPart then
			self._integerPart = vType
		elseif IntegerLiteral.is(nIntegerPart) then
			local nIntegerUnion = IntegerLiteralUnion.new(self._manager)
			nIntegerUnion:putAwait(vType)
			nIntegerUnion:putAwait(nIntegerPart)
			self._integerPart = nIntegerUnion
		elseif IntegerLiteralUnion.is(nIntegerPart) then
			nIntegerPart:putAwait(vType)
		elseif Integer.is(nIntegerPart) then
			 
		else
			error("set put wrong")
		end
	else
		error("set put wrong")
	end
end

function MixingNumberUnion:assumeIntersectAtom(vAssumeSet, vType)
	if Number.is(vType) or Truth.is(vType) then
		do return self
	 end elseif Integer.is(vType) then
		do return self._integerPart
	 end else
		do return self:assumeIncludeAtom(nil, vType)
	 end end
end

function MixingNumberUnion:assumeIncludeAtom(vAssumeSet, vType, _)
	if FloatLiteral.is(vType) then
		if self._floatLiteralSet[vType] then
			do return vType
		 end else
			do return false
		 end end
	else
		local nIntegerPart = self._integerPart
		do return nIntegerPart and nIntegerPart:assumeIncludeAtom(vAssumeSet, vType, _)
	 end end
end

function MixingNumberUnion:foreach(vFunc)
	for nLiteralType, v in pairs(self._floatLiteralSet) do
		vFunc(nLiteralType)
	::continue:: end
	local nIntegerPart = self._integerPart
	if nIntegerPart then
		nIntegerPart:foreach(vFunc)
	end
end

do return MixingNumberUnion
 end 
end end
--thlua.type.union.MixingNumberUnion end ==========)

--thlua.type.union.Never begin ==========(
do local _ENV = _ENV
packages['thlua.type.union.Never'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local BaseUnionType = require "thlua.type.union.BaseUnionType"
local class = require "thlua.class"

  

local Never = class (BaseUnionType)

function Never:ctor(vManager)
	self.bits=TYPE_BITS.NEVER
end

function Never:detailString(vStringCache, vVerbose)
	do return "Never"
 end end

function Never:foreach(vFunc)
end

function Never:assumeIncludeAtom(vAssumeSet, vType, _)
	do return false
 end end

function Never:assumeIntersectAtom(vAssumeSet, vType)
	do return false
 end end

function Never:unionSign()
	do return ""
 end end

function Never:isNever()
    do return true
 end end

do return Never
 end 
end end
--thlua.type.union.Never end ==========)

--thlua.type.union.ObjectUnion begin ==========(
do local _ENV = _ENV
packages['thlua.type.union.ObjectUnion'] = function (...)

local TYPE_BITS = require "thlua.type.TYPE_BITS"
local OpenTable = require "thlua.type.object.OpenTable"
local SealTable = require "thlua.type.object.SealTable"
local BaseObject = require "thlua.type.object.BaseObject"
local TypedObject = require "thlua.type.object.TypedObject"
local Truth = require "thlua.type.basic.Truth"

local BaseUnionType = require "thlua.type.union.BaseUnionType"
local class = require "thlua.class"

  

local ObjectUnion = class (BaseUnionType)

function ObjectUnion:ctor(vManager)
	self._typedObjectDict={}  
	self._sealTableDict={}  
	self._openTableDict={}  
	self._typedPart=false
	self.bits=TYPE_BITS.OBJECT
end

function ObjectUnion:foreach(vFunc)
	for nType, _ in pairs(self._typedObjectDict) do
		vFunc(nType)
	::continue:: end
	for nType, _ in pairs(self._sealTableDict) do
		vFunc(nType)
	::continue:: end
	for nType, _ in pairs(self._openTableDict) do
		vFunc(nType)
	::continue:: end
end

function ObjectUnion:putAwait(vType)
	if self:includeAtom(vType) then
		do return
	 end end
	if not BaseObject.is(vType) then
		error("object-type unexpected")
	end
	if OpenTable.is(vType) then
		self._openTableDict[vType] = true
		do return
	 end end
	   
	local nDeleteList1 = {}
	for nSealTable, _ in pairs(self._sealTableDict) do
		if vType:includeAtom(nSealTable) then
			nDeleteList1[#nDeleteList1 + 1] = nSealTable
		end
	::continue:: end
	for _, nSealTable in pairs(nDeleteList1) do
		self._sealTableDict[nSealTable] = nil
	::continue:: end
	if SealTable.is(vType) then
		self._sealTableDict[vType] = true
	elseif TypedObject.is(vType) then
		   
		local nDeleteList2 = {}
		for nTypedObject, _ in pairs(self._typedObjectDict) do
			if vType:includeAtom(nTypedObject) then
				nDeleteList2[#nDeleteList2 + 1] = nTypedObject
			else
				local nIntersect = vType:intersectAtom(nTypedObject)
				if nIntersect then
					error("unexpected intersect when union object")
				end
			end
		::continue:: end
		for _, nTypedObject in pairs(nDeleteList2) do
			self._typedObjectDict[nTypedObject] = nil
		::continue:: end
		self._typedObjectDict[vType] = true
	else
		error("object-type unexpected???")
	end
end

function ObjectUnion:assumeIntersectAtom(vAssumeSet, vType)
	if Truth.is(vType) then
		do return self
	 end end
	if not BaseObject.is(vType) then
		do return false
	 end end
	local nCollection = self._manager:TypeCollection()
	local nExplicitCount = 0
	self:foreach(function(vSubType)
		if nExplicitCount then
			local nCurIntersect = vType:assumeIntersectAtom(vAssumeSet, vSubType)
			if nCurIntersect == true then
				nExplicitCount = false
			elseif nCurIntersect then
				nExplicitCount = nExplicitCount + 1
				nCollection:put(nCurIntersect)
			end
		end
	end)
	if not nExplicitCount then
		do return true
	 end else
		do return nExplicitCount > 0 and nCollection:mergeToAtomUnion()
	 end end
end

function ObjectUnion:partTypedObject()
	local nTypedPart = self._typedPart
	if nTypedPart then
		do return nTypedPart
	 end else
		if not next(self._openTableDict) and not next(self._sealTableDict) then
			self._typedPart = self
			do return self
		 end else
			local nCollection = self._manager:TypeCollection()
			for k,v in pairs(self._typedObjectDict) do
				nCollection:put(k)
			::continue:: end
			local nTypedPart = nCollection:mergeToAtomUnion()
			self._typedPart = nTypedPart
			do return nTypedPart
		 end end
	end
end

function ObjectUnion:mayRecursive()
	do return true
 end end

function ObjectUnion:assumeIncludeAtom(vAssumeSet, vType, _)
	if OpenTable.is(vType) then
		do return self._openTableDict[vType] and vType or false
	 end end
	if SealTable.is(vType) then
		for nTable, _ in pairs(self._sealTableDict) do
			if nTable:assumeIncludeAtom(vAssumeSet, vType) then
				do return nTable
			 end end
		::continue:: end
	end
	for nObject, _ in pairs(self._typedObjectDict) do
		if nObject:assumeIncludeAtom(vAssumeSet, vType) then
			do return nObject
		 end end
	::continue:: end
	do return false
 end end

do return ObjectUnion
 end 
end end
--thlua.type.union.ObjectUnion end ==========)

--thlua.type.union.StringLiteralUnion begin ==========(
do local _ENV = _ENV
packages['thlua.type.union.StringLiteralUnion'] = function (...)

local StringLiteral = require "thlua.type.basic.StringLiteral"
local String = require "thlua.type.basic.String"
local Truth = require "thlua.type.basic.Truth"
local TYPE_BITS = require "thlua.type.TYPE_BITS"

local BaseUnionType = require "thlua.type.union.BaseUnionType"
local class = require "thlua.class"

  

local StringLiteralUnion = class (BaseUnionType)

function StringLiteralUnion:ctor(vTypeManager)
	self._literalSet={}     
	self.bits=TYPE_BITS.STRING
end

function StringLiteralUnion:putAwait(vType)
	if StringLiteral.is(vType) then
		self._literalSet[vType] = true
	else
		error("set put wrong")
	end
end

function StringLiteralUnion:assumeIntersectAtom(vAssumeSet, vType)
	if String.is(vType) or Truth.is(vType) then
		do return self
	 end else
		do return self:assumeIncludeAtom(nil, vType)
	 end end
end

function StringLiteralUnion:assumeIncludeAtom(vAssumeSet, vType, _)
	if StringLiteral.is(vType) then
		if self._literalSet[vType] then
			do return vType
		 end else
			do return false
		 end end
	else
		do return false
	 end end
end

function StringLiteralUnion:foreach(vFunc)
	for nLiteralType, v in pairs(self._literalSet) do
		vFunc(nLiteralType)
	::continue:: end
end

do return StringLiteralUnion
 end 
end end
--thlua.type.union.StringLiteralUnion end ==========)

            local boot = require "thlua.boot"
            -- local f = io.open("d:/log.txt", "w")
            boot.runServer(...)
        