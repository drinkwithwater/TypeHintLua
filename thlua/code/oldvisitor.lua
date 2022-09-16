--[[
This module implements a faster visitor for the Typed Lua AST.
--!cz
]]

local oldvisitor = {}

local visit_node
local visit_block, visit_stm, visit_exp, visit_var, visit_par, visit_list, visit_field
local visit_explist, visit_varlist, visit_parlist

-- __call for all visit dict
local function visit_tag(raw_visit_dict, visitor, t)
  if visitor.stop then
	  return
  end
  local tag = t.tag
  local stack = visitor.stack
  local index = #stack + 1
  -- Step 1. push node into stack
  stack[index] = t
  -- Step 2. before default
  local before_default = visitor.before_default
  if before_default then
	  before_default(visitor, t)
  end
  -- Step 3. before
  local before = visitor.before_dict[tag]
  if before then
	  before(visitor, t)
  end
  -- Step 4. override
  local override = visitor.override_dict[tag]
  if override then
	  local self_visit = visit_node[tag]
	  override(visitor, t, visit_node, self_visit)
  else
	  local middle = raw_visit_dict[tag]
	  if middle then
		  middle(visitor, t)
	  end
  end
  -- Step 5. after
  local after = visitor.after_dict[tag]
  if after then
	  after(visitor, t)
  end
  -- Step 6. after default
  local after_default = visitor.after_default
  if after_default then
	  after_default(visitor, t)
  end
  -- Step 7. pop node
  stack[index] = nil
end

visit_var = setmetatable({
	Id = false,
	Index = function(visitor, node)
		visit_exp(visitor, node[1])
		visit_exp(visitor, node[2])
	end,
}, {
	__call=visit_tag,
	__index=function(t, tag)
		error("expecting a variable, but got a " .. tag)
	end
})

visit_par = setmetatable({
	Id = false,
	Dots = false,
}, {
	__call=visit_tag,
	__index=function(t, tag)
		error("expecting a parameter declare, but got a " .. tag)
	end
})

function visit_varlist (visitor, varlist)
  for k, v in ipairs(varlist) do
    visit_var(visitor, v)
  end
end

function visit_parlist (visitor, parlist)
  local len = #parlist
  for i=1, len do
	  visit_par(visitor, parlist[i])
  end
end


visit_exp = setmetatable({
	Nil=false,
	Dots=false,
	True=false,
	False=false,
	Number=false,
	String=false,

	Function = function(visitor, func)
		visit_list(visitor, func[1])
		if func[3] then
			visit_type(visitor, func[2])
			visit_block(visitor, func[3])
		else
			visit_block(visitor, func[2])
		end
	end,
	Table = function(visitor, fieldlist)
		for k, v in ipairs(fieldlist) do
			visit_field(visitor, v)
		end
	end,
	Op = function(visitor, exp)
		-- opid: exp[1]
		visit_exp(visitor, exp[2])
		if exp[3] then
			visit_exp(visitor, exp[3])
		end
	end,
	Paren = function(visitor, exp)
		visit_exp(visitor, exp[1])
	end,
	Call = function(visitor, exp)
		visit_exp(visitor, exp[1])
		visit_list(visitor, exp[2])
	end,
	Invoke = function(visitor, exp)
		visit_exp(visitor, exp[1])
		visit_exp(visitor, exp[2])
		visit_list(visitor, exp[3])
	end,
	Id = false,
	Index = visit_var.Index,
}, {
	__call=visit_tag,
	__index=function(t, tag)
		error("expecting a expression, but got a " .. tag)
	end
})

function visit_explist (visitor, explist)
  for k, v in ipairs(explist) do
	visit_exp(visitor, v)
  end
end

