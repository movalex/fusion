version = "1.0 Jan 10 2015"
--[[
    hos_SaverLister
    
    House of Secrets Saver Lister.
    For those of us that create comps with many savers.
    
    Allows enabling and disabling saver tools from a single interface.
    Allows settings render start and render end for savers (prevents saver failures and unnecessary calculating of tool networks.)
    
    Callback creation and assignment is a bit of a jumble right now as it is scattered through out the script.
    Might need to clean this up a bit.
    
    TODO / upcoming:
    1.x
      Refreshing of list on demand using F5
      Refreshing of ranges (global and savers) on timer? or window enter/activate.
      Sorting by Saver names, Saver Hierarchy (GetToolList/current behaviour), ranges, path.
      
    History:
    1.0
      Public preview release
      Cleaned up code
      Added workarounds for various IUP3 problems
      Changed PassThrough icons (added Python source for IupImage icon code generator, just for completion sake.)
    
    0.5 Dec 12 2014
      Added saver output path to list
      Changed vary large start and end times to render range start and end (this is a visual aid, the actual values are still very much -1000000 and 1000000)
    
    0.3 Sep 5 2014
      Using icons for PassThrough to fix button BGCOLOR problem in Fu7
    
    0.2 Oct 12 2013
      Initial in-house release.
    
]]--

-- This function allows us to sort our Saver array by saver tool name (by creating a new array with the saver names as keys.)
function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
        table.sort(a, f)
        local i = 0      -- iterator variable
        local iter = function ()   -- iterator function
            i = i + 1
            if a[i] == nil then return nil
            else return a[i], t[a[i]]
            end
    end
    return iter
end

local tools = composition:GetToolList()
local savers = {}
for k,v in pairs(tools) do
    if v.ID == "Saver" then
        savers[v.Name] = v
    end
end

local vbox1 = iup.vbox
{
    BGCOLOR="60 60 60",
    EXPAND="YES",
}

-- bg and c are used for colouring even and odd lines (improves readability of the saver list.)
local bg = {}
bg[1] = "60 60 60"
bg[2] = "50 50 50"
local c = 1
local fusion_major_version = math.floor(fu.Version)
local range_mode = 1
local range_min = -1000000
local range_max = 1000000
-- Fusion 7 uses a much MUCH larger possible frame range, check for that
if fusion_major_version == 7 then
    range_min = -1000000000
    range_max = 1000000000
end
local comp_render_range_min = composition:GetAttrs()["COMPN_RenderStartTime"]
local comp_render_range_max = composition:GetAttrs()["COMPN_RenderEndTime"]

-- PassThrough icons, created using Python and PIL:

--from PIL import Image
--
--im = Image.open('E:/Projects/passthrough_on.bmp')
--img_p = im.convert("P", palette=Image.ADAPTIVE, colors=9)
--img_rgb = img_p.convert('RGB')
--img_raw = img_p.tostring()
--palette = dict()
--s = 'img = iup.image {\n'
--for y in range(im.size[1]):
--    s += '\t{'
--    for x in range(im.size[0]):
--        s += '%s,' % (ord(img_raw[x+y*im.size[0]]) + 1)
--        palette[ord(img_raw[x+y*18]) + 1] = img_rgb.getpixel((x,y))
--    s += '},\n'
--s += '\tcolors = {\n'
--
--for i in palette.values():
--    s += '\t\t"%s %s %s",\n' % (i[0], i[1], i[2])
--s += '\t},\n'
--s += '}'
--
--print(s)

