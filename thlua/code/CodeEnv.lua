
local parser = require "thlua.code.parser"
local Node = require "thlua.code.Node"
local VisitorExtend = require "thlua.code.VisitorExtend"
local Exception = require "thlua.Exception"
local CodeEnv = {}

CodeEnv.__index=CodeEnv

function CodeEnv.new(vSubject, vChunkName)
	local self = setmetatable({
		filename = vFileName,
		hinting = false,
		scopeTraceList = {},
		_linePosList = {},
		_subject = vSubject,
		_chunkName = vChunkName,
		_posToChange = {}, -- if value is string then insert else remove
		_astOrErr = nil,
		_nodeList = false, -- as init flag
		_nameList = {},
		_scopeList = {},
		_rootScope = false,
		_identList = {},
		_typingFn = "typing code not execute",
	}, CodeEnv)

	self:_init()
	return self
end

function CodeEnv:makeErrNode(vPos, vErr)
	local nLine, nColumn = self:fixupPos(vPos)
	return setmetatable({
		tag="Error",
		path=self._chunkName,
		pos=vPos,
		l=nLine,
		c=nColumn,
		vErr
	}, Node)
end

function CodeEnv:dumpAst()
	local l = {}
	local function recur(t, depth)
		local indent = string.rep(" ", depth)
		l[#l + 1] = indent .. tostring(t.tag) .. "{\n"
		for k,v in ipairs(t) do
			if type(v) == "table" then
				recur(v, depth + 1)
			else
				l[#l+1] = indent .." ".. tostring(v).."\n"
			end
		end
		l[#l + 1] = indent .. "}\n"
	end
	recur(self._astOrErr, 0)
	print(table.concat(l))
end

function CodeEnv:prepare()
	if self._nodeList then
		return
	end
	local nNodeList = {}
	self._nodeList = nNodeList

	-- 1. set line & column, parent
	local nStack = {}
	self:visit(function(visitor, vNode)
		-- 1. put into nodelist
		local nIndex = #nNodeList + 1
		nNodeList[nIndex] = vNode
		vNode.index = nIndex
		-- 2. put into namelist
		if (vNode.tag == "Id" or vNode.tag == "String") and vNode.posEnd > vNode.pos then
			table.insert(self._nameList, vNode)
		end
		-- 3. get path, parent, l, c
		vNode.parent = nStack[#nStack] or false
		vNode.path = self._chunkName
		vNode.l, vNode.c = self:fixupPos(vNode.pos, vNode)
		nStack[#nStack + 1] = vNode
		visitor:rawVisit(vNode)
		nStack[#nStack] = nil
		setmetatable(vNode, Node)
		-- 4. mark return statement for chunk or function
		if vNode.tag == "Return" then
			local nFuncOrChunk = vNode.parent
			while not (nFuncOrChunk.tag == "Function" or nFuncOrChunk.tag == "Chunk") do
				nFuncOrChunk = nFuncOrChunk.parent
			end
			if #vNode[1] > 0 then
				nFuncOrChunk.retFlag = true
			end
		end
	end)
	table.sort(self._nameList, function(a,b)
		return a.pos < b.pos
	end)
end

function CodeEnv:visit(vDictOrFunc)
	local visitor = VisitorExtend(vDictOrFunc)
	visitor:realVisit(self._astOrErr)
end

function CodeEnv:binSearch(vList, vPos)
	if #vList <= 0 then
		return false
	end
	if vPos < vList[1].pos then
		return false
	end
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
	end
	return nLeft, vList[nLeft]
end

-- pos to line & column
function CodeEnv:fixupPos(vPos, vNode)
	local line, lineInfo = self:binSearch(self._linePosList, vPos)
	if not line then
		print("warning pos out of range, pos="..vPos, vNode and vNode.tag)
		return 1, 1
	else
		return line, vPos - lineInfo.pos + 1
	end
end

function CodeEnv:_init()
	-- 1. calc line pos
	local nSubject = self._subject
	local nStartPos = 1
	local nFinishPos = 0
	local nList = {}
	local nLineCount = 0
	while true do
		nLineCount = nLineCount + 1
		nFinishPos = nSubject:find("\n", nStartPos)
		if nFinishPos then
			nList[#nList + 1] = {
				pos=nStartPos,
				posEnd=nFinishPos
			}
			nStartPos = nFinishPos + 1
		else
			if nStartPos <= #nSubject then
				nList[#nList + 1] = {
					pos=nStartPos,
					posEnd=#nSubject
				}
			end
			break
		end
	end
	self._linePosList = nList
	-- 2. gen ast
	local ok, astOrErr = pcall(parser.parse,self, self._subject)
	if not ok then
		if type(astOrErr) == "table" and astOrErr.tag == "Error" then
			self._astOrErr = astOrErr
		else
			self._astOrErr = self:makeErrNode(1, "parse error: "..tostring(astOrErr))
		end
	else
		self._astOrErr = astOrErr
	end
end

function CodeEnv:subScript(vStartPos, vFinishPos)
	return self._subject:sub(vStartPos, vFinishPos)
end

function CodeEnv:markDel(vStartPos, vFinishPos)
	self._posToChange[vStartPos] = vFinishPos
end

function CodeEnv:markAdd(vStartPos, vContent)
	self._posToChange[vStartPos] = vContent
end

function CodeEnv:genLuaCode()
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
			-- hint in hint
			-- TODO replace in hint script
			-- continue
		else
			local nChange = nPosToChange[nStartPos]
			if type(nChange) == "number" then
				-- 1. save lua code
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = nLuaCode
				-- 2. replace hint code with space and newline
				local nFinishPos = nPosToChange[nStartPos]
				local nHintCode = nSubject:sub(nStartPos, nFinishPos)
				nContents[#nContents + 1] = nHintCode:gsub("[^\r\n \t]", "")
				nPreFinishPos = nFinishPos
			--[[elseif type(nChange) == "string" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = nChange
				nPreFinishPos = nStartPos]]
			else
				error("unexpected branch")
			end
		end
	end
	nContents[#nContents + 1] = nSubject:sub(nPreFinishPos + 1, #nSubject)
	return table.concat(nContents)
end

function CodeEnv:genTypingCode()
	local ReferVisitor = require "thlua.code.ReferVisitor"
	ReferVisitor.new(self):realVisit(self._astOrErr)
	self:prepare()
	local TypeHintGen = require "thlua.code/TypeHintGen"
	return TypeHintGen.visit(self)
end

function CodeEnv:loadTyping()
	local ok, fnOrErr = pcall(function ()
		local nTypingCode = self:genTypingCode()
		local nFunc, nInfo = load(nTypingCode, self._chunkName, "t", setmetatable({}, {
			__index=function(t,k)
				-- TODO, give node pos
				error("indexing global is fatal error")
			end
		}))
		assert(type(nFunc) == "function", "typing code must return function")
		if not nFunc then
			-- TODO, give node pos
			error(nInfo)
		end
		return nFunc
	end)
	if ok then
		self._typingFn = fnOrErr
	else
		self._typingFn = tostring(fnOrErr)
	end
end

function CodeEnv:checkOkay()
	if self._astOrErr.tag == "Error" then
		return false, self._astOrErr
	elseif type(self._typingFn) == "string" then
		return false, self._typingFn
	else
		return true
	end
end

function CodeEnv:recordScope(vCurScopeOrNil, vNode)
	local nNewIndex = #self._scopeList + 1
	vNode.scope_refer = nNewIndex
	if vCurScopeOrNil then
		vNode.symbol_ident_dict = setmetatable({}, {
			__index=vCurScopeOrNil.symbol_ident_dict,
		})
		table.insert(vCurScopeOrNil.scope_children, vNode)
	else
		vNode.symbol_ident_dict = setmetatable({}, {
			__index={_ENV=self._identList[1]}
		})
		self._rootScope = vNode
	end
	vNode.scope_children = {}
	vNode.symbol_dots = false
	vNode.is_region = false
	vNode.lookup_block = vCurScopeOrNil or false
	self._scopeList[nNewIndex] = vNode
end

function CodeEnv:record_ENV(vIdentNode)
	assert(#self._identList == 0, "_ENV must be first identity")
	assert(vIdentNode[1] == "_ENV", "only _ENV can be used in this function")
	self._identList[1] = vIdentNode
	vIdentNode.ident_refer = 1
	vIdentNode.scope_refer = 0
	vIdentNode.is_define = true
end

function CodeEnv:recordSymbol(vCurScope, vIdentNode)
	local nNewIndex = #self._identList + 1
	vIdentNode.ident_refer = nNewIndex
	vIdentNode.scope_refer = vCurScope.scope_refer
	vIdentNode.is_define = true
	self._identList[nNewIndex] = vIdentNode
	if vIdentNode.tag == "Id" then
		local nName = vIdentNode[1]
		local nLookupNode = vCurScope.symbol_ident_dict[nName]
		vCurScope.symbol_ident_dict[nName] = vIdentNode
		vIdentNode.lookup_ident = nLookupNode
	elseif vIdentNode.tag == "Dots" then
		vCurScope.symbol_dots = vIdentNode
	else
		error("ident type error:"..tostring(vIdentNode.tag))
	end
end

function CodeEnv:getNodeList()
	return self._nodeList
end

function CodeEnv:getIdent(vIdentRefer)
	return self._identList[vIdentRefer]
end

function CodeEnv:getScope(vScopeRefer)
	return self._scopeList[vScopeRefer]
end

function CodeEnv:getAstTree()
	return self._astOrErr
end

function CodeEnv:getTypingFn()
	return self._typingFn
end

function CodeEnv:lcToPos(l, c)
	local nLineInfo = self._linePosList[l]
	if nLineInfo then
		return nLineInfo.pos + c - 1
	else
		return 0
	end
end

function CodeEnv:searchScopeByTrace(vList)
	local nScope = self._rootScope
	for i=1,#vList-1 do
		local nTrace = vList[i]
		nScope = nScope.scope_children[nTrace]
	end
	return nScope
end

function CodeEnv:searchNameByError(vErrorNode)
	local nErrExpr = vErrorNode[2]
	if not nErrExpr or nErrExpr.tag ~= "Id" then
		return
	end
	local nTraceList = vErrorNode[3]
	local nPos = nErrExpr.pos
	local nScope = self:searchScopeByTrace(nTraceList)
	local nName = nErrExpr[1]
	local nIdent = nScope.symbol_ident_dict[nName]
	while nIdent and nIdent.pos > nPos do
		nIdent = nIdent.lookup_ident
	end
	return nIdent
end

function CodeEnv:searchName(vPos)
	local nIndex, nNode = self:binSearch(self._nameList, vPos)
	if not nIndex then
		return nil
	end
	if vPos >= nNode.pos + #nNode[1] or vPos > nNode.posEnd then
		return nil
	end
	return nNode
end

function CodeEnv:getContent()
	return self._subject
end

return CodeEnv
