------------------------------------------------------------------------------
--[[
Bake Colors utility script for Color Analyzer Macro

Copyright © 2024 Alexey Bogomolov

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
------------------------------------------------------------------------------


function GetStep()
    -- Ask the user how often to set keyframes
    settings = composition:AskUser("Bake Colors", {
        { "Step", "Slider", Integer = true, Default = 1, Min = 1, Max = 10},
    })

    if not settings then
        print("Cancelled.")
        return
    end
    step = settings.Step
    comp:SetData("ColorAnalyzer.settings")
    return step
end

function AddToSet(set, key)
    set[key] = true
end

function SetContains(set, key)
    return set[key] ~= nil
end

local lastPercent = -1 -- Initialize with a value that will never be a valid percent

function UpdateProgress(currentInputIndex, totalInputs, currentKeyIndex, totalKeys)
    local totalProgressSteps = totalInputs * totalKeys
    local currentProgressStep = (currentInputIndex - 1) * totalKeys + currentKeyIndex
    local percent = math.floor((currentProgressStep / totalProgressSteps) * 100)
    -- Update and print the progress only if it has changed
    if percent ~= lastPercent then
        print("Baking Colors: " .. percent .. "%")
        lastPercent = percent -- Update the lastPercent to the current percent
    end
end


function Process(step)
    local input_id = {"Red", "Green", "Blue"}
    local tool = comp:GetToolList(true)[1] or comp.ActiveTool
    local compAttrs = comp:GetAttrs()
    local from = compAttrs.COMPN_RenderStart
    local to = compAttrs.COMPN_RenderEnd
    local compRange = to - from + 1
    local totalInputs = #input_id
    settings = tool:SaveSettings()
    
    tools = tool:GetChildrenList(false)
    for i, t in ipairs(tools) do
        settings = t:SaveSettings()
        print(t.ID)
        comp:SetData("ColorAnalyzer."..t.Name, settings)
    end
    comp:SetData("ColorAnalyzer.settings", settings)


    comp:StartUndo("Bake Colors")

    for i, inputName in ipairs(input_id) do
        local toolInput = tool[inputName]
        local inputAttrs = toolInput:GetAttrs()
        -- Get the compRange to Process from render compRange
        -- Record keyframes into a table for later use
        local keyframes = {}
        local totalKeys = math.ceil((to - from) / step) + 1
        for key = from, to, step do
            keyframes[key] = toolInput[key]
            local currentKeyIndex = math.ceil((key - from) / step) + 1
            UpdateProgress(i, totalInputs, currentKeyIndex, totalKeys)
        end
        -- -- Remove Expressions
        if tool[inputName]:GetExpression() then
            tool[inputName]:SetExpression(nil)
        end
        -- -- This removes the Probe modifier
        tool[inputName] = comp:BezierSpline({})
        -- Now set the keyframes back in
        for i = from, to, step do
            toolInput[i] = keyframes[i]
        end
    end
    comp:EndUndo()

    -- fusion.CacheManager:Purge()
    print("\nDone!")
end



step = GetStep()

if step then
    Process(step)
end