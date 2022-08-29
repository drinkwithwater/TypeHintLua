
local UnionTerm = require "thlua.term.UnionTerm"
local TableBuilder = {}

function TableBuilder.Begin(vContext, vNode, vPairMaker)
	local nData = {
		context=vContext,
		node=vNode,
		pairMaker=vPairMaker,
		selfTable=false,
	}
	-- 1. create table
	local nHintMethod = {
		New=function(self)
			local nTagFn = assert(vContext:getNewTagFn(), "New() can only work with RetNew()")
			local nRefer = assert(nTagFn.newTypeRefer, "New() can only work with RetNew()")
			local nTableType = nRefer:checkType()
			nData.selfTable = nTableType
			return self
		end,
	}
	return nData, nHintMethod
end

function TableBuilder.End(vData)
	local nContext = vData.context
	local nManager = nContext._manager
	local nTableType = vData.selfTable or nManager:LuaTable()
	nTableType:setName("("..nContext:getPath().."-"..tostring(vNode)..")")
	local vList, vDotsStart, vDotsTuple = vData.pairMaker()
	local nTypePairList = {}
	for i, nPair in ipairs(vList) do
		local nKey = nPair[1]:getType()
		local nValue = nPair[2]:getType()
		if not nKey:isSingleton() then
			nValue = nManager:Union(nValue, nManager.type.Nil)
		end
		nTypePairList[i] = {nKey, nValue}
	end
	if vDotsTuple then
		local nTypeTuple = vDotsTuple:getTypeTuple()
		local nRepeatType = nTypeTuple:getRepeatType()
		if nRepeatType then
			nTypePairList[#nTypePairList + 1] = {
				nManager.type.Number, nManager:Union(nRepeatType, nManager.type.Nil)
			}
		else
			for i=1, #nTypeTuple do
				nTypePairList[#nTypePairList + 1] = {
					nManager:Literal(vDotsStart + i - 1),nTypeTuple:get(i)
				}
			end
		end
	end
	local nKeyUnion, nTypeDict = nManager:mergePairList(nTypePairList)
	nTableType:initByKeyValue(nKeyUnion, nTypeDict)
	return nTableType
end

return TableBuilder
