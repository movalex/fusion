--local params = {...}

------------------------------------------------------------------		
-- Range tool - currently bolted onto a ChannelBoolean tool
------------------------------------------------------------------

local tool = comp:GetToolList(true)[1]
local newcontrol = {} -- initialise our table that will contain the controls we want to add
local newpublish = {} -- initialise a table to contain a publish
local numberofbuttons = tool.NumberOfButtons[fu.TIME_UNDEFINED]

-- define the controls to add
newcontrol[1] = {
					LINKS_Name = "Set "..numberofbuttons+1,
					LINKID_DataType = "Number",
					INPID_InputControl = "LabelControl",
					INP_Integer = true,
					LBLC_DropDownButton = true,
					INP_Default = 1,
					LBLC_NumInputs = 3,
					ICS_ControlPage = "Point"
				}
newcontrol[2] = {
					LINKS_Name = "Min "..numberofbuttons+1,
					LINKID_DataType = "Point",
					INPID_InputControl = "OffsetControl",
					INPID_PreviewControl = "CrosshairControl",
					ICS_ControlPage = "Point",
				}
newcontrol[3] = {
					LINKS_Name = "Max "..numberofbuttons+1,
					LINKID_DataType = "Point",
					INPID_InputControl = "OffsetControl",
					INPID_PreviewControl = "CrosshairControl",
					ICS_ControlPage = "Point",
					DefaultX = 0.5,
					DefaultY = 0.5,
				}
newcontrol[4] = {
					LINKS_Name = "Out "..numberofbuttons+1,
					LINKID_DataType = "Point",
					INPID_InputControl = "OffsetControl",
					ICS_ControlPage = "Point",
					IC_Visible         = false,
					DefaultX = 0.5,
					DefaultY = 0.5,
				}
				------------------------------------------------------------------		
-- FUNCTIONS - scavenged from the User Controls script on VFXPedia
------------------------------------------------------------------

function RefreshTool()
	local out = tool:FindMainOutput(1)
	local views = {}

	-- remember views
	if out then
		views = out:GetConnectedInputs()
	end

	-- kludge to force tool to show its new inputs
--	tool = tool.Refresh()	-- doesn't work :-(
	comp:StartUndo("Refresh tool")
	tool:Delete()
	comp:EndUndo(true)
	
	comp:Undo()
	comp:SetActiveTool(tool)

	-- reconnect views
	for i,v in pairs(views) do
		local o = v:GetConnectedOutput()
		if o == nil then
			ok = v:ViewOn(tool)	-- ConnectTo() works, but asserts
		end
	end
end

-- Validate the string as an ID
-- returns true/false, and a valid ID
function ValidID(id)
	local n1,n2

	if type(id) == "string" then
		id, n1 = string.gsub(id, "^[^%a]+", "")	-- no leading characters other than letters
		id, n2 = string.gsub(id, "[^%w_]", "")	-- no characters other than alphanums and _
	else
		id = "unknown"
		n1 = 1
	end
	
	return (n1 and n2 and n1+n2 == 0), id
end

-- Add a new UserControl
function AddControl(name, id, settings)
	local ctrls = tool.UserControls
	local valid

	-- make sure it's an ordered table
	if type(ctrls) ~= "table" or pairs({})(ctrls) == nil then
		ctrls = ordered() {}
	end

	valid, id = ValidID(id)

	ctrls[id] = settings
			
	if name ~= id then
		ctrls[id].LINKS_Name = name
	end

	tool.UserControls = ctrls

	return id
end


-- Remove/hide an existing control
function RemoveControl(id)
	if tool.UserControls[id] then
		local ctrls = tool.UserControls
		ctrls[id] = nil
		tool.UserControls = ctrls
	end
	if tool[id] then		-- input exists?
		if tool[id]:WindowControlsVisible() then
			tool[id]:HideWindowControls()
		end
		if tool[id]:ViewControlsVisible() then
			tool[id]:HideViewControls()
		end
	end
end

------------------------------------------------------------------		
-- MAIN
------------------------------------------------------------------
-- add our controls
for i, v in ipairs (newcontrol) do
	AddControl(v.LINKS_Name,v.LINKS_Name,v)
end
-- refresh the tool so our controls show and are available to the rest of our script.
RefreshTool()
-- add expression to our hidden input (output)
local _,currentout = ValidID(newcontrol[4].LINKS_Name)
--print (tool.Name)
local outexpression = tool.Name..".Max"..(numberofbuttons+1).."*"..tool.Name..".Range + "..tool.Name..".Min"..(numberofbuttons+1).."*(1-"..tool.Name..".Range)"

--tool[currentout]:SetExpression(outexpression)
--dump (tool[currentout].ID)

-- add a Publish modifier to our tool (thanks Bryan!)
tool:AddModifier(tool[currentout].ID, "PublishPoint")
local publish = tool[currentout]:GetConnectedOutput():GetTool()
--dump (publish.ID)
publish.Value:SetExpression(outexpression)

-- increase our button count
tool.NumberOfButtons = numberofbuttons+1
