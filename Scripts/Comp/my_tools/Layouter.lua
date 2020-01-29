_author = "Alexey Bogomolov <mail@abogomolov.com>"
_date = "2020-01-29"
_VERSION = "0.1"


if fusion == nil then
	print("[Fusion] Error: Please open up the Fusion GUI before running this tool.\n")
else
	ui = app.UIManager
	disp = bmd.UIDispatcher(ui)
end

local mainWindow = fu:GetPrefs("Global.Main.Window")
if not mainWindow or mainWindow.Width == -1 then
	if app:GetVersion().App == 'Fusion' then
		print("[Warning] The Window dimensions are undefined. Please press 'Grab probram layout' button in the Layout Preferences section.")
		mainWindow.Height = 1900
		mainWindow.Width = 1100
	else
		print('this app will work in Fusion Standalone only')
		disp.ExitLoop()
	end
end

local minWidth, minHeight = 265, 75
local originX, originY = mainWindow.Left + (mainWindow.Width/2) - (minWidth/2), mainWindow.Top + (mainWindow.Height/2) - (minHeight/2)

print(string.format("[Layouter] - v%s %s ", _VERSION, _date))
print(string.format("[Created By] %s\n\n", _author))


function get_cf()
	local comp = fu:GetCurrentComp()
	local cf = comp.CurrentFrame
	return cf
end

local win = disp:AddWindow({
	ID = 'Win',
	TargetID = 'Layouter',
	Geometry = {originX, originY, minWidth, minHeight},
	WindowTitle = 'Layouter',
    -- WindowFlags = {SplashScreen = true},
    Events = {Close = true, KeyPress = true, KeyRelease = true, },
    ui:VGroup{
		ui:HGroup{
			ui:Button{ID = "LL", Text = "Load Layout",Weight = .3, MinimumSize = {5,10},},
			ui:Button{ID = "reset", Text = "reset", Weight = .2, MinimumSize = {5,10},},
			ui:Button{ID = "SL", Text = "Save Layout", Weight = .3, MinimumSize = {5,10},},
		},
        ui:Button{ID = "Close", Text = "Close"},
        },
    })

local itm = win:GetItems()

function win.On.Win.Close(ev)
	disp:ExitLoop()
end

-- A flag to track shift state
local shiftdown = false

function win.On.Close.Clicked(ev)
    disp:ExitLoop()
end

-- If the shift key is pressed, set our flag
function win.On.Win.KeyPress(ev)
	if ev.Key == 16777248 then
		shiftdown = true
		itm.LL.Text = "Wow!"
		itm.SL.Text = "Such Script!"
		itm.Close.Text = "Many Useful!"
		itm.reset.Text = "Wow!"
	end
end

-- If the shift key is released, reset our flag
function win.On.Win.KeyRelease(ev)
	if ev.Key == 16777248 then
		shiftdown = false
		itm.LL.Text = "Load Layout"
		itm.SL.Text = "Save layout"
		itm.Close.Text = "Close"
		itm.reset.Text = "reset"

	end
end
function win.On.SL.Clicked(ev)
	if shiftdown then
		print("don't push that shift button!")
	else
		print("Save current layout")
		get_cf():SaveLayout()
	end
end

-- Now we can use our flag to differentiate button presses
function win.On.LL.Clicked(ev)
	if shiftdown then
		print("don't push that shift button!")
	else
		print("Load existing layout")
		get_cf():LoadLayout()
	end
end

function win.On.reset.Clicked(ev)
	if shiftdown then
		print("don't push that shift button!")
	else
		print("resetting to default layout")
		get_cf():ResetLayout()
		comp:DoAction("Fusion_View_Show", {view = "Nodes", show = false})
		comp:DoAction("Fusion_View_Show", {view = "Nodes", show = true})
		comp:DoAction("Fusion_View_Show", {view = "Time", show = true})
		comp:DoAction("Fusion_View_Show", {view = "Inspector", show = true})
	end
end

win:Show()
disp:RunLoop()
win:Hide()
