------------------------------------------------------
-- Change Paths script, Revision: 2.4

-- search for (and replace) a pattern in filenames in the flow, 
-- including Loader Filename, Proxy, and Savers. Full support for
-- cliplists.
-- place in Fusion:/Scripts/Comp
--
-- TODO Add regular expressions support 
--    - partial / multi matches
--    - autodetection of missing files in dfscriptlib?
--
-- written by Isaac Guenard (izyk@eyeonline.com)
-- created : unknown date, by Isaac Guenard
-- updated : Sept 27, 2005
-- changes : updated for 5
-- update for Fu8 michael vorberg mv@empty98.de
-- v2.2 changes: add "process selected nodes only" for Loaders, Proxy and Savers
--               works for multiple Savers
-- v3.0, 2011-01-28 by Stefan Ihringer:
--    * option to remember search strings in globals
--    * don't lowercase whole path name
--    * trim in and trim are no longer reset
-- v4.0, 2018-02-05 by Bryan Ray:
--    * Updated for Fusion 9
-- v4.0.1, 2018-02-07:
--    * Updated preferences code with SetData()
-- v4.1, 2018-11-01:
--      use gsub for pattern search.
--          Add replace filepath with up to 2 matches. 
--          To search for 'v22' put 'v22' or 'v%d%d' into search field. 
--      Short pattern cheatsheet:
--          .  represents any single character
--          %a represents all letters A-Z and a-z
--          %d represents all digits 0-9
--          %p represents all punctuation characters or symbols such as . , ? ! : ; @ [ ] _ { } ~
--          %s represents all white space characters such as Tab, Carr.Return, Linefeed, Space, etc
--          %w represents all alphanumeric characters A-Z and a-z and 0-9
--      More: https://www.fhug.org.uk/wiki/wiki/doku.php?id=plugins:understanding_lua_patterns
--
------------------------------------------------------

function conform(filepath)
    local matched = string.match(filepath, srchFor)
    print("found pattern: ", matched)
    if matched == nil then
        return nil
    end
    -- build the new filename using gsub
    newclip = string.gsub(filepath, matched, srchTo)
    print("New file path is: ", newclip)            
    return newclip
end

-- restore settings from globals (if available)
local prefs = fusion:GetData("changePath")
if prefs then
	lastSource = prefs.Source or ""
	lastReplacement = prefs.Replacement or ""
	doLoaders = prefs.Loaders or 1
	doSavers = prefs.Savers or 0
	doProxy = prefs.Proxy or 0
    doValid = prefs.Valid or 0
    doProcessSelected = prefs.ProcessSelected or 0
    doGeoLoaders = prefs.GeoLoaders or 0
else
    lastSource = ""
    lastReplacement = ""
    doLoaders = 1
    doSavers = 0
    doProxy = 0
    doValid = 0
    doProcessSelected = 0
    doGeoLoaders = 0
end

-- ask the user for some information
d = {}
d[1] = {"Loaders", "Checkbox", Name = "Loaders", NumAcross = 3,  Default = doLoaders}
d[2] = {"Proxy", "Checkbox", Name = "Proxy", NumAcross = 3, Default = doProxy}
d[3] = {"Savers", "Checkbox", Name = "Savers", NumAcross = 3, Default = doSavers}
d[4] = {"GeoLoaders", "Checkbox", Name = "GeoLoaders", NumAcross = 3, Default = doGeoLoaders}
d[5] = {"Source", "Text", Name = "Enter pattern to search for", Default = lastSource}
d[6] = {"Replacement", "Text", Name = "Enter the replacement path", Default = lastReplacement}
d[7] = {"Valid", "Checkbox", Name = "Check If New Path is Valid", Default = doValid}
d[8] = {"ProcessSelected", "Checkbox", Name = "Process only selected nodes", Default = doProcessSelected}
d[9] = {"Remember", "Checkbox", Name = "Remember options for next time", Default = 1}


x = composition:AskUser("Repath Tool", d)

-- did we get a response, or did they cancel
if bmd.trim then
    trim = bmd.trim
else 
    function trim(str)
        str = string.gsub(str, "^(%s+)", "")
        str = string.gsub(str, "(%s+)$", "")
        return str
    end
