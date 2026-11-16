TypeHintLua说明文档
TypeHintLua的语法分为两部分，一部分是Lua的语法，另一部分也是Lua的语法。
一、背景
1.	Lua是一门在游戏行业被广泛使用的语言。但它动态类型的特性不利于大型项目开发。
2.	市面上已经有一些工具尝试解决Lua的类型系统问题，包括：
a.	LuaLS：https://github.com/LuaLS/lua-language-server
b.	EmmyLua：https://github.com/EmmyLua/IntelliJ-EmmyLua
c.	Luau：https://github.com/Roblox/luau
d.	Teal：https://github.com/teal-language/tl
e.	TypedLua：https://github.com/andremm/typedlua
f.	TypeScriptToLua：https://github.com/TypeScriptToLua/TypeScriptToLua
3.	但以上工具都还不够好，目前在编程语言领域，这类问题最成功的解决方案是TypeScript，它比较好地解决了JavaScript的动态类型问题。而以上工具距离TypeScript都有不小差距，所以我开发了TypeHintLua，试图达到TypeScript的能力。
4.	编程语言的开发是一个长期的过程，虽然目前TypeHintLua还有很多问题，但眼下它已经勉强可用
二、项目地址
1.	TypeHintLua的项目地址：https://github.com/drinkwithwater/TypeHintLua
2.	TypeHintLua的playground：https://drinkwithwater.github.io/playground.html
3.	TypeHintLua的vscode插件：https://marketplace.visualstudio.com/items?itemName=drinkwithwater.TypeHintLua
三、使用方式
TypeHintLua的主要用法分为编译运行和类型检查：
1. 编译运行：
a.	下载thlua.lua：https://github.com/drinkwithwater/TypeHintLua/blob/master/thlua.lua
i.	注：该Lua代码可以无依赖运行，不过它会自动检查环境是否有lpeg库，如果有则可以运行地更快，否则会自动切成慢100倍的lulpeg库。
b.	使用 thlua.lua 编译 TypeHintLua 代码，可以翻译为lua代码，也可以直接编译为function：
Lua
local thlua = require "thlua"
local thlua_code = [[
(@print("hint space"))

const s = "hello world"
print(s)
]]
local lua_code = thlua.compile(thlua_code)
print(lua_code) --[[输出：

local s = "hello world"
print(s)

]]

