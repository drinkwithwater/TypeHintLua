
local UnionTerm = require "thlua.term.UnionTerm"
local TableBuilder = {}

function TableBuilder.Begin(vContext, vPairMaker, vNode)
	local nData = {
		context=vContext,
		node=vNode,
		pairMaker=vPairMaker,
		newTypeRefer=false,
	}
	local nHintMethod = {
		New=function(self)
			nData.newTypeRefer = vContext:getNewTypeRefer()
			return self
		end,
	}
	return nData, nHintMethod
end

function TableBuilder.End(vData)
	local nContext = vData.context
	local nRefer = vData.newTypeRefer
	local nManager = nContext._manager
	-- 1. create table
	local nTableType
	-- 2. refer table
	if not nRefer then
		nTableType = nManager:LuaTable()
		nTableType:setName("("..nContext:getPath().."-"..tostring(vData.node)..")")
	else
		nTableType = nRefer:checkType()
	end
	-- 3. set table's key value
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
