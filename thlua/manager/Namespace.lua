
local Reference = require "thlua.type.Reference"
local Namespace = {}
Namespace.__tostring=function(self)
	return "namespace-"..tostring(self._context:getPath())..tostring(self._name or "")
end
Namespace.__index=Namespace

function Namespace.new(vManager, vIndexTable)
	local self = setmetatable({
		_manager=vManager,
		_name2type=vIndexTable and setmetatable({}, {__index=vIndexTable}) or {},
		_closed=false,
		_context=false,
		_name=false,
	}, Namespace)
	self.localExport=setmetatable({}, {
		__index=function(_,k)
			local rawgetV = rawget(self._name2type, k)
			if rawgetV ~= nil then
				return rawgetV
			end
			if self._closed then
				error("namespace closed, can't create key="..tostring(k))
			end
			local getV = self._name2type[k]
			if getV ~= nil then
				error("var shadow get : key="..tostring(k))
			end
			local refer = self._manager:Reference(k)
			self._name2type[k] = refer
			return refer
		end,
		__newindex=function(_,k,newV)
			if self._closed then
				error("namespace closed, can't create key="..tostring(k))
			end
			local getV = self._name2type[k]
			local rawgetV = rawget(self._name2type, k)
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
					if not namespace._context then
						namespace:setContextName(self._context, k)
					end
					self._name2type[k] = newV
				else
					if Reference.is(newV) then
						self._name2type[k] = newV
					else
						self._manager:assertValueType(newV)
						local refer = self._manager:Reference(k)
						refer:setTypeAsync(function()
							return newV
						end)
						self._name2type[k] = refer
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
			local v = self._name2type[k]
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

function Namespace:setContextName(vContext, vName)
	assert(not self._context, "context can only be set once")
	self._context = vContext
	if vName then
		self._name = vName
	end
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

function Namespace:setName(vName)
	assert(type(vName) == "string", "namespace's name must be string")
	self._name = vName
end

function Namespace:createChild(vContext)
	local nSpace = Namespace.new(self._manager, self._name2type)
	nSpace:setContextName(vContext)
	return nSpace
end

function Namespace:close()
	self._closed=true
end

return Namespace
