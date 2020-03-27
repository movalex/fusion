------------------------------------------------------------
-- 
--
-- Set tools to passthrough/process according to their 'priority level'.
-- This level is assigned by putting PL1, PL2,...PL4 in the tool's info-tab.
--
-- place in Fusion:\Scripts\Comp 
--
-- copied & pasted by SirEdric (Eric@SirEdric.de), March 2007
------------------------------------------------------------


GeneralOpt={"Do Not Change", "Pass Through", "Process"}
SwitchOpt={"", "true", "false"}
MyCnt=0
if not comp then
    comp = fu:GetCurrentComp()
end
ret = comp:AskUser("SirEdric's Priority Pasthrough", {	
	{"PLevel1",  "Dropdown", Options = GeneralOpt},
	{"PLevel2",  "Dropdown", Options = GeneralOpt},
	{"PLevel3",  "Dropdown", Options = GeneralOpt},
	{"PLevel4",  "Dropdown", Options = GeneralOpt},
	{"Selected", Name = "Affect Selected Tools Only", "Checkbox", Default = 0},
	})

if ret then
	print()
	print("SE_PPassthrough is about to change...")
	print("...PLevel1 to ["..GeneralOpt[ret.PLevel1+1].."]")
	print("...PLevel2 to ["..GeneralOpt[ret.PLevel2+1].."]")
	print("...PLevel3 to ["..GeneralOpt[ret.PLevel3+1].."]")
	print("...PLevel4 to ["..GeneralOpt[ret.PLevel4+1].."]")
	if ret.Selected==1 then
		print("...... *** on selected tools only! ***")
	end
	print("---------------------------------------------------")
	print()

	-- ((ret.Selected ==1)) will return true if the 
	-- selected checkbox is enabled.....
	
	for i, tool in ipairs(composition:GetToolList((ret.Selected) == 1)) do
		id = tool:GetAttrs().TOOLS_RegID
		MyName = tool:GetAttrs().TOOLS_Name
		
		if tool.Comments then --does the tool have a Comments tab?

			if string.find(tool.Comments[TIME_UNDEFINED], "PL1") then
				MyCnt=MyCnt+1
				print("Changing "..MyName.." Options:")
				print(ret.PLevel1)
				if ret.PLevel1 == 1 then
					print("PLevel1 set to Passthrough")
					tool:SetAttrs({TOOLB_PassThrough = true})
				end
				if ret.PLevel1 == 2 then 
					print("PLevel1 set to Process")
					tool:SetAttrs({TOOLB_PassThrough = false})
				end
			end

			if string.find(tool.Comments[TIME_UNDEFINED], "PL2") then
				MyCnt=MyCnt+1
				print("Changing "..MyName.." Options:")
				print(ret.PLevel2)
				if ret.PLevel2 == 1 then
					print("PLevel2 set to Passthrough")
					tool:SetAttrs({TOOLB_PassThrough = true})
				end
				if ret.PLevel2 == 2 then 
					print("PLevel2 set to Process")
					tool:SetAttrs({TOOLB_PassThrough = false})
				end
			end
		
			if string.find(tool.Comments[TIME_UNDEFINED], "PL3") then
				MyCnt=MyCnt+1
				print("Changing "..MyName.." Options:")
				print(ret.PLevel3)
				if ret.PLevel3 == 1 then
					print("PLevel3 set to Passthrough")
					tool:SetAttrs({TOOLB_PassThrough = true})
				end
				if ret.PLevel3 == 2 then 
					print("PLevel1 set to Process")
					tool:SetAttrs({TOOLB_PassThrough = false})
				end
			end

			if string.find(tool.Comments[TIME_UNDEFINED], "PL4") then
				MyCnt=MyCnt+1
				print("Changing "..MyName.." Options:")
				print(ret.PLevel4)
				if ret.PLevel4 == 1 then
					print("PLevel4 set to Passthrough")
					tool:SetAttrs({TOOLB_PassThrough = true})
				end
				if ret.PLevel4 == 2 then 
					print("PLevel4 set to Process")
					tool:SetAttrs({TOOLB_PassThrough = false})
				end
			end
		end


		
	end
	if MyCnt==0 then
		print ("No tools have been influenced")
		print ("Seems as if there are no 'PL1', 'PL2', 'PL3' or 'PL4' in the comments-tabs.")
	else
		print(MyCnt .. " tools have been processed")
	end
end