end

if x then
   srchFor = trim(x.Source)
   srchTo = trim(x.Replacement)
else
   return nil
end

if srchFor == "" then
   print("What are you searching for?\n")
   return nil
end

if srchTo == "" then
   print("What are you changing ".. srchFor .." to?\n")
   return nil
end

-- remember strings for next time

if x.Remember == 1 then
	-- print("Saving Preferences")
	fusion:SetData("changePath.Source", x.Source)
	fusion:SetData("changePath.Replacement", x.Replacement)
	fusion:SetData("changePath.Loaders", x.Loaders)
	fusion:SetData("changePath.Savers", x.Savers)
	fusion:SetData("changePath.Proxy", x.Proxy)
	fusion:SetData("changePath.Valid", x.Valid)
    fusion:SetData("changePath.ProcessSelected", x.ProcessSelected)
	fusion:SetData("changePath.GeoLoaders", x.GeoLoaders)
end

-------------------------
-- lock the flow
-------------------------
composition:Lock()

-------------------------
-- start an undo event
-------------------------
composition:StartUndo("Path Remap - " .. srchFor .. " to " ..srchTo)

-------------------------
-- get table of tools in flow
-------------------------

function selected_checked()
   if x.ProcessSelected == 1 then
      -- print "checked"
      return true
   end
   return false
end


toollist = composition:GetToolList(selected_checked())

-------------------------
-- main loop
-------------------------


for i, tool in ipairs(toollist) do
    tool_a = tool:GetAttrs()

    if tool_a.TOOLS_RegID == "Loader" then
        
        clipTable = tool_a.TOOLST_Clip_Name
        altclipTable = tool_a.TOOLST_AltClip_Name
        startTime = tool_a.TOOLNT_Clip_Start
        trimIn = tool_a.TOOLIT_Clip_TrimIn
        trimOut = tool_a.TOOLIT_Clip_TrimOut
        
        -- pass a function the filename, get the newclip back, or nil

        if x.Loaders == 1 then
            for i = 1, table.getn(clipTable) do
                newclip = conform(clipTable[i])
                
                if newclip then
                    if fileexists(composition:MapPath(newclip)) == false and x.Valid == 1 then
                        print( "FAILED : New clip does not exist; skipping sequence.\n")
                    else
                        tool.Clip[startTime[i]] = newclip
                        tool.ClipTimeStart[startTime[i]] = trimIn[i]
                        tool.ClipTimeEnd[startTime[i]] = trimOut[i]
                    end
                end
            end
        end
        
        -- pass a function the filename, get the newclip back, or nil

        if x.Proxy == 1 then
            for i = 1, table.getn(altclipTable) do
                if altclipTable[i] ~= "" then
                newclip = conform(altclipTable[i])
        
                if newclip then
                    if fileexists(composition:MapPath(newclip) == false) and x.Valid == 1 then
                        print("FAILED : New proxy clip does not exist; skipping sequence.\n")
                    else
                        tool.ProxyFilename[startTime[i]] = newclip
                    end
                end
                end
            end
        end
    end
   
    if tool_a.TOOLS_RegID == "Saver" and x.Savers == 1 then
        saverTable = tool_a.TOOLST_Clip_Name 
        for i = 1, table.getn(saverTable) do
            newsaver = conform(tool_a.TOOLST_Clip_Name[i])
            if newsaver ~= nil then
                tool.Clip[fu.TIME_UNDEFINED] = newsaver
            end
        end    
    end

    -- process mesh loaders 

    if tool_a.TOOLS_RegID == "SurfaceFBXMesh" and x.GeoLoaders == 1 then   
        old_name = tool.ImportFile[1]
        newclip = conform(old_name)
        if newclip ~= nil then
            tool.ImportFile[fu.TIME_UNDEFINED] = newclip
        end
    end

    if tool.ID =='MediaIn' and x.Loaders == 1 then
        print('The tool does not work with Resolve\'s MediaIns')
    end
end

-------------------------
-- close the undo event
-------------------------
composition:EndUndo(true)

-------------------------
-- unlock the comp
-------------------------
composition:Unlock()
