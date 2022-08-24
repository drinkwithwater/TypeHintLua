
local Meta = require "thlua.runtime.Meta"
local FunctionBuilder = require "thlua.builder.FunctionBuilder"
local TableBuilder = require "thlua.builder.TableBuilder"
local UnionTerm = require "thlua.term.UnionTerm"
local function ContextClass()
	local Context = {}
	Context.__index=Context
	function Context:__tostring()
		return "context:"..self:getPath()
	end

	function Context:Meta(vNode)
		return self:newContext(vNode)._meta
	end

	function Context:TABLE_NEW(vNode, vTableFunc, vHinterHandler)
		local nData, nHintMethod = TableBuilder.Begin(self, vTableFunc, vNode)
		vHinterHandler(nHintMethod)
		local nTableType = TableBuilder.End(nData)
		return self._manager:UnionTerm(nTableType)
	end

	function Context:FUNC_NEW(vNode, vFunc, vHinterHandler)
		local nData, nHintMethod = FunctionBuilder.Begin(self, vFunc, vNode)
		vHinterHandler(nHintMethod)
		local nLuaFunc = FunctionBuilder.End(nData)
		local nTerm = self._manager:UnionTerm(nLuaFunc)
		return nTerm
	end

	function Context:HINT(vNode, vTerm, vType)
		-- TODO check cast valid
		return self._manager:UnionTerm(vType)
	end

	function Context:TruthTerm()
		return UnionTerm.new(self._manager, self._manager.type.Truth)
	end

	function Context:NilTerm()
		return UnionTerm.new(self._manager, self._manager.type.Nil)
	end

	function Context:LiteralTerm(v)
		return UnionTerm.new(self._manager, self:Literal(v))
	end

	function Context:Literal(vValue)
		return self._manager:Literal(vValue)
	end

	function Context:getGlobalTerm()
		return self._runtime.global_term
	end

	function Context:error(...)
		print("[ERROR] "..self:getPath(), ...)
	end

	function Context:warn(...)
		print("[WARN] "..self:getPath(), ...)
	end

	function Context:info(...)
		print("[INFO] "..self:getPath(), ...)
	end

	function Context:getRegion()
		return self._region
	end

	return Context
end

return ContextClass
