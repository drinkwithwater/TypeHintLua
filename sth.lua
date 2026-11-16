
local Counters = {}
local Names = {}

local function hook (k)
	print(k)
	local f = debug.getinfo(2, "f").func
	if Counters[f] == nil then    -- first time `f' is called?
		Counters[f] = 1
		Names[f] = debug.getinfo(2, "Sn")
	else  -- only increment the counter
		Counters[f] = Counters[f] + 1
	end
end

debug.sethook(hook, "cr")

local function getname (func)
	local n = Names[func]
	if n.what == "C" then
		return n.name
	end
	local loc = string.format("[%s]:%s",
														n.short_src, n.linedefined)
	if n.namewhat ~= "" then
		return string.format("%s (%s)", loc, n.name)
	else
		return string.format("%s", loc)
	end
end

local function hello()
end

local co = coroutine.create(function()
debug.sethook(hook, "crl")
for i=1,100 do
	hello()
end
debug.sethook()
end)
coroutine.resume(co)

debug.sethook()
for func, count in pairs(Counters) do
	print(getname(func), count)
end
