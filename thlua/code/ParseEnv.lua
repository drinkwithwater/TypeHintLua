--[[
This module implements a parser for Lua 5.3 with LPeg,
and generates an Abstract Syntax Tree.

Some code modify from
https://github.com/andremm/typedlua and https://github.com/Alloyed/lua-lsp
]]
local ok, lpeg = pcall(require, "lpeg")
if not ok then
	ok, lpeg = pcall(require, "lulpeg")
	if not ok then
		error("lpeg or lulpeg not found")
	end
end
lpeg.setmaxstack(1000)
lpeg.locale(lpeg)

local ParseEnv = {}
ParseEnv.__index = ParseEnv

local Cenv = lpeg.Carg(1)
local Cpos = lpeg.Cp()
local cc = lpeg.Cc
local select = select

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
	elseif str == "<" then
		return token(lpeg.P("<")*-lpeg.P("/<"))
	elseif str == ">" then
		return token(lpeg.P(">")*-lpeg.P(">"))
	elseif str == "/" then
		return token(lpeg.P("/")*-lpeg.P(">"))
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
	nameIndex=function(prefix, name)
		return { tag = "Index", pos=prefix.pos, posEnd=name.posEnd, prefix, name}
	end,
	binOp=function(e1, op, e2)
		if not op then
			return e1
		else
			return {tag = "Op", pos=e1.pos, posEnd=e2.posEnd, op, e1, e2 }
		end
	end,
	hintPoly=function(pos, e, hintShort, posEnd)
		return { tag = "HintAt", pos = pos, [1] = e, hintShort=hintShort, posEnd=posEnd}
	end,
	hintExpr=function(pos, e, hintShort, posEnd, env)
		if not hintShort then
			return e
		else
			local eTag = e.tag
			if eTag == "Dots" or eTag == "Call" or eTag == "Invoke" then
				env.codeBuilder:markParenWrap(pos, hintShort.pos-1)
			end
			-- both poly & expr cast use tag="HintAt"
			return { tag = "HintAt", pos = pos, [1] = e, hintShort = hintShort, posEnd=posEnd}
		end
	end
}

local parF = {
	identUse=function(vPos, vName, vNotnil, vPosEnd)
		return {tag="Ident", pos=vPos, posEnd=vPosEnd, [1] = vName, kind="use", notnil=vNotnil}
	end,
	identDef=function(vPos, vName, vHintShort, vPosEnd)
		return {tag="Ident", pos=vPos, posEnd=vPosEnd, [1] = vName, kind="def", hintShort=vHintShort}
	end,
	identDefSelf=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "self", kind="def", isHidden=true}
	end,
	identDefPolySelf=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "Self", kind="def", isHidden=true}
	end,
	identDefENV=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "_ENV", kind="def", isHidden=true}
	end,
	identDefLet=function(vPos)
		return {tag="Ident", pos=vPos, posEnd=vPos, [1] = "let", kind="def", isHidden=true}
	end,
}


local function buildLoadChunk(vPos, vBlock)
	return {
		tag="Chunk", pos=vPos, posEnd=vBlock.posEnd,
		letNode = parF.identDefLet(vPos),
		hintEnvNode = parF.identDefENV(vPos),
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
	})
	nChunk.injectNode = expr
	return nChunk
end

