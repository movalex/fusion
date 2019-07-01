-- hos_ConnectMultipleTools_Fu8
-- Connects multiple tool outputs to multiple tool inputs

-- adjusted to work with the new UI system for Fusion 8 by Pieter Van Houte, by example of the "Licensing" UI script by Peter Loveday

-- THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
-- INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
-- THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND
-- DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
-- UPDATES, ENHANCEMENTS, OR MODIFICATIONS. 

-----------------------
-- UI script Fu8

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

-----------------------

local inputtools = nil
local outputtools = nil

-- Connect to Fusion instance

if not fusion then
   -- The second argument is the timeout.  Otherwise it will try to connect forever.
   fusion = Fusion("localhost", 10)
end

-- See if comp exists, if not, grab the current comp from our Fusion instance
if not comp then
    comp = fusion:GetCurrentComp()
end

-- If comp still is nil it's safe to asume there are no comps open or something is wrong, we exit the program.
if not comp then
    print("No active composition found")
    return
end

-----------------------
-- window setup

win = disp:AddWindow(
	{
		ID = "ConnectMultipleTools",
		WindowTitle = "Connect Multiple Tools",
		Composition = comp,
		View = view,
		MaximumSize = {400, 101},
		ui:VGroup
		{
			ID = "root",

			ui:HGroup
			{
				Weight = 0,

				ui:Button{ ID = "LoadOutputNodes", Text = "Load Output Nodes" },
				ui:HGap(5), -- fixed 5 pixels
				ui:LineEdit{ ID = "OutputList", Events= { ReadOnly=true },
					PlaceholderText = "Outputs: 0",
					Weight = 1.5,
					MinimumSize = {100, 24} },
			},
			
			ui:HGroup
			{
				Weight = 0,

				ui:Button{ ID = "LoadInputNodes", Text = "Load Input Nodes" },
				ui:HGap(5), -- fixed 5 pixels
				ui:LineEdit{ ID = "InputList", Events= { ReadOnly=true },
					PlaceholderText = "Inputs: 0",
					Weight = 1.5,
					MinimumSize = {100, 24} },
			},
			
			ui:HGroup
			{
				Weight = 0,

				ui:Button{ ID = "ConnectNodes", Text = "Connect Nodes" },
			},
		},
	})


-----------------------
-- worker functions


function addSelectionToOutputList()
    outputtools = comp:GetToolList(true)
    itm.OutputList.Text = "Outputs: " .. table.getn(outputtools)
end

function addSelectionToInput()
    inputtools = comp:GetToolList(true)
    itm.InputList.Text = "Inputs: "..table.getn(inputtools)
end

function getInput(tool, i)
    -- This returns the main input with index i
    input = tool:FindMainInput(i)
    return input
end

function getNextInput(tool)
    -- This will search for the next available non-connected input.
    -- We abuse the pcall function by simply increasing the FindMainInput index
    --  until an error occurs (pcall in this case works like a poor mans
    --  try-catch flow.)
    -- If no error occurs we check if the input is connected already, if not
    --  we'll use that one.
    local i = 1
    local status = true
   
    while status == true do
        if pcall(getInput(tool, i)) then
            -- No error occurred, check if the input is already connected
            if tool:FindMainInput(i):GetConnectedOutput() == nil then
                -- Great, it's not, use this one to connect to an output.
                status = false
            else
                -- Move along, this is not the input you are looking for.
                i = i + 1
            end
        else
            -- An error occured, use the previous input.
            -- A note here:
            -- This will overwrite connections when not dealing with Merge3D
            --  tools (as this was initially designed as an example for that
            --  useage scenario.)
            i = i - 1
            status = false
        end
    end
    return tool:FindMainInput(i)
end

function connectAll()
    -- Connects all inputtools inputs with outputtools outputs
    if inputtools == nil or outputtools == nil then
        print("error")
        return
    end
    if table.getn(inputtools) < 1 or table.getn(outputtools) < 1 then
        print("error")
        return
    end
    for k1, outputtool in pairs(outputtools) do
        for k2, inputtool in pairs(inputtools) do
            getNextInput(inputtool):ConnectTo(outputtool:FindMainOutput(1))
        end
    end
end

-----------------------
-- UI handlers

function win.On.LoadOutputNodes.Clicked(ev)
	addSelectionToOutputList()
end

function win.On.LoadInputNodes.Clicked(ev)
	addSelectionToInput()
end

function win.On.ConnectNodes.Clicked(ev)
	connectAll()
end

function win.On.ConnectMultipleTools.Close(ev)
	disp:ExitLoop()
end


-----------------------
-- Init


itm = win:GetItems()

-----------------------
-- Event loop

win:Show()
disp:RunLoop()
win:Hide()