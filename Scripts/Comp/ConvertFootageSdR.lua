    ------------------------------------------------------------------------------------------------
    --      Convert Footage.lua, Revision 10
    --
    --
    --      Comp script for Eyeon Fusion or Rotation
    --
    --      by  peter@wwfx.net
    --
    --      Created Jun 2004
    --      Update Nov 03 2005 - Port to Fusion 5
    --      Update Jul 20 2006 - include some utility functions and added conversion between all known to fusion fileformats
    --      Update Aug 02 2006 - can work without templates, switching views in verbose mode.
    --      Update Sep 27 2006 - fixed fusion crash after creating the flows.
    --      Update Aug 09 2007 - Can use Fusion Slave or another Full Fusion on the network, to assemble and render comps.
    --                 - Can be launched from Rotation and Learning Edition.
    --              Update Aug 06 2010 - fixed fusion crash after creating the flows. The last created flow will remain active. Results are printed in console of comp from which script was executed.
    --      Update Aug 22 2018 - Port to Fusion 9 by Bryan Ray
    --      Update March 7 2020 - small changes to get it working in Fusion 16 by Bryan Ray (mostly) and Sander de Regt (a little bit)
    --
    --      requires:   eyeon.scriptlib, Rotation or Fusion LE
    --
    ------------------------------------------------------------------------------------------------
     
    --[[
     
    The script was made to automate creating of reference clips from firewire drives with film footage.
    It can be used to search recursive(or not) any folder for footage that Fusion can load
    and convert it to any other file format fusion can write to.
     
    Some features:
     
        - Template comps. You can to create custom template comps, adjust bc,size,e.t.c. and use them for batch conversions.
        - Can store specific loader's settings and apply them to loaders in generated comps. This is done via list of loader inputs which can be edited (arround line 530, table "keep").
        - Choice for names of new clips and comps. They can be either source sequence name or its folder. Checks for duplicate names and append parent folder to name until it become unique.
        - choosing queue group for created comps and submit them to render master.
        - In verbose mode - current processed footage is displayed on fusion views, while creating the comp..
        - Can create single jpg still from the middle of the sequence.(i.e. for web thumbs)
     
    ------------------------------------------------------------------------------------------------
     
        INSTALL
     
        1.  Place Convert footage.eyeonscript in your fusions script directory.
        2.  If using templates - path to template comps must be provided  in ('templates_path' variable)
     
    ------------------------------------------------------------------------------------------------
     
        USAGE
     
    You can use this without woring about templates, e.t.c. Templates are valuable, when loader must have some special predefined options
    i.e, ByPass convertion,spec import modes, also when resizing source footage or modifying it with bc..
    When not using templates, simple loader->saver comp will be generated, optionaly with framecounter.
    In verbose mode  script prints more info about what is hapening and also shows current sequence in fu views, but that takes more time to finish.
    When generating names for new comps and saver clips, there is a check to escape duplicate names.
    Name of next parent folder is included to clip name, until name becomes uniqie.
    i.e. scanning c:\my docs    for *.jpg and we have found those:
        c:\my docs\folder.jpg
        c:\my docs\band\folder.jpg
    I this case output comp and clip names will be set to:
        folder.jpg
        band_folder.jpg
    This is only if script find duplicate clip names.
    ------------------------------------------------------------------------------------------------
     
        CREATING NEW TEMPLATES
     
    Provided template can be customized assuming existing tool names are not changed:
    LDR,SQ,JPG,MergeCounter,Counter - those are required by the script.
    If you dont need counter, script will work without it and its merge.
    The most important to keep are the loader(LDR) and savers(SQ,JPG). Between them you can put any other tools you need.
     
    Place new templates in template folder - they will be listed in script dialog so you can choose them from there.
     
    If you need to make two quicktimes, leave SQ to be set by script and add saver called MOV, point it to directory of your choice. Script will change only the clipname in the second saver.
     
    ]]
     
     
    --=========================       CONFIGURATION START    =========================--
     
    templates_path = [[F:\Fusiontemplates]]
    --templates_path = Comp:MapPath("Comps:") .. "[ Templates ]" -- i.e. C:\Program Files\Fusion\Comps\[ Templates ]
     
    --=========================     CONFIGURATION   END     =========================--
     
     
     
    if (not comp) then
        print("--\nConvert Footage is COMPOSITION SCRIPT.\n"
        .."To use it, please move it to:\n"
        ..Fusion():GetPrefs().Global.Paths.Scripts.."\\Comp"
        .."\nopen new comp and look for \"Convert Footage\" in the script menu :)\n--")
        do
            return
        end
    end
    local addslash  =   function (th)
        if string.sub(th, - 1, - 1) ~= "\\" then
            return
            (th.. "\\")
        else
            return
            th
        end
    end
    local GetFormats    =   function()
        formats,result,movs = FusionRemote:GetRegList(CT_ImageFormat),{},{}
        for ik  in  pairs(formats)      do
                f,ismovie = formats[ik]:GetAttrs().REGST_MediaFormat_Extension,
                            formats[ik]:GetAttrs().REGB_MediaFormat_CanLoadMulti
                if f then
                    to = table.getn(f)
                    for mm, to in pairs(f) do
                        if (ismovie == true) then
                            table.insert(movs, f[mm])
                        end
                        table.insert(result, f[mm])
                    end
                end
            end
            table.sort(result)
        return
        result, movs
    end
    local file_exists   =   function(th)  --    for unc, local dirs and files
        if not th then
            return false
        end
        if fileexists(th) then
            return true
        end
        if string.sub(th, - 1, - 1) == "\\" then
             b,s=(string.sub(th, 1, string.len(th) - 1)),(th)
        else
             b,s=th,th.."\\"
        end
        return(direxists(b) or direxists(s))
    end
    local pm = function(message)    print(string.rep('-', 50),("\n\t" .. message.."\n"))  end
    function ScanDir(dir, mask, recursive)
        dir,    maxlen, clips = addslash(dir),  (maxlen or 0),  (clips or {})
        local files = readdir(dir .. '*')
        local tt,   temp = table.getn(files),   {}
        if (tt > maxlen) then
            maxlen = tt
        end
        for i = 1, tt do
            --fi,       e = string.lower(dir .. files[i].Name),     nil
            fi,     e = dir .. files[i].Name,   nil
            if (files[i].IsDir == true and recursive == 1 and files[i].IsSystem == false) then
                ScanDir(fi, mask, recursive)
            else
                string.gsub(fi, "^(.+)(%..+)$", function(n, E) e = E end)
                if (fi and e) then
                    if ((e == mask) or (mask == '*')) then
                        local seq = eyeon.parseFilename(fi)
                        if (eyeon.isin(movs, mask) == true) then
                            t = seq.FullPath
                        else
                            t = seq.CleanName
                        end
                        if (eyeon.isin(temp, t) == false) then
                            printf("%0s %8s", '->', seq.Path .. seq.FullName)
                            table.insert(clips, seq)
                            table.insert(temp, t)
                            t = nil
                        end
                    end
                end
            end
        end
        scanned = (scanned or 0) + 1
    end
    myscriptprefs = function(op)
     
        local _scriptname   =   eyeon.split(debug.getinfo(1).source,[[/]])
        local _scriptname   =_scriptname[table.getn(_scriptname)]
        local prefname  =   _scriptname..[[.ScriptPrefs]]
     
        cpath   =   fusion:MapPath("Profile:")..([[ScriptPrefs\]])
     
        local cfg       =   cpath..prefname
       
        pm("Using: "..cfg)
       
        if op and op=='write' then
          if not fileexists(cpath) then
            createdir(cpath)
          end
        file,err = io.open(cfg, "w + ")
        if file then
          local h="-- Script preferences for ".._scriptname.."\n-- generated by ".._scriptname.."\n\n"
              file:write(h .. "_cfs = {}\n")
              for i, v in _cfs do
                  if (type(v) == "string") then
                      file:write("_cfs[\"" .. i .. "\"]= [["..v.."]]\n")
                  elseif (type(v) == "boolean" or type(v) == "number") then
                      file:write("_cfs[\"" .. i .. "\"]= " .. v .. "\n")
                  end
              end
          file:close() 
          end
          file = nil
        else
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
    function alert(message)
        _ALERT(message)
        ret = comp:AskUser("Alert!", {{"", "Text", Wrap=false, Lines=15,Default = message,Width=2}})
        return ret
    end
    function getToolPositions(c)  --Fusion 5.2 and up. returns nil if 5.1 or lower
        local positions =   {}
        if not c.CurrentFrame then do return nil end end
        local grid      =   c.CurrentFrame.FlowView
        if not grid then do return nil end end
        local grattr    =   grid:GetAttrs()
        if grattr.VIEWN_Top then
            grid:SetScale(0.5)
            for i, tool in ipairs(c:GetToolList()) do
                name    =   tostring(tool:GetAttrs().TOOLS_Name)
                x,y =   c.CurrentFrame.FlowView:GetPos(tool)
                positions[name]={["x"]=x,["y"]=y}
            end
        return positions
        end
     return nil
    end
    --========================   end utils
    local fta=fusion:GetAttrs()
    _cfs={}
    pm('local: '..fta.FUSIONS_FileName,' version ',fta.FUSIONS_Version,' with ',_G["_VERSION"])
    LocalIsFusion       =   eyeon.isin(split(fta.FUSIONS_FileName,'\\'),'Fusion.exe') and not (fta.FUSIONB_IsDemo==true)
    remote = comp:AskUser("", {
    {"", "Text", Wrap=true, Lines=3,Default ='Remote or local hostname/IP address with  Fusion or Render Slave to use:',Width=1},
    {"host", "Text", Wrap=false, Lines=1,Default ='localhost',Width=1},
    })
    if not remote then
    alert('Script aborted.')
        do return end
    end
    FusionRemote=Fusion(remote['host'])
    if not FusionRemote then
        alert('Can\'t connect to fusion instance')
        do return end
    end
    local fa=FusionRemote:GetAttrs()
    pm(fa.FUSIONS_FileName,' version ',fa.FUSIONS_Version,' with ',_G["_VERSION"])
    local o=split(fa.FUSIONS_FileName,'\\')
    IsRotation  =   eyeon.isin(o,'Rotation.exe')
    IsSlave     =   eyeon.isin(o,'RenderSlave.exe') or eyeon.isin(o,'ConsoleSlave.exe')
    IsFusion    =   eyeon.isin(o,'Fusion.exe')
    IsVision    =   eyeon.isin(o,'Vision.exe')
    --========================
    ccomp = fusion.GetCurrentComp() or fusion:GetCurrentComp()
    frame = ccomp:GetFrameList()[1]
    frame:SwitchMainView('ConsoleView')  -- take users attention.
    _cfs,   templates_path, tpl = myscriptprefs('read'),    fusion:MapPath(addslash(eyeon.trim(templates_path))),   {}
    local exts,movs = GetFormats()
    if table.getn(exts)==0 then
    alert('Can\'t get list of file formats, aborting the script!')
    do return end
    end
    exts2=exts
    exts2[table.getn(exts) + 1] = '- none -'
    if (file_exists(templates_path) == false) then
        _cfs.ut = 0
        _ale=[[The path to templates:\n
    --------------------------------------------------\n
    ]] .. (templates_path or '') .. [[
    --------------------------------------------------\n
    set in the beginning of this script is NOT VALID!
    If you want to use your own templates:
    [1].    Configure script :
    ]]..debug.getinfo(1).source..[[
    by editing it with text editor.
    Type there the path to templates.
    [2].    Run the script without templates once.
    Simple loader->merge->counter->saver comps will be generated.
    Copy those to your templates path. Adjust them to suit your needs,
    without changing names of existing tools, so script can find and set them later.
    [3]. Run the script again - you should see menu with your template comps.
    If you continue script will continue
    with creating basic template with loader->saver
    ]]
        alert(_ale)
    else
        k = readdir(templates_path .. '*.comp')
        if ((table.getn(k)) == 0) then
            alert("No templates found in:\n" .. templates_path .. ".\n\nScript will use internal ones on the fly :)")
            _cfs['ut'] = 0
        else
            for i = 1, table.getn(k) do
                table.insert(tpl, k[i].Name)
            end
        end
    end
     
    if ((file_exists(_cfs['Destination'])) == false) then
        _cfs['Destination'] = ''
    end
     
    if ((file_exists(_cfs['flws'])) == false) then
        _cfs['flws'] = ''
    end
     
    if ((file_exists(_cfs['sequence'])) == false) then
        _cfs['sequence'] = ''
    end
    if FusionRemote.RenderManager then
        g   =   FusionRemote.RenderManager:GetGroupList() or {'all'}
        else
        g={'all'}
    end
     
    opts = {
        {
            "sequence",
            Name = "Scan directory:",
            "PathBrowse",
            Default = (_cfs["sequence"]or ""),
        },{
            "recurse",
            Name = "Recurse? ",
            "Checkbox",
            Default = (_cfs["recurse"]or 1),
            Width = 0.5,
        },{
            "mask",
            Name = "Search for:",
            "Dropdown",
            Options = exts,
            Default = (_cfs["mask"]or 28),
        },{
            "sq",
            Name = 'Convert to:',
            "Dropdown",
            Options = exts2,
            Default = (_cfs["sq"]or 17),
        },{
            "Destination",
            Name = "Save clips to:",
            "PathBrowse",
            Default = (_cfs["Destination"]or ""),
        },{
            "ut",
            Name = "Use templates?",
            "Checkbox",
            NumAcross = 2,
            Default = (_cfs["ut"]or 1),
        },{
            "Comps",
            Name = "Template:",
            "Dropdown",
            Options = tpl,
            Default = (_cfs["Comps"]or ""),
        },{
            "compnames",
            Name = "New clip names:",
            "Dropdown",
            Options ={
                'using sequence name',
                'using folder',
                'using parent folder (1 level up)',
            },
            Default = (_cfs["compnames"]or ""),
        },{
            "jpeg",
            Name = "Make JPG still? ",
            "Checkbox",
            Default = (_cfs["jpeg"]or 1),
            Width = 1.0,
        },{
            "jpegs",
            Name = "JPG Width",
            "Slider",
            Default = (_cfs["jpegs"]or 720),
            Integer = true,
            Min = 120,
            Max = 2000,
            Width = 1.0
        },{
            "counter",
            Name = "Make counter? ",
            "Checkbox",
            Default = (_cfs["counter"]or 1),
            Width = 1.0,
        },{
            "flws",
            Name = "Save generated comps in:",
            "PathBrowse",
            Default = (comp:MapPath(_cfs["flws"]) or ""),
        },{
            "QueueNow",
            Name = "Send to RenderManager?",
            "Checkbox",
            Default = (_cfs["QueueNow"]or 0),
            Width = 1.0,
        },{
            "Submit comps paused",
            Name = 'Paused?',
            "Checkbox",
            Default = (_cfs["Paused"]or 1),
            Width = 0.5,
        },{
            "gs",
            Name = 'Use slaves:',
            "Dropdown",
            Options = g,
        },
    }
     
    ret = comp:AskUser("Convert footage", opts)
    if (not ret) then
        pm('Aborting the script..')
        do
            return
        end
    end
     
    if (table.getn(g)) then
        groups = g[ret.gs + 1]
    else
        groups = "local,all"
    end
     
    ret.Destination,    ret.sequence,   ret.flws =  addslash(comp:MapPath(ret.Destination)),    addslash(comp:MapPath(ret.sequence)),   addslash(comp:MapPath(ret.flws))
    if (ret.sequence == [[\]])  or (ret.flws == [[\]])  or (ret.Destination == [[\]]) then
        alert('\n\n\n\tAborting the script, please provide VALID PATHS.')
        do
            return
        end
    elseif ((ret.jpeg == 0) and (exts2[ret.sq + 1]== '- none -')) then
        alert('No output format selected.\n\n (sequence or single jpg)\n\nAborting the script.')
        do
            return
        end
    elseif ((file_exists(ret.flws)) == false) then
        alert('Folder for saving new comps does not exist!\n' .. ret.flws)
        do
            return
        end
    end
    _cfs,   mask = ret, exts[ret.mask + 1]
    myscriptprefs('write')
    if (fusion:GetPrefs().Global.Network.ServerName == 'localhost') then
        fusion.RenderManager:SetAttrs({ RQUEUEB_Paused = true, })
        warnrm = true
        pm('RenderManager : PAUSED.')
    end
     
    pm('Searching for '..mask..',please wait...')
    if FusionRemote.CacheManager then FusionRemote.CacheManager:Purge() end
    local t1 = os.time()
    ScanDir(ret.sequence, mask, ret["recurse"])
    local cl, timescan = table.getn(clips), os.difftime(os.time(), t1)
    local secs = math.fmod(timescan, 60)
    local mins = (timescan - secs) / 60
    local time1 = mins .. 'm. ' .. secs .. 's. '
    if (cl > 0) then
        pm(cl .. ' clips found in ' .. scanned .. ' dirs.\n\tTime: ' .. time1 .. '\nLongest clip has '..maxlen..'\nCreating comps, please wait...')
    else
        alert('No ' .. mask .. ' files found in \n' .. ret.sequence .. '\nTime to search:' .. time1)
        do
            return
        end
    end
    local t2,   user = os.time(),   (os.getenv("USERNAME") or '')
    local userinfo = user .. ' at ' .. os.getenv("COMPUTERNAME")
    if (ret.ut == 0 or (table.getn(tpl) == 0)) then
        pm('Creating base comp..')
        -- NewComp([boolean quiet[, boolean: autoclose[, boolean: hidden]]])
     
        c = FusionRemote:NewComp(true, true, false) or false
        pos =   getToolPositions(c) or nil
        if not c then do return end end
        SetActiveComp(c)    --SetAttrs({ COMPN_GlobalStart = 1, COMPN_RenderStart = 1 })
        Lock()
        UpdateMode = "All"
        LDR = Loader({ Clip = '' })
        LDR:SetAttrs({TOOLS_Name = "LDR"})
        out = LDR.Output
        pm('Ik heb een loader gemaakt')
        if pos then
            c.CurrentFrame.FlowView:SetPos(LDR,0.1,1.1)
        end
        if (ret.counter==1 and (not IsRotation)) then
            Counter=TextPlus{ Center = { 0.9, 0.08}, StyledText=TimeCode{Mins = 0, Hrs = 0, Secs = 0, Flds = 0, Frms = 1}}
            Counter:SetAttrs{ TOOLS_Name = "Counter" }
            MergeCounter = Merge({Background = out, Foreground =Counter.Output})
            MergeCounter:SetAttrs({TOOLS_Name = "MergeCounter"})
            out = MergeCounter.Output
            if pos then
                c.CurrentFrame.FlowView:SetPos(MergeCounter,2,1)
                c.CurrentFrame.FlowView:SetPos(Counter,2,2)
            end
        end
        if (not(exts2[ret.sq + 1]== '- none -')) then
            SQ = Saver({Clip = '', Input = out})
            SQ:SetAttrs({TOOLS_Name = "SQ"})
            if pos then
                c.CurrentFrame.FlowView:SetPos(SQ,4,1)
            end
        end
        if (ret.jpeg == 1) then
            RSZ = BetterResize({Width = ret['jpegs'], Input = out, KeepAspect = 1, Comments = 'Web thumb size.'})
            JPG = Saver({Clip = '', Input = RSZ.Output})
            JPG:SetAttrs({TOOLS_Name = "JPG"})
            if pos then
                c.CurrentFrame.FlowView:SetPos(RSZ,3,2)
                c.CurrentFrame.FlowView:SetPos(JPG,4,2)
            end
        end
        for i, tl in ipairs(c:GetToolList()) do
            tl.TileColor = {R = 1,G = 1,B = 1}
            tl.TextColor = {R = 0,G = 0,B = 0}
            tl.Comments = (tl.Comments or '') .. '\ndon\'t change my name please..'
        end
    else
        templatecomp = templates_path .. tpl[ret.Comps + 1]
        pm('Loading template: ' .. templatecomp)
        c = FusionRemote:LoadComp(templatecomp, false,false,false) or false
        -- the line above used to be---> c = FusionRemote:LoadComp(templatecomp, true,true,true) or false
        -- changing it made loading (and more importantly saving) templates work all of a sudden
     pm('I am still here. Just checking.')
        if (c == false) then
            alert('Unable to load template comp\n\nAborting the script.Please check that file exists and all tools can be loaded.')
            do
                return
            end
        end
     
        if ((not c.JPG) and (not c.SQ)) or (not c.LDR) then
            alert('This comp can not be used as template.\n' .. 'There are missing default tools.\n' .. 'Make sure loader witn name LDR present, and saver with name SQ or JPG')
            do
                return
            end
        end
        SetActiveComp(c)
        c:Lock()
        c.UpdateMode,setldr = "All",    {}
        keep ={
            "Import Mode",
            "Process Mode",
            "Hold First Frame",
            "Hold Last Frame",
            "Reverse",
            "Loop",
            "Missing Frames",
            "Depth",
            "Pixel Aspect",
            "Custom Pixel Aspect",
            "First Frame",
            "Make Alpha solid",
            "Invert Alpha",
            "Post-Multiply by Alpha",
            "Swap Field Dominance",
            "Bypass Conversion",
            "Lock R/G/B",
            "Black Level",
            "White Level",
            "Soft Clip (Knee)",
            "Film Stock Gamma",
            "Conversion Gamma",
            "Green Black Level",
            "Green White Level",
            "Green Soft Clip (Knee)",
            "Green Film Stock Gamma",
            "Green Conversion Gamma",
            "Blue Black Level",
            "Blue White Level",
            "Blue Soft Clip (Knee)",
            "Blue Film Stock Gamma",
            "Blue Conversion Gamma",
            "Conversion Table",
            "Frame Render Script",
            "Start/End Render Scripts",
            "Start Render Script",
            "End Render Script",
            "Comments",
            --"Clip List","Load","Replace","Insert","Import","Format Name","Detect Pulldown Sequence"
            --"KeyCode","Time Code Offset","Video Track","Effect Mask",
            --"Global In","Global Out","Trim In","Trim Out","Apply Mask Inverted",
            --"Multiply by Mask","Blank2","Channel","High","Low","Clip","Proxy Filename",
        }
        for i, input in ipairs(c.LDR:GetInputList()) do
            n = input:GetAttrs().INPS_Name
            if (eyeon.isin(keep, n)) then
                table.insert(setldr, i, {['name']= n,['val']= input[TIME_UNDEFINED]})
            end
        end
    end
    SetActiveComp(c)
    pos =   getToolPositions(c) or nil
    pm('Creating comps:')
    --if not pos then _ALERT('Unable to fetch tool positions. Expect comps with messed tools :-)') end
    cnames = {}
    if FusionRemote.CacheManager then FusionRemote.CacheManager:Purge() end
    for i, fi in pairs(clips) do --main loop
        local iFile = i
        -- SDR This is what my son put in there which helped create a counter making the names of the saved comps even more unique in line 636
        SetAttrs({COMPN_GlobalStart = 1, COMPN_GlobalEnd = 500000000000})
        to = (c.LDR.Output:GetConnectedInputs())
        c.LDR:Delete()      --grr...
        LDR = c.Loader({Clip = ''})
        LDR:SetAttrs({TOOLS_Name = "LDR"})
        if pos  then c.CurrentFrame.FlowView:SetPos(LDR,pos['LDR'].x,pos['LDR'].y) end
        for i, x in pairs(to) do    x:ConnectTo(LDR.Output) end
        masp=eyeon.split(fi.Path, [[\]])
        for i, line in ipairs(masp) do
            if (tonumber(string.len(eyeon.trim(line))) > 0) then
                folder = line
                parent= masp[i-1]
                parentvandeparent = masp[i-2]
                -- SDR I added another layer to make the names even more unique
            end
        end
        if (ret.compnames == 0) then
            shotname = fi.Name
        elseif(ret.compnames ==1 )  then
            shotname = folder
        else
            shotname = parentvandeparent .. '_' .. parent .. '_' .. folder
            -- dit was shotname = parent
        end
        savedcomp = ret.flws .. iFile .. '_' .. shotname .. '.comp'
        if (eyeon.isin(cnames, savedcomp) == true) then  --> check if is uniqie.
            a,j = eyeon.split(fi.FullPath,[[\]]),{}
            a[1],a[table.getn(a)] = nil,nil
            for xc, vv in ipairs(a) do
                table.insert(j, vv)
            end
            o = table.getn(j)
            for i, k in ipairs(j) do
                if (j[o + 1 - i]) then
                    shotname = j[o + 1 - i] .. '.' .. shotname
                    savedcomp = ret.flws .. iFile .. '_' .. shotname .. '.comp'
                end
                if (eyeon.isin(cnames, savedcomp) == false) then
                    break
                end
            end
        end
        table.insert(cnames, savedcomp)
        c.LDR.Clip[TIME_UNDEFINED] = fi.FullPath
        wait(0.5)
        if (setldr) then
            for g, input in ipairs(c.LDR:GetInputList()) do
                for o, k in ipairs(setldr) do
                    if (k.name == input:GetAttrs().INPS_Name) then                  --print(n,k.val)
                        input[TIME_UNDEFINED] = k.val
                    end
                end
            end
        end
        c:Save(savedcomp)
        att     = c.LDR:GetAttrs()
        start,  frames = att.TOOLNT_Clip_Start[1],  att.TOOLNT_Clip_End[1]
        if (not frames) then
            alert('UNABLE TO LOAD:\n' .. fi.FullPath)
        else
            c.CurrentTime = (math.ceil(frames / 2))
            if (ret.counter==1 and c.Counter and c.MergeCounter) then
                if (IsRotation) then
                    c.Counter:SetAttrs({TOOLB_PassThrough = true})
                    c.MergeCounter:SetAttrs({TOOLB_PassThrough = true})
                else
                    c.Counter.GlobalOut[TIME_UNDEFINED],c.Counter.Width,c.MergeCounter.Width,c.Counter.Height,c.MergeCounter.Height,
                    c.Counter.Enabled3 = frames,att.TOOLIT_Clip_Width[1],att.TOOLIT_Clip_Width[1],att.TOOLIT_Clip_Height[1],att.TOOLIT_Clip_Height[1],1
                end
            end
            if ((not(exts2[ret.sq + 1]== '- none -')) and c.SQ) then
                c.SQ:SetAttrs({TOOLB_PassThrough = false})
                c.SQ.Clip = ret.Destination .. shotname .. string.lower(exts2[ret.sq + 1])
                --if exts2[ret.sq + 1]=='.omf' and (not IsRotation) then
                    --c.SQ.OMFFormat.Codec[0]='AJPG'
                    --c.SQ.OMFFormat.AJPG.CodecVariety[0]='AVR9s'      -- ADD ANOTHER FILE FORMAT DEFAULT SAVER SETTINGS HERE AS ABOVE FOR OMF
                --end
            else
                if c.SQ then
                    c.SQ:SetAttrs({TOOLB_PassThrough = false})
                end
            end
            -- add another default savers here
     
            if c.OMF and (not IsRotation)then
                if exts2[ret.sq + 1]=='.omf' then
                    c.OMF:SetAttrs({TOOLB_PassThrough = true})
                    pm('Skiping OMF saver, because you have SQ set  to the same OMF!')
                else
                    c.OMF.Clip = ret.Destination .. shotname .. '.omf'
                    --c.OMF.OMFFormat.Codec[0]='AJPG'
                    --c.OMF.OMFFormat.AJPG.CodecVariety[0]='AVR9s'
                    pm('Setting omf saver. Format is'..c.OMF.OMFFormat.AJPG.CodecVariety[0])
                end
            end
     
     
            if c.MOV then
     
                local sq1=eyeon.parseFilename(ret.Destination).Path
                local mov1=eyeon.parseFilename(mov.Clip[TIME_UNDEFINED]).Path
          print('Found custom MOV saver'..mov1)
          print('The default one is '..sq1)
     
                if exts2[ret.sq + 1]=='.mov' then
                    if sq1 == mov1 then
            print('TWO SAVERS IN SAME DIR!! - ADDING _CUSTOM TO YOUR CLIP NAME_')
                                c.MOV.Clip = mov1..'_custom_' .. shotname .. '.mov'
                    end
                else
                    c.MOV.Clip = mov1 .. shotname .. '.mov'
                end
            end
     
        if ((exts2[ret.sq + 1]== '- none -') and (ret.jpeg == 1 and c.JPG)) then -- if creating  only JPG's
                c:SetAttrs({ COMPN_GlobalStart = start,COMPN_GlobalEnd = frames * 2, COMPN_RenderStart = c.CurrentTime,
                COMPN_RenderEnd = c.CurrentTime, COMPN_CurrentTime = c.CurrentTime })
            else
                c:SetAttrs({ COMPN_GlobalStart = start, COMPN_GlobalEnd = frames * 2, COMPN_RenderStart = start,
                COMPN_RenderEnd = frames, COMPN_CurrentTime = c.CurrentTime })
            end
            if (ret.jpeg and c.JPG) and (not IsRotation) then
                c.JPG:SetAttrs({TOOLB_PassThrough = false})
                _j = ret.Destination .. shotname .. '.jpg'
                c.JPG.Clip[0]=_j
                if c.JPG.Blend then
                    c.JPG.Blend =  BezierSpline()
                    c.JPG.Blend[start],c.JPG.Blend[c.CurrentTime - 1],c.JPG.Blend[c.CurrentTime],c.JPG.Blend[c.CurrentTime + 1] = 0,0,1,0
                    if c.JPG.ProcessWhenBlendIs00  then     c.JPG.ProcessWhenBlendIs00[1]=0 end
                end
                c.JPG.FrameSavedScript[0] = '\n_j=' .. '[['.._j..']]' ..
                '\nf=Fusion()Comp:MapPath(filename)\n' .. 'if(fileexists(f)) then\n' ..
                'h,e=os.rename(f,_j) \n' .. "if h == true then\n" .. "print(filename..' renamed to '.._j)\n" ..
                "else\n" .. "_ALERT(e,'Error renaming '..filename..' please rename it manualy to '.._j)\n" ..
                "end\n" .. "else\n" .. "_ALERT('Still frame NOT RENDERED !')\n" .. "end\n"
            else
                if c.JPG then c.JPG:SetAttrs({TOOLB_PassThrough = true}) end
            end
            ct = c:GetAttrs()
            c:SetPrefs{
                ["Comp.Info.Comments"] = 'Created using ' .. '\tConvert Footage.eyeonscript by ' ..
                userinfo .. ' on ' .. os.date() .. '\n\nSource:\t' .. fi.FullPath ..
                '\n\nClip:\t[' .. i .. ' from ' .. cl .. ']' .. '\n\nDestination:\t' ..
                ret.Destination .. shotname .. '\n\nComp saved:\t' .. savedcomp,
                ["Comp.Info.ModifyDate"] = os.date()}
            c:Save(savedcomp)
            pm('I just saved a comp!')
            --eyeon.fprint('Clip ' .. i .. '/' .. cl..':' ,fi.Name,ct.COMPN_RenderStart .. '..' .. ct.COMPN_RenderEnd)
            if (ret["QueueNow"]== 1) and fusion.RenderManager then
                job = fusion:QueueComp({ FileName = savedcomp, Start = start, End = frames, QueuedBy = user, Groups = groups })
                if (ret["Paused"]== 1) then
                    job:SetAttrs{RJOBB_Paused = true}
                end
            end
        end --if frames
    -- collectgarbage()
    end -- clips loop
    --c:Unlock()
    if ccomp then
        SetActiveComp(ccomp)
    end
     
     
    while c:IsLocked() == true do
    print('unlocking..')
       c:Unlock()
    end
    -- c:Close() --for some reason Fusion 6.0, 6.1 crashes here.
     
    local totaltime     =   os.difftime(os.time(), t1)
     
    if not FusionRemote.RenderManager then
        _ALERT('Script is finished, but generated comps are not submitted to rendermanager.Unable to connect. Please do this manualy.')
    end
     
     
     
    endmsg='Script Convert Footage Finished!\nSee console for details.'
    --eyeon.fprint('Scaned folders:',scanned ,' in '..time1)
    --eyeon.fprint('Clips found:',cl)
    --eyeon.fprint('Total time:',((totaltime - math.fmod(totaltime, 60)) / 60)..'m. '..(math.fmod(totaltime, 60))..'s.')
    pm('Comps saved in:\t\t'..ret.flws)
     
     
     
    if (cl > 0) then    executebg('explorer /e ,' ..ret.flws)end
    if (warnrm) then
        fusion.RenderManager:SetAttrs({ RQUEUEB_Paused = false, })
    end
    -- collectgarbage()
    alert(endmsg)
     
