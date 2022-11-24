--[[
This module implements a parser for Lua 5.3 with LPeg,
and generates an Abstract Syntax Tree.

Some code modify from
https://github.com/andremm/typedlua and https://github.com/Alloyed/lua-lsp
]]
local lpeg = require "lpeg"
lpeg.setmaxstack(1000)
lpeg.locale(lpeg)

local Node = require "thlua.code.Node"

local parser = {}

local Cenv = lpeg.Carg(1)
local Cpos = lpeg.Cp()
local cc = lpeg.Cc

local function throw(vErr)
	return lpeg.Cmt(Cenv, function(_, i, env)
		error(env:makeErrNode(i, "syntax error : "..vErr))
		return true
	end)
end

local vv=setmetatable({}, {
	__index=function(t,tag)
		local patt = lpeg.V(tag)
		t[tag] = patt
		return patt
	end
})

local vvA=setmetatable({}, {
	__index=function(t,tag)
		local patt = lpeg.V(tag) + throw("expect a '"..tag.."'")
		t[tag] = patt
		return patt
	end
})

local function token (patt)
  return patt * vv.Skip
end

local function symb(str)
	if str=="." then
		return token(lpeg.P(".")*-lpeg.P("."))
	elseif str==":" then
		return token(lpeg.P(":")*-lpeg.P(":"))
	elseif str=="-" then
		return token(lpeg.P("-")*-lpeg.P("-"))
	elseif str == "[" then
		return token(lpeg.P("[")*-lpeg.S("=["))
	elseif str == "~" then
		return token(lpeg.P("~")*-lpeg.P("="))
	elseif str == "@" then
		return token(lpeg.P("@")*-lpeg.P("!"))
	elseif str == "@!" then
		return token(lpeg.P("@!")*-lpeg.P("!"))
	else
		return token(lpeg.P(str))
	end
end

local function symbA(str)
  return symb(str) + throw("expect symbol '"..str.."'")
end

local function kw (str)
  return token(lpeg.P(str) * -vv.IdRest)
end

local function kwA(str)
  return kw(str) + throw("expect keyword '"..str.."'")
end

local expF={
	binOp=function(e1, op, e2)
		if not op then
			return e1
		else
			return {tag = "Op", pos=e1.pos, posEnd=e2.posEnd, op, e1, e2 }
		end
	end,
	suffixed=function(e1, e2)
		local e2tag = e2.tag
		assert(e2tag == "Call" or e2tag == "Invoke" or e2tag == "Index", "exprSuffixed args exception")
		e2.pos = e1.pos
		e2[1] = e1
		return e2
	end,
	paren=function(pos, e, posEnd)
		return { tag = "Paren", pos = pos, [1] = e, posEnd=posEnd}
	end,
	hintExpr=function(pos, e, hintShort, posEnd)
		if not hintShort then
			return e
		else
			-- TODO, use other tag
			return { tag = "Paren", pos = pos, [1] = e, hintShort = hintShort, posEnd=posEnd}
		end
	end
}

local tagC=setmetatable({}, {
	__index=function(t,tag)
		local f = function(patt)
			-- TODO , make this faster : 1. rm posEnd, 2. use table not lpeg.Ct
			if patt then
				return lpeg.Ct(lpeg.Cg(Cpos, "pos") * lpeg.Cg(lpeg.Cc(tag), "tag") * patt * lpeg.Cg(Cpos, "posEnd"))
			else
				return lpeg.Ct(lpeg.Cg(Cpos, "pos") * lpeg.Cg(Cpos, "posEnd") * lpeg.Cg(lpeg.Cc(tag), "tag"))
			end
		end
		t[tag] = f
		return f
	end
})

local hintC={
	string=function(pattBegin,pattScript,pattEndOrNil)
		pattScript = pattScript/function(...) end
		local pattEndPos = (pattEndOrNil and pattEndOrNil * Cpos or Cpos)
		local patt = Cenv * Cpos * pattBegin * Cpos * pattScript * Cpos * pattEndPos / function(env,p1,p2,p3,p4)
			env:markDel(p1, p4-1)
			return env:subScript(p2, p3-1)
		end
		-- TODO, refactor this capture to be faster
		local thluaPatt = vv.HintBegin * (patt * vv.HintSuccessEnd + vv.HintFailEnd)
		return thluaPatt
		--local commentPatt = lpeg.P"--[["*Cenv*pattBegin*
		--Cpos*pattScript*Cpos*pattEndPos*lpeg.P"]]"*vv.Skip/function(env,p1,p2,p3)
			--return env:subScript(p1, p2-1)
		--end
		--return thluaPatt + commentPatt
	end,
	char=function(char)
		return lpeg.Cmt(Cenv*Cpos*lpeg.P(char), function(_, i, env, pos)
			if env.hinting then
				return false
			else
				env:markDel(pos, pos)
				return true
			end
		end)
	end
}

local function chainOp (pat, kwOrSymb, op1, ...)
	local sep = kwOrSymb(op1) * lpeg.Cc(op1)
	local ops = {...}
	for _, op in pairs(ops) do
		sep = sep + kwOrSymb(op) * lpeg.Cc(op)
	end
  return lpeg.Cf(pat * lpeg.Cg(sep * pat)^0, expF.binOp)
end

