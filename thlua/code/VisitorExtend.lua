
require "thlua.code.Node"

--[[(@do

var.node = import("thlua.code.Node").node

local TNodeVisitor = function(IVisitor)
	return Struct {
		Chunk=Fn(IVisitor, node.Chunk),
		Block=Fn(IVisitor, node.Block),

		-- stat
		Do=Fn(IVisitor, node.Do),
		Set=Fn(IVisitor, node.Set),
		While=Fn(IVisitor, node.While),
		Repeat=Fn(IVisitor, node.Repeat),
		If=Fn(IVisitor, node.If),
		Fornum=Fn(IVisitor, node.Fornum),
		Forin=Fn(IVisitor, node.Forin),
		Local=Fn(IVisitor, node.Local),
		Localrec=Fn(IVisitor, node.Localrec),
		Return=Fn(IVisitor, node.Return),
		Break=Fn(IVisitor, node.Break),
		Label=Fn(IVisitor, node.Label),
		HintStat=Fn(IVisitor, node.HintStat),

		-- apply
		Call=Fn(IVisitor, node.Call),
		Invoke=Fn(IVisitor, node.Invoke),

		-- expr
		Nil=Fn(IVisitor, node.Nil),
		False=Fn(IVisitor, node.False),
		True=Fn(IVisitor, node.True),
		Number=Fn(IVisitor, node.Number),
		String=Fn(IVisitor, node.String),
		Function=Fn(IVisitor, node.Function),
		Table=Fn(IVisitor, node.Table),
		Op=Fn(IVisitor, node.Op),
		Paren=Fn(IVisitor, node.Paren),
		Dots=Fn(IVisitor, node.Dots),

		-- lhs
		Index=Fn(IVisitor, node.Index),
		Id=Fn(IVisitor, node.Id),

		-- list
		ParList=Fn(IVisitor, node.ParList),
		VarList=Fn(IVisitor, node.VarList),
		ExpList=Fn(IVisitor, node.ExpList),
		NameList=Fn(IVisitor, node.NameList),
	}
end

node.IVisitor = Struct {
	realVisit=Fn(node.IVisitor, Truth),
	rawVisit=Fn(node.IVisitor, Truth),
}

end)]]

local TagToTraverse = {
	Chunk=function(self, node)
		self:realVisit(node[1])
	end,
	Block=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,

	-- expr
	Do=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	Set=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	While=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Repeat=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	If=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	Forin=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
	end,
	Fornum=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
		self:realVisit(node[4])
		local last = node[5]
		if last then
			self:realVisit(last)
		end
	end,
	Local=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Localrec=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Return=function(self, node)
		self:realVisit(node[1])
	end,
	Break=function(self, node)
	end,
	Label=function(self, node)
	end,
	HintStat=function(self, node)
	end,

	-- apply
	Call=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Invoke=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
		self:realVisit(node[3])
	end,

	-- expr
	Nil=function(self, node)
	end,
	False=function(self, node)
	end,
	True=function(self, node)
	end,
	Number=function(self, node)
	end,
	String=function(self, node)
	end,
	Function=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Table=function(self, node)
		for i=1, #node do
			self:realVisit(node[i])
		end
	end,
	Op=function(self, node)
		self:realVisit(node[2])
		local right = node[3]
		if right then
			self:realVisit(right)
		end
	end,
	Paren=function(self, node)
		self:realVisit(node[1])
	end,
	Dots=function(self, node)
	end,

	-- lhs
	Index=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
	Id=function(self, node)
	end,

	-- list
	ParList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	ExpList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	VarList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	NameList=function(self, node)
		for i=1,#node do
			self:realVisit(node[i])
		end
	end,
	Pair=function(self, node)
		self:realVisit(node[1])
		self:realVisit(node[2])
	end,
}

local function VisitorExtend(vTable, vDictOrFunc) --[[::open()]]
	local t = vTable
	local nType = type(vDictOrFunc)
	if nType == "table" then
		function t:realVisit(node) --[[::nocheck()]]
			local tag = node.tag
			local f = vDictOrFunc[tag] or TagToTraverse[tag]
			if not f then
				error("tag="..tostring(tag).."not existed")
			end
			f(self, node)
		end
	elseif nType == "function" then
		function t:realVisit(node) --[[::nocheck()]]
			vDictOrFunc(self, node)
		end
	else
		error("VisitorExtend must take a function or dict for override")
	end
	function t:rawVisit(node) --[[::nocheck()]]
		TagToTraverse[node.tag](self, node)
	end
	return t
end

return VisitorExtend
