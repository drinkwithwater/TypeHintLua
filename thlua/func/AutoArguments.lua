
local Variable = require "thlua.func.Variable"
local AutoArguments = {}
AutoArguments.__index=AutoArguments

function AutoArguments.new(vManager, vArgList, vArgDots)
	if Variable.is(vArgDots) then
		vArgDots = vManager.type.Truth
	end
	return setmetatable({
		_manager=vManager,
		_argList=vArgList,
		_argDots=vArgDots,
	}, AutoArguments)
end

function AutoArguments:hasVariable()
	for k,v in pairs(self._argList) do
		if Variable.is(v) then
			return true
		end
	end
	return false
end

function AutoArguments:check(vContext, vTypeTuple)
	local nConvertList = {}
	for i=1, #self._argList do
		local nInputType = vTypeTuple:get(i)
		local nFuncArg = self._argList[i]
		if Variable.is(nFuncArg) then
			-- generic TODO
			self._argList[i] = nInputType
			nConvertList[i] = nInputType
		else
			self._manager:cast(vContext, nInputType, nFuncArg)
			local nContainType = nFuncArg:contain(nInputType)
			if not nContainType then
				vContext:warn("variable "..tostring(nFuncArg).." not contain:"..tostring(nInputType))
			end
			nConvertList[i] = nFuncArg
		end
	end
	local nDotsType = self._argDots
	if #self._argList < #vTypeTuple then
		if not nDotsType then
			vContext:error("args check failed: arg num not match")
		else
			for i=#self._argList + 1, #vTypeTuple do
				if not nDotsType:contain(vTypeTuple:get(i)) then
					vContext:error("args check failed in dots")
				end
			end
		end
	end
	local nArgTuple = self._manager:Tuple(table.unpack(nConvertList))
	if not nDotsType then
		return nArgTuple
	else
		return nArgTuple:Dots(nDotsType)
	end
end

return AutoArguments
