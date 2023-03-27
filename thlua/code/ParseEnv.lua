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
		return token(lpeg.P("@")*-lpeg.S("!<>?"))
	elseif str == "(" then
		return token(lpeg.P("(")*-lpeg.P("@"))
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

local exprF = {
	binOp=function(e1, op, e2)
		if not op then
			return e1
		else
			return {tag = "Op", pos=e1.pos, posEnd=e2.posEnd, op, e1, e2 }
		end
	end,
	suffixed=function(e1, e2)
		local e2tag = e2.tag
		assert(e2tag == "HintAt" or e2tag == "Call" or e2tag == "Invoke" or e2tag == "Index", "exprSuffixed args exception")
		e2.pos = e1.pos
		e2[1] = e1
		return e2
	end,
	hintAt=function(pos, e, hintShort, posEnd)
		return { tag = "HintAt", pos = pos, [1] = e, hintShort=hintShort, posEnd=posEnd}
	end,
	hintExpr=function(pos, e, hintShort, posEnd, env)
		if not hintShort then
			return e
		else
			local eTag = e.tag
			if eTag == "Dots" or eTag == "Call" or eTag == "Invoke" then
				local nSubject = env._subject
				env:markParenWrap(pos-1, hintShort.pos-1)
			end
			-- TODO, use other tag
			return { tag = "HintAt", pos = pos, [1] = e, hintShort = hintShort, posEnd=posEnd}
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
	identDefLet=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "let", kind="def"}
	end,
}


local function buildLoadChunk(vPos, vBlock)
	return {
		tag="Chunk", pos=vPos, posEnd=vBlock.posEnd,
		letNode = parF.identDefLet(vPos),
		[1]=parF.identDefENV(vPos),
		[2]={
			tag="ParList",pos=vPos,posEnd=vPos,
			[1]={
				tag="Dots",pos=vPos,posEnd=vPos
			}
		},
		[3]=vBlock,
		[4]=false
	}
end

local function buildInjectChunk(expr)
	local nChunk = buildLoadChunk(expr.pos, {
		tag="Block", pos=expr.pos, posEnd=expr.posEnd,
		[1]={
			tag="Return", pos=expr.pos, posEnd=expr.posEnd,
			[1]={
				tag="ExprList", pos=expr.pos, posEnd=expr.posEnd,
				[1] = expr
			}
		}
	})
	nChunk.injectNode = expr
	return nChunk
end

local function buildHintInjectChunk(shortHintSpace)
	local nChunk = buildLoadChunk(shortHintSpace.pos, {
		tag="Block", pos=shortHintSpace.pos, posEnd=shortHintSpace.posEnd,
		[1]={}
	})
	nChunk.injectNode = shortHintSpace
	return nChunk
end

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

