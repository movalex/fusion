------------------------------------
-- Split RGB Matte Passes Script
-- 1.4

-- written by Tim Little for Fusion 6.4 (timhlittle@gmail.com)
-- timhlittle.prosite.com

-- UPDATE LOG


-- v1.4
-- Use Channel booleans instead of BG node to maintain the image size of source tool

-- v1.2
-- Cleaned up code and made changing the String Phrase and Flow Direction easier

-- v1.1
-- BG nodes are created and placed in flow using XY values instead of AddTool()
------------------------------------


-----------------------------------------------------------------------------------------
--	DEFINE VARIABLES
-----------------------------------------------------------------------------------------

fusion = Fusion()
composition = fusion:GetCurrentComp()
flow = composition.CurrentFrame.FlowView

-----------------------------------------------------------------------------------------
--	DEFINE FUNCTIONS
-----------------------------------------------------------------------------------------


function splitRGBPasses(sourceTool, redChannelNameInput, greenChannelNameInput, blueChannelNameInput)

	comp:Lock()

	if sourceTool ~= nil then

		comp:SetActiveTool(sourceTool)

		-- Define String Variable for appending to node name
		stringPhrase = "_MAT"

		-- Define Variables for Tool Placement
		count = 1
		if tiles == true then
			y_pos_add = 3
		else
			y_pos_add = 1
		end

		-- cdir variable controls flow direction. 1 for horizontal, 0 for vertical
		cdir = 1

		flow=comp.CurrentFrame.FlowView
		org_x_pos, org_y_pos = flow:GetPos(sourceTool)
		_cfs = {}
		--_cfs = myscriptprefs('read')


		ret = {}

		-- Store Width and Height to eventually ensure the BG node is the same size as the input
		sourceHeight = sourceTool:GetAttrs("TOOLI_ImageHeight")
		sourceWidth = sourceTool:GetAttrs("TOOLI_ImageWidth")

		--// RED //--
		if redChannelNameInput ~= nil then

			myBool = composition:ChannelBoolean()

			flow:SetPos(myBool, org_x_pos + (count * cdir), org_y_pos + (y_pos_add * count * (1 - cdir)))
			count = count + 1

			myBool.Background = sourceTool

			myBool.ToRed = 5 -- (Red BG)
			myBool.ToGreen = 5 -- (Red BG)
			myBool.ToBlue = 5 -- (Red BG)
			myBool.ToAlpha = 5 -- (Red BG)

			myBool.TileColor = {R = .75, G = 0, B = 0}
			myBool.TextColor = {R = 1, G = 1, B = 1}

			myBool:SetAttrs({TOOLS_Name = (redChannelNameInput .. stringPhrase)})

		end

		--// GREEN //--
		if greenChannelNameInput ~= nil then

			myBool = composition:ChannelBoolean()

			flow:SetPos(myBool, org_x_pos + (count * cdir), org_y_pos + (y_pos_add * count * (1 - cdir)))
			count = count + 1

			myBool.Background = sourceTool

			myBool.ToRed = 6 -- (Green BG)
			myBool.ToGreen = 6 -- (Green BG)
			myBool.ToBlue = 6 -- (Green BG)
			myBool.ToAlpha = 6 -- (Green BG)

			myBool.TileColor = {R = 0, G = .75, B = 0}
			myBool.TextColor = {R = 0, G = 0, B = 0}

			myBool:SetAttrs({TOOLS_Name = (greenChannelNameInput .. stringPhrase)})

		end

		--// BLUE //--
		if blueChannelNameInput ~= nil then

			myBool = composition:ChannelBoolean()

			flow:SetPos(myBool, org_x_pos + (count * cdir), org_y_pos + (y_pos_add * count * (1 - cdir)))
			count = count + 1

			myBool.Background = sourceTool

			myBool.ToRed = 7 -- (Blue BG)
			myBool.ToGreen = 7 -- (Blue BG)
			myBool.ToBlue = 7 -- (Blue BG)
			myBool.ToAlpha = 7 -- (Blue BG)

			myBool.TileColor = {R = 0, G = 0, B = .75}
			myBool.TextColor = {R = 1, G = 1, B = 1}

			myBool:SetAttrs({TOOLS_Name = (blueChannelNameInput .. stringPhrase)})
		end
		comp:Unlock()
	else
		error (sourceTool .. " could not be found. Invalid input")
	end
	wait(1)
	comp:Unlock()
end


-----------------------------------------------------------------------------------------
--	EXECUTE SCRIPT
-----------------------------------------------------------------------------------------

for i, tool in ipairs(composition:GetToolList(true)) do -- iterate through selected tools in the comp

	if tool ~= nil then

		toolName = tool.Name

		--comp.CurrentFrame:ViewOn(1) -- clear view 1
		--comp.CurrentFrame:ViewOn(tool, 1) --view tool in Top Left viewer Window

		print "Launching UI"

		--=============================================================================================--
		--// Pop-up Window //--

		ret = composition:AskUser("Split RGB Matte Passes 1.3",
				{
				--{"Instructions:","Text", Default = "\n- Choose new file for the selected loader\n- The script will update other loaders that share the same file\n", 		ReadOnly=true, Lines=3,Width=2.5},
				{"Selected Tool:","Text",Lines =1, ReadOnly = true, Default = toolName },
				{"RED:","Text", Lines =1, ReadOnly=false, Default = ""},
				{"GREEN:","Text", Lines =1, ReadOnly=false, Default = ""},
				{"BLUE:","Text", Lines =1, ReadOnly=false, Default = ""},
				})

		--// Button Handling for the User Interface //--
		-- Check to see if the user cancelled
		if not ret then
			print("Cancelled")
			dialogCancel = true
		else

		--// Store User Response

		-- Define the file to be converted
			redChannelNameInput = ret["RED:"]
			if redChannelNameInput == "" then redChannelNameInput = nil end

			greenChannelNameInput = ret["GREEN:"]
			if greenChannelNameInput == "" then greenChannelNameInput = nil end

			blueChannelNameInput = ret["BLUE:"]
			if blueChannelNameInput == "" then blueChannelNameInput = nil end

			-------------------------------
			print (redChannelNameInput)
			print (greenChannelNameInput)
			print (blueChannelNameInput)

			if dialogCancel ~= true then
				splitRGBPasses(tool, redChannelNameInput, greenChannelNameInput, blueChannelNameInput)
			end
		end

		--// Pop-up Window to Let User Know Script is Complete //--
		ret = composition:AskUser("Script Complete!",{})
		print "============== SCRIPT END =============="

	else
			--// Pop-up Window to Let User Know Script is Complete //--
			ret = composition:AskUser("Please select a tool before running script",{})
			print "============== PLEASE SELECT A TOOL  =============="
	end

end



