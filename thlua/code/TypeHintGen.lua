
local oldvisitor = require "thlua.code/oldvisitor"
local CodeEnv = require "thlua.code/CodeEnv"
local TypeHintGen = {}

function TypeHintGen:indent()
	table.insert(self.buffer_list, string.rep("\t", self.indent_count - 1))
end

function TypeHintGen:autoUnpack()
	local parent = self.stack[#self.stack - 1]
	local node = self.stack[#self.stack]
	if parent.tag == "ExpList" or parent.tag == "ParList" or parent.tag == "Block" then
		-- block is for function-Call-statement
		return false
	elseif node.table_tail then
		return false
	else
		return true
	end
end

function TypeHintGen:print(...)
	for i=1, select("#", ...) do
		local obj = select(i, ...)
		if type(obj) == "table" then
			oldvisitor.visit_node(obj, self)
		else
			table.insert(self.buffer_list, obj)
		end
	end
end

function TypeHintGen:pos()
	local nTopNode = self.stack[#self.stack]
	return "\'"..nTopNode.l..","..nTopNode.c.."\'"
end

function TypeHintGen:rgn(vName)
	local nTopNode = self.stack[#self.stack]
	return "rgn:"..vName.."(\'"..nTopNode.l..","..nTopNode.c.."\'"
end

function TypeHintGen:hook(vName)
	local nTopNode = self.stack[#self.stack]
	return "self:Hook(\'"..nTopNode.l..","..nTopNode.c.."\'):"..vName
end

function TypeHintGen:printn(c, n)
	for i=1, n do
		self:print(c..i)
		if i < n then
			self:print(",")
		end
	end
end

function TypeHintGen:get_ident_scope_refer(vIdentNode)
	return self.env.ident_list[vIdentNode.ident_refer].scope_refer
end

local visitor_block = {
	Chunk={
		before=function(visitor, node)
			visitor:print("local rgn,var,_ENV=self:REGION(", visitor:pos(), ")\n")
		end
	},
	Block={
		before=function(visitor, node)
			visitor.indent_count = visitor.indent_count + 1
		end,
		override=function(visitor, node)
			visitor:indent()
			visitor:print("local ____s"..node.self_scope_refer.."={}\n")
			local parent = visitor.stack[#visitor.stack - 1]
			if node.is_fornum_block then
				visitor:indent()
				visitor:print(parent[1], "=")
				visitor:print(visitor:rgn("SYMBOL"), ", fornum_i)\n")
			elseif node.is_forin_block then
				for i=1, #parent[1] do
					visitor:indent()
					visitor:print(parent[1][i], "=")
					visitor:print(visitor:rgn("SYMBOL"), ", forin_gen", i, ")\n")
				end
			elseif node.is_function_block then
				for i=1, #parent[1] do
					local par = parent[1][i]
					if par.tag ~= "Dots" then
						visitor:indent()
						visitor:print(par, "=", visitor:rgn("SYMBOL"), ", ", "v_"..par[1], ")\n")
					end
				end
			end
			for i=1, #node do
				visitor:indent()
				visitor:print(node[i])
				visitor:print("\n")
			end
			local parent = visitor.stack[#visitor.stack-1]
			if parent.tag == "Function" or parent.tag == "Chunk" then
				visitor:indent()
				visitor:print("return ", visitor:rgn("CLOSE"), ")\n")
			end
		end,
		after=function(visitor, node)
			visitor.indent_count = visitor.indent_count - 1
		end
	}
}

local visitor_stm = {
	Do={
		before=function(visitor, node)
			visitor:print("do\n")
		end,
		after=function(visitor, node)
			visitor:indent()
			visitor:print("end")
		end
	},
	Set={
		override=function(visitor, node)
			visitor:print("local ")
			visitor:printn("set_a", #node[1])
			visitor:print("=", visitor:hook("EXPLIST_UNPACK"), "("..#node[1]..",")
			visitor:print(node[2])
			visitor:print(")\n")
			for i=1, #node[1] do
				visitor:indent()
				local var = node[1][i]
				if var.tag == "Id" then
					var.is_set = true
					if var.ident_refer ~= CodeEnv.G_IDENT_REFER then
						visitor:print(var, ":SET(")
					else
						visitor:print(visitor:hook("META_SET"), "(")
						visitor:print(var)
						visitor:print(",")
					end
				elseif var.tag == "Index" then
					visitor:print(visitor:hook("META_SET"), "(")
					visitor:print(var[1])
					visitor:print(", ")
					visitor:print(var[2])
					visitor:print(", ")
				end
				if i == #node[1] then
					visitor:print("set_a", i, ",", tostring(node.override or false), ")")
				else
					visitor:print("set_a", i, ",", tostring(node.override or false), ")\n")
				end
			end
		end
	},
	While={
		override=function(visitor, node)
			visitor:indent()
			visitor:print("local while_a=")
			visitor:print(node[1])
			visitor:print("\n")
			visitor:indent()
			visitor:print(visitor:rgn("WHILE"), ",while_a, function()\n")
			visitor:print(node[2])
			visitor:indent()
			visitor:print("end)\n")
		end,
	},
	Repeat={
		override=function(visitor, node)
			error("repeat not implement")
			--[[visitor:indent()
			visitor:print("repeat")
			visitor:print(node[1])
			visitor:indent()
			visitor:print("until(")
			visitor:print(node[2])
			visitor:print(")\n")]]
		end,
	},
	If={
		override=function(visitor, node)
			visitor:print("---------------- if begin\n")
			local function put(exprNode, blockNode, nextIndex, level)
				visitor:indent()
				visitor:print("local if_a"..level.."=")
				visitor:print(exprNode)
				visitor:print("\n")
				visitor:indent()
				visitor:print(visitor:rgn("IF"), ",if_a"..level..", function()\n")
				visitor:print(blockNode)
				if node[nextIndex] then
					visitor:indent()
					visitor:print("end,function()\n")
					if node[nextIndex + 1] then
						visitor.indent_count = visitor.indent_count + 1
						put(node[nextIndex], node[nextIndex + 1], nextIndex + 2, level + 1)
						visitor.indent_count = visitor.indent_count - 1
					else
						visitor:print(node[nextIndex])
					end
					visitor:indent()
					visitor:print("end)\n")
				else
					visitor:indent()
					visitor:print("end)\n")
				end
			end
			put(node[1], node[2], 3, 1)
			visitor:indent()
			visitor:print("---------------- if end\n")
			--[[visitor:print("local if_a=")
			visitor:print(node[1])
			visitor:print("\n")
			visitor:print(visitor:hook("IF"), "(if_a, function()")
			visitor:print(node[2])
			visitor:indent()
			visitor:print("end,function()")
			for i=3,#node-1,2 do
				visitor:indent()
				visitor:print("elseif ")
				visitor:print(node[i])
				visitor:print(" then\n")
				visitor:print(node[i+1])
			end
			if #node >= 3 and #node % 2 == 1 then
				visitor:indent()
				visitor:print("else\n")
				visitor:print(node[#node])
			end
			visitor:indent()
			visitor:print("end")]]
		end
	},
	Fornum={
		override=function(visitor, node)
			local blockNode
			if #node == 4 then
				visitor:print("local fornum_r1, fornum_r2 = ")
				visitor:print(node[2], ", ", node[3], "\n")
				blockNode = node[4]
			elseif #node == 5 then
				visitor:print("local fornum_r1, fornum_r2, fornum_r3 =")
				visitor:print(node[2], ", ", node[3], ", ", node[4], "\n")
				blockNode = node[5]
			end
			visitor:print(visitor:rgn("FOR_NUM"), ",function(fornum_i)\n")
			blockNode.is_fornum_block = true
			visitor:print(blockNode)
			visitor:indent()
			visitor:print("end, fornum_r1, fornum_r2, fornum_r3)\n")
		end
	},
	Forin={
		override=function(visitor, node)
			--visitor:print("for ")
			--visitor:print(node[1])
			--visitor:print(" in ")
			visitor:indent()
			visitor:print("local forin_next, forin_self, forin_init = ", visitor:hook("EXPLIST_UNPACK"), "(3,", node[2], ")\n")
			visitor:print(visitor:rgn("FOR_IN"), ",function(vIterTuple)\n")
			visitor:indent()
			visitor:print("\tlocal ")
			visitor:printn("forin_gen", #node[1])
			visitor:print("=", visitor:hook("TUPLE_UNPACK"), "(vIterTuple,", #node[1], ",false)\n")
			--visitor:print("for ")
			--visitor:print(" in forin_gen do\n")
			visitor:indent()
			node[3].is_forin_block = true
			visitor:print(node[3])
			visitor:indent()
			visitor:print("end, forin_next, forin_self, forin_init)\n")
		end
	},
	Local={
		override=function(visitor, node)
			visitor:print("local ")
			visitor:printn("local_a", #node[1])
			if #node[2]>0 then
				visitor:print("=", visitor:hook("EXPLIST_UNPACK"), "("..#node[1]..",")
				visitor:print(node[2])
				visitor:print(")")
			end
			visitor:print("\n")
			for i=1, #node[1] do
				visitor:indent()
				local idNode = node[1][i]
				visitor:print(idNode, "=")
				visitor:print(visitor:rgn("SYMBOL"), ", local_a"..i)
				if idNode.hintShort then
					visitor:print(",", idNode.hintShort)
				end
				visitor:print(")\n")
			end
		end
	},
	Localrec={
		override=function(visitor, node)
			visitor:print(node[1], "=", visitor:rgn("SYMBOL"), ", ", node[2], ")")
		end,
	},
	Goto={
		before=function()
			print("--goto TODO")
		end
	},
	Label={
		before=function()
			print("--label TODO")
		end
	},
	Return={
		override=function(visitor, node)
			visitor:print(visitor:rgn("RETURN"), ",", visitor:hook("EXPLIST_PACK"), "(false, {")
			visitor:print(node[1])
			visitor:print("}))")
		end,
	},
	Break={
		before=function(visitor, node)
			-- visitor:print("break")
		end,
	},
	Call={
		override=function(visitor, node)
			if visitor:autoUnpack() then
				visitor:print(visitor:hook("EXPLIST_UNPACK"), "(1,")
			end
			visitor:print(visitor:hook("META_CALL"), "(")
			visitor:print(node[1], ",")
			visitor:print(visitor:hook("EXPLIST_PACK"), "(true, {")
			if #node[2] > 0 then
				node[2].is_args = true
				visitor:print(node[2])
			end
			visitor:print("}))")
			if visitor:autoUnpack() then
				visitor:print(")")
			end
		end
	},
	Invoke={
		override=function(visitor, node)
			if visitor:autoUnpack() then
				visitor:print(visitor:hook("EXPLIST_UNPACK"), "(1,")
			end
			visitor:print(visitor:hook("META_INVOKE"), "(")
			visitor:print(node[1])
			visitor:print(",\"")
			visitor:print(node[2][1])
			visitor:print("\"")
			if #node[3] > 0 then
				visitor:print(",")
				visitor:print(visitor:hook("EXPLIST_PACK"), "(false, {")
				node[3].is_args = true
				visitor:print(node[3])
				visitor:print("})")
			else
				visitor:print(",", visitor:hook("EXPLIST_PACK"), "(false, {})")
			end
			visitor:print(")")
			if visitor:autoUnpack() then
				visitor:print(")")
			end
		end
	},
	HintStat={
		override=function(visitor, node)
					visitor:indent()
			-- visitor:print("local block = function(self) ", node[1], " end block(self)\n")
			visitor:print(" ",node[1], " ")
		end
	}
}

local visitor_exp = {
	Nil={
		before=function(visitor, node)
			visitor:print("self:NilTerm()")
		end
	},
	Dots={
		before=function(visitor, node)
			if not visitor:autoUnpack() then
				visitor:print("vDOTS")
			else
				visitor:print(visitor:hook("EXPLIST_UNPACK"), "(1, vDOTS)")
			end
		end
	},
	True={
		before=function(visitor, node)
			visitor:print("self:LiteralTerm(true)")
		end
	},
	False={
		before=function(visitor, node)
			visitor:print("self:LiteralTerm(false)")
		end
	},
	Number={
		before=function(visitor, node)
			visitor:print("self:LiteralTerm")
			visitor:print("("..tostring(node[1])..")")
		end
	},
	String={
		before=function(visitor, node)
			visitor:print("self:LiteralTerm")
			local s = node[1]
			if node.isLong then
				visitor:print('([[' .. s .. ']])')
			else
				visitor:print('("' .. s .. '")')
			end
		end
	},
	Function={
		override=function(visitor, node)
			visitor:print("self:FUNC_NEW(", visitor:pos(), ", function(self, vArgTuple) \n")
			visitor:indent()
			visitor:indent()
			local nParList = node[1]
			if #nParList > 0 then
				visitor:print("\tlocal ", node[1], "=", visitor:hook("TUPLE_UNPACK"))
				if nParList[#nParList].tag == "Dots" then
					visitor:print("(vArgTuple,",tostring(#nParList-1),",true)\n")
				else
					visitor:print("(vArgTuple,",tostring(#nParList),",false)\n")
				end
			end
			visitor:indent()
			visitor:print("\tlocal rgn,var,_ENV=self:REGION(", visitor:pos(), ")\n")
			node[2].is_function_block = true
			visitor:print(node[2])
			visitor:indent()
			local nParHintList = {}
			local nDotsHintScript = false
			for i=1, #nParList do
				local nParNode = nParList[i]
				if nParNode.tag == "Dots" then
					if nParNode.hintShort then
						nDotsHintScript = nParNode.hintShort
					else
						nDotsHintScript = "____builder:Variable(false)"
					end
				else
					if nParNode.hintShort then
						nParHintList[#nParHintList + 1] = nParNode.hintShort
					elseif nParNode.self then
						nParHintList[#nParHintList + 1] = "____builder:Variable(true)"
					else
						nParHintList[#nParHintList + 1] = "____builder:Variable(false)"
					end
				end
			end
			local nLongHintScript = node.hintLong or ""
			visitor:print("end, function(____builder) return ____builder:Args(", table.concat(nParHintList,","), ")")
			if nDotsHintScript then
				visitor:print(":Dots(", nDotsHintScript, ")")
			end
			visitor:print(nLongHintScript, " end)")
		end
	},
	Table={
		override=function(visitor, node)
			visitor:print("self:TABLE_NEW(", visitor:pos(), ", function() return {")
			local count = 0
			local tailDots = nil
			for i=1, #node do
				if node[i].tag == "Pair" then
					visitor:print("{", node[i][1], ",", node[i][2], "}")
				else
					count = count + 1
					local nTag = node[i].tag
					if i==#node and (nTag == "Dots" or nTag == "Invoke" or nTag == "Call") then
						tailDots = node[i]
					else
						local key = "self:LiteralTerm("..count..")"
						visitor:print("{", key, ",", node[i], "}")
					end
				end
				visitor:print(i < #node and "," or "")
			end
			if not tailDots then
				visitor:print("}, 0, nil end, ")
			else
				visitor:print("}, ", count, ", ")
				tailDots.table_tail = true
				visitor:print(tailDots, " end, ")
			end
			local nLongHintScript = node.hintLong or ""
			visitor:print("function(____builder) return ____builder", nLongHintScript, " end )")
		end,
	},
	Op = {
		override=function(visitor, node)
			local t = {["or"]=1,["not"]=1,["and"]=1}
			if t[node[1]] then
				if node[1] == "not" then
					visitor:print(visitor:rgn("LOGIC_NOT"), ",", node[2], ")")
				else
					visitor:print(visitor:rgn("LOGIC_"..node[1]:upper()),
					",", node[2], ", function() return ", node[3], " end)")
				end
			else
				if #node == 2 then
					visitor:print(visitor:hook("META_UOP"), "(\"", node[1], "\",", node[2], ")")
				elseif node[1] == "==" then
					visitor:print(visitor:hook("META_EQ_NE"), "(true,", node[2], ",", node[3], ")")
				elseif node[1] == "~=" then
					visitor:print(visitor:hook("META_EQ_NE"), "(false,", node[2], ",", node[3], ")")
				else
					visitor:print(visitor:hook("META_BOP_SOME"), "(\"", node[1], "\",", node[2], ",", node[3], ")")
				end
			end
		end
	},
	Paren = {
		before=function(visitor, node)
			local nHint = node.hintShort
			if nHint then
				visitor:print(visitor:hook("HINT("))
			end
			visitor:print("(")
		end,
		after=function(visitor, node)
			visitor:print(")")
			local nHint = node.hintShort
			if nHint then
				visitor:print(",", nHint, ")")
			end
		end,
	},
	--Call = {},
	--Invoke = {},
	Id = {
		before=function(visitor, node)
			local preNode = visitor.stack[#visitor.stack-1]
			if preNode.tag == "ParList" then
				visitor:print("v_"..node[1])
			else
				if node.ident_refer == CodeEnv.G_IDENT_REFER then
					local symbol = "\""..node[1].."\""
					if node.is_define or node.is_set then
						visitor:print(symbol)
					else
						visitor:print(visitor:hook("META_GET"), "(s1, self:LiteralTerm(", symbol, "))")
					end
				else
					local ident_refer = node.ident_refer
					local scope_refer = visitor.env.ident_list[ident_refer].scope_refer
					local symbol = "____s"..scope_refer.."."..node[1]..ident_refer
					if node.is_define or node.is_set then
						visitor:print(symbol)
					else
						if preNode.tag == "ExpList" and preNode.is_args then
							visitor:print(" function() return ")
						end
						visitor:print(symbol, ":GET()")
						if preNode.tag == "ExpList" and preNode.is_args then
							visitor:print(" end ")
						end
					end
				end
			end
			--visitor:print(node[1])
		end
	},
	Index = {
		override=function(visitor, node)
			visitor:print(visitor:hook("META_GET"), "(")
			visitor:print(node[1])
			visitor:print(",")
			visitor:print(node[2])
			visitor:print(",", tostring(node.notnil or false), ")")
		end
	},
}

local visitor_list = {
	ExpList={
		override=function(visitor, node)
			for i=1,#node do
				visitor:print(node[i])
				visitor:print(i < #node and "," or "")
			end
		end
	},
	ParList={
		override=function(visitor, node)
			for i=1, #node do
				visitor:print(node[i])
				visitor:print(i < #node and "," or "")
			end
		end
	},
	VarList={
		override=function(visitor, node)
			for i=1, #node do
				visitor:print(node[i])
				visitor:print(i < #node and "," or "")
			end
		end
	},
	NameList={
		override=function(visitor, node)
			for i=1,#node do
				visitor:print(node[i])
				visitor:print(i < #node and "," or "")
			end
		end
	},
}

local visitor_object_dict = oldvisitor.concat(visitor_block, visitor_stm, visitor_exp, visitor_list)

function TypeHintGen.visit(vFileEnv, vPath)
	local pre_codes = {
		'return function(self, vArgTuple)\n',
		"\n----------------------------\n",
		"local s"..CodeEnv.G_SCOPE_REFER.."=".."self:getGlobalTerm()\n",
	}
	local visitor = setmetatable({
		object_dict = visitor_object_dict,
		buffer_list = pre_codes,
		env = vFileEnv,
		indent_count = 0,
		path = vPath,
	}, {
		__index=TypeHintGen
	})

	oldvisitor.visit_obj(vFileEnv.ast, visitor)
	table.insert(visitor.buffer_list,"\nend")
	return table.concat(visitor.buffer_list)
end

return TypeHintGen
