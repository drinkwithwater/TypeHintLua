
local parser = require "thlua.code.parser"
local Node = require "thlua.code.Node"
local VisitorExtend = require "thlua.code.VisitorExtend"
local Exception = require "thlua.Exception"
local CodeEnv = {}

CodeEnv.__index=CodeEnv

CodeEnv.G_IDENT_REFER = 0
CodeEnv.G_SCOPE_REFER = 1
CodeEnv.G_REGION_REFER = 1

function CodeEnv.new(vSubject, vFileName, vPath, vNode)
	local nGlobalEnv = setmetatable({
		filename = vFileName,
		hinting = false,
		_linePosList = {},
		_subject = vSubject,
		_path = vPath or vFileName,
		_posToChange = {}, -- if value is string then insert else remove
		_ast = false,
		_nodeList = {},
		_scopeList = {},
		_regionList = nil, -- _regionList = _scopeList
		_identList = {},
	}, CodeEnv)

	nGlobalEnv._regionList = nGlobalEnv._scopeList

	-- create and set root scope
	local nRootScope = CodeEnv.create_region(nGlobalEnv, nil, nil, vNode or Node.newRootNode())

	-- create and bind ident
	nRootScope.record_dict["_ENV"] = CodeEnv.G_IDENT_REFER
	nGlobalEnv.root_scope = nRootScope

	nGlobalEnv:_initLinePosList()
	nGlobalEnv:_parse()
	return nGlobalEnv
end

function CodeEnv:makeErrNode(vPos, vErr)
	local nLine, nColumn = self:fixupPos(vPos)
	return setmetatable({
		tag="Error",
		path=self._path,
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
	recur(self._ast, 0)
	print(table.concat(l))
end

function CodeEnv:_parse()
	-- 1. gen ast
	local ok, ast = pcall(parser.parse,self, self._subject)
	if not ok then
		error(ast)
		return
	end
	self._ast = ast
	-- 2. set line & column, parent
	local nStack = {}
	local nNodeList = self._nodeList
	self:visit(function(visitor, vNode)
		-- 1. put into nodelist
		local nIndex = #nNodeList + 1
		nNodeList[nIndex] = vNode
		vNode.index = nIndex
		-- 2. put into namelist
		-- 3. get path, parent, l, c
		vNode.parent = nStack[#nStack] or false
		vNode.path = self._path
		vNode.l, vNode.c = self:fixupPos(vNode.pos, vNode)
		nStack[#nStack + 1] = vNode
		visitor:rawVisit(vNode)
		nStack[#nStack] = nil
		setmetatable(vNode, Node)
	end)
end

function CodeEnv:visit(vDictOrFunc)
	local visitor = VisitorExtend(vDictOrFunc)
	visitor:realVisit(self._ast)
end

-- pos to line & column
function CodeEnv:fixupPos(vPos, vNode)
	if vPos == 0 then
		return 0, 1
	end
	local nList = self._linePosList
	local nLeft = 1
	local nRight = #nList
	assert(nRight>=nLeft)
	if vPos > nList[nRight].finishPos then
		print("warning pos out of range1, "..vPos, vNode and vNode.tag)
		return nRight, nList[nRight].finishPos - nList[nRight].startPos + 1
	elseif vPos < nList[nLeft].startPos then
		print("warning pos out of range2, "..vPos, vNode and vNode.tag)
		return 1, 1
	end
	local nMiddle = (nLeft + nRight)// 2
	while true do
		local nMiddleInfo = nList[nMiddle]
		if vPos < nMiddleInfo.startPos then
			nRight = nMiddle - 1
			nMiddle = (nLeft + nRight)// 2
		elseif nMiddleInfo.finishPos < vPos then
			nLeft = nMiddle + 1
			nMiddle = (nLeft + nRight)// 2
		else
			return nMiddle, vPos - nMiddleInfo.startPos + 1
		end
	end
end

function CodeEnv:_initLinePosList()
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
				startPos=nStartPos,
				finishPos=nFinishPos
			}
			nStartPos = nFinishPos + 1
		else
			if nStartPos <= #nSubject then
				nList[#nList + 1] = {
					startPos=nStartPos,
					finishPos=#nSubject
				}
			end
			break
		end
	end
	self._linePosList = nList
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
	ReferVisitor.new(self):realVisit(self._ast)
	local TypeHintGen = require "thlua.code/TypeHintGen"
	return TypeHintGen.visit(self, self._path or self.filename)
end

function CodeEnv:create_scope(vCurScope, vNode)
	local nNewIndex = #self._scopeList + 1
	local nNextScope = {
		tag = "Scope",
		node = vNode,
		record_dict = vCurScope and setmetatable({}, {
			__index=vCurScope.record_dict
		}) or {},
		scope_refer = nNewIndex,
		parent_scope_refer = vCurScope and vCurScope.scope_refer,
	}
	self._scopeList[nNewIndex] = nNextScope
	-- if vCurScope then
		-- vCurScope[#vCurScope + 1] = nNextScope
	-- end
	return nNextScope
end

function CodeEnv:create_region(vParentRegion, vCurScope, vNode)
	local nRegion = self:create_scope(vCurScope, vNode)
	nRegion.node = vNode
	nRegion.sub_tag = "Region"
	nRegion.region_refer = nRegion.scope_refer
	if nRegion.region_refer ~= CodeEnv.G_REGION_REFER then
		nRegion.parent_region_refer = vParentRegion.region_refer
	else
		nRegion.parent_region_refer = false
	end
	return nRegion
end

function CodeEnv:getNodeList()
	return self._nodeList
end

function CodeEnv:newIdent(vCurScope, vIdentNode)
	local nNewIndex = #self._identList + 1
	local nName
	if vIdentNode.tag == "Id" then
		nName = vIdentNode[1]
	elseif vIdentNode.tag == "Dots" then
		nName = "..."
	else
		error("ident type error:"..tostring(vIdentNode.tag))
	end
	local nIdent = {
		tag = "IdentDefine",
		node=vIdentNode,
		ident_refer=nNewIndex,
		scope_refer=vCurScope.scope_refer,
		nName,
		nNewIndex,
	}
	self._identList[nNewIndex] = nIdent
	vCurScope.record_dict[nIdent[1]] = nNewIndex
	vCurScope[#vCurScope + 1] = nIdent
	return nIdent
end

function CodeEnv.thluaSearchContent(name, searchLua)
	local thluaPath = package.path:gsub("[.]lua", ".thlua")
	local fileName, err1 = package.searchpath(name, thluaPath)
	if not fileName then
		if not searchLua then
			return false, err1
		end
		fileName, err1 = package.searchpath(name, package.path)
		if not fileName then
			return false, err1
		end
	end
	local file, err2 = io.open(fileName, "r")
	if not file then
		return false, err2
	end
	local thluaCode = file:read("*a")
	file:close()
	return true, thluaCode, fileName
end

function CodeEnv:getIdent(vIdentRefer)
	return self._identList[vIdentRefer]
end

function CodeEnv:getAstTree()
	return self._ast
end

return CodeEnv
