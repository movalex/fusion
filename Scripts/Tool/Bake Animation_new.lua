------------------------------------------------------------------------------
-- Bake Animation, Revision: 3.2
--
-- Tool Script
--
-- This tool script is used to 'bake' the animation of any animated control into
-- a single value per frame. When run, a dialog listing all controls driven by a
-- path, spline or modifier will appear. Select the control you want to bake, as
-- well as the interval you want to use. An interval of 1 is default, representing
-- one value per frame.
--
-- When you select OK, Fusion will obtain the value of that control at each frame,
-- and apply it to a new path or polyline as appropriate. It will then replace the
-- old animation or modifier applied to the control with the newly created path or
-- spline.
--
-- You could use this script to convert the output of a Shake modifier to a path for
-- hand tweaking, or to obtain an editable spline of the Unsteady size of a
-- tracker....
--- rev 3.2 michael vorberg (mv@empty98.de) changes for FU9
------------------------------------------------------------------------------


if not tool then
	tool = composition.ActiveTool
	if not tool then
		composition:AskUser("Tool Script Error", {
			{"description", "Text", Lines=5, Default="This is a tool script, you must select a tool in the flow to run this script", ReadOnly=true, Wrap=true},
		})

		do return end
	end
end



-- We can't bake DT_Image or DT_Mask (and possibly others...)
unbakeable = { Image = true, Mask = true, Particles = true, DataType3D = true }

-- Generate a list of inputs that are animated
inputs = {}
input_id = {}
for key,inp in pairs(tool:GetInputList()) do
	if inp:GetConnectedOutput() or inp:GetExpression() then
		if not unbakeable[inp:GetAttrs().INPS_DataType] then
			table.insert(inputs, inp.Name)
			table.insert(input_id, inp.ID)
		end
	end
end

if #inputs == 0 then
	composition:AskUser("Nothing to Bake", {
	{"description", "Text", Lines=5, Default="This tool has no inputs which can be baked by this script.", ReadOnly=true, Wrap=true},
	})

	do return end
end

-- Ask the user which input, and how often to set keyframes
settings = composition:AskUser("Bake Animation", {
	{ "Input", "Dropdown", Options = inputs },
	{ "Step", "Slider", Integer = true, Default = 1, Min = 1, Max = 10},
	})

if settings then
	composition:Lock()
	composition:StartUndo("Bake Animation")

	local inpname = input_id[settings.Input+1]
	local inp = tool[inpname]
	local inpattrs = inp:GetAttrs()

	-- Get the range to process from render range
	local compattrs = composition:GetAttrs()
	local from = compattrs.COMPN_RenderStart
	local to = compattrs.COMPN_RenderEnd
	local step = settings.Step

	-- Record keyframes into a table for later use
	local keyframes = {}
	print("Recording "..(to-from+1)/step.." keyframes from "..inp.Name.."...")
	for i=from,to,step do
		keyframes[i] = inp[i]
	end

	-- Create an appropriate modifier.
	-- We assume BezierSpline unless it's a DT_Point, then we use a Path

	if inpattrs.INPS_DataType == "Point" then
		modifier = comp:Path({})
	else
		modifier = comp:BezierSpline({})
	end

	if tool[inpname]:GetExpression() then
		tool[inpname]:SetExpression(nil)
	end

	-- Now connect it up.  This removes the old modifier
	tool[inpname] = modifier

	-- Now set the keyframes back in
	print("Baking keyframes...")
	for i=from,to,step do
		inp[i] = keyframes[i]
	end
	print("Done.")

	composition:EndUndo(true)
	composition:Unlock()
end