local G = lpeg.P { "TypeHintLua";
	Shebang = lpeg.P("#") * (lpeg.P(1) - lpeg.P("\n"))^0 * lpeg.P("\n");
	TypeHintLua = vv.Shebang^-1 * vv.Chunk * (lpeg.P(-1) + throw("invalid chunk"));

  -- hint begin {{{
	HintBegin = lpeg.Cmt(Cenv, function(_, i, env)
		if not env.hinting then
			env.hinting = true
			return true
		else
			return false
		end
	end);

	HintSuccessEnd = lpeg.Cmt(Cenv, function(_, _, env)
		assert(env.hinting, "hinting state error when lpeg parsing when success case")
		env.hinting = false
		return true
	end);

	HintFailEnd = lpeg.Cmt(Cenv, function(_, _, env)
		assert(env.hinting, "hinting state error when lpeg parsing when fail case")
		env.hinting = false
		return true
	end) * lpeg.P(false);

	NotnilHint = hintC.char("!");

	OverrideHint = hintC.char("?");

	AtHint = hintC.string(symb("@") + symb("@!!"), vvA.SimpleExpr);

	ColonHint = hintC.string(symb(":"), vvA.Expr);

	LongHint = hintC.string(lpeg.P(":"), (symb":" * vv.Name * vv.FuncArgs)^1, symb(";")^-1);

	HintStat = tagC.HintStat(hintC.string(symb("(")*symb("@"), vv.AssignStat + vv.ApplyExp + vv.DoStat + throw("hint-statement need do-statment or apply-statement or assign-statement inside"), symbA(")")));

  -- hint end }}}


	-- parser
	Chunk = tagC.Chunk(tagC.Id(cc("_ENV")) * tagC.ParList(tagC.Dots()) * vv.Skip * vv.Block);

	FuncDef = kw("function") * vv.FuncBody;

	Constructor = (function()
		local Pair = tagC.Pair(
          ((symb"[" * vvA.Expr * symbA"]") + tagC.String(vv.Name)) *
          symb"=" * vv.Expr)
		local Field = Pair + vv.Expr
		local fieldsep = symb(",") + symb(";")
		local FieldList = (Field * (fieldsep * Field)^0 * fieldsep^-1)^-1
		return tagC.Table(symb("{") * lpeg.Cg(vv.LongHint, "hintLong")^-1 * FieldList * symbA("}"))
	end)();

	Id = tagC.Id(vv.Name);
	IdHintable = tagC.Id(vv.Name * lpeg.Cg(vv.ColonHint, "hintShort")^-1);

	NameList = tagC.NameList(vv.IdHintable * (symb(",") * vv.IdHintable)^0);

	ExpList = tagC.ExpList(vv.Expr * (symb(",") * vv.Expr)^0);

	FuncArgs = tagC.ExpList(symb("(") * (vv.Expr * (symb(",") * vv.Expr)^0)^-1 * symb(")") +
             vv.Constructor + vv.String);

	String = tagC.String(token(vv.LongString)*lpeg.Cg(cc(true), "isLong") + token(vv.ShortString));

	UnaryExpr = (function()
		local UnOp = kw("not")/"not" + symb("-")/"-" + symb("~")/"~" + symb("#")/"#"
		local PowExpr = vv.SimpleExpr * ((symb("^")/"^") * vv.UnaryExpr)^-1 / expF.binOp
		return tagC.Op(UnOp * vv.UnaryExpr) + PowExpr
	end)();
	ConcatExpr = (function()
		local MulExpr = chainOp(vv.UnaryExpr, symb, "*", "//", "/", "%")
		local AddExpr = chainOp(MulExpr, symb, "+", "-")
	  return AddExpr * (symb("..")/"..") * vv.ConcatExpr / expF.binOp + AddExpr
	end)();
	Expr = (function()
		local ShiftExpr = chainOp(vv.ConcatExpr, symb, "<<", ">>")
		local BAndExpr = chainOp(ShiftExpr, symb, "&")
		local BXorExpr = chainOp(BAndExpr, symb, "~")
		local BOrExpr = chainOp(BXorExpr, symb, "|")
		local RelExpr = chainOp(BOrExpr, symb, "~=", "==", "<=", ">=", "<", ">")
		local AndExpr = chainOp(RelExpr, kw, "and")
		local OrExpr = chainOp(AndExpr, kw, "or")
		return OrExpr
	end)();

	SimpleExpr = Cpos * (vv.String +
              tagC.Number(token(vv.Number)) +
              tagC.Nil(kw"nil") +
              tagC.False(kw"false") +
              tagC.True(kw"true") +
              vv.FuncDef +
              vv.Constructor) * (vv.AtHint + cc(nil)) * Cpos /expF.hintExpr +
              lpeg.Cmt(Cpos * vv.SuffixedExp * (vv.AtHint + cc(nil)) * Cpos, function(s,i, pos, expr, hint, posEnd)
                  if not hint then
                      return true, expr
                  else
                      local tag = expr.tag
                      if tag == "Call" or tag == "Invoke" or tag == "Dots" then
                          return false
                      else
                          return true, expF.hintExpr(pos, expr, hint, posEnd)
                      end
                  end
              end) + tagC.Dots(symb"...");

	SuffixedExp = (function()
		local notnil = lpeg.Cg(vv.NotnilHint*vv.Skip*cc(true) + cc(false), "notnil")
		-- . index
		local index1 = tagC.Index(cc(false) * symb(".") * tagC.String(vv.Name) * notnil)
		-- [] index
		local index2 = tagC.Index(cc(false) * symb("[") * vvA.Expr * symbA("]") * notnil)
		-- invoke
		local invoke = tagC.Invoke(cc(false) * symb(":") * tagC.String(vv.Name) * vvA.FuncArgs)
		-- call
		local call = tagC.Call(cc(false) * vv.FuncArgs)
		-- add completion case
		local succPatt = lpeg.Cf(vv.PrimaryExp * (index1 + index2 + invoke + call)^0, expF.suffixed);
		return lpeg.Cmt(succPatt * (Cenv*Cpos*symb(".") + Cenv*Cpos*symb(":")) ^-1, function(_, _, exp, env, predictPos)
			if not predictPos then
				return true, exp
			else
				local nNode = env:makeErrNode(predictPos+1, "syntax error : expect a name")
				nNode[2] = exp
				nNode[3] = env.scopeTraceList
				local l = {}
				for k,v in pairs(env.scopeTraceList) do
					l[#l + 1] = v
				end
				print("scope trace:", table.concat(l, ","))
				error(nNode)
				return false
			end
		end)
	end)();

	ApplyExp = lpeg.Cmt(vv.SuffixedExp, function(_,_,exp) return exp.tag == "Call" or exp.tag == "Invoke", exp end);
	VarExp = lpeg.Cmt(vv.SuffixedExp, function(_,_,exp) return exp.tag == "Id" or exp.tag == "Index", exp end);

	PrimaryExp = vv.Id + Cpos * symb("(") * vv.Expr * symbA(")") * Cpos / expF.paren;

	Block = tagC.Block(lpeg.Cmt(Cenv, function(_,_,env)
		if not env.hinting then
			local len = #env.scopeTraceList
			env.scopeTraceList[len + 1] = 0
			if len > 0 then
				env.scopeTraceList[len] = env.scopeTraceList[len] + 1
			end
		end
		return true
	end) * vv.Stat^0 * vv.RetStat^-1 * lpeg.Cmt(Cenv, function(_,_,env)
		if not env.hinting then
			env.scopeTraceList[#env.scopeTraceList] = nil
		end
		return true
	end));
	DoStat = tagC.Do(kw"do" * vv.Block * kwA"end");
	FuncBody = (function()
		local IdHintableList = vv.IdHintable * (symb(",") * vv.IdHintable)^0;
		local DotsHintable = tagC.Dots(symb"..." * lpeg.Cg(vv.ColonHint, "hintShort")^-1)
		local ParList = tagC.ParList(IdHintableList * (symb(",") * DotsHintable)^-1) +
									tagC.ParList(DotsHintable^-1);
		return tagC.Function(symbA("(") * ParList * symbA(")") *
			lpeg.Cg(vv.LongHint, "hintLong")^-1 * vv.Block * kwA("end"))
	end)();

	AssignStat = (function()
		local VarList = tagC.VarList(vv.VarExp * (symb(",") * vv.VarExp)^0)
		local OverrideHint = lpeg.Cg(symb("=")*cc(false) + vv.OverrideHint*symb("=")*cc(true), "override")
		return tagC.Set(VarList * OverrideHint * vv.ExpList)
	end)();

	RetStat = tagC.Return(kw("return") * (vv.ExpList + tagC.ExpList()) * symb(";")^-1);

	Stat = (function()
		local LocalFunc = tagC.Localrec(kw"function" * vvA.Id * vv.FuncBody)
		local LocalAssign = tagC.Local(vv.NameList * (symb"=" * vvA.ExpList + tagC.ExpList()))
		local LocalStat = kw"local" * (LocalFunc + LocalAssign + throw("wrong local-statement")) +
				Cenv * Cpos * kw"const" * (LocalFunc + LocalAssign + throw("wrong const-statement")) / function(env, pos, t)
					env:markConst(pos)
					t.isConst = true
					return t
				end
		local FuncStat = (function()
			local function makeNameIndex(ident1, ident2)
				return { tag = "Index", pos=ident1.pos, posEnd=ident2.posEnd, ident1, ident2}
			end
			local FuncName = lpeg.Cf(vv.Id * (symb"." * tagC.String(vv.Name))^0, makeNameIndex)
			local MethodName = symb(":") * tagC.String(vv.Name) + cc(false)
			return Cpos * kw("function") * FuncName * MethodName * (vv.OverrideHint*vv.Skip*cc(true) + cc(false)) * Cpos * vv.FuncBody * Cpos / function (pos, prefix, methodName, override, posMid, funcExpr, posEnd)
				if methodName then
					table.insert(funcExpr[1], 1, { tag = "Id", pos=pos, self=true, [1] = "self", posEnd=pos})
					prefix = makeNameIndex(prefix, methodName)
				end
				return {
					tag = "Set", pos=pos, override=override, posEnd=posEnd,
					{ tag="VarList", pos=pos, posEnd=posMid, prefix},
					{ tag="ExpList", pos=posMid, posEnd=posEnd, funcExpr },
				}
			end
		end)()
		local LabelStat = tagC.Label(symb"::" * vv.Name * symb"::")
		local BreakStat = tagC.Break(kw"break")
		local GoToStat = tagC.Goto(kw"goto" * vvA.Name)
		local RepeatStat = tagC.Repeat(kw"repeat" * vv.Block * kwA"until" * vvA.Expr)
		local IfStat = tagC.If(kw("if") * vvA.Expr * kwA("then") * vv.Block *
			(kw("elseif") * vvA.Expr * kwA("then") * vv.Block)^0 *
			(kw("else") * vv.Block)^-1 *
			kwA("end"))
		local WhileStat = tagC.While(kw("while") * vvA.Expr * kwA("do") * vv.Block * kwA("end"))
		local ForStat = (function()
			local ForBody = kwA("do") * vv.Block
			local ForNum = tagC.Fornum(vv.Id * symb("=") * vvA.Expr * symbA(",") * vvA.Expr * (symb(",") * vv.Expr)^-1 * ForBody)
			local ForIn = tagC.Forin(vv.NameList * kwA("in") * vvA.ExpList * ForBody)
			return kw("for") * (ForNum + ForIn + throw("wrong for-statement")) * kwA("end")
		end)()
		local BlockEnd = lpeg.P("return") + "end" + "elseif" + "else" + "until" + lpeg.P(-1)
		return vv.HintStat +
         LocalStat + FuncStat + LabelStat + BreakStat + GoToStat +
				 RepeatStat + ForStat + IfStat + WhileStat +
				 vv.DoStat + vv.AssignStat + vv.ApplyExp + symb(";") + (lpeg.P(1)-BlockEnd)*throw("wrong statement")
	end)();

	-- lexer
	Skip     = (lpeg.space^1 + vv.Comment)^0;
	Comment  = lpeg.P"--" * (vv.LongString / function () return end + (lpeg.P(1) - lpeg.P"\n")^0);

	Number = (function()
		local Hex = (lpeg.P"0x" + lpeg.P"0X") * lpeg.xdigit^1
		local Decimal = lpeg.digit^1 * lpeg.P"." * lpeg.digit^0
									+ lpeg.P"." * -lpeg.P"." * lpeg.digit^1
		local Expo = lpeg.S"eE" * lpeg.S"+-"^-1 * lpeg.digit^1
		local Int = lpeg.digit^1
		local Float = Decimal * Expo^-1 + Int * Expo
		return lpeg.C(Hex + Float + Int) / tonumber
	end)();

	LongString = (function()
		local Equals = lpeg.P"="^0
		local Open = "[" * lpeg.Cg(Equals, "openEq") * "[" * lpeg.P"\n"^-1
		local Close = "]" * lpeg.C(Equals) * "]"
		local CloseEq = lpeg.Cmt(Close * lpeg.Cb("openEq"), function (s, i, closeEq, openEq) return #openEq == #closeEq end)
		return Open * lpeg.C((lpeg.P(1) - CloseEq)^0) * (Close+throw("--[...[comment  not close")) / function (s, eqs) return s end
	end)();

	ShortString = lpeg.P('"') * lpeg.C(((lpeg.P('\\') * lpeg.P(1)) + (lpeg.P(1) - lpeg.P('"')))^0) * (lpeg.P'"' + throw('" not close'))
							+ lpeg.P("'") * lpeg.C(((lpeg.P("\\") * lpeg.P(1)) + (lpeg.P(1) - lpeg.P("'")))^0) * (lpeg.P"'" + throw("' not close"));

	IdRest = lpeg.alnum + lpeg.P"_";

	Name = (function()
		local Ident = (lpeg.alpha + lpeg.P"_") * vv.IdRest^0
		local Keywords  = lpeg.P"and" + "break" + "do" + "elseif" + "else" + "end"
		+ "false" + "for" + "function" + "goto" + "if" + "in"
		+ "local" + "nil" + "not" + "or" + "repeat" + "return"
		+ "then" + "true" + "until" + "while" + "const"
		local Reserved = Keywords * -vv.IdRest
		return token(-Reserved * lpeg.C(Ident) * -vv.IdRest);
	end)();

}

function parser.parse(vFileEnv, vSubject)
    return lpeg.match(G, vSubject, nil, vFileEnv)
end

return parser