img_pass_cold = iup.image {
	{7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,},
	{7,7,7,7,7,9,9,8,6,6,8,8,9,7,7,7,7,7,},
	{7,7,7,7,9,6,5,5,4,4,5,5,6,9,7,7,7,7,},
	{7,7,7,8,5,4,1,1,1,1,1,2,4,6,8,7,7,7,},
	{7,7,9,5,2,1,1,1,1,2,2,2,2,4,6,9,7,7,},
	{7,9,6,4,1,1,1,1,2,2,2,2,3,3,4,6,9,7,},
	{7,9,5,1,1,1,1,2,2,2,2,3,3,3,3,5,8,7,},
	{7,8,5,1,1,1,2,2,2,2,3,3,3,4,3,5,8,7,},
	{7,6,4,1,1,2,2,2,2,3,3,3,4,4,4,4,6,7,},
	{7,6,4,1,2,2,2,2,3,3,3,4,4,4,4,4,6,7,},
	{7,8,5,1,2,2,2,3,3,3,4,4,4,4,4,5,8,7,},
	{7,8,5,2,2,2,3,3,3,4,4,4,4,4,4,5,8,7,},
	{7,9,6,4,2,3,3,3,4,4,4,4,4,4,4,6,9,7,},
	{7,7,9,6,4,3,3,4,4,4,4,4,4,4,6,9,7,7,},
	{7,7,7,8,6,4,3,3,4,4,4,4,4,6,8,7,7,7,},
	{7,7,7,7,9,6,5,5,4,4,5,5,6,9,7,7,7,7,},
	{7,7,7,7,7,9,8,8,6,6,8,8,9,7,7,7,7,7,},
	{7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,},
	colors = {
		"122 219 61",
		"121 214 57",
		"121 209 55",
		"120 203 51",
		"91 156 44",
		"53 71 39",
		"60 60 60",
		"52 60 46",
		"54 56 52",
	},
}

img_pass_hot = iup.image {
	{7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,},
	{7,7,7,7,7,8,8,9,9,9,9,8,8,7,7,7,7,7,},
	{7,7,7,7,9,9,7,6,5,5,6,8,9,9,7,7,7,7,},
	{7,7,7,9,8,5,1,1,1,1,1,1,6,8,9,7,7,7,},
	{7,7,9,8,3,1,1,1,1,1,1,2,2,5,8,9,7,7,},
	{7,8,9,5,1,1,1,1,1,1,2,2,3,3,6,9,8,7,},
	{7,8,7,1,1,1,1,1,1,2,2,3,3,3,3,8,8,7,},
	{7,9,6,1,1,1,1,1,2,2,3,3,3,4,4,6,9,7,},
	{7,9,5,1,1,1,1,2,2,3,3,3,4,4,4,6,9,7,},
	{7,9,5,1,1,1,2,2,3,3,4,4,4,4,4,6,9,7,},
	{7,9,6,1,1,2,2,3,3,4,4,4,4,4,4,6,9,7,},
	{7,8,8,1,2,2,3,3,3,4,4,4,4,5,5,8,9,7,},
	{7,8,9,6,2,3,3,3,4,4,4,4,5,5,6,9,8,7,},
	{7,7,9,8,5,3,3,4,4,4,4,5,5,6,9,9,7,7,},
	{7,7,7,9,8,6,3,4,4,4,4,5,6,9,9,7,7,7,},
	{7,7,7,7,9,9,8,6,6,6,6,8,9,9,7,7,7,7,},
	{7,7,7,7,7,8,8,9,9,9,9,9,8,7,7,7,7,7,},
	{7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,},
	colors = {
		"88 88 88",
		"86 86 86",
		"85 85 85",
		"84 84 84",
		"82 82 82",
		"74 74 74",
		"60 60 60",
		"55 55 55",
		"46 46 46",
	},
}

-- Labels

btnrender_range_startF = iup.button{title="In", FGCOLOR="200 200 200", BGCOLOR="60 60 60", RASTERSIZE = "80x18", PADDING="0x0", EXPAND="NO", CANFOCUS="NO"}
btnrender_range_endF = iup.button{title="Out", FGCOLOR = "200 200 200", RASTERSIZE = "80x18", EXPAND="NO", CANFOCUS="NO"}
btnSaverF = iup.button{title = "Tool", FGCOLOR = "200 200 200", RASTERSIZE = "100x18", EXPAND="NO", CANFOCUS="NO"}
btnPathF = iup.button{title = "Destination Path", FGCOLOR = "200 200 200", RASTERSIZE = "280x18", EXPAND="YES", CANFOCUS="NO"}
btn_pass_throughF = iup.button{title = "P", RASTERSIZE = "18x18", BGCOLOR = "60 60 60", EXPAND="NO", CANFOCUS="NO"}