local function buildHintInjectChunk(shortHintSpace)
	local nChunk = buildLoadChunk(shortHintSpace.pos, {
		tag="Block", pos=shortHintSpace.pos, posEnd=shortHintSpace.posEnd,
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
	-- short hint
	wrap=function(isParen, pattBegin, pattBody, pattEnd)
		pattBody = Cenv * pattBody / function(env, ...) return {...} end
		return Cenv *
					Cpos * pattBegin * vv.HintBegin *
					Cpos * pattBody * vv.HintEnd *
					Cpos * (pattEnd and pattEnd * Cpos or Cpos) / function(env,p1,castKind,p2,innerList,p3,p4)
			local evalList = env:captureEvalByVisit(innerList)
			env.codeBuilder:markDel(p1, p4, isParen)
			local nHintSpace = env:buildIHintSpace(isParen and "ParenHintSpace" or "ShortHintSpace", innerList, evalList, p1, p2, p3-1)
			nHintSpace.castKind = castKind
			return nHintSpace
		end
	end,
	-- long hint
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
			env.codeBuilder:markDel(p1, posEnd)
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
					tag = "HintSpace",
					kind = "LongHintSpace",
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
	-- string to be true or false
	take=function(patt)
		return lpeg.Cmt(Cenv*Cpos*patt*Cpos, function(_, i, env, pos, posEnd)
			if not env:hinting() then
				env.codeBuilder:markDel(pos, posEnd)
				return true
			else
				return false
			end
		end) * vv.Skip
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
	HintAssertNot = lpeg.Cmt(Cenv, function(_, i, env)
		env:assertNotHint(i, "syntax error : hint space only allow normal lua syntax")
		return true
	end);

	HintBegin = lpeg.Cmt(Cenv, function(_, i, env)
		env:assertHintBegin(i, "syntax error : hint space only allow normal lua syntax")
		return true
	 end);

	HintEnd = lpeg.Cmt(Cenv, function(_, i, env)
		env:assertHintEnd(i, "hinting state error when lpeg parsing when success case")
		return true
	end);

	EvalBegin = lpeg.Cmt(Cenv, function(_, i, env)
		env:assertEvalBegin(i, "syntax error : eval syntax can only be used in hint")
		return true
	end);

	EvalEnd = lpeg.Cmt(Cenv, function(_, i, env)
		env:assertEvalEnd(i, "hinting state error when lpeg parsing when success case")
		return true
	end);

	NotnilHint = hintC.take(lpeg.P("!"));

	ValueConstHint = hintC.take(lpeg.P("const")*-vv.NameRest);

	AtCastHint = hintC.wrap(
		false,
		symb("@") * cc("@") +
		symb("@!") * cc("@!") +
		symb("@>") * cc("@>") +
		symb("@?") * cc("@?"),
		vv.SimpleExpr) ;

	ColonHint = hintC.wrap(false, symb(":") * cc(false), vv.SimpleExpr);

	LongHint = hintC.long();

	ParenHintSpace = hintC.wrap(true, symb("(@") * cc(nil),
		vv.DoStat + vv.SuffixedExprOrAssignStat + vv.EvalExpr + throw("ParenHintSpace need DoStat or Apply or AssignStat or EvalExpr inside"),
	symbA(")"));

	HintPolyParList = Cenv * tagC.HintPolyParList(symb("@<") * (
		lpeg.Cg(tagC.Dots(symb"..."), "dots") +
		vvA.IdentDefN * (symb "," * vv.IdentDefN) ^ 0 * lpeg.Cg(symb "," * tagC.Dots(symb "...") + cc(false), "dots")
	) * symbA(">")) / function(env, polyParList)
		env.codeBuilder:markDel(polyParList.pos, polyParList.posEnd)
		return polyParList
	end;

	AtPolyHint = hintC.wrap(false, symb("@<") * cc("@<"),
		vvA.SimpleExpr * (symb"," * vv.SimpleExpr)^0, symbA(">"));

	EvalExpr = tagC.HintEval(symb("$") * vv.EvalBegin * (vv.DoStat + vvA.SimpleExpr) * vv.EvalEnd);

  -- hint & eval end }}}


	-- parser
	-- Chunk = tagC.Chunk(Cpos/parF.identDefENV * tagC.ParList(tagC.Dots()) * vv.Skip * vv.Block);
	Chunk = Cpos * (lpeg.P("\xef\xbb\xbf")/function() end)^-1 * vv.Skip * vv.Block/buildLoadChunk;

	FuncPrefix = kw("function") * (vv.LongHint + cc(nil));
	FuncDef = vv.FuncPrefix * vv.FuncBody / function(vHint, vFuncExpr)
		vFuncExpr.hintPrefix = vHint
		return vFuncExpr
	end;

	Constructor = (function()
		local Pair = tagC.Pair(((symb"[" * vvA.Expr * symbA"]") + tagC.String(vv.Name)) * symb"=" * vv.Expr)
		local Field = Pair + vv.Expr
		local fieldsep = symb(",") + symb(";")
		local FieldList = (Field * (fieldsep * Field)^0 * fieldsep^-1)^-1
		return tagC.Table(symb("{") * lpeg.Cg(vv.LongHint, "hintLong")^-1 * FieldList * lpeg.Cg(Cpos, "closePos") * symbA("}"))
	end)();

	IdentUse = Cpos*vv.Name*(vv.NotnilHint * cc(true) + cc(false))*Cpos/parF.identUse;
	IdentDefT = Cpos*vv.Name*(vv.ColonHint + cc(nil))*Cpos/parF.identDef;
	IdentDefN = Cpos*vv.Name*cc(nil)*Cpos/parF.identDef;

	LocalIdentList = tagC.IdentList(vvA.IdentDefT * (symb(",") * vv.IdentDefT)^0);
	ForinIdentList = tagC.IdentList(vvA.IdentDefN * (symb(",") * vv.IdentDefN)^0);

	ExprListOrEmpty = tagC.ExprList(vv.Expr * (symb(",") * vv.Expr)^0) + tagC.ExprList();

	ExprList = tagC.ExprList(vv.Expr * (symb(",") * vv.Expr)^0);

	FuncArgs = tagC.ExprList(symb("(") * (vv.Expr * (symb(",") * vv.Expr)^0)^-1 * lpeg.Cg(Cpos, "closeParenPos") * symb(")") + vv.SimpleArgExpr);

	String = tagC.String(
		token(vv.LongString*lpeg.Cg(Cpos, "closePosEnd"))*lpeg.Cg(cc(true), "isLong") +
		token(vv.ShortString*lpeg.Cg(Cpos, "closePosEnd"))
	);

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

	SimpleArgExpr = Cpos * (vv.Constructor + vv.String) * (vv.AtCastHint + cc(nil)) * Cpos * Cenv / exprF.hintExpr;

	SimpleExpr = vv.SimpleArgExpr + Cpos * (
						tagC.Number(token(vv.Number)) +
						tagC.False(kw"false") +
						tagC.True(kw"true") +
						tagC.Nil(kw"nil") +
						vv.FuncDef +
						lpeg.Cmt(Cenv*vv.SuffixedExpr, function(_, pos, env, suffixedExpr)
							if suffixedExpr.tag == "HintSpace" then
								env:assertNotRootLevel(pos, "paren hint can't be an expr outside hint space or eval space")
							end
							return true, suffixedExpr
						end) +
						tagC.Dots(symb"...") +
						vv.EvalExpr
					) * (vv.AtCastHint + cc(nil)) * Cpos * Cenv/ exprF.hintExpr;


	SuffixedExpr = (function()
		local primaryExpr = vv.IdentUse + tagC.Paren(symb"(" * vv.Expr * symb")") + vv.ParenHintSpace
		local notnil = lpeg.Cg(vv.NotnilHint*cc(true) + cc(false), "notnil")
		local polyArgs = lpeg.Cg(vv.AtPolyHint + cc(false), "hintPolyArgs")
		-- . index
		local index1 = tagC.Index(cc(false) * symb(".") * tagC.String(vv.Name) * notnil)
		-- [] index
		local index2 = tagC.Index(cc(false) * symb("[") * vvA.Expr * symbA("]") * notnil)
		-- invoke
		local invoke = tagC.Invoke(cc(false) * symb(":") * tagC.String(vv.Name) * notnil * polyArgs * vvA.FuncArgs)
		-- call
		local call = tagC.Call(cc(false) * vv.FuncArgs)
		-- atPoly
		local atPoly= Cpos * cc(false) * vv.AtPolyHint * Cpos / exprF.hintPoly
		-- add completion case
		local succPatt = lpeg.Cmt(Cenv * primaryExpr * (index1 + index2 + invoke + call + atPoly)^0, function(_, pos, env, primary, ...)
				if ... then
					if primary.tag == "HintSpace" then
						env:assertNotRootLevel(pos, "paren hint can't take suffixed ouside hint space or eval space")
					end
					local firstExpr = primary
					for i=1, select("#", ...) do
						local secondExpr = select(i, ...)
						secondExpr.pos = firstExpr.pos
						secondExpr[1] = firstExpr
						firstExpr = secondExpr
					end
					return true, firstExpr
				else
					return true, primary
				end
			end)
		return lpeg.Cmt(Cpos*succPatt * Cenv * Cpos*((symb(".") + symb(":"))*cc(true) + cc(false)), function(_, _, pos, expr, env, posEnd, triggerCompletion)
			if not triggerCompletion then
				if expr.tag == "HintAt" then
					local curExpr = expr[1]
					while curExpr.tag == "HintAt" do
						curExpr = curExpr[1]
					end
					-- if poly cast is after invoke or call, then add ()
					if curExpr.tag == "Invoke" or curExpr.tag == "Call" then
						env.codeBuilder:markParenWrap(pos, curExpr.posEnd-1)
					end
				end
				return true, expr
			else
				local nNode = env:makeErrNode(posEnd+1, "syntax error : expect a name")
				if not env:hinting() then
					nNode[2] = {
						pos=pos,
						capture=buildInjectChunk(expr),
						script=env._subject:sub(pos, posEnd - 1),
						traceList=env.scopeTraceList
					}
				else
					local innerList = {expr}
					local evalList = env:captureEvalByVisit(innerList)
					local hintSpace = env:buildIHintSpace("ShortHintSpace", innerList, evalList, pos, pos, posEnd-1)
					nNode[2] = {
						pos=pos,
						capture=buildHintInjectChunk(hintSpace),
						script=env._subject:sub(pos, posEnd-1),
						traceList=env.scopeTraceList
					}
				end
				-- print("scope trace:", table.concat(env.scopeTraceList, ","))
				error(nNode)
				return false
			end
		end)
	end)();

	SuffixedExprOrAssignStat = Cenv*vv.SuffixedExpr * ((symb(",") * vv.SuffixedExpr) ^ 0 * symb("=") * vv.ExprList)^-1 / function(env, first,...)
		if not ... then
			return first
		else
			local nVarList = {
				tag="VarList", pos=first.pos, posEnd = 0,
				first, ...
			}
			local nExprList = nVarList[#nVarList]
			nVarList[#nVarList] = nil
			nVarList.posEnd = nVarList[#nVarList].posEnd
			for _, varExpr in ipairs(nVarList) do
				if varExpr.tag ~= "Ident" and varExpr.tag ~= "Index" then
					error(env:makeErrNode(first.pos, "syntax error: only identify or index can be left-hand-side in assign statement"))
				elseif varExpr.notnil then
					error(env:makeErrNode(first.pos, "syntax error: notnil can't be used on left-hand-side in assign statement"))
				end
			end
			return {
				tag="Set", pos=first.pos, posEnd=nExprList.posEnd,
				nVarList,nExprList
			}
		end
	end;

	ApplyOrAssignStat = Cenv*vv.SuffixedExprOrAssignStat/function(env,exprOrStat)
		if exprOrStat.tag == "Set" then
			return exprOrStat
		else
			if exprOrStat.tag == "Call" or exprOrStat.tag == "Invoke" then
				return exprOrStat
			elseif exprOrStat.tag == "HintSpace" and exprOrStat.kind == "ParenHintSpace" then
				return exprOrStat
			else
				error(env:makeErrNode(exprOrStat.pos, "syntax error: "..tostring(exprOrStat.tag).." expression can't be a single stat"))
			end
		end
	end;

	Block = lpeg.Cmt(Cenv, function(_,pos,env)
		if not env:hinting() then
			--local nLineNum = select(2, env._subject:sub(1, pos):gsub('\n', '\n'))
			--print(pos, nLineNum)
			local len = #env.scopeTraceList
			env.scopeTraceList[len + 1] = 0
			if len > 0 then
				env.scopeTraceList[len] = env.scopeTraceList[len] + 1
			end
		end
		return true
	end) * tagC.Block(vv.Stat^0 * vv.RetStat^-1) * lpeg.Cmt(Cenv, function(_,_,env)
		if not env:hinting() then
			env.scopeTraceList[#env.scopeTraceList] = nil
		end
		return true
	end);
	DoStat = tagC.Do(kw"do" * lpeg.Cg(vv.LongHint, "hintLong")^-1 * vv.Block * kwA"end");
	FuncBody = (function()
		local IdentDefTList = vv.IdentDefT * (symb(",") * vv.IdentDefT)^0;
		local DotsHintable = tagC.Dots(symb"..." * lpeg.Cg(vv.ColonHint, "hintShort")^-1)
		local ParList = tagC.ParList(IdentDefTList * (symb(",") * DotsHintable)^-1 + DotsHintable^-1);
		return lpeg.Cmt(Cenv*Cpos*
			(vv.HintPolyParList + cc(false)) *
			symbA("(") * ParList * symbA(")") *
			(vv.LongHint + cc(false)) *
			vv.Block * kwA("end")*Cpos, function(_, _, env, pos, hintPolyParList, parList, hintSuffix, block, posEnd)
				return true, {
					tag="Function", pos=pos, posEnd=posEnd,
					letNode=(not env:hinting()) and parF.identDefLet(pos),
					hintEnvNode=(not env:hinting()) and parF.identDefENV(pos),
					hintPolyParList=hintPolyParList,
					hintSuffix=hintSuffix,
					[1]=parList,[2]=block,
				}
			end)
		--[[return tagC.Function(
			lpeg.Cg(Cpos/parF.identDefLet, "letNode")*
			lpeg.Cg(vv.HintPolyParList, "hintPolyParList")^-1*symbA("(") * ParList * symbA(")") *
			lpeg.Cg(vv.LongHint, "hintSuffix")^-1 * vv.Block * kwA("end"))]]
	end)();

	RetStat = tagC.Return(kw("return") * vv.ExprListOrEmpty * symb(";")^-1);

	NameChain = lpeg.Cf(vv.IdentUse * (symb"." * tagC.String(vv.Name))^0, exprF.nameIndex);
	Stat = (function()
		local LocalFunc = vv.FuncPrefix * tagC.Localrec(vvA.IdentDefN * vv.FuncBody) / function(vHint, vLocalrec)
			vLocalrec[2].hintPrefix = vHint
			return vLocalrec
		end
		local LocalAssign = tagC.Local(vv.LocalIdentList * (symb"=" * vvA.ExprList + tagC.ExprList()))
		local LocalStat = kw"local" * (LocalFunc + LocalAssign + throw("wrong local-statement")) +
				Cenv * Cpos * kw"const" * vv.HintAssertNot * (LocalFunc + LocalAssign + throw("wrong const-statement")) / function(env, pos, t)
					env.codeBuilder:markConst(pos)
					t.isConst = true
					return t
				end
		local FuncStat = (function()
			local MethodName = symb(":") * tagC.String(vv.Name) + cc(false)
			return Cpos * vv.FuncPrefix * vv.NameChain * MethodName * Cpos * vv.FuncBody * Cpos / function (pos, hintPrefix, varPrefix, methodName, posMid, funcExpr, posEnd)
				funcExpr.hintPrefix = hintPrefix
				if methodName then
					-- member method sugar: add self ident for function parameter
					table.insert(funcExpr[1], 1, parF.identDefSelf(pos))
					-- member method sugar: add index for left side var
					varPrefix = exprF.nameIndex(varPrefix, methodName)
					-- member method sugar for polyPar
					local hintPolyParList = funcExpr.hintPolyParList
					local polySelf = parF.identDefPolySelf(pos)
					if hintPolyParList then
						table.insert(hintPolyParList, 1, polySelf)
					else
						funcExpr.hintPolyParList = {
							tag="HintPolyParList", pos=pos, posEnd=pos, dots=false, polySelf
						}
					end
				end
				return {
					tag = "Set", pos=pos, posEnd=posEnd,
					{ tag="VarList", pos=pos, posEnd=posMid, varPrefix},
					{ tag="ExprList", pos=posMid, posEnd=posEnd, funcExpr },
				}
			end
		end)()
		local function loopMark(loopNode, env)
			local blockNode = loopNode.tag == "Repeat" and loopNode[1] or loopNode[#loopNode]
			assert(blockNode.tag == "Block")
			local last = blockNode[#blockNode]
			if last then
				if last.tag == "Return" then
					env.codeBuilder:continueMarkLoopEnd(last.pos, blockNode.posEnd)
				else
					env.codeBuilder:continueMarkLoopEnd(false, blockNode.posEnd)
				end
			end
			return loopNode
		end
		local LabelStat = tagC.Label(symb"::" * vv.Name * symb"::")
		local BreakStat = tagC.Break(kw"break")
		local ContinueStat = Cenv*tagC.Continue(kw"continue")*vv.HintAssertNot/function(env,node)
			env.codeBuilder:continueMarkGoto(node.pos)
			return node
		end
		local GoToStat = tagC.Goto(kw"goto" * vvA.Name)
		local RepeatStat = tagC.Repeat(kw"repeat" * vv.Block * kwA"until" * vvA.Expr) * Cenv / loopMark
		local IfStat = tagC.If(kw("if") * vvA.Expr * kwA("then") * vv.Block *
			(kw("elseif") * vvA.Expr * kwA("then") * vv.Block)^0 *
			(kw("else") * vv.Block)^-1 *
			kwA("end"))
		local WhileStat = tagC.While(kw"while" * vvA.Expr * kwA"do" * lpeg.Cg(vv.LongHint, "hintLong")^-1 *  vv.Block * kwA"end") * Cenv / loopMark
		local ForStat = (function()
			local ForBody = kwA("do") * lpeg.Cg(vv.LongHint, "hintLong")^-1 * vv.Block
			local ForNum = tagC.Fornum(vv.IdentDefN * symb("=") * vvA.Expr * symbA(",") * vvA.Expr * (symb(",") * vv.Expr)^-1 * ForBody)
			local ForIn = tagC.Forin(vv.ForinIdentList * kwA("in") * vvA.ExprList * ForBody)
			return kw("for") * (ForNum + ForIn + throw("wrong for-statement")) * kwA"end" * Cenv / loopMark
		end)()
		local BlockEnd = lpeg.P("return") + "end" + "elseif" + "else" + "until" + lpeg.P(-1)
		return LocalStat + FuncStat + LabelStat + BreakStat + GoToStat + ContinueStat +
				 RepeatStat + ForStat + IfStat + WhileStat +
				 vv.DoStat + Cenv*Cpos*vv.ApplyOrAssignStat / function(env, pos, stat)
					env.codeBuilder:recordSuffixableStatPos(pos)
					return stat;
				 end + symb(";") + (lpeg.P(1)-BlockEnd)*throw("wrong statement")
	end)();

	-- lexer
	Skip     = (lpeg.space^1 + vv.Comment)^0;
	Comment  = Cenv*Cpos*
		lpeg.P"--" * (vv.LongString / function () return end + (lpeg.P(1) - lpeg.P"\n")^0)
		*Cpos/function(env, pos, posEnd) env.codeBuilder:markDel(pos, posEnd) return end;

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
		+ "then" + "true" + "until" + "while" + "const" + "continue"
		local Reserved = Keywords * -vv.NameRest
		return token(-Reserved * lpeg.C(RawName));
	end)();

}

local CodeBuilder = {}
CodeBuilder.__index = CodeBuilder

--- {{{ ---
do
	function CodeBuilder.new(vSubject, vEnv)
		local self = setmetatable({
			_subject = vSubject,
			_posToChange = {},
			_statPosSet = {},
			_env = vEnv,
		}, CodeBuilder)
		return self
	end

	-- '@' when hint for invoke and call, need to add paren
	-- eg.
	--   aFunc() @ Integer -> (aFunc())
	-- so mark paren here
	function CodeBuilder:markParenWrap(vStartPos, vFinishPos)
		self._posToChange[vStartPos] = function(vContentList, vRemainStartPos)
			vContentList[#vContentList + 1] = self._subject:sub(vRemainStartPos, vStartPos-1)
			vContentList[#vContentList + 1] = "("
			return vStartPos
		end
		self._posToChange[vFinishPos] = function(vContentList, vRemainStartPos)
			vContentList[#vContentList + 1] = self._subject:sub(vRemainStartPos, vFinishPos)
			vContentList[#vContentList + 1] = ")"
			return vFinishPos + 1
		end
	end

	-- hint script to be delete
	function CodeBuilder:markDel(vStartPos, vNextStartPos, vIsParenHint)
		self._posToChange[vStartPos] = function(vContentList, vRemainStartPos)
			-- 1. save lua code
			local nLuaCode = self._subject:sub(vRemainStartPos, vStartPos-1)
			vContentList[#vContentList + 1] = nLuaCode
			if vIsParenHint or self._statPosSet[vNextStartPos] then
				vContentList[#vContentList + 1] = ";"
			end
			-- 2. replace hint code with space and newline
			local nHintCode = self._subject:sub(vStartPos, vNextStartPos - 1)
			vContentList[#vContentList + 1] = nHintCode:gsub("[^\r\n\t ]", "")
			return vNextStartPos
		end
	end

	-- local -> const
	function CodeBuilder:markConst(vStartPos)
		self._posToChange[vStartPos] = function(vContentList, vRemainStartPos)
			vContentList[#vContentList + 1] = self._subject:sub(vRemainStartPos, vStartPos - 1)
			vContentList[#vContentList + 1] = "local"
			return vStartPos + 5
		end
	end

	function CodeBuilder:_insertChange(vInsert, vStartPos)
		return function(vContentList, vRemainStartPos)
			local nLuaCode = self._subject:sub(vRemainStartPos, vStartPos-1)
			vContentList[#vContentList + 1] = nLuaCode
			vContentList[#vContentList + 1] = vInsert
			vContentList[#vContentList + 1] = " "
			return vStartPos
		end
	end

	-- continue -> goto continue
	function CodeBuilder:continueMarkGoto(vStartPos)
		self._posToChange[vStartPos] = self:_insertChange("goto", vStartPos)
	end

	-- return xxx -> do return xxx end
	-- for end / repeat until / while end -> for ::continue:: end, repeat ::continue:: until, while ::continue:: end
	function CodeBuilder:continueMarkLoopEnd(vRetStartPos, vEndStartPos)
		if vRetStartPos then
			self._posToChange[vRetStartPos] = self:_insertChange("do", vRetStartPos)
			self._posToChange[vEndStartPos] = self:_insertChange("end ::continue::", vEndStartPos)
		else
			self._posToChange[vEndStartPos] = self:_insertChange("::continue::", vEndStartPos)
		end
	end

	function CodeBuilder:recordSuffixableStatPos(vStartPos)
		self._statPosSet[vStartPos] = true
	end

	function CodeBuilder:genLuaCode()
		local nSubject = self._subject
		local nPosToChange = self._posToChange
		local nChangePosList = {}
		for nChangePos, _ in pairs(nPosToChange) do
			nChangePosList[#nChangePosList + 1] = nChangePos
		end
		table.sort(nChangePosList)
		local nContents = {}
		local nRemainStartPos = 0
		for _, nChangePos in pairs(nChangePosList) do
			if nChangePos < nRemainStartPos then
				-- do nothing in hint space
			else
				nRemainStartPos = nPosToChange[nChangePos](nContents, nRemainStartPos)
			end
		end
		nContents[#nContents + 1] = nSubject:sub(nRemainStartPos, #nSubject)
		return table.concat(nContents)
	end
end
--- }}} ---

function ParseEnv.new(vSubject)
	local self = setmetatable({
		scopeTraceList = {},
		codeBuilder = nil,
		_hintLevel = 0,
		_subject = vSubject,
	}, ParseEnv)
	self.codeBuilder = CodeBuilder.new(vSubject, self)
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

function ParseEnv:hinting()
	return self._hintLevel % 2 == 1
end

function ParseEnv:assertNotRootLevel(vPos, vErrMsg)
	if self._hintLevel == 0 then
		error(self:makeErrNode(vPos, vErrMsg))
	end
end

function ParseEnv:assertNotHint(vPos, vErrMsg)
	if self._hintLevel % 2 == 1 then
		error(self:makeErrNode(vPos, vErrMsg))
	end
end

function ParseEnv:assertHintBegin(vPos, vErrMsg)
	local hintLevel = self._hintLevel
	if hintLevel % 2 == 0 then
		self._hintLevel = hintLevel + 1
	else
		error(self:makeErrNode(vPos, vErrMsg))
	end
end

function ParseEnv:assertHintEnd(vPos, vErrMsg)
	local hintLevel = self._hintLevel
	if hintLevel % 2 == 1 then
		self._hintLevel = hintLevel - 1
	else
		error(self:makeErrNode(vPos, vErrMsg))
	end
end

function ParseEnv:assertEvalBegin(vPos, vErrMsg)
	local hintLevel = self._hintLevel
	if hintLevel % 2 == 1 then
		self._hintLevel = hintLevel + 1
	else
		error(self:makeErrNode(vPos, vErrMsg))
	end
end

function ParseEnv:assertEvalEnd(vPos, vErrMsg)
	local hintLevel = self._hintLevel
	if hintLevel % 2 == 0 then
		self._hintLevel = hintLevel - 1
	else
		error(self:makeErrNode(vPos, vErrMsg))
	end
end

function ParseEnv:getAstOrErr()
	return self._astOrErr
end

function ParseEnv:makeErrNode(vPos, vErr)
	return {
		tag="Error",
		pos=vPos,
		posEnd=vPos,
		vErr
	}
end

function ParseEnv:buildIHintSpace(vTag, vInnerList, vEvalList, vRealStartPos, vStartPos, vFinishPos)
	local nHintSpace = {
		tag = "HintSpace",
		kind = vTag,
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
	return self.codeBuilder:genLuaCode()
end

local boot = {}
-- return luacode | false, errmsg
function boot.compile(vContent, vChunkName)
	vChunkName = vChunkName or "[anonymous script]"
	local nAstOrFalse, nCodeOrErr = boot.parse(vContent)
	if not nAstOrFalse then
		local nLineNum = select(2, vContent:sub(1, nCodeOrErr.pos):gsub('\n', '\n'))
		local nMsg = vChunkName..":".. nLineNum .." ".. nCodeOrErr[1]
		return false, nMsg
	else
		return nCodeOrErr
	end
end

-- return false, errorNode | return chunkNode, string
function boot.parse(vContent)
	local nEnv = ParseEnv.new(vContent)
	local nAstOrErr = nEnv:getAstOrErr()
	if nAstOrErr.tag == "Error" then
		return false, nAstOrErr
	else
		return nAstOrErr, nEnv:genLuaCode()
	end
end

local load = load
function boot.load(chunk, chunkName, ...)
	local f, err = load(chunk, chunkName, ...)
	if f then
		-- if lua parse success, just return
		return f
	end
	local luaCode, err = boot.compile(chunk, chunkName)
	if not luaCode then
		return false, err
	end
	local f, err = load(luaCode, chunkName, ...)
	if not f then
		return false, err
	end
	return f
end

local patch = false

-- patch for load thlua code in lua
function boot.patch()
	if not patch then
		local path = package.path:gsub("[.]lua", ".thlua")
		table.insert(package.searchers, function(name)
			local fileName, err1 = package.searchpath(name, path)
			if not fileName then
				return err1
			end
			local file, err2 = io.open(fileName, "r")
			if not file then
				return err2
			end
			local thluaCode = file:read("*a")
			file:close()
			return assert(boot.load(thluaCode, fileName))
		end)
		patch = true
	end
end

return boot
