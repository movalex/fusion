------------------------------------------------------------
-- bfSmartConnect -- $Revision: 0.2$
--
-- flow script
--
-- This scripts tries to figure out what you want to connect
-- and does the connection.
-- It's not that smart yet but further concepts will follow
-- Initial Idea by my collegue Fred Claﬂen
--
-- Used parts of dts74 / pingkings cutom hotkey script.
--
-- KNOWN ISSUES
--   Quite alot i bet, is pretty unefficient, hope your work is not
--
-- TODO
--   Use Positions if got equals
--   Sisterscript for Masks
--
-- RELEASE NOTES
-- November 13th, 2009 - Rev 0.2
--   Merge when two males collide -- say what?
-- November 12th, 2009 - Rev 0.1
--   First release
--
-- written by Blazej Floch (mail: labs bfloch com)
-- Last Update: November 13th, 2009

-- ### Workaround for Fusions Way of handling Inputs as Tools in GetToolList (hidden Tools are selected)

fusion = Fusion()
composition = fusion:GetCurrentComp()
flow = composition.CurrentFrame.FlowView


local oToollist = composition:GetToolList(true) -- # insert true or false here	

local oVisibleToollist = {}	-- # Table for(not-hidden) tools
for i = 1, table.getn(oToollist) do

	if oToollist[i]:GetAttrs().TOOLB_Visible == true then
		table.insert(oVisibleToollist , oToollist[i])
	end
end

-- ### Process oVisibleToollist

print ()
print ("bfSmartConnect preparing for duty!")
print ("----------------------------------")

if table.getn(oVisibleToollist) < 2 then
	print ("Select at least two tools")
	
	
else
	-- # Try to find the Male ;p
	
	
	
	oNoInput = {}	
	oGotInput = {}
	oSecInput = {}
	oSecFemInps = {}
	
	oFemales = {}
	oFemInps = {}
	
	for i = 1, table.getn(oVisibleToollist) do
		
		
		curInp = (oVisibleToollist[i]:FindMainInput(1))
		
		if curInp == nil then
		
			-- ### Method 1: tool has no input (creator)
			table.insert(oNoInput, i)
			
			
		else
		
			-- ### Method 2: Get the one that has an input
			
			if curInp:GetConnectedOutput() == nil then
				-- No connection
				table.insert(oFemales, i)
				table.insert(oFemInps, curInp)
				
			else
				-- Got an input connection
				table.insert(oGotInput, i)
				
				-- Check if he got a second input
				oInpList = oVisibleToollist[i]:GetInputList("Image")
				
				if table.getn(oInpList) > 2 then
					for j, inp in pairs(oInpList) do
						
						if inp~= curInp and inp:GetAttrs().INPS_ID ~= "EffectMask" then
							
							-- Got a second input
							-- Already occupied?
							if  (inp:GetConnectedOutput() == nil) then
								table.insert(oSecInput, i)
								table.insert(oSecFemInps, inp)
							end
	
						end
						
					end
				end
				
			end
		end
	end
	
	
	-- ### Start by Priorities
	
	-- Creator
	iCreators = table.getn(oNoInput)
	iConnected = table.getn(oGotInput)
	iFemales = table.getn(oFemales)
	iSecInp = table.getn(oSecInput)
	
	
	
	if iFemales == 0 then
	
		if iSecInp == 0 then
			print ("Nothing to connect to")
		else
			
			-- Use the secondary input
			oFemales = oSecInput
			iFemales = iSecInp
			oFemInps = oSecFemInps
			
			-- Remove the secondaries from possible Male
			for i, curFem in pairs(oFemales) do
				
				if iConnected > 0 then
					for j, curMale in pairs(oGotInput) do
						if curFem == curMale then
						
							table.remove(oGotInput, j)
							iConnected = iConnected - 1
						
						end
					end
				end
			end
		end
	end
	
	--print ("No Input: " .. table.getn(oNoInput))
	--print ("Got Input: " .. table.getn(oGotInput))
	--print ("......................................")
	--print ("Females: " .. table.getn(oFemales))

	
	if iFemales ~= 0 then
	
		if iCreators == 1 then
			iMale = oNoInput[1]
		
		elseif iCreators > 1 then
			-- ### Housten we have a problem -> more than one creator
		
		elseif iConnected == 1 then
			iMale = oGotInput[1]
			
		elseif iConnected > 1 then
			-- ### Housten we have a problem -> more than one Connected
		end

		if iMale == nil then
			
			print ("Sorry, I'm not smart enough")
		else
			-- ### Machoman
			for i = 1, iFemales do
				
				print ("Connecting " .. oVisibleToollist[iMale]:GetAttrs().TOOLS_Name .. " to " .. oVisibleToollist[oFemales[i]]:GetAttrs().TOOLS_Name)
				oFemInps[i]:ConnectTo(oVisibleToollist[iMale])
				
			end
		
		end
	else
		if (iCreators + iConnected) == 2 then 	
			-- ### Two males
			
			if composition.ActiveTool == nil then
				-- ### Use the first one
				CurTool = oVisibleToollist[1]
				
			else
				-- ### The active Tool is above selection! So make it male
				CurTool = composition.ActiveTool
				
			end
			
			CurXPos, CurYPos  = flow:GetPos(CurTool)
			
			if (fusion:GetPrefs().Comp.FlowView.Direction) == 1 then
			    AddX = 0.0
			    AddY = 1.0
			else
			    AddX = 1.0
			    AddY = 0.0
			end
			composition:Lock()
			outp = {}
			if CurTool then
			    tool = composition:AddTool("Merge",(CurXPos+AddX),(CurYPos+AddY))
			    flow:SetPos(tool, (CurXPos+AddX), (CurYPos+AddY))
			    local inp = tool:FindMainInput(1)
			    if inp and CurTool then
				inp:ConnectTo(CurTool)
			    end
			    for a,b in CurTool.Output:GetConnectedInputs() do
				if (CurTool.Output:GetConnectedInputs()[a]) then
				    outp[a] = CurTool.Output:GetConnectedInputs()[a]:GetTool()
				end
			    end
			    for c,d in outp do
				    for i,inp in outp[c]:GetInputList("Image") do
					if (outp[c]:GetInputList("Image")[i]:GetConnectedOutput()) then
					    con = (outp[c]:GetInputList("Image")[i]:GetConnectedOutput():GetTool())
					    if con == CurTool then
						outp[c]:GetInputList("Image")[i]:ConnectTo(tool.Output)
					    end
					 else
					   if (inp:GetAttrs().INPS_Name == "Foreground") then
					   	-- ### connect males
						for i, curSelTool in pairs(oVisibleToollist) do
							if curSelTool ~= CurTool then
								inp:ConnectTo(curSelTool)
							end
						end	
					   
					   end
					 end
					
				    end
			    end
			else
			    tool = composition:AddTool("Merge", composition.XPos, composition.YPos)
			end
			
			composition:Unlock()


			
			
		else
			print ("Sorry, I'm not smart enough")
		end
	
	end
end
