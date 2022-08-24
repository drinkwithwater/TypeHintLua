
local TermCase = require "thlua.term.TermCase"
local UnionTerm = require "thlua.term.UnionTerm"

local Branch = {}

Branch.__index = Branch
Branch.__tostring = function(self)
	return "Branch"
end

function Branch.new(vRuntime, vPreBranch, vTermCase)
	local nTermCase
	if vPreBranch then
		if vTermCase then
			nTermCase = vPreBranch.case & vTermCase
		else
			nTermCase = vPreBranch.case
		end
	else
		nTermCase = TermCase.new()
	end
	return setmetatable({
		_runtime=vRuntime,
		case=nTermCase,
		symbolToTerm=setmetatable({}, {__index=vPreBranch and vPreBranch.symbolToTerm}),
	}, Branch)
end

function Branch:symbol_get(vSymbol)
	local nUnionTerm = self.symbolToTerm[vSymbol]
	if not nUnionTerm then
		-- TODO, set upvalue symbol in prepre...prebranch
		local nType = vSymbol:getType()
		nUnionTerm = self._runtime.typeManager:UnionTerm(nType)
		nUnionTerm:add_self(vSymbol)
		self.symbolToTerm[vSymbol] = nUnionTerm
		return nUnionTerm
	end
	local nType = self.case[nUnionTerm]
	if nType then
		if not nType:isNever() then
			return nUnionTerm:filter(nType)
		else
			local nManager = self._runtime.typeManager
			print("TODO type is never when get symbol"..tostring(vSymbol), nUnionTerm)
			return nManager:UnionTerm(nManager.type.Never)
		end
	else
		return nUnionTerm
	end
end

function Branch:symbol_init(vUnionSymbol, vTerm)
	vTerm:add_self(vUnionSymbol)
	self.symbolToTerm[vUnionSymbol] = vTerm
end

function Branch:symbol_set(vUnionSymbol, vValueTerm)
	local nValueType = vValueTerm:getType()
	if vUnionSymbol:getType():contain(nValueType) then
		local nUnionTerm = self._runtime.typeManager:UnionTerm(nValueType)
		nUnionTerm:add_self(vUnionSymbol)
		self.symbolToTerm[vUnionSymbol] = nUnionTerm
	else
		print(tostring(nValueType).." can't be assigned to "..tostring(vUnionSymbol:getType()))
	end
end

function Branch:merge_from(vContext, vTrueBranch, vFalseBranch)
	local nModSymbolDict = {}
	for nSymbol, nUnion in pairs(vTrueBranch.symbolToTerm) do
		nModSymbolDict[nSymbol] = true
	end
	for nSymbol, nUnion in pairs(vFalseBranch.symbolToTerm) do
		nModSymbolDict[nSymbol] = true
	end
	for nSymbol, _ in pairs(nModSymbolDict) do
		if self.symbolToTerm[nSymbol] then
			local nType = vTrueBranch:symbol_get(nSymbol):getType() | vFalseBranch:symbol_get(nSymbol):getType()
			local nUnionTerm = self._runtime.typeManager:UnionTerm(nType)
			self.symbolToTerm[nSymbol] = nUnionTerm
			nUnionTerm:add_self(nSymbol)
		end
	end
end

return Branch
