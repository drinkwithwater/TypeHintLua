
local Reference = require "thlua.type.Reference"
local Namespace = {}
Namespace.__tostring=function(self)
	return (self:isVarSpace() and "varspace-" or "namespace-") .. tostring(self._node).."|"..tostring(self._key or "!keynotset")
end
Namespace.__index=Namespace

function Namespace.new(vManager, vNode, vIndexTable)
	local self = setmetatable({
		_manager=vManager,
		_key2type=vIndexTable and setmetatable({}, {__index=vIndexTable}) or {},
		_closed=false,
		_node=vNode,
		_key=false,
	}, Namespace)
	self.localExport=setmetatable({}, {
		__index=function(_,k)
			local rawgetV = rawget(self._key2type, k)
			if rawgetV ~= nil then
				return rawgetV
			end
			if self._closed then
				error("namespace closed, can't create key="..tostring(k))
			end
			local getV = self._key2type[k]
			if getV ~= nil then
				error("var shadow get : key="..tostring(k))
			end
			local refer = self._manager:Reference(k)
			self._key2type[k] = refer
			return refer
		end,
		__newindex=function(_,k,newV)
			if self._closed then
				error("namespace closed, can't create key="..tostring(k))
			end
			local getV = self._key2type[k]
			local rawgetV = rawget(self._key2type, k)
			if getV ~= nil and rawgetV == nil then
				error("var shadow set : key="..tostring(k))
			end
			if rawgetV ~= nil then
				-- for recursive indexing reference
				self._manager:assertValueType(newV)
				if Reference.is(rawgetV) then
					rawgetV:setTypeAsync(function()
						if Reference.is(newV) then
							return newV:getTypeAwait()
						else
							return newV
						end
					end)
				else
					error("conflict assign : key="..tostring(k))
				end
			else
				local namespace = Namespace.fromLocalExport(newV)
				if namespace then
					namespace:trySetKey(k)
					self._key2type[k] = newV
				else
					if Reference.is(newV) then
						newV:trySetKey(k)
						self._key2type[k] = newV
					else
						self._manager:assertValueType(newV)
						local refer = self._manager:Reference(k)
						refer:setTypeAsync(function()
							return newV
						end)
						self._key2type[k] = refer
					end
				end
			end
		end,
		__tostring=function(t)
			return tostring(self).."->localExport"
		end,
		__self=self,
	})
	self.globalExport=setmetatable({}, {
		__index=function(_,k)
			local v = self._key2type[k]
			if v ~= nil then
				return v
			end
			error("key with empty value, key="..tostring(k))
		end,
		__newindex=function(t,k,v)
			error("global can't assign")
		end,
		__tostring=function(t)
			return tostring(self).."->globalExport"
		end,
	})
	return self
end

function Namespace:trySetKey(vKey)
	if not self._key then
		self._key = vKey
	end
end

function Namespace:isVarSpace()
	return getmetatable(self._key2type) and true or false
end

function Namespace.fromLocalExport(t)
	local nMeta = getmetatable(t)
	if type(nMeta) == "table" then
		local self = rawget(nMeta, "__self")
		if getmetatable(self) == Namespace then
			return self
		end
	end
	return false
end

function Namespace:close()
	self._closed=true
end

function Namespace:getKeyToType()
	return self._key2type
end

return Namespace
