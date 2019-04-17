--[[
-------------------------------------------------------------------------------------------------------------------------
SaverRanges

this script animates the range in which the saver is active

it builds a list of all savers in the comp and let the user deside which should be active and in which range
by default all savers are active (besides if the are in passthrough or not) and the renderange is the comp renderrange

v0.2.3 Use all or only selected savers - Alex Bogomolov
v0.2.2 Fusion9 compatibility 3/4/2019 - Alex Bogomolov
v0.2.1 01.09.2008
	fixed bug for creating a keyframe at current time with blend = 0
v0.2 inital release 27.03.2008
	added setting of new renderrange in conjunction with ranges of savers 
    (min renderstart becomes renderrange start and max renderend becomes renderrange end)
	added check if start < end
v0.1 inital release 26.03.2008 by Tim Little 

-------------------------------------------------------------------------------------------------------------------------
--]]

fusion = Fusion()
cmp = fusion:GetCurrentComp()
all_savers = bmd.GetSavers(cmp)


function if_selected(cmp)
    sel_savers = cmp:GetToolList(true, 'Saver')
    if #sel_savers > 0 then
        print(#sel_savers .. ' savers selected')
        return sel_savers
    end
    return all_savers
end

function main(savers)
    local attrs = cmp:GetAttrs()
    local prefs = fusion:GetPrefs()

    local RenderStart = attrs.COMPN_RenderStartTime
    local RenderEnd = attrs.COMPN_RenderEndTime
    local GlobalStart = attrs.COMPN_GlobalStart

    local dialog = {}
    local dialogcounter = 1
    cmp:StartUndo("SaverRangesScript")

    for i, v in ipairs(savers) do
        dialog[dialogcounter] = {"process"..i, Name= "Process: "..v:GetAttrs().TOOLS_Name, "Checkbox", Default=1, NumAcross=2}
        dialog[dialogcounter+1] = {"renderrange"..i, Name="RenderRange", "Position", Default = {RenderStart, RenderEnd} }
        dialogcounter = dialogcounter + 2
    end
    dialog[dialogcounter+1] = {"",  "Text", Lines = 0, ReadOnly=true}
    dialog[dialogcounter+2] = {"newrange", Name= "Set new renderrange?", "Checkbox", Default=1, NumAcross=2}

    ask = cmp:AskUser("Savers", dialog)

    if ask == nil then print("cancelled") return end

    local RenderEndNew = ask.renderrange1[2]
    local RenderStartNew = ask.renderrange1[1]


    for i, v in ipairs(savers) do
        local processVar = "process"..i
        local renderrangeVar = "renderrange"..i
        local start = ask[renderrangeVar][1]
        local ende = ask[renderrangeVar][2]
        if start > ende then
            a = start
            start = ende
            ende = a
        end
        if ask[processVar] == 0 then
            v:SetAttrs({TOOLB_PassThrough = true})
        end
        if ask[processVar] == 1 then
            v:SetAttrs({TOOLB_PassThrough = false})
            v.ProcessWhenBlendIs00 = 0
            v:AddModifier('Blend', 'BezierSpline')
            if ((attrs.COMPN_CurrentTime > start) and (attrs.COMPN_CurrentTime < ende)) then
                v.Blend[attrs.COMPN_CurrentTime] = 1
            elseif attrs.COMPN_CurrentTime > ende then
                v.Blend[attrs.COMPN_CurrentTime] = 0
            elseif attrs.COMPN_CurrentTime < start then
                v.Blend[attrs.COMPN_CurrentTime] = 0
            end
            v.Blend[start - 1] = 0
            v.Blend[start] = 1
            v.Blend[ende] = 1
            v.Blend[ende+1] = 0
            if ende > RenderEndNew then RenderEndNew = ende end
            if start < RenderStartNew then RenderStartNew = start end
        end
    end
    if ask.newrange == 1 then
        cmp:SetAttrs({COMPN_RenderStart = RenderStartNew})
        cmp:SetAttrs({COMPN_RenderEnd = RenderEndNew})
    end
    cmp:EndUndo(true)
end

if #all_savers == 0 then
    print('no savers in this comp')
else
    savers = if_selected(cmp)
    main(savers)
end
