--[[

	hos_PSDLayers v1.6
	by S.Neve / House of Secrets
	
	Creates a loader and merge for each layer in the PSD file or,
	creates a loader, 3D image plane for each layer and merges these
	together either with or without	a 3D projector and expression for parallax
	effects.
	
    v1.6
    Added checksum to see which fusion version is running
    
    v1.5
    Fixed preference saving, iterating over the table needs to be done using pairs, rather than ipairs
    
    v1.4
    Added Fusion 7 support by iterating over tables by using ipairs.
    
    v1.3
    Fixed an error on Win7/8 where a script no longer has permissions on the
    filesystem to dump the tool settings to any folder other than the user's
    home directory.
    Fixed filmback aspect ratio problem (plane not matching camera fov)
    
	v1.2
	Added Prefix string
	Added saveSettings and loadSettings for newly created Loaders, so
	they 'inherit' the original PSD Loader settings (needs further testing
	though, as Global In and Out seem to do their usual freaky shit.)
    
	v1.1
	Added layer names to generated Loader

	v1.0
	Initial version.
]]--

version = "version 1.6 (Aug 30 2016)"

myscriptprefs = function(op)

	-- saves or loads script preferences, i have no idea who wrote the original
	-- code, recognize your code, let me know for the proper kudos.
    local _scriptname
    if(fusion.Version < 7.5) then
        _scriptname=eyeon.split(debug.getinfo(1).source,[[/]])
    else
        _scriptname=bmd.split(debug.getinfo(1).source,[[/]])
    end
	local _scriptname=_scriptname[table.getn(_scriptname)]
 
	local prefname = _scriptname..[[.ScriptPrefs]]
    if os.getenv( "userprofile" ) then
        cpath = os.getenv( "userprofile" )..([[\ScriptPrefs\]])
    elseif os.getenv("FUSION_PROFILE_DIR") and os.getenv("FUSION_PROFILE") then
		cpath=os.getenv("FUSION_PROFILE_DIR")..[[\]]..os.getenv("FUSION_PROFILE")..([[\ScriptPrefs\]])
	else
		cpath = fusion:MapPath("Fusion:\\").."profiles"..([[\ScriptPrefs\]])
	end
 
	local cfg = cpath..prefname
 
	if op and op=='write' then
		if not fileexists(cpath) then
			createdir(cpath)
		end
		file,err = io.open(cfg, "w + ")
		if file then
			local h="-- Script preferences for ".._scriptname.."\n-- generated by ".._scriptname.."\n\n"
			file:write(h .. "_cfs = {}\n")
			for i, v in pairs(_cfs) do
				if (type(v) == "string") then
					file:write("_cfs[\"" .. i .. "\"]= [["..v.."]]\n")
				elseif (type(v) == "boolean" or type(v) == "number") then
					file:write("_cfs[\"" .. i .. "\"]= " .. v .. "\n")
				end
			end
		end
		file:close()
		file = nil
	elseif op=='read' then
		if (fileexists(cfg)) then
			dofile(cfg)
			if (type("_cfs") == nil) then
				return
				{}
			end
		else
			return
			{}
		end
	end
end
------------------------------------------------------------------------

attrs = tool:GetAttrs()

-- check to see we have a Loader
if attrs.TOOLS_RegID == "Loader" then
	if tool.Clip[comp.CurrentTime] == "" then
		print("Loader contains no clips to explore")
		return
	end
	if attrs.TOOLST_Clip_FormatName[1] ~= "PSDFormat" then
		print("Loader is not a PSD file")
		return
	end
else
	print("Selected tool is not a Loader")
	return
end

--use the SaveSettings feature to dump all the settings of the tool to a file rather than doing it manually by reading and wrting all inputs/settings.
tool:SaveSettings("HoS_PSDLayers.setting")

local PSDFileName = attrs.TOOLST_Clip_Name[1]

--get list of all channels
channelList = tool.Clip1.PSDFormat.Layer:GetAttrs().INPST_ComboControl_String

flow=comp.CurrentFrame.FlowView
org_x_pos, org_y_pos = flow:GetPos(tool)
_cfs = {}
_cfs = myscriptprefs('read')
ret = {}


placementsOpts = {"Horizontal", "Vertical"}
cmodeOpts = {"(2D) Merge", "(3D) Image Planes"}
projOpts = {"None", "3D Projector", "Camera"}

