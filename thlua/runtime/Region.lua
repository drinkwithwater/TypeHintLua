
local Region = {}
local Branch = require "thlua.runtime.Branch"
local Symbol = require "thlua.runtime.Symbol"

Region.__index = Region
Region.__tostring = function(self)
	return "Region-"..tostring(self.path)..":"..tostring(self.pos)
end

function Region.new(vRuntime, vContext)
	local nRootBranch = Branch.new(vRuntime)
	return setmetatable({
		_runtime=vRuntime,
		_manager=vRuntime.typeManager,
		_context=vContext,
		cur_branch=nRootBranch,
		branch_stack={nRootBranch},
		ret_tuple=false,
		path="path todo",
		pos="pos todo",
	}, Region)
end

function Region:push_branch(vTermCase)
	local nNewBranch = Branch.new(self._runtime, self.cur_branch, vTermCase)
	self.branch_stack[#self.branch_stack + 1] = nNewBranch
	self.cur_branch = nNewBranch
end

function Region:pop_branch()
	local len = #self.branch_stack
	self.branch_stack[len] = nil
	local old_branch = self.cur_branch
	self.cur_branch = self.branch_stack[len - 1]
	return old_branch
end

function Region:top_branch()
	return self.cur_branch
end

function Region:or_return(vTermTuple)
	if not self.ret_tuple then
		self.ret_tuple = vTermTuple
	else
		self.ret_tuple = self.ret_tuple | vTermTuple
	end
end

function Region:get_return()
	local re = self.ret_tuple
	if not re then
		re = self._runtime.typeManager:TermTuple({})
		self.ret_tuple = re
	end
	re:setContext(self._context)
	return re
end

function Region:get_path()
	return self.path
end

function Region:SYMBOL(vPos, vTerm, vHintType)
	if not vHintType then
		local nType = vTerm:getType()
		local nSymbol = Symbol.new(self._runtime, self, vPos, nType)
		self:top_branch():symbol_init(nSymbol, vTerm)
		return nSymbol
	else
		local nTerm = self._manager:UnionTerm(vHintType)
		local nSymbol = Symbol.new(self._runtime, self, vPos, vHintType)
		self:top_branch():symbol_init(nSymbol, nTerm)
		return nSymbol
	end
end

function Region:IF(vPos, vTerm, vTrueFunction, vFalseFunction)
	local nTrueCase = vTerm:caseTrue()
	self:push_branch(nTrueCase)
	if nTrueCase then
		vTrueFunction()
	end
	local nTrueBranch = self:pop_branch()
	local nFalseCase = vTerm:caseFalse()
	self:push_branch(nFalseCase)
	if vFalseFunction and nFalseCase then
		vFalseFunction()
	end
	local nFalseBranch = self:pop_branch()
	self:top_branch():merge_from(self, nTrueBranch, nFalseBranch)
end

function Region:WHILE(vPos, vTerm, vTrueFunction)
	local nTrueCase = vTerm:caseTrue()
	self:push_branch(nTrueCase)
	if nTrueCase then
		vTrueFunction()
	else
		self._context:warn("while loop is unreachable scope")
	end
	local nTrueBranch = self.region:pop_branch()
end

function Region:FOR_IN(vPos, vFunc, vNext, vSelf, vInit)
	local nTuple = self._context:Hook(vPos):META_CALL(vNext, function () return self._manager:TermTuple({vSelf, vInit}) end)
	if #nTuple <= 0 then
		self._context:error("FOR_IN must receive at least 1 value")
		return
	end
	local nFirstTerm = nTuple:get(1)
	if not nFirstTerm:getType():isNilable() then
		self._context:error("FOR_IN must receive nilable type, TODO : run logic when error")
		return
	end
	local nNewTuple = self._manager:TermTuple({nFirstTerm:notnilTerm()}, nTuple:select(2))
	local nCase = nFirstTerm:caseNotnil()
	if not nCase then
		self._context:error("FOR_IN into a empty loop")
		return
	end
	self:push_branch(nCase)
	vFunc(nNewTuple)
	self:pop_branch()
end

function Region:FOR_NUM(vPos, vFunc, vStart, vStop, vStepOrNil)
	vFunc(self._manager:UnionTerm(self._runtime.type.Number))
end

function Region:LOGIC_OR(vPos, vLeftTerm, vRightFunction)
	local nLeftTrueTerm = vLeftTerm:trueTerm()
	local nLeftFalseCase = vLeftTerm:caseFalse()
	if not nLeftFalseCase then
		return nLeftTrueTerm
	else
		self:push_branch(nLeftFalseCase)
		local nRightUnion = vRightFunction()
		self:pop_branch()
		nRightUnion:and_case(nLeftFalseCase)
		return nLeftTrueTerm | nRightUnion
	end
end

function Region:LOGIC_AND(vPos, vLeftTerm, vRightFunction)
	local nLeftFalseTerm = vLeftTerm:falseTerm()
	local nLeftTrueCase = vLeftTerm:caseTrue()
	if not nLeftTrueCase then
		return nLeftFalseTerm
	else
		self:push_branch(nLeftTrueCase)
		local nRightUnion = vRightFunction()
		self:pop_branch()
		nRightUnion:and_case(nLeftTrueCase)
		return nLeftFalseTerm | nRightUnion
	end
end

function Region:LOGIC_NOT(vPos, vData)
	return vData:notTerm()
end

function Region:RETURN(vPos, vTermTuple)
	self:or_return(vTermTuple)
end

function Region:CLOSE(vPos)
	self._context._namespace:close()
	return self:get_return()
end

return Region
