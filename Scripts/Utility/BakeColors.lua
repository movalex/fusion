------------------------------------------------------------------------------
-- Bake Color script compation for ml_analyze macro
------------------------------------------------------------------------------

tool = comp:GetToolList(true)[1]
if not tool then
	tool = comp.ActiveTool
end
-- Ask the user how often to set keyframes
settings = composition:AskUser("Bake Colors", {
	{ "Step", "Slider", Integer = true, Default = 1, Min = 1, Max = 10},
	})

if settings then
    step = settings.Step
else
    step = 1
end

inputs = {"Color", "Green", "Blue"}
input_id ={"Input1", "Input2", "Input3"}

-- comp:Lock()
comp:StartUndo("Bake Colors")
current = 0
percents = {}

function addToSet(set, key)
    set[key] = true
end

function setContains(set, key)
    return set[key] ~= nil
end

for i, inp_name in ipairs(inputs) do
    local inpname = input_id[i]
    local inp = tool[inpname]
    local inpattrs = inp:GetAttrs()
    -- Get the range to process from render range
	local compattrs = comp:GetAttrs()
	local from = compattrs.COMPN_RenderStart
	local to = compattrs.COMPN_RenderEnd
    local range = to - from + 1
	-- Record keyframes into a table for later use
	local keyframes = {}
	for key = from, to, step do
		keyframes[key] = inp[key]
        current = current + step
        local percent = math.ceil((current * 100 / range)/3)
        if percent > 100 then
            percent = 100
        end
        if not setContains(percents, percent) then
            addToSet(percents, percent)
            print('processing: ' .. percent .. "%")
        end
	end
    modifier = comp:BezierSpline({})
	if tool[inpname]:GetExpression() then
		tool[inpname]:SetExpression(nil)
	end
	-- Now connect it up.  This removes the old modifier
	tool[inpname] = modifier
	-- Now set the keyframes back in
	for i = from, to, step do
		inp[i] = keyframes[i]
	end
    collectgarbage()
end
print("Done.")

comp:EndUndo(true)