visit_stm = setmetatable({
	Do=function(visitor, stm)
		visit_block(visitor, stm[1])
	end,
	Set=function(visitor, stm)
		visit_list(visitor, stm[1])
		visit_list(visitor, stm[2])
	end,
	While=function(visitor, stm)
		visit_exp(visitor, stm[1])
		visit_block(visitor, stm[2])
	end,
	Repeat=function(visitor, stm)
		visit_block(visitor, stm[1])
		visit_exp(visitor, stm[2])
	end,
	If=function(visitor, stm)
		local len = #stm
		if len % 2 == 0 then
			for i=1,len-2,2 do
				visit_exp(visitor, stm[i])
				visit_block(visitor, stm[i+1])
			end
			visit_exp(visitor, stm[len-1])
			visit_block(visitor, stm[len])
		else
			for i=1,len-3,2 do
				visit_exp(visitor, stm[i])
				visit_block(visitor, stm[i+1])
			end
			visit_exp(visitor, stm[len-2])
			visit_block(visitor, stm[len-1])
			visit_block(visitor, stm[len])
		end
	end,
	Fornum=function(visitor, stm)
		visit_var(visitor, stm[1])
		visit_exp(visitor, stm[2])
		visit_exp(visitor, stm[3])
		if stm[5] then
			visit_exp(visitor, stm[4])
			visit_block(visitor, stm[5])
		else
			visit_block(visitor, stm[4])
		end
	end,
	Forin=function(visitor, stm)
		visit_list(visitor, stm[1])
		visit_list(visitor, stm[2])
		visit_block(visitor, stm[3])
	end,
	Local=function(visitor, stm)
		visit_list(visitor, stm[1])
		visit_list(visitor, stm[2])
	end,
	Localrec=function(visitor, stm)
		visit_var(visitor, stm[1])
		visit_exp(visitor, stm[2])
	end,
	Goto=false,
	Label=false,
	Return=function(visitor, stm)
		visit_list(visitor, stm[1])
	end,
	Break=false,
	Call=function(visitor, stm)
		visit_exp(visitor, stm[1])
		visit_list(visitor, stm[2])
	end,
	Invoke=function(visitor, stm)
		visit_exp(visitor, stm[1])
		visit_exp(visitor, stm[2])
		visit_list(visitor, stm[3])
	end,
	HintStat=false,
}, {
	__call=visit_tag,
	__index=function(t, tag)
		error("expecting a statement, but got a " .. tag)
	end
})

visit_block = setmetatable({
	Chunk=function(visitor, chunk)
		--visit_par(visitor, chunk[1])
		--visit_parlist(visitor, chunk[2])
		visit_block(visitor, chunk[3])
	end,
	Block=function(visitor, block)
	  for k, v in ipairs(block) do
		  visit_stm(visitor, v)
	  end
	end,
}, {
	__call=visit_tag,
	__index=function(t, tag)
		error("expecting a block or do, but got a " .. tag)
	end
})

local function setDefaultVisitor(visitor)
	visitor.before_dict = visitor.before_dict or {}
	visitor.after_dict = visitor.after_dict or {}
	visitor.override_dict = visitor.override_dict or {}
	visitor.stack = visitor.stack or {}
	visitor.stop = false
end

visit_list = setmetatable({
	ExpList=visit_explist,
	ParList=visit_parlist,
	VarList=visit_varlist,
	NameList=visit_varlist,
}, {
	__call=visit_tag,
	__index=function(t, tag)
		error("expecting a list, but got a " .. tag)
	end
})

visit_field = setmetatable({
	Pair=function(visitor, node)
		visit_exp(visitor, node[1])
		visit_exp(visitor, node[2])
	end
},{
	__call=visit_tag,
	__index=function(t, tag)
		return visit_exp[tag]
	end
})


local sub_visitor_list = {
	visit_block,
	visit_stm,
	visit_exp,
	visit_var,
	visit_list,
	visit_field,
}

visit_node = setmetatable({},{
	__call=visit_tag,
	__index=function(t, tag)
		error("expecting a valid tag, but got a " .. tag)
	end
})


for _, sub_visitor in ipairs(sub_visitor_list) do
	for tag, func in pairs(sub_visitor) do
		visit_node[tag] = func
	end
end

function oldvisitor.visit_node(node, visitor)
	visit_node(visitor, node)
end

function oldvisitor.visit_raw(block, visitor)
	setDefaultVisitor(visitor)
	visit_block(visitor, block)
end

function oldvisitor.visit_obj(block, visitor)
	setDefaultVisitor(visitor)
	visitor.after_dict = {}
	visitor.override_dict = {}
	visitor.before_dict = {}
	for tag, object in pairs(visitor.object_dict) do
		visitor.after_dict[tag] = object.after
		visitor.override_dict[tag] = object.override
		visitor.before_dict[tag] = object.before
	end
	visit_block(visitor, block)
end

function oldvisitor.visit_type(node, visitor)
	setDefaultVisitor(visitor)
	visit_type(visitor, node)
end

function oldvisitor.concat(...)
	local nDict = {}
	for i=1, select("#", ...) do
		local t = select(i, ...)
		for k,v in pairs(t) do
			if nDict[k] then
				error("visitor concat duplicate")
			end
			nDict[k] = v
		end
	end
	return nDict
end

return oldvisitor
