local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 250,300
tool = nil

comp = fu:GetCurrentComp()

function getBounds()
    compAttrs = comp:GetAttrs()
    rStart = compAttrs.COMPN_RenderStart
    rEnd = compAttrs.COMPN_RenderEnd
    return rStart, rEnd
end

function showUI()
    frameOffset = comp:GetData("FrameRanger.offset") or 24
    local windowPosX = 900
    local windowPosY = 800
    local buttonSize = {45, 25}

    win = disp:AddWindow({
        ID = "FrameRanger",
        TargetID = "FrameRanger",
        WindowTitle = "Frame Ranger",
        Geometry = {windowPosX +20, windowPosY, width, height},
        ui:VGroup {
            ui:VGroup{
                Weight = 0,
            ui:HGroup{
                ui:HGap(0.25,0),
                ui:Label{
                    Weight = 0.6,
                    ID = 'Label',
                    Text = 'Frame Handles:',
                    Alignment = {AlignLeft = true, AlignVCenter = true}
                },
                ui:SpinBox {
                    Weight = 0.4,
                    ID = 'offset', Value = frameOffset,
                    Alignment = {AlignRight = true},
                    Maximum = comp:GetAttrs().COMPN_GlobalEnd / 2,
                    Events = {ValueChanged = true, EditingFinished = true},
                },
            },
            ui:HGroup {
                ui:Button{
                    -- MaximumSize = buttonSize,
                    MinimumSize = buttonSize,
                    ID = 'minus', Text = '> <',
                },
                ui:Button{
                    -- MaximumSize = buttonSize,
                    MinimumSize = buttonSize,
                    ID = 'plus', Text = '< >',
                },
                ui:Button{
                    -- MaximumSize = buttonSize,
                    MinimumSize = buttonSize,
                    ID = 'left', Text = '< <',
                },
                ui:Button{
                    -- MaximumSize = buttonSize,
                    MinimumSize = buttonSize,
                    ID = 'right', Text = '> >',
                },
            },
            ui:HGroup {
                ui:Button{
                    ID = 'setRange', Text = 'Set from Loader',
                },
                ui:Button{
                    ID = 'reset', Text = 'Reset range',
                },
            },
        },
            ui:HGroup {
                ui:Tree{
                    Alignment = {AlignHCenter = true, AlignBottom = true},
                    ID = 'Tree',
                    SortingEnabled = true,
                    Events = { ItemClicked = true, ItemDoubleClicked = true, CurrentItemChanged = true, ItemActivated = true }
                },
            },
            ui:HGroup {
                Weight = 0,
                ui:Button{
                    ID = 'SaveButton', Text = 'Save Range',
                },
                ui:Button{
                    ID = 'DeleteButton', Text = 'Delete Range',
                },
            },
            ui:HGroup {
                Weight = 0,
                ui:Button{
                    ID = 'RefreshButton', Text = 'Refresh In/Out List',
                },

            }
        }, 
    })
    itm = win:GetItems()

    -- Add a header row.
    local hdr = itm.Tree:NewItem()
    itm.Tree:SetHeaderItem(hdr)
    hdr.Text[0] = 'IN Point'
    hdr.Text[1] = 'OUT Point'
    hdr.Text[2] = 'num'

    -- add columns    
    itm.Tree.ColumnCount = 2
    -- Resize the Columns
    itm.Tree.ColumnWidth[0] = width / 2 - 12
    itm.Tree.ColumnWidth[1] = width / 2 - 12

    itm.offset:SelectAll()

    local function GetTreeItems(tree)
        return tree:FindItems("*",
        {
            MatchExactly = false,
            MatchFixedString = false,
            MatchContains = false,
            MatchStartsWith = false,
            MatchEndsWith = false,
            MatchCaseSensitive = false,
            MatchRegExp = false,
            MatchWildcard = true,
            MatchWrap = false,
            MatchRecursive = true,
        }, 0)
    end

    function RefreshTable()
        comp = fu:GetCurrentComp()
        itm.Tree:Clear()
        local data = comp:GetData("FrameRanger.InOuts")
        if not data then
            return
        end

        for num, range in pairs(data) do
            inPoint, outPoint = range[1], range[2]
            itRow = itm.Tree:NewItem();
            itRow.Text[0] = tostring(inPoint)
            itRow.Text[1] = tostring(outPoint)
            itRow.Text[2] = tostring(num) -- not registered, data use
            itm.Tree:AddTopLevelItem(itRow)
        end
    end
    
    function hasValue(tab, val)
        for index, value in pairs(tab) do
            if value[1] == val[1] and value[2] == val[2] then
                return true
            end
        end
        return false
    end

    function win.On.SaveButton.Clicked(ev)
        local data = comp:GetData("FrameRanger.InOuts") or {}
        renderIn = comp:GetAttrs().COMPN_RenderStart
        renderOut = comp:GetAttrs().COMPN_RenderEnd
        addData = {renderIn, renderOut}
        if hasValue(data, addData) then
            print('In/Out range already exists')
            return
        end
        table.insert(data, {renderIn, renderOut})
        comp:SetData("FrameRanger.InOuts")
        comp:SetData("FrameRanger.InOuts", data)
        RefreshTable()
    end

    function win.On.DeleteButton.Clicked(ev)
        if selected then
            comp:SetData("FrameRanger.InOuts."..selected)
            RefreshTable()
            selected = nil
        end
        itm.Tree:SetFocus("OtherFocusReason")
    end

    function win.On.RefreshButton.Clicked(ev)
        RefreshTable()
    end
   
    function win.On.Tree.ItemClicked(ev)
        selected = ev.item.Text[2]
    end 

    function win.On.Tree.ItemDoubleClicked(ev)
        renderStart, renderEnd = ev.item.Text[0], ev.item.Text[1]
        renderStart = tonumber(renderStart)
        renderEnd = tonumber(renderEnd)
        comp:SetAttrs({COMPN_RenderStart = renderStart})
        comp:SetAttrs({COMPN_RenderEnd = renderEnd})
        local range = renderEnd - renderStart
        ending = "s"
        if range == 1 then
            ending = ""
        end
        print("Selected render range: " .. renderEnd - renderStart .. " frame" .. ending)
    end
    
    function win.On.setRange.Clicked(ev)
        comp = fu:GetCurrentComp()
        tool = comp.ActiveTool or comp:GetToolList(true, "Loader")[1]
        if not tool then
            print("Select Loader")
            return
        end
        comp:StartUndo("Set Range based on Loader")
        toolAttrs = tool:GetAttrs()
        local clipStart = tool.GlobalIn[1]
        compIn = comp:GetAttrs().COMPN_RenderStart
        globalIn = comp:GetAttrs().COMPN_GlobalStart
        if clipStart == compIn then
            comp:SetAttrs({COMPN_RenderStart = globalIn})
            -- print("Set Render Start Time to Comp Global In")
        else
            comp:SetAttrs({COMPN_RenderStart = clipStart})
            print("Set Render Start Time to Loader Global In")
        end
        clipStart = toolAttrs.TOOLIT_Clip_TrimIn[1]
        clipEnd = toolAttrs.TOOLIT_Clip_TrimOut[1]
        comp:SetAttrs({COMPN_GlobalEnd = globalIn + (clipEnd - clipStart)})
        comp:SetAttrs({COMPN_RenderEnd = globalIn + (clipEnd - clipStart)})
        comp:EndUndo()
        -- altPressed = ev.modifiers.AltModifier
        -- print(altPressed == true)
    end

    function win.On.offset.ValueChanged(ev)
        comp:SetData("FrameRanger.offset", itm.offset.Value)
    end

    function win.On.offset.EditingFinished(ev)
        comp:SetData("FrameRanger.offset", itm.offset.Value)
    end

    function win.On.left.Clicked(ev)
        comp = fu:GetCurrentComp()
        local currentOffset = itm.offset.Value
        local renderIn, renderOut = getBounds()
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        midPoint = (renderIn+renderOut)/2
        newIn = renderIn - currentOffset
        newOut = renderOut - currentOffset
        if newIn < GStart then
            newIn = GStart
        end
        if newOut < GStart + currentOffset then
            newOut = GStart + currentOffset
        end
        comp:SetAttrs({COMPN_RenderStart = newIn})
        comp:SetAttrs({COMPN_RenderEnd = newOut})
        comp:SetData("FrameRanger.IsSet", "true")
    end

    function win.On.right.Clicked(ev)
        comp = fu:GetCurrentComp()
        local currentOffset = itm.offset.Value
        local renderIn, renderOut = getBounds()
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        midPoint = (renderIn+renderOut)/2
        newIn = renderIn + currentOffset
        newOut = renderOut + currentOffset
        if newIn > GEnd - currentOffset then
            newIn = GEnd - currentOffset
        end
        if newOut > GEnd then
            newOut = GEnd
        end
        comp:SetAttrs({COMPN_RenderStart = newIn})
        comp:SetAttrs({COMPN_RenderEnd = newOut})
        comp:SetData("FrameRanger.IsSet", "true")
    end

    function win.On.minus.Clicked(ev)
        comp = fu:GetCurrentComp()
        local currentOffset = itm.offset.Value
        local renderIn, renderOut = getBounds()
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        midPoint = (renderIn+renderOut)/2
        newIn = renderIn + currentOffset

        newOut = renderOut - currentOffset
        if newIn > midPoint then
            newIn = midPoint
        end
        if newOut < midPoint then
            newOut = midPoint
        end
        comp:SetAttrs({COMPN_RenderStart = newIn})
        comp:SetAttrs({COMPN_RenderEnd = newOut})
        comp:SetData("FrameRanger.IsSet", "true")
    end

    function win.On.plus.Clicked(ev)
        comp = fu:GetCurrentComp()
        local currentOffset = itm.offset.Value
        local renderIn, renderOut = getBounds()
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        newIn = renderIn - currentOffset
        newOut = renderOut + currentOffset
        if newIn < GStart then
            newIn = GStart
        end
        if newOut > GEnd then
            newOut = GEnd
        end
        comp:SetAttrs({COMPN_RenderStart = newIn})
        comp:SetAttrs({COMPN_RenderEnd = newOut})
        comp:SetData("FrameRanger.IsSet", "true")
    end

    function win.On.reset.Clicked(ev)
        comp = fu:GetCurrentComp()
        gStart = comp:GetAttrs().COMPN_GlobalStart
        if gStart < 0 then
            gStart = 0
            comp:SetAttrs({COMPN_GlobalStart = 0})
        end
        gEnd = comp:GetAttrs().COMPN_GlobalEnd
        comp:SetAttrs({COMPN_RenderStart = gStart})
        comp:SetAttrs({COMPN_RenderEnd = gEnd})
        GEnd = comp:GetAttrs().COMPN_GlobalEnd
        GStart = comp:GetAttrs().COMPN_GlobalStart
        comp:SetData("FrameRanger.IsSet", "false")
    end

    function win.On.FrameRanger.Close(ev)
        disp:ExitLoop()
    end

    RefreshTable()

    win:Show()
    disp:RunLoop()
    win:Hide()
end


showUI()
