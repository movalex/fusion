ct = comp.CurrentTime
se_Name = 'se_LookAhead'
se_Slider = {
		LINKID_DataType = 'Number',
		LINKS_Name = se_Name,
		INP_Integer = false,
		INPID_InputControl = 'SliderControl',
		INP_MaxScale = 10,
		INP_Default = 1,
		INP_MinScale = -10,
		ICS_ControlPage = '3D',
		}
axes = {'X','Y','Z'}
targetControl = 'Transform3DOp.Target'
switch = 'Transform3DOp.UseTarget'

function AddControl()
	-- get any existing UserControls, so we don't overwrite them
	local ctrls = tool.UserControls

	-- make sure it's an ordered table
	if type(ctrls) ~= "table" or next(ctrls) == nil then
		ctrls = table.ordered()
	end
	
	-- what's in there?
--	dump(ctrls)
	
	-- define our slider-control
	ctrls['se_LookAhead'] = se_Slider
	
	-- set the new controls
	tool.UserControls = ctrls
end

function AddExpression()
	-- enable Use Target
	tool[switch][ct] = 1
	for n, pivot in pairs(axes) do
		exprString = [[self:GetValue("Transform3DOp.Translate.]] .. pivot .. [[",time+]] .. se_Name .. [[)]]
		tool[targetControl][pivot]:SetExpression(exprString)
	end
end

-- very, very basic error check!
if not tool[switch] then
	error('This script currently works on 3D Tools only. Please select a 3D Tool.')
end

-------------------------------------------------------------- MAIN
-- Add the LookAhead Slider
AddControl()
-- Add the Expression
AddExpression()
-- update Tool
tool:Refresh()
-- Goodbye
collectgarbage()
print("If you like this script, why not buy me a [coffee|bike|car|boat|swiss chalet] by donating on https://www.paypal.me/siredric")