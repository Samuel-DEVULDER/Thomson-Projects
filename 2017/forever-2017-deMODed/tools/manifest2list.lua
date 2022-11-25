#!tools/lua52.exe

file = io.open(arg[1],"r")
cpt  = -2
bin  = ""
mod  = nil
KEY  = '1'
while true do
	local line = file:read("*line")
	if line==nil then break end
	if line:match("^%s*#") then
		line = line:gsub("^%s*#%s*(.-)%s*$","%1")
		if not mod then 
			mod = cpt>=1 and line:match(" data ") and {} or mod
		-- elseif line:upper():match("END OF LIST.*") then	
			-- break
		else 
			local key,txt = line:match("^(.)%s+(.*)$")
			if key and (mod[3] or " "):len()>0 then
				for _,v in ipairs(mod) do
					bin=bin..v..string.char(0) 
				end
				print(line)
				if key=='_' then
					key = KEY
					KEY = KEY=='9' and 'A' or string.char(KEY:byte()+1)
				end
				mod = {key..txt,"",""}
			elseif (mod[3] or "")=="" then
				print(line)
				mod[2] = mod[2]..line
			end
		end
	elseif line:match("^%s*%d") then
		cpt = cpt + 1
		if mod then 
			print(" "..cpt)
			mod[3]=mod[3]..string.char(cpt) 
		end
	end
end
for _,v in ipairs(mod) do
	bin=bin..v..string.char(0) 
end
file:close()

if bin:len()>0 then
	bin = bin..string.char(0)
	file = io.open(arg[2],"wb")
	file:write(string.char(0,math.floor(bin:len()/256),bin:len()%256,0,0)..
			   bin..
			   string.char(255,0,0,0,0))
	file:close()
end