local hintC={
	wrap=function(isStat, pattBegin, pattBody, pattEnd)
		pattBody = Cenv * pattBody / function(env, ...) return {...} end
		return Cenv *
					Cpos * pattBegin * vv.HintBegin *
					Cpos * pattBody * vv.HintEnd *
					Cpos * (pattEnd and pattEnd * Cpos or Cpos) / function(env,p1,castKind,p2,innerList,p3,p4)
			local evalList = env:captureEvalByVisit(innerList)
			env:markDel(p1, p4-1)
			local nHintSpace = env:buildIHintSpace(isStat and "StatHintSpace" or "ShortHintSpace", innerList, evalList, p1, p2, p3-1)
			nHintSpace.castKind = castKind
			return nHintSpace
		end
	end,
	long=function()
		local name = tagC.String(vvA.Name)
		local colonInvoke = name * symbA"(" * vv.ExprListOrEmpty * symbA")";
		local pattBody = (
			(symb"." * vv.HintBegin * name)*(symb"." * name)^0+
			symb":" * vv.HintBegin * colonInvoke
		) * (symb":" * colonInvoke)^0 * vv.HintEnd
		return Cenv * Cpos * pattBody * Cpos / function(env, p1, ...)
			local l = {...}
			local posEnd = l[#l]
			env:markDel(p1, posEnd-1)
			l[#l] = nil
			local middle = nil
			local nAttrList = {}
			for i, nameOrExprList in ipairs(l) do
				local nTag = nameOrExprList.tag
				if nTag == "ExprList" then
					if not middle then
						middle = i-1
					end
				else
					assert(nTag == "String")
					nAttrList[#nAttrList + 1] = nameOrExprList[1]
				end
			end
			local nEvalList = env:captureEvalByVisit(l)
			if middle then
				local nHintSpace = env:buildIHintSpace("LongHintSpace", l, nEvalList, p1, l[middle].pos, posEnd-1)
				nHintSpace.attrList = nAttrList
				return nHintSpace
			else
				local nHintSpace = {
					tag = "LongHintSpace",
					pos = p1,
					posEnd = posEnd,
					attrList = nAttrList,
					evalScriptList = {},
					table.unpack(l),
				}
				return nHintSpace
			end
		end
	end,
	char=function(char)
		return lpeg.Cmt(Cenv*Cpos*lpeg.P(char), function(_, i, env, pos)
			if not env.hinting then
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

local function suffixedExprByPrimary(primaryExpr)
	local notnil = lpeg.Cg(vv.NotnilHint*vv.Skip*cc(true) + cc(false), "notnil")
	local polyArgs = lpeg.Cg(vv.AtPolyHint + cc(false), "hintPolyArgs")
	-- . index
	local index1 = tagC.Index(cc(false) * symb(".") * tagC.String(vv.Name) * notnil)
	-- [] index
	local index2 = tagC.Index(cc(false) * symb("[") * vvA.Expr * symbA("]") * notnil)
	-- invoke
	local invoke = tagC.Invoke(cc(false) * symb(":") * tagC.String(vv.Name) * polyArgs * vvA.FuncArgs)
	-- call
	local call = tagC.Call(cc(false) * vv.FuncArgs)
	-- atPoly
	local atPoly= Cpos * cc(false) * vv.AtPolyHint * Cpos / exprF.hintAt
	-- add completion case
	local succPatt = lpeg.Cf(primaryExpr * (index1 + index2 + invoke + call + atPoly)^0, exprF.suffixed);
	return lpeg.Cmt(succPatt * Cenv * (Cpos*symb(".") + Cpos*symb(":")) ^-1, function(_, _, expr, env, predictPos)
		if not predictPos then
			if expr.tag == "HintAt" then
				local hintAtExpr = expr
				local curExpr = expr[1]
				while curExpr.tag == "HintAt" do
					hintAtExpr = curExpr
					curExpr = curExpr[1]
				end
				-- if poly cast is after invoke or call, then add ()
				if curExpr.tag == "Invoke" or curExpr.tag == "Call" then
					env:markParenWrap(curExpr.pos, curExpr.posEnd - 1)
				end
			end
			return true, expr
		else
			local nNode = env:makeErrNode(predictPos+1, "syntax error : expect a name")
			if not env.hint then
				nNode[2] = {
					pos=expr.pos,
					capture=buildInjectChunk(expr),
					script=env._subject:sub(expr.pos, predictPos - 1),
					traceList=env.scopeTraceList
				}
			else
				local innerList = {expr}
				local evalList = env:captureEvalByVisit(innerList)
				local hintSpace = env:buildIHintSpace("ShortHintSpace", innerList, evalList, expr.pos, expr.pos, predictPos-1)
				nNode[2] = {
					pos=expr.pos,
					capture=buildHintInjectChunk(hintSpace),
					script=env._subject:sub(expr.pos, predictPos-1),
					traceList=env.scopeTraceList
				}
			end
			-- print("scope trace:", table.concat(env.scopeTraceList, ","))
			error(nNode)
			return false
		end
	end)
end

local G = lpeg.P { "TypeHintLua";
	Shebang = lpeg.P("#") * (lpeg.P(1) - lpeg.P("\n"))^0 * lpeg.P("\n");
	TypeHintLua = vv.Shebang^-1 * vv.Chunk * (lpeg.P(-1) + throw("invalid chunk"));

  -- hint & eval begin {{{
	HintBegin = lpeg.Cmt(Cenv, function(_, i, env)
		if not env.hinting then
			env.hinting = true
			return true
		else
			error(env:makeErrNode(i, "syntax error : hint space only allow normal lua syntax"))
			return false
		end
	end);

	HintEnd = lpeg.Cmt(Cenv, function(_, _, env)
		assert(env.hinting, "hinting state error when lpeg parsing when success case")
		env.hinting = false
		return true
	end);

	EvalBegin = lpeg.Cmt(Cenv, function(_, i, env)
		if env.hinting then
			env.hinting = false
			return true
		else
			error(env:makeErrNode(i, "syntax error : eval syntax can only be used in hint"))
			return false
		end
	end);

	EvalEnd = lpeg.Cmt(Cenv, function(_, i, env)
		assert(not env.hinting, "hinting state error when lpeg parsing when success case")
		env.hinting = true
		return true
	end);

	NotnilHint = hintC.char("!");

	AtCastHint = hintC.wrap(
		false,
		symb("@") * cc("@") +
		symb("@!") * cc("@!") +
		symb("@>") * cc("@>") +
		symb("@?") * cc("@?"),
		vv.SimpleExpr) ;

	ColonHint = hintC.wrap(false, symb(":") * cc(false), vv.SimpleExpr);

	LongHint = hintC.long();

	StatHintSpace = hintC.wrap(true, symb("(@") * cc(nil),
		vv.AssignStat + vv.ApplyExpr + vv.DoStat + throw("StatHintSpace need DoStat or Apply or AssignStat inside"),
	symbA(")"));

	HintTerm = suffixedExprByPrimary(
		tagC.HintTerm(hintC.wrap(false, symb("(@") * cc(false), vv.EvalExpr + vv.SuffixedExpr, symbA(")"))) +
		vv.PrimaryExpr
	);

	HintPolyParList = Cenv * Cpos * symb("@<") * vvA.Name * (symb"," * vv.Name)^0 * symbA(">") * Cpos / function(env, pos, ...)
		local l = {...}
		local posEnd = l[#l]
		l[#l] = nil
		env:markDel(pos, posEnd - 1)
		return l
	end;

	AtPolyHint = hintC.wrap(false, symb("@<") * cc("@<"),
		vvA.SimpleExpr * (symb"," * vv.SimpleExpr)^0, symbA(">"));

	EvalExpr = tagC.HintEval(symb("$") * vv.EvalBegin * (vv.HintTerm + vvA.SimpleExpr) * vv.EvalEnd);

  -- hint & eval end }}}


	-- parser
	-- Chunk = tagC.Chunk(Cpos/parF.identDefENV * tagC.ParList(tagC.Dots()) * vv.Skip * vv.Block);
	Chunk = Cpos * vv.Skip * vv.Block/buildLoadChunk;

	FuncPrefix = kw("function") * (vv.LongHint + cc(nil));
	FuncDef = vv.FuncPrefix * vv.FuncBody / function(vHint, vFuncExpr)
		vFuncExpr.hintPrefix = vHint
		return vFuncExpr
	end;

	Constructor = (function()
		local Pair = tagC.Pair(
          ((symb"[" * vvA.Expr * symbA"]") + tagC.String(vv.Name)) *
          symb"=" * vv.Expr)
		local Field = Pair + vv.Expr
		local fieldsep = symb(",") + symb(";")
		local FieldList = (Field * (fieldsep * Field)^0 * fieldsep^-1)^-1
		return tagC.Table(symb("{") * lpeg.Cg(vv.LongHint*(symb(",") + symb(";"))^-1, "hintLong")^-1 * FieldList * symbA("}"))
	end)();

	IdentUse = Cpos*vv.Name*Cpos/parF.identUse;
	IdentDefT = Cpos*vv.Name*(vv.ColonHint + cc(nil))*Cpos/parF.identDef;
	IdentDefN = Cpos*vv.Name*cc(nil)*Cpos/parF.identDef;

	LocalIdentList = tagC.IdentList(vvA.IdentDefT * (symb(",") * vv.IdentDefT)^0);
	ForinIdentList = tagC.IdentList(vvA.IdentDefN * (symb(",") * vv.IdentDefN)^0);

	ExprListOrEmpty = tagC.ExprList(vv.Expr * (symb(",") * vv.Expr)^0) + tagC.ExprList();

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
	  return AddExpr * ((symb("..")/"..") * vv.ConcatExpr) ^-1 / exprF.binOp
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

	SimpleExpr = Cpos * (
						vv.String +
						tagC.Number(token(vv.Number)) +
						tagC.Nil(kw"nil") +
						tagC.False(kw"false") +
						tagC.True(kw"true") +
						vv.FuncDef +
						vv.Constructor +
						vv.SuffixedExpr +
						tagC.Dots(symb"...") +
						vv.EvalExpr
					) * (vv.AtCastHint + cc(nil)) * Cpos * Cenv/ exprF.hintExpr;

	PrimaryExpr = vv.IdentUse + tagC.Paren(symb"(" * vv.Expr * symb")");

	SuffixedExpr = suffixedExprByPrimary(vv.PrimaryExpr);

	ApplyExpr = lpeg.Cmt(vv.SuffixedExpr, function(_,_,exp) return exp.tag == "Call" or exp.tag == "Invoke", exp end);
	VarExpr = lpeg.Cmt(vv.SuffixedExpr, function(_,_,exp) return exp.tag == "Ident" or exp.tag == "Index", exp end);

	Block = tagC.Block(lpeg.Cmt(Cenv, function(_,pos,env)
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
	DoStat = tagC.Do(kw"do" * lpeg.Cg(vv.LongHint, "hintLong")^-1 * vv.Block * kwA"end");
	FuncBody = (function()
		local IdentDefTList = vv.IdentDefT * (symb(",") * vv.IdentDefT)^0;
		local DotsHintable = tagC.Dots(symb"..." * lpeg.Cg(vv.ColonHint, "hintShort")^-1)
		local ParList = tagC.ParList(IdentDefTList * (symb(",") * DotsHintable)^-1 + DotsHintable^-1);
		return tagC.Function(
			lpeg.Cg(Cpos/parF.identDefLet, "letNode")*
			lpeg.Cg(vv.HintPolyParList, "hintPolyParList")^-1*symbA("(") * ParList * symbA(")") *
			lpeg.Cg(vv.LongHint, "hintSuffix")^-1 * vv.Block * kwA("end"))
	end)();

	AssignStat = (function()
		local VarList = tagC.VarList(vv.VarExpr * (symb(",") * vv.VarExpr)^0)
		return tagC.Set(VarList * symb("=") * vv.ExprList)
	end)();

	RetStat = tagC.Return(kw("return") * vv.ExprListOrEmpty * symb(";")^-1);

	Stat = (function()
		local LocalFunc = vv.FuncPrefix * tagC.Localrec(vvA.IdentDefN * vv.FuncBody) / function(vHint, vLocalrec)
			vLocalrec[2].hintPrefix = vHint
			return vLocalrec
		end
		local LocalAssign = tagC.Local(vv.LocalIdentList * (symb"=" * vvA.ExprList + tagC.ExprList()))
		local LocalStat = kw"local" * (LocalFunc + LocalAssign + throw("wrong local-statement")) +
				Cenv * Cpos * kw"const" * vv.HintBegin * vv.HintEnd * (LocalFunc + LocalAssign + throw("wrong const-statement")) / function(env, pos, t)
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
			return Cpos * vv.FuncPrefix * FuncName * MethodName * Cpos * vv.FuncBody * Cpos / function (pos, hintPrefix, varPrefix, methodName, posMid, funcExpr, posEnd)
				funcExpr.hintPrefix = hintPrefix
				if methodName then
					table.insert(funcExpr[1], 1, parF.identDefSelf(pos))
					varPrefix = makeNameIndex(varPrefix, methodName)
				end
				return {
					tag = "Set", pos=pos, posEnd=posEnd,
					{ tag="VarList", pos=pos, posEnd=posMid, varPrefix},
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
		return vv.StatHintSpace +
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

function ParseEnv.new(vSubject)
	local self = setmetatable({
		hinting = false,
		scopeTraceList = {},
		_subject = vSubject,
		_posToChange = {},
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

function ParseEnv:getAstOrErr()
	return self._astOrErr
end

function ParseEnv:makeErrNode(vPos, vErr)
	return {
		tag="Error",
		pos=vPos,
		vErr
	}
end

function ParseEnv:buildIHintSpace(vTag, vInnerList, vEvalList, vRealStartPos, vStartPos, vFinishPos)
	local nHintSpace = {
		tag = vTag,
		pos = vRealStartPos,
		posEnd = vFinishPos + 1,
		evalScriptList = {},
		table.unpack(vInnerList)
	}
	local nEvalScriptList = nHintSpace.evalScriptList
	local nSubject = self._subject
	for _, nHintEval in ipairs(vEvalList) do
		nEvalScriptList[#nEvalScriptList + 1] = {
			tag = "HintScript",
			pos=vStartPos,
			posEnd=nHintEval.pos,
			[1] = nSubject:sub(vStartPos, nHintEval.pos-1)
		}
		nEvalScriptList[#nEvalScriptList + 1] = nHintEval
		vStartPos = nHintEval.posEnd
	end
	if vStartPos <= vFinishPos then
		nEvalScriptList[#nEvalScriptList + 1] = {
			tag="HintScript",
			pos=vStartPos,
			posEnd=vFinishPos+1,
			[1]=nSubject:sub(vStartPos, vFinishPos)
		}
	end
	return nHintSpace
end

-- @ hint for invoke & call , need to add paren
-- eg.
--   aFunc() @ Integer -> (aFunc())
-- so mark paren here
function ParseEnv:markParenWrap(vStartPos, vFinishPos)
	self._posToChange[vStartPos] = "("
	self._posToChange[vFinishPos] = ")"
end

-- hint script to be delete
function ParseEnv:markDel(vStartPos, vFinishPos)
	self._posToChange[vStartPos] = vFinishPos
end

-- local convert to const
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

function ParseEnv:captureEvalByVisit(vNode, vList)
	vList = vList or {}
	for i=1, #vNode do
		local nChildNode = vNode[i]
		if type(nChildNode) == "table" then
			if nChildNode.tag == "HintEval" then
				vList[#vList + 1] = nChildNode
			else
				self:captureEvalByVisit(nChildNode, vList)
			end
		end
	end
	return vList
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
			elseif nChange == "(" or nChange == ")" then
				local nLuaCode = nSubject:sub(nPreFinishPos + 1, nStartPos)
				nContents[#nContents + 1] = nLuaCode
				nContents[#nContents + 1] = nChange
				nPreFinishPos = nStartPos
			else
				error("unexpected branch")
			end
		end
	end
	nContents[#nContents + 1] = nSubject:sub(nPreFinishPos + 1, #nSubject)
	return table.concat(nContents)
end

-- return lua code or throw error
function ParseEnv.compile(vContent, vChunkName)
	vChunkName = vChunkName or "[anonymous script]"
	local nEnv = ParseEnv.new(vContent)
	local nAstOrErr = nEnv:getAstOrErr()
	if nAstOrErr.tag == "Error" then
		local nLineNum = select(2, vContent:sub(1, nAstOrErr.pos):gsub('\n', '\n'))
		local nMsg = vChunkName..":".. nLineNum .." ".. nAstOrErr[1]
		error(nMsg)
	else
		return nEnv:genLuaCode()
	end
end

-- return false, errorNode | return chunkNode
function ParseEnv.parse(vContent)
	local nEnv = ParseEnv.new(vContent)
	local nAstOrErr = nEnv:getAstOrErr()
	if nAstOrErr.tag == "Error" then
		return false, nAstOrErr
	else
		return nAstOrErr
	end
end

return ParseEnv