local func = thlua.load(thlua_code)
func() --输出：hello world
c.	也可以直接使用thlua.patch，使得require可以直接加载.thlua文件。
i.	该过程会在package.searchers中增加一项，用来在package.path的相关路径上查找.thlua文件。
ii.	但因为lua一般运行在受到限制的环境中，patch中的处理方式常常不能能正确生效。
Lua
local thlua = require "thlua"
thlua.patch()
local sth = require "sth" -- 在未找到sth.lua或sth.so时，会去寻找sth.thlua
2. 类型检查：
a.	类型检查建议使用vscode插件TypeHintLua。
b.	在一个工程对多文件进行类型检查需要在工程目录下配置throot.thlua，用于在类型检查时处理require时的路径以及需要进行类型检查的文件。
i.	注：目前这个用法尚未稳定，后续可能会修改。
Lua
(@do
        local rawList = {
                "./",
        }
        local pathList = {}
        for _, rawPath in _G.pairs(rawList) do
                pathList[#pathList + 1] = rawPath .. "?.d.thlua"
                pathList[#pathList + 1] = rawPath .. "?.thlua"
        end
        setPath(_G.table.concat(pathList, ";"))
end)
-- main.thlua以及其require到的thlua、d.thlua文件都会进行类型检查
require "main"
四、语法扩展
假设你对Lua语言的语法已经有了足够的了解，TypeHintLua只是在Lua的语法基础之上做了一些扩展。
1. Hint语法
TypeHintLua扩展的语法构成了Hint Space
Lua

-- 在特定的地方能插入类型，提供类型检查功能，
local sth:Integer = 321
local a:Integer, b:String = 321,"rew"

-- 定义一个带有类型的函数
local function dosth(a:Integer):Ret(Integer)
    return a
end

-- 在(@)中可以插入一些语句，在其中能进行一些较为复杂的类型操作
-- (@)中支持赋值语句、函数调用和do语句。
-- (@)语句和一些插入类型的扩展语法统一构成了TypeHintLua的Hint Space
-- Hint Space中的Lua代码会按照一定的上下文运行。
(@let.Hello = Number) -- 将Number类型赋给Hello，let可以类比为lua的local。
(@print(321)) -- 打印321
(@do
    -- 定义一个结构体
    let.A = Struct {
        fds=Hello,
        rew=String,
        -- 通过let实现递归结构体
        recurField=OrNil(let.A),
    }

    -- 声明一个命名空间，命名空间可以自动串联多级字符串
    let.name = namespace()

    name.subfield.subfield2.Node = Struct {
        data=String,
        left=name.Node,
        right=name.Node,
    }

    -- 通过$可以取到lua空间中变量sth的类型，类似于c++中的 decltype
    print($sth)
    print($(nil@!let.A).fds)
end)


2. 类型转换
TypeHintLua提供'@'的语法用来在特定情况下做类型转换
Lua

-- @相关的符号用于类型转换

-- ‘@’ 表示类型协变，@右边的类型包含左边的类型。会扩大类型范围，是一种安全的转换
local castToA = 321 @ Integer

-- ‘@!’ 表示忽略空值并进行类型协变，是一种不安全的转换
castToA = nil @! Integer

-- ‘@>’ 表示类型逆变，@>左边的类型包含右边的类型。会收窄类型范围，是一种不安全的转换。
local contraCast:Union(1,2) = castToA @> Literal(1)

-- '@?' 表示强制设置类型，非常不安全。
local forceCast:Union(1,2) = "fdsfs" @? Literal(1)

-- '@<' '>' 用于实现泛型函数
local function dosth@<T>(a:T):Ret(T)
    return a
end

local t:Integer = dosth@<Integer>(321)

--对于索引表达式和变量表达式，可以后接一个'!'符号，用来表示忽略空值。
local i2s:Dict(Integer,String) = {} -- Dict类型索引的值类型返回时会自动添加空值类型，
local s:String = i2s[1]!

-- 定义一个结构体，并做强制类型转换
local dataA:Struct {fds=123, rew="fds"} = {
    fds=123,
    rew="fds",
}

--定义一个class
const function:class(let.Hello) make(a:Integer, b:String)
    -- 必须用.class来表示该构造函数中构造的table class是哪个
    return {.class
        a=a,
        b=b,
    }
end

3. 额外关键字
增加了continue和const的关键字。
Lua
-- const关键字
const a=321 -- const变量无法被重新赋值。

-- continue关键字
for i =1, 10 do
    continue
end
-- 翻译为lua代码时会自动补充为goto ::continue::，并在end前加上::continue::,即:
--[[
for i =1, 10 do
    goto ::continue::
::continue:: end
]]

五、类型系统
1. 基础类型
Lua
-- primitive types
const a:Boolean = true

const a:Number = 321

const a:String = "fdsfds"

-- literal type
const a:False = false

const a:Literal(321) = 321

const a:Literal("fds") = "fds"

-- thread
const a:Thread = coroutine.create(function()
end)

-- Truth
const a:Truth = math.random() > 0.5 and 321 or {}


2. 代数数据类型
Lua

-- union 类型
const t:Union(Integer, String) = math.random() > 0.5 and 321 or "fdsfs"

-- assign when t is table
if type(t) == "number" then
    const i:Integer = t
else
    const i:String = t
end

-- struct 类型 / interface 类型

(@do

-- define a struct
let.Point = Struct {
    x=Number,
    y=Number,
}

-- Interface和Struct的区别在于Interface的字段是只读的
let.IPoint = Interface {
    x=Number,
    y=Number,
}

end)

-- union object with other type
const t:Union(Point, String) = {
    x=321,
    y=123,
}

-- assign when t is table
if type(t) == "table" then
    t.x = 321
end


3. table类型
table类型分为3种：auto table，class table，open table
Lua
const t = {} -- 默认的table是auto table
const function:class(let.Sth) newSth() -- 使用构造函数定义一个class table
    return {.class}
end
const open = {.open} -- 定义一个open table
-- open table与auto table的区别在于open table的字段的类型可以发生变化
4. function类型
非泛型的函数分为3种类型：auto function，class function，open function
其中auto function由分为成员函数和非成员函数，open function又分为普通的open function和guard function
Lua
const function dosth(a:Integer) -- 一个auto function，auto function的参数和返回值类型是固定的
end
const function multi(a:Integer):Ret(True, Integer):Ret(False, String) -- auto function支持多种返回值
    if math.random() > 0.4 then
        return true, a
    else
        return false, "failed"
    end
end
const function:class(let.Sth) newSth() -- 定义一个class function，class function用于构造class table类型
    return {.class} -- :class的function与.class的table必须配套使用
end
const function.open makeTable(a) -- open function的参数可以不声明参数类型，且不能声明返回类型
    return { -- 每次调用时会构建新的auto table类型
        a=a
    }
end
-- guard function可以用于收窄变量的类型，
const function.open isString(v):isguard(String)
        return type(v) == "string"
end
const a:Truth = 321
if isString(a) then
        (@print($a))
        const s:String = a
end
5. 泛型
泛型分为两种：类型泛型，函数泛型，
Lua
(@do
    -- 类型泛型本质上就是Hint Space的函数。
    let.TPair = Template(function(A,B)
        return Struct {
            first=A,
            second=B
        }
    end)
end)
const a:TPair(Integer, String) = {
    first=321,
    second="321"
}

-- 函数泛型使用@<>语法定义
const function a@<A, B>(first:A, second:B):Ret(A,B)
    return first, second
end
-- 调用一个泛型函数
const i, s = a@<Integer, String>(321, "fds")
6. 面向对象
结合以上特性，我们可以将云风实现的面向对象机制（https://blog.codingnow.com/cloud/LuaOO）类型化：
https://github.com/drinkwithwater/TypeHintLua/blob/master/examples/4_2_oo_more.thlua
7. Hint Space中内置的一些函数、泛型、类型等：
Lua
(@do
-- import 获得另一份thlua代码的let
import("sth")

-- namespace 创建一个类型空间
let.game = namespace()

-- print，打印一些内容
print(312)

-- easymap构造一个类型映射对象
let.a2b = easymap()
a2b[Integer] = False

-- Literal，将一个number、string、boolean值转为类型
Literal(321)


-- 一些构造类型的方法
Union(1)
Struct {}
Interface {}
OrNil(321)
OrFalse(31)
Fn(String):Ret(Integer)

-- 内置的泛型
Dict(Integer, String)
IDict(String, Integer)
List(String)
IList(String)
Cond(True, String, Boolean) -- 条件控制泛型
-- 内置的类型
print(
False,
True,
Nil,
Any,
Truth
)

end)
8. 其他
nocheck的使用，表示跳过一个scope中的类型检查和计算
Plain Text
const function.nocheck dosth(a:Integer):Ret(Integer) -- nocheck的function必须要有类型。
end
do.nocheck
    const a:Integer = "fdsfs"
end
六、后续开发计划
1.	短期计划
a.	enum类型
b.	unity支持
c.	错误码
d.	unused变量提示
e.	meta event
2.	长期计划
a.	Effect system，副作用系统
b.	Type deduction，类型推导
c.	Tensor类型，named tensor


