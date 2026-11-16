local function find()
	for i=1,3 do
		if i==1 then goto continue end
		do return i
	end ::continue:: end
end
assert(find()==2)
print('ok')