-- Since button BGCOLOR is broken in IUP3, make sure we actually can read the button text by making it darker
if iup.GetGlobal("VERSION"):sub(1,1) == "3" then
    btnrender_range_startF.fgcolor = "20 20 20"
    btnrender_range_endF.fgcolor = "20 20 20"
    btnSaverF.fgcolor = "20 20 20"
    btnPathF.fgcolor = "20 20 20"
    btn_pass_throughF.fgcolor = "20 20 20"
end

hbox = iup.hbox
{
    btn_pass_throughF,
    btnSaverF,
    
    btnrender_range_startF,
    btnrender_range_endF,
    btnPathF,
    MARGIN="1x1",
    EXPAND="HORIZONTAL"
}
iup.Append(vbox1, hbox)

-- Build saver list content
for k,v in pairs(savers) do
        local attrs = v:GetAttrs()
        local render_range_start = attrs["TOOLNT_EnabledRegion_Start"][1]
        local render_range_end = attrs["TOOLNT_EnabledRegion_End"][1]
        local pass_through = attrs["TOOLB_PassThrough"]
        local path = attrs["TOOLST_Clip_Name"][1]
        local render_range_start_set = true
        local render_range_end_set = true
        
        if render_range_start == range_min then
            render_range_start_set = false
            if range_mode == 1 then
                render_range_start = attrs["TOOLNT_Region_Start"][1]
            else
                render_range_start = comp_render_range_min
            end
        end
        if render_range_end == range_max then
            render_range_end_set = false
            if range_mode == 1 then
                render_range_end = attrs["TOOLNT_Region_End"][1]
            else
                render_range_end = comp_render_range_max
            end
        end
        -- Debug print thingy
        --[[
        local s = v.Name .. " : "
        s = s .. " s: " .. render_range_start
        s = s .. ", e: " .. render_range_end
        s = s .. ", p: " .. tostring(pass_through)
        s = s .. ", " .. path
        print(s)
        ]]--
        
        text_render_range_start = iup.text{value=render_range_start, FGCOLOR = "200 200 200", RASTERSIZE = "80x18", EXPAND="NO", FILTER="NUMBER"}
        if render_range_start_set == false then
            text_render_range_start.BGCOLOR = "80 60 60"
        end
        -- Attach a function to the text action callback.
        text_render_range_start.action = function(self, c, new_value)
            if new_value == "" then
                v:SetAttrs({TOOLNT_EnabledRegion_Start = range_min})
                self.value = comp_render_range_min
                self.bgcolor = "80 60 60"
                --return iup.IGNORE
            else
                v:SetAttrs({TOOLNT_EnabledRegion_Start = tonumber(new_value)})
                self.bgcolor = "60 60 60"
            end
            --force the TimelineView to update by switching MainViews (probably will break in Fusion 7)
            comp.CurrentFrame:SwitchMainView("ConsoleView")
            comp.CurrentFrame:SwitchMainView("TimelineView")
        end
        text_render_range_end = iup.text{value=math.floor(render_range_end), FGCOLOR = "200 200 200", RASTERSIZE = "80x18", EXPAND="NO", FILTER="NUMBER"}
        if render_range_end_set == false then
            text_render_range_end.BGCOLOR = "80 60 60"
        end
        -- Attach a function to the text action callback.
        text_render_range_end.action = function(self, c, new_value)
            if new_value == "" then
                v:SetAttrs({TOOLNT_EnabledRegion_End = range_max})
                self.value = comp_render_range_max
                self.bgcolor = "80 60 60"
                --return iup.IGNORE
            else
                v:SetAttrs({TOOLNT_EnabledRegion_End = tonumber(new_value) + .9999})
                self.bgcolor = "60 60 60"
            end
            --force the TimelineView to update by switching MainViews (probably will break in Fusion 7)
            comp.CurrentFrame:SwitchMainView("ConsoleView")
            comp.CurrentFrame:SwitchMainView("TimelineView")
        end

        label_saver = iup.label{title = " " .. v.Name, RASTERSIZE = "100x18", FGCOLOR = "200 200 200", EXPAND="NO", BGCOLOR=bg[c]}
        -- Double clicking Saver label will select Saver tool (Fu7 / IUP3 only)
        -- This behaviour has been added just so it's easier to identify a Saver
        label_saver.button_cb = function(self, button, pressed, x, y, status)
            if iup.isdouble(status) then
                composition:SetActiveTool(v)
            end
        end
        
        label_path = iup.label{title = " " .. path, RASTERSIZE = "280x18",FGCOLOR = "200 200 200", BGCOLOR=bg[c], EXPAND="YES"}
        
        -- Colour the buttons according to the state of the tool PassThrough
        if pass_through then
            btn_pass_through = iup.button{title = "", IMAGE=img_pass_hot, IMPRESS=img_pass_hot, RASTERSIZE = "18x18", BGCOLOR = "60 60 60", EXPAND="NO", FLAT="YES"}
        else
            btn_pass_through = iup.button{title = "", IMAGE=img_pass_cold, IMPRESS=img_pass_cold, RASTERSIZE = "18x18", BGCOLOR = "60 255 0", EXPAND="NO", FLAT="YES"}
        end
        -- Attach an action callback to the button so it colours according to the tool PassThrough state.
        btn_pass_through.action = function(self)
            v:SetAttrs({TOOLB_PassThrough = not v:GetAttrs().TOOLB_PassThrough})
            if v:GetAttrs().TOOLB_PassThrough then
                self.BGCOLOR = "60 60 60"
                self.IMAGE=img_pass_hot
                self.IMPRESS=img_pass_hot
            else
                self.BGCOLOR = "60 255 0"
                self.IMAGE=img_pass_cold
                self.IMPRESS=img_pass_cold
            end
        end
        hbox = iup.hbox
        {
        btn_pass_through,
            label_saver,
            
            text_render_range_start,
            text_render_range_end,
            label_path,
            MARGIN="1x1",
            EXPAND="HORIZONTAL",
        }
        --work around bgcolors being removed/bugged from label elements in IUP 3.x
        --use a backgroundbox to color the odd even lines in IUP 3.x
        if iup.GetGlobal("VERSION"):sub(1,1) == "3" then
            backgroundbox = iup.backgroundbox {
                BORDER="NO",
                BGCOLOR=bg[c],
            }
            iup.Append(backgroundbox, hbox)
            iup.Append(vbox1, backgroundbox)
        else
            iup.Append(vbox1, hbox)
        end
        if c == 1 then c = 2 else c = 1 end
end

--Create the dialog, make sure it is set to TOPMOST (we don't want to go searching for windows behind Fusion every time.)
dlg = iup.dialog
{
  vbox1,
  title="HoS Saver Lister  " .. version, menu=mnu, BGCOLOR="60 60 60", FGCOLOR = "200 200 200", TOPMOST = "YES", FONT="Lucida Sans Unicode, 7", RESIZE = "YES", MAXBOX = "NO"
}
-- IupDialog k_any callback seems to work in IUP3 only?
dlg.k_any = function(self, c)
    if c == iup.K_F5 then
        -- TODO : Refresh all data (current workaround: close window, run script again)
    elseif c==iup.K_cA then
        -- Selecting all Savers (oh, if only SetActiveTool allowed for more than one tool)
    end
    return c
end
-- Show the dialog
dlg:showxy(iup.CENTER, iup.CENTER)
-- Throw it into the main loop.
iup.MainLoop()