----------------------------------------------------------------------------------
-- renameLoaders Version:1.1
--
-- Digital Fusion script
--
-- This script renames all the loader to their folder name if it matches the catch word
-- To do: 
--	- option to set the step of counter (if needed)
-- 	
--
-- written by : Raja v (rajavijayaraman@gmail.com)
-- written    : Oct. 26, 2009

-- This script is freeware, can be freely used and modified, with proper credits.  
-- If you use this script, and have any comments or issues feel free to contact me
-- on the above email adress.
--
----------------------------------------------------------------------------------

-- Add Catch Word

defCatch = "Amb,Key,Occ,zDepth,Fill,amb,key,occ,fill"

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- Default Catch


myDialog = composition:AskUser("Rename Loader", { 
		{"useCatchWord",Name="Use Catch Words", "Checkbox", Default = 0},
          {"DefCatch", Name="Catch Words","Text", ReadOnly = false, Lines = 5, Wrap = true, Default = defCatch},
           {"renFolder",Name="Rename 2 Parent Folder", "Checkbox", Default = 1}
           } )

if myDialog == nil then
	print("Ok!Dude")
else
	function split_myCatch(str)
		return split(str,'[,]+')
	end
	
	function split_path(str)
		return split(str,'[\\/]+')
	end
						
	print(myDialog["renFolder"])
	
	catches = split_myCatch(myDialog["DefCatch"])
	loaderlist = eyeon.GetLoaders(composition)
	for i, tool in loaderlist do 
		attrs = tool:GetAttrs() 
		if attrs["TOOLST_Clip_Name"] then
			for j = 1, table.getn(attrs["TOOLST_Clip_Name"]) do 
				tmpPath=attrs["TOOLST_Clip_Name"][j]
				if myDialog["useCatchWord"]==1 then
				for i,key in catches do
					if string.find (tmpPath, key) then						
						pathTable=split_path(tmpPath)
						for j,catchWord in pathTable do
							--print (catchWord)
							if string.find (catchWord, key) then
								--print (key)
								tool:SetAttrs({TOOLB_NameSet = true})
								if myDialog["renFolder"] == 1 then
									tool:SetAttrs({TOOLS_Name= catchWord})
								else
									tool:SetAttrs({TOOLS_Name= key})
								end
							end	
						end
					end
				end
				else
				pathTable=split_path(tmpPath)
				tmpInd=table.getn(pathTable)
				
				tool:SetAttrs({TOOLB_NameSet = true})
				tool:SetAttrs({TOOLS_Name= pathTable[tmpInd-1]})
				
				end
			
			end
		
		end
	end
end
