--[[
This module implements a parser for Lua 5.3 with LPeg,
and generates an Abstract Syntax Tree.

Some code modify from
https://github.com/andremm/typedlua and https://github.com/Alloyed/lua-lsp
]]
local lpeg = require "lpeg"
lpeg.setmaxstack(1000)
lpeg.locale(lpeg)

local ParseEnv = {}

ParseEnv.__index = ParseEnv

local NOT_IN = 0
local IN_HINT = 1
local IN_EVAL = 2

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

local vvA=setmetatable({
	IdentDefT=lpeg.V("IdentDefT") + throw("expect a 'Name'"),
	IdentDefN=lpeg.V("IdentDefN") + throw("expect a 'Name'"),
}, {
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
	elseif str == "(" then
		return token(lpeg.P("(")*-lpeg.P("@"))
	elseif str == "<" then
		return token(lpeg.P("<")*-lpeg.P("@"))
	else
		return token(lpeg.P(str))
	end
end

local function symbA(str)
  return symb(str) + throw("expect symbol '"..str.."'")
end

local function kw (str)
  return token(lpeg.P(str) * -vv.NameRest)
end

local function kwA(str)
  return kw(str) + throw("expect keyword '"..str.."'")
end

local exprF
exprF = {
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
		if e2.hintShort then
			return exprF.hintExpr(e2.pos, e2, e2.hintShort, e2.posEnd)
		else
			return e2
		end
	end,
	paren=function(pos, e, hintShort, posEnd)
		return { tag = "Paren", pos = pos, [1] = e, hintShort=hintShort, posEnd=posEnd}
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

local parF = {
	identUse=function(vPos, vName, vPosEnd)
		return {tag="Ident", pos=vPos, posEnd=vPosEnd, [1] = vName, kind="use"}
	end,
	identDef=function(vPos, vName, vHintShort, vPosEnd)
		return {tag="Ident", pos=vPos, posEnd=vPosEnd, [1] = vName, kind="def", hintShort=vHintShort}
	end,
	identDefSelf=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "self", kind="def", isSelf=true}
	end,
	identDefENV=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "_ENV", kind="def"}
	end,
	dotsDef=function(vPos, vHintShort, vPosEnd)
		return {tag="Dots", pos=vPos, posEnd=vPosEnd, kind="def", hintShort=vHintShort}
	end,
	dotsUse=function(vPos, vPosEnd)
		return {tag="Dots", pos=vPos, posEnd=vPosEnd, kind="use"}
	end,
}

local tagC=setmetatable({
}, {
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

local pHintOrEvalC={
	string=function(startByOffset, intoHintOrEval, pattBegin, pattBody, pattEnd)
		assert(intoHintOrEval == IN_HINT or intoHintOrEval == IN_EVAL, "second arg must be IN_HINT or IN_EVAL")
		local triggerBegin = intoHintOrEval == IN_HINT and vv.HintBegin or vv.EvalBegin
		local triggerEnd = intoHintOrEval == IN_HINT and vv.HintEnd or vv.EvalEnd
		pattBegin = pattBegin / function(...) end
		pattBody = pattBody / function(...) end
		return Cenv *
					Cpos * pattBegin * triggerBegin *
					Cpos * pattBody * triggerEnd *
					Cpos * (pattEnd and pattEnd * Cpos or Cpos) / function(env,p1,p2,p3,p4)
			if intoHintOrEval == IN_HINT then
				env:markDel(p1, p4-1)
				if startByOffset then
					return env:subScript(p1+startByOffset, p3-1)
				else
					return env:subScript(p2, p3-1)
				end
			else
				return
			end
		end
	end,
	charHint=function(char)
		return lpeg.Cmt(Cenv*Cpos*lpeg.P(char), function(_, i, env, pos)
			if env.inHintOrEval == NOT_IN then
				env:markDel(pos, pos)
				return true
			else
				return false
			end
		end)
	end,
}

local function chainOp (pat, kwOrSymb, op1, ...)
	local sep = kwOrSymb(op1) * lpeg.Cc(op1)
	local ops = {...}
	for _, op in pairs(ops) do
		sep = sep + kwOrSymb(op) * lpeg.Cc(op)
	end
  return lpeg.Cf(pat * lpeg.Cg(sep * pat)^0, exprF.binOp)
end

local G = lpeg.P { "TypeHintLua";
	Shebang = lpeg.P("#") * (lpeg.P(1) - lpeg.P("\n"))^0 * lpeg.P("\n");
	TypeHintLua = vv.Shebang^-1 * vv.Chunk * (lpeg.P(-1) + throw("invalid chunk"));

  -- hint & eval begin {{{
	HintBegin = lpeg.Cmt(Cenv, function(_, i, env)
		if env.inHintOrEval == NOT_IN then
			env.inHintOrEval = IN_HINT
			return true
		else
			error(env:makeErrNode(i, "syntax error : hint-in-hint syntax not allow"))
			return false
		end
	end);

	HintEnd = lpeg.Cmt(Cenv, function(_, _, env)
		assert(env.inHintOrEval == IN_HINT, "hinting state error when lpeg parsing when success case")
		env.inHintOrEval = NOT_IN
		return true
	end);

	EvalBegin = lpeg.Cmt(Cenv, function(_, i, env)
		if env.inHintOrEval == IN_HINT then
			env.inHintOrEval = IN_EVAL
			return true
		else
			error(env:makeErrNode(i, "syntax error : eval syntax can only be used in hint"))
			return false
		end
	end);

	EvalEnd = lpeg.Cmt(Cenv, function(_, i, env)
		assert(env.inHintOrEval == IN_EVAL, "hinting state error when lpeg parsing when success case")
		env.inHintOrEval = IN_HINT
		return true
	end);

	NotnilHint = pHintOrEvalC.charHint("!");

	OverrideHint = pHintOrEvalC.charHint("?");

	AtHint = pHintOrEvalC.string(false, IN_HINT,
		symb("@") + symb("@!!"), vv.SimpleExpr);

	ColonHint = pHintOrEvalC.string(false, IN_HINT,
		symb(":"), vv.SimpleExpr);

	LongHint = pHintOrEvalC.string(1, IN_HINT,
		symb"::" * vv.Name * symb"(",
		vv.ExprList^-1 * symbA ")" * (symb":" * vvA.Name * symbA"(" * vv.ExprList^-1 * symbA")")^0,
		symb(";")^-1);

	HintStat = tagC.HintStat(pHintOrEvalC.string(false, IN_HINT,
		symb("(@"),
		vv.AssignStat + vv.ApplyExpr + vv.DoStat + throw("HintStat need DoStat or Apply or AssignStat inside"),
		symbA(")")));

	GenericParHint = pHintOrEvalC.string(false, IN_HINT,
		symb("<@"), vvA.Name * (symb"," * vv.SimpleExpr)^0, symbA(">"));

	GenericArgHint = pHintOrEvalC.string(false, IN_HINT,
		symb("<@"), vvA.SimpleExpr * (symb"," * vv.SimpleExpr)^0, symbA(">"));

	EvalExpr = pHintOrEvalC.string(false, IN_EVAL,
		symb("$"), vvA.PrimaryExpr);

  -- hint & eval end }}}


	-- parser
	Chunk = tagC.Chunk(Cpos/parF.identDefENV * tagC.ParList(tagC.Dots()) * vv.Skip * vv.Block);

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

	IdentUse = Cpos*vv.Name*Cpos/parF.identUse;
	IdentDefT = Cpos*vv.Name*(vv.ColonHint + cc(nil))*Cpos/parF.identDef;
	IdentDefN = Cpos*vv.Name*cc(nil)*Cpos/parF.identDef;

	LocalIdentList = tagC.IdentList(vvA.IdentDefT * (symb(",") * vv.IdentDefT)^0);
	ForinIdentList = tagC.IdentList(vvA.IdentDefN * (symb(",") * vv.IdentDefN)^0);

	ExprList = tagC.ExprList(vv.Expr * (symb(",") * vv.Expr)^0);

	FuncArgs = tagC.ExprList(symb("(") * (vv.Expr * (symb(",") * vv.Expr)^0)^-1 * symb(")") +
             vv.Constructor + vv.String);

	String = tagC.String(token(vv.LongString)*lpeg.Cg(cc(true), "isLong") + token(vv.ShortString));

	UnaryExpr = (function()
		local UnOp = kw("not")/"not" + symb("-")/"-" + symb("~")/"~" + symb("#")/"#"
		local PowExpr = vv.SimpleExpr * ((symb("^")/"^") * vv.UnaryExpr)^-1 / exprF.binOp
		return tagC.Op(UnOp * vv.UnaryExpr) + PowExpr
	end)();
	ConcatExpr = (function()
		local MulExpr = chainOp(vv.UnaryExpr, symb, "*", "//", "/", "%")
		local AddExpr = chainOp(MulExpr, symb, "+", "-")
	  return AddExpr * (symb("..")/"..") * vv.ConcatExpr / exprF.binOp + AddExpr
	end)();
	Expr = (function()
		local ShiftExpr = chainOp(vv.ConcatExpr, symb, "<<", ">>")
		local BAndExpr = chainOp(ShiftExpr, symb, "&")
		local BXorExpr = chainOp(BAndExpr, symb, "~")
		local BOrExpr = chainOp(BXorExpr, symb, "|")
		local RelExpr = chainOp(BOrExpr, symb, "~=", "==", "<=", ">=", "<", ">")
		local AndExpr = chainOp(RelExpr, kw, "and")
		local OrExpr = chainOp(AndExpr, kw, "or")
		return vv.EvalExpr + OrExpr
	end)();

	SimpleExpr = Cpos * (vv.String +
              tagC.Number(token(vv.Number)) +
              tagC.Nil(kw"nil") +
              tagC.False(kw"false") +
              tagC.True(kw"true") +
              vv.FuncDef +
              vv.Constructor) * (vv.AtHint + cc(nil)) * Cpos /exprF.hintExpr +
              vv.SuffixedExpr + tagC.Dots(symb"...");

	PrimaryExpr = Cpos * vv.IdentUse * (vv.AtHint + cc(nil)) * Cpos / exprF.hintExpr +
			Cpos * symb"(" * (
				vv.Expr * cc(nil) * symb")" +
				vv.ApplyExpr * vv.AtHint * symb")" +
				throw("invalid paren expression")
			) * Cpos * (vv.AtHint + cc(nil)) * Cpos / function(pos, expr, innerHint, posMid, outerHint, posEnd)
				if innerHint then
					expr = exprF.paren(pos, expr, innerHint, posMid)
				end
				return exprF.paren(pos, expr, outerHint, posEnd)
			end;

	SuffixedExpr = (function()
		local function addAtHint(patt)
			return patt * (vv.AtHint + cc(nil)) / function(expr, hintShort)
				expr.hintShort = hintShort
				return expr
			end
		end
		local notnil = lpeg.Cg(vv.NotnilHint*vv.Skip*cc(true) + cc(false), "notnil")
		local generic = lpeg.Cg(vv.GenericArgHint + cc(false), "hintGeneric")
		-- . index
		local index1 = tagC.Index(cc(false) * symb(".") * tagC.String(vv.Name) * notnil)
		index1 = addAtHint(index1)
		-- [] index
		local index2 = tagC.Index(cc(false) * symb("[") * vvA.Expr * symbA("]") * notnil)
		index2 = addAtHint(index2)
		-- invoke
		local invoke = tagC.Invoke(cc(false) * symb(":") * tagC.String(vv.Name) * generic * vvA.FuncArgs)
		-- call
		local call = tagC.Call(cc(false) * generic * vv.FuncArgs)
		-- add completion case
		local succPatt = lpeg.Cf(vv.PrimaryExpr * (index1 + index2 + invoke + call)^0, exprF.suffixed);
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

	ApplyExpr = lpeg.Cmt(vv.SuffixedExpr, function(_,_,exp) return exp.tag == "Call" or exp.tag == "Invoke", exp end);
	VarExpr = lpeg.Cmt(vv.SuffixedExpr, function(_,_,exp) return exp.tag == "Ident" or exp.tag == "Index", exp end);

	Block = tagC.Block(lpeg.Cmt(Cenv, function(_,_,env)
		if not env.inHintOrEval then
			local len = #env.scopeTraceList
			env.scopeTraceList[len + 1] = 0
			if len > 0 then
				env.scopeTraceList[len] = env.scopeTraceList[len] + 1
			end
		end
		return true
	end) * vv.Stat^0 * vv.RetStat^-1 * lpeg.Cmt(Cenv, function(_,_,env)
		if not env.inHintOrEval then
			env.scopeTraceList[#env.scopeTraceList] = nil
		end
		return true
	end));
	DoStat = tagC.Do(kw"do" * lpeg.Cg(vv.LongHint, "hintLong")^-1 * vv.Block * kwA"end");
	FuncBody = (function()
		local IdentDefTList = vv.IdentDefT * (symb(",") * vv.IdentDefT)^0;
		local DotsHintable = tagC.Dots(symb"..." * lpeg.Cg(vv.ColonHint, "hintShort")^-1)
		local ParList = tagC.ParList(IdentDefTList * (symb(",") * DotsHintable)^-1) +
									tagC.ParList(DotsHintable^-1);
		return tagC.Function(lpeg.Cg(vv.GenericParHint, "hintGeneric")^-1*symbA("(") * ParList * symbA(")") *
			lpeg.Cg(vv.LongHint, "hintLong")^-1 * vv.Block * kwA("end"))
	end)();

	AssignStat = (function()
		local VarList = tagC.VarList(vv.VarExpr * (symb(",") * vv.VarExpr)^0)
		local OverrideHint = lpeg.Cg(symb("=")*cc(false) + vv.OverrideHint*symb("=")*cc(true), "override")
		return tagC.Set(VarList * OverrideHint * vv.ExprList)
	end)();

	RetStat = tagC.Return(kw("return") * (vv.ExprList + tagC.ExprList()) * symb(";")^-1);

	Stat = (function()
		local LocalFunc = tagC.Localrec(kw"function" * vvA.IdentDefN * vv.FuncBody)
		local LocalAssign = tagC.Local(vv.LocalIdentList * (symb"=" * vvA.ExprList + tagC.ExprList()))
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
			local FuncName = lpeg.Cf(vv.IdentUse * (symb"." * tagC.String(vv.Name))^0, makeNameIndex)
			local MethodName = symb(":") * tagC.String(vv.Name) + cc(false)
			return Cpos * kw("function") * FuncName * MethodName * (vv.OverrideHint*vv.Skip*cc(true) + cc(false)) * Cpos * vv.FuncBody * Cpos / function (pos, prefix, methodName, override, posMid, funcExpr, posEnd)
				if methodName then
					table.insert(funcExpr[1], 1, parF.identDefSelf(pos))
					prefix = makeNameIndex(prefix, methodName)
				end
				return {
					tag = "Set", pos=pos, override=override, posEnd=posEnd,
					{ tag="VarList", pos=pos, posEnd=posMid, prefix},
					{ tag="ExprList", pos=posMid, posEnd=posEnd, funcExpr },
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
			local ForNum = tagC.Fornum(vv.IdentDefN * symb("=") * vvA.Expr * symbA(",") * vvA.Expr * (symb(",") * vv.Expr)^-1 * ForBody)
			local ForIn = tagC.Forin(vv.ForinIdentList * kwA("in") * vvA.ExprList * ForBody)
			return kw("for") * (ForNum + ForIn + throw("wrong for-statement")) * kwA("end")
		end)()
		local BlockEnd = lpeg.P("return") + "end" + "elseif" + "else" + "until" + lpeg.P(-1)
		return vv.HintStat +
         LocalStat + FuncStat + LabelStat + BreakStat + GoToStat +
				 RepeatStat + ForStat + IfStat + WhileStat +
				 vv.DoStat + vv.AssignStat + vv.ApplyExpr + symb(";") + (lpeg.P(1)-BlockEnd)*throw("wrong statement")
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

	NameRest = lpeg.alnum + lpeg.P"_";

	Name = (function()
		local RawName = (lpeg.alpha + lpeg.P"_") * vv.NameRest^0
		local Keywords  = lpeg.P"and" + "break" + "do" + "elseif" + "else" + "end"
		+ "false" + "for" + "function" + "goto" + "if" + "in"
		+ "local" + "nil" + "not" + "or" + "repeat" + "return"
		+ "then" + "true" + "until" + "while" + "const"
		local Reserved = Keywords * -vv.NameRest
		return token(-Reserved * lpeg.C(RawName));
	end)();

}

function ParseEnv.new(vSubject, vChunkName)
	local self = setmetatable({
		inHintOrEval = NOT_IN,
		scopeTraceList = {},
		_subject = vSubject,
		_chunkName = vChunkName,
		_posToChange = {},
		_astOrErr = nil,
	}, ParseEnv)
	local nOkay, nAstOrErr = pcall(lpeg.match, G, vSubject, nil, self)
	if not nOkay then
		if type(nAstOrErr) == "table" and nAstOrErr.tag == "Error" then
			self._astOrErr = nAstOrErr
		else
			self._astOrErr = self:makeErrNode(1, "unknown parse error: "..tostring(nAstOrErr))
		end
	else
		self._astOrErr = nAstOrErr
	end
	return self
end

function ParseEnv:get()
	return self._astOrErr
end

function ParseEnv:makeErrNode(vPos, vErr)
	return {
		tag="Error",
		pos=vPos,
		vErr
	}
end

function ParseEnv:subScript(vStartPos, vFinishPos)
	local nScript = self._subject:sub(vStartPos, vFinishPos)
	return {script=nScript}
end

function ParseEnv:markDel(vStartPos, vFinishPos)
	self._posToChange[vStartPos] = vFinishPos
end

function ParseEnv:markConst(vStartPos)
	self._posToChange[vStartPos] = "const"
end

function ParseEnv:assertWithLineNum()
	local nNode = self._astOrErr
	local nLineNum = select(2, self._subject:sub(1, nNode.pos):gsub('\n', '\n'))
	if nNode.tag == "Error" then
		local nMsg = self._chunkName..":".. nLineNum .." ".. nNode[1]
		error(nMsg)
	end
end

function ParseEnv:genLuaCode()
	self:assertWithLineNum()
	local nSubject = self._subject
	local nPosToChange = self._posToChange
	local nStartPosList = {}
	for nStartPos, _ in pairs(nPosToChange) do
		nStartPosList[#nStartPosList + 1] = nStartPos
	end
	table.sort(nStartPosList)
	local nContents = {}
	local nPreFinishPos = 0
	for _, nStartPos in pairs(nStartPosList) do
		if nStartPos <= nPreFinishPos then
			-- hint in hint
			-- TODO replace in hint script
			-- continue
		else
			local nChange = nPosToChange[nStartPos]
			if type(nChange) == "number" then
				-- 1. save lua code
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = nLuaCode
				-- 2. replace hint code with space and newline
				local nFinishPos = nPosToChange[nStartPos]
				local nHintCode = nSubject:sub(nStartPos, nFinishPos)
				nContents[#nContents + 1] = nHintCode:gsub("[^\r\n \t]", "")
				nPreFinishPos = nFinishPos
			--[[elseif type(nChange) == "string" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = nChange
				nPreFinishPos = nStartPos]]
			elseif nChange == "const" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos-1)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = "local"
				nPreFinishPos = nStartPos + 4
			else
				error("unexpected branch")
			end
		end
	end
	nContents[#nContents + 1] = nSubject:sub(nPreFinishPos + 1, #nSubject)
	return table.concat(nContents)
end

return ParseEnv