ret = composition:AskUser("hos_PSDLayers", {
	{"prefix", Name = "Prefix ", "Text", Default = (_cfs.prefix or "PSD_"), Lines = 1, Width = 1.0},
	{"cdir", Name = "Placement ", "Dropdown", Default = (_cfs.cdir or comp:GetPrefs().Comp.FlowView.ForceSource), Options = placementsOpts, Width = 1.0},
	{"tiles", Name = "Source Tiles ", "Checkbox", Default = (_cfs.tiles or comp:GetPrefs().Comp.FlowView.ForceSource), Width = 1.0},
	{"cmode", Name = "Mode ", "Dropdown", Default = (_cfs.cmode or 0), Options = cmodeOpts, Width = 1.0},
	{"zstep", Name = "Z-Step ", "Slider", Default = (_cfs.zstep or 0.1), Width = 1.0},
	{"zoffs", Name = "Z-Offset ", "Slider", Default = (_cfs.zoffs or 0.5), Width = 1.0},
	{"proj", Name = "Projection type ", "Dropdown", Default = (_cfs.proj or 1), Options = projOpts, Width = 1.0},
})

if ret == nil then return end
prefix = ret.prefix
cdir = ret.cdir
cmode = ret.cmode
zoffs = ret.zoffs
zstep = ret.zstep
proj = ret.proj
tiles = ret.tiles

_cfs = ret
myscriptprefs('write')

if tiles == 1 then
	csize = 3   -- placement offset size, use 3 when using Tiled view for Tools.
	count = 3
else
	csize = 1
	count = 1  -- used to add to the placement offset for the tool in the flow
end
cTools = 0;

comp:Lock()

for i = 1, table.getn(channelList) do
	myLoader = Loader({Clip = PSDFileName})
	myLoader:LoadSettings("HoS_PSDLayers.setting") -- read all settings back from the previously dumped settings file
	myLoader:SetAttrs({TOOLB_NameSet = true, TOOLS_Name = prefix..channelList[i]})
	myLoader.Clip1.PSDFormat.Layer = i-1
	flow:SetPos(myLoader, org_x_pos + (i * (1 - cdir)), org_y_pos + (count * cdir))
	if(cmode == 0) then
		if i == 1 then
			myLastMerge = myLoader
		end
		if i > 1 then
			myMerge = Merge({Background = myLastMerge, Foreground = myLoader})
			flow:SetPos(myMerge, org_x_pos + (i * (1 - cdir))+ (1 * cdir), org_y_pos + (count * cdir) + (3 * (1 - cdir)) )
			myLastMerge = myMerge
		end
	end
	if(cmode == 1) then
		if(i == 1) then
			myMerge3D = Merge3D
			flow:SetPos(myMerge3D, org_x_pos + (i * (1 - cdir)) + (3 * cdir), org_y_pos + (count * cdir) + (6 * (1 - cdir)) )
			if proj == 1 then
				myProjector3D = LightProjector
				myProjector3D.Intensity = 0
				myProjector3D.Fit = "Width"
				myProjector3DName = myProjector3D:GetAttrs().TOOLS_Name
				flow:SetPos(myProjector3D, org_x_pos + (i * (1 - cdir)) + (2 * cdir), org_y_pos + (count * cdir) + (7 * (1 - cdir)) )
				myMerge3D["SceneInput1"]:ConnectTo(myProjector3D)
				cTools = 1
			end
			if proj == 2 then
				myCamera = Camera3D
				myCamera.AovType = 1
				myCamera.AoV = 40
				myCamera.ResolutionGateFit = "Width"
				myProjector3DName = myCamera:GetAttrs().TOOLS_Name
				flow:SetPos(myCamera, org_x_pos + (i * (1 - cdir)) + (2 * cdir) , org_y_pos + (count * cdir) + (7 * (1 - cdir)) )
				myMerge3D["SceneInput1"]:ConnectTo(myCamera)
				cTools = 1
			end
		end
		myImagePlane = ImagePlane3D({Background = myLoader})
		myImagePlane:SetAttrs({TOOLS_Name = channelList[i]})
		myImagePlane.Transform3DOp.Translate.Z =  i * zstep - table.getn(channelList) * zstep - zoffs
		myImagePlane.MaterialInput:ConnectTo(myLoader.Output)
		if proj == 1 then
			myImagePlane.Transform3DOp.Scale.X:SetExpression("(Transform3DOp.Translate.Z - " .. myProjector3DName .. ".Transform3DOp.Translate.Z) * math.tan(" .. myProjector3DName .. ".Angle / 360 *math.pi) * -2")
		end
		if proj == 2 then
			myImagePlane.Transform3DOp.Scale.X:SetExpression("(Transform3DOp.Translate.Z - " .. myProjector3DName .. ".Transform3DOp.Translate.Z) * math.tan(" .. myProjector3DName .. ".AoV / 360 *math.pi) * -(" .. myProjector3DName .. ".ApertureW / " .. myProjector3DName .. ".ApertureH) * 2")
		end
		myMerge3D["SceneInput" .. (i + cTools)]:ConnectTo(myImagePlane.Output)
		flow:SetPos(myImagePlane, org_x_pos + (i * (1 - cdir)) + (1 * cdir), org_y_pos + (count * cdir) + (3 * (1 - cdir)) )
	end
	count = count + csize
end

comp:Unlock()