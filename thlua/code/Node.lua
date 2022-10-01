--[[(@do

let.node = namespace()

local function NodeStruct(t)
	t.pos = Number
	t.l = Number
	t.c = Number
	return Struct(t)
end

node.Chunk = NodeStruct {
	tag = "Chunk",
	[1] = node.Block,
}

node.Block = NodeStruct {
	tag = "Block",
	[Number] = node.Stat,
}

node.Stat = Union (
	node.Do,
	node.Set,
	node.While,
	node.Repeat,
	node.If,
	node.Fornum,
	node.Forin,
	node.Local,
	node.Localrec,
	node.Return,
	node.Break,
	node.Apply,
	node.HintStat
)

node.Do = NodeStruct {
	tag = "Do",
	[1] = node.Block,
}

node.Set = NodeStruct {
	tag = "Set",
	[1] = node.VarList,
	[2] = node.ExpList,
}

node.While = NodeStruct {
	tag = "While",
	[1] = node.Expr,
	[2] = node.Block,
}

node.Repeat = NodeStruct {
	tag = "Repeat",
	[1] = node.Block,
	[2] = node.Expr,
}

node.If = NodeStruct {
	tag = "Repeat",
	[Number] = Union(node.Block, node.Expr),
}

node.Fornum = NodeStruct {
	tag = "Fornum",
	[1] = node.Id,
	[2] = node.Expr,
	[3] = node.Expr,
	[4] = Union(node.Expr, node.Block),
	[5] = Union(node.Block, Nil),
}

node.Forin = NodeStruct {
	tag = "Forin",
	[1] = node.NameList,
	[2] = node.ExpList,
	[3] = node.Block,
}

node.Local = NodeStruct {
	tag = "Local",
	[1] = node.NameList,
	[2] = node.ExpList,
}

node.Localrec = NodeStruct {
	tag = "Localrec",
	[1] = node.Id,
	[2] = node.Expr,
}

node.Return = NodeStruct {
	tag = "Return",
	[1] = node.ExpList,
}

node.Break = NodeStruct {
	tag = "Break",
}

node.HintStat = NodeStruct {
	tag = "HintStat",
	[1] = String,
}

node.Apply = Union (
	node.Call,
	node.Invoke
)

node.Call = NodeStruct {
	tag = "Call",
	[1] = node.Expr,
	[2] = node.ExpList,
}

node.Invoke = NodeStruct {
	tag = "Invoke",
	[1] = node.Expr,
	[2] = node.String,
	[3] = node.ExpList,
}

node.Lhs = Union (
	node.Id,
	node.Index
)

node.Index = NodeStruct {
	tag = "Index",
	[1] = node.Expr,
	[2] = node.Expr,
}

node.Id = NodeStruct {
	tag = "Id",
	[1] = String,
}

node.Expr = Union (
	node.Nil,
	node.False,
	node.True,
	node.Number,
	node.String,
	node.Lhs
)

node.Nil = NodeStruct {
	tag = "Nil"
}

node.False = NodeStruct {
	tag = "False"
}

node.True = NodeStruct {
	tag = "True"
}

node.Number = NodeStruct {
	tag = "Number",
	[1] = Number,
}

node.String = NodeStruct {
	tag = "String",
	[1] = String,
}

node.Function = NodeStruct {
	tag = "Function",
	[1] = node.ParList,
	[2] = node.Block,
}

node.Table = NodeStruct {
	tag = "Table",
	[Number] = Union(node.Pair, node.Expr)
}

node.Pair = NodeStruct {
	tag = "Pair",
	[1] = node.Expr,
	[2] = node.Expr,
}

node.Op = NodeStruct {
	tag = "Op",
	[1] = String,
	[2] = node.Expr,
	[3] = Union(node.Expr, Nil),
}

node.Dots = NodeStruct {
	tag = "Dots"
}


node.Paren = NodeStruct {
	tag = "Paren",
	[1] = node.Expr
}

node.ParList = NodeStruct {
	tag = "ParList",
	[Number] = Union(node.Id, node.Dots),
}

node.ExpList = NodeStruct {
	tag = "ExpList",
	[Number] = node.Expr,
}

node.VarList = NodeStruct {
	tag = "VarList",
	[Number] = node.Lhs,
}

node.NameList = NodeStruct {
	tag = "NameList",
	[Number] = node.Id,
}

end)]]

local Node = {}

Node.__index=Node

function Node.__tostring(self)
	local before = self.path..":".. self.l ..(self.c > 0 and ("," .. self.c) or "")
	if self.tag ~= "Error" then
		return before
	else
		return before .." ".. (self[1] or "")
	end
end

function Node.newRootNode(vFileName)
	return setmetatable({tag = "Root", pos=1, l=1, c=1, path=vFileName}, Node)
end

function Node.getDebugNode(vDepth)
	local nInfo = debug.getinfo(vDepth)
	return setmetatable({tag = "Root", pos=1, l=nInfo.currentline, c=0, path=nInfo.source}, Node)
end

function Node.is(vNode)
	return getmetatable(vNode) == Node
end

return Node

