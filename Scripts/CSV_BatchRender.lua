--[[
CSV_BatchRender.eyeonscript
####################################

Changes the tools of a comp based on a CSV file and renders the 
comps via the rendermanager.

The header/first line of the csv file names the Tools and inputs.
E.g.
MainTitle,MainTitle2,MainTitle3.Text

... results in MainTitle.StyledText, MainTitle2.StyledText and MainTitle3.Text
being replaced with with proper text from the data below.

:copyright: 2013 eyeon Software. Written by Blazej Floch
:version: 
    0.1 - Initial Release
	0.2 - 18.oct.2015 - adjusted to work with Fu7+ by Pieter Van Houte
--]]

-- -------------------------------------------------------------------------------------
-- Splits a string into a table based on a delimiter.
-- If delimiter is "" or nil the a table with a single entry is created.
--
function split(str, sep)
    if sep == nil or #sep < 1 then
        return {str}
    end
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- -------------------------------------------------------------------------------------
-- Creates the dialog and returns its result
--
function AskUser()
    ret = composition:AskUser("CSV BatchRender", { 
        {"csv", Name="Select a CSV File", "FileBrowse"},
        {"delimiter", Name="Delimiter", "Text", Lines=1, Max=1, Default=","},
        {"temp", Name="Composition Directory", "PathBrowse", Default="Temp:"},
        --{"saver", Name="Adapt Saver Paths", "Checkbox", Default = 1},
        --{"render", Name="Add to RenderQueue", "Checkbox", Default = 1},
    } )
    return ret
end    

-- -------------------------------------------------------------------------------------
-- Reads the CSV File and returns a table with each row as entry. 
-- Each column is split into a table based on the delimiter.
-- If delimiter is "" or nil the a table with a single entry is created.
--
function ReadCSV(filename, delimiter)
    fileContent = {}
    if filename and filename ~= "" then
        file, msg = io.open(filename, "rb")

        if file then
            for line in file:lines() do
                    table.insert(fileContent, split(line, delimiter))
            end
            file:close()
        else
            print("Error: Could not open file\n"..msg)
            return nil
        end

    end

    return fileContent
end

-- -------------------------------------------------------------------------------------
-- Find Input with id in tool of type inpType
--
function FindInput(tool, id, inpType)
    for i, input in ipairs(tool:GetInputList(inpType)) do
        if input.ID == id then
            return input
        end
    end

    return nil
end

-- -------------------------------------------------------------------------------------
-- Get the tools based on the header table from the current comp and store in a table
--
function HeaderTools(header)

    headerToolsTable = {}
    -- Lua doesnt table.getn for dicts. We have to count in here.
    count = 0
    for i, tool in ipairs(comp:GetToolList()) do
        for j, headerName in ipairs(header) do
            parts = split(headerName, ".")
            toolName = parts[1]
            inputName = parts[2]
            
            if inputName == nil then inputName = "StyledText" end


            if tool.Name == toolName then
                -- Warn if there is no styledText
                input = FindInput(tool, inputName, "Text")
                if input == nil then
                    print("Warning: " .. headerName .. " does not have a ".. inputName .." Input. Ignored.")
                else
                    headerToolsTable[j] = input
                    count = count + 1
                end
            end
        end
    end

    -- No matching tools found found
    if count < 1 then
        local names = ""
        for i, name in ipairs(header) do
            names = names .. name .. " "
        end
        print ("Error: No tools for columns found: - " .. names)
        return nil
    end

    -- Not all matching tools found
    if count ~= #header then
        print("Warning: Not all tools for each column has been found.")
    end

    return headerToolsTable

end

-- -------------------------------------------------------------------------------------
-- Return an array of Savers.
-- Optionally only active savers are returned.
--
function Savers(isActive)
    if isActive == nil then isActive = true end
    saverToolsTable = {}
    for i, tool in ipairs(comp:GetToolList(false, "Saver")) do
        if isActive == false or (isActive == true and  tool:GetAttrs("TOOLB_PassThrough") == false) then
            saverToolsTable[tool] = tool.Clip[TIME_UNDEFINED]
        end
    end    

    return saverToolsTable
end

-- -------------------------------------------------------------------------------------
-- Change the tools StyledText based on the input table.
-- The tools need to have a StyledText input
-- The index is used as key for the entries.
--
-- Returns the first entry
function ChangeTools(toolList, entryList)
    firstEntry = nil
    for i, input in ipairs(toolList) do
        if firstEntry == nil then firstEntry = entryList[i] end
        input[TIME_UNDEFINED] = entryList[i]
    end

    return firstEntry
end

-- -------------------------------------------------------------------------------------
-- Split Path into dir, filename and extension
--
function SplitPath(path)
    return string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
end

-- -------------------------------------------------------------------------------------
-- Add a traling slash if needed
--
function AddTrailingSlash(path, sep)
    sep = sep or "\\"
    path = comp:MapPath(path)
	if string.sub(path, -1) ~= sep then
		return path .. sep
	else
		return path
	end
end

-- -------------------------------------------------------------------------------------
-- Adds a subfolder to the savers path.
--
function AddFolderToSavers(savers, foldername)
    comp:Lock()
    for saver, origPath in ipairs(savers) do
        dir, filename, ext = SplitPath(origPath)

        newDir = dir .. foldername
        if not eyeon.direxists(newDir) then
            eyeon.createdir(newDir)
        end
        saver.Clip = AddTrailingSlash(newDir) .. filename
    end
    comp:Unlock()
end

-- -------------------------------------------------------------------------------------
-- Get Rid of everything non alphanumeric
--
function PlainText(strText)
    return strText:gsub("(%W)","_")
end 


-- -------------------------------------------------------------------------------------
-- Make a label
--
function MakeLabel(index, name)
    return string.format("%02d_%s", index, PlainText(name))
end

-- -------------------------------------------------------------------------------------
-- Save the comp and add to RenderQueue if needed.
--
function SaveCompAs(path, doRender)
    comp:Save(path)

    if doRender == true then
        fusion.RenderManager:AddJob(path)
    end
end

-- -------------------------------------------------------------------------------------
-- Main Function
--
function Main()

    options = AskUser()
    -- Canceled?
    if options == nil then
        return nil
    end

    -- Not an option in this version
    options.saver = 1
    options.render = 1

    csv = ReadCSV(options.csv, options.delimiter)
    -- File could not be read?
    if csv == nil then
        return nil
    end

    -- The first entry is the header indicating the Tool Names
    local header = csv[1]
    table.remove(csv, 1)
    headerTools = HeaderTools(header)

    if headerTools == nil then
        return nil
    end

    -- Get all the active savers
    if options.saver == 1 then
        saverTools = Savers(true)
    else
        saverTools = {}
    end

    origComp = comp:GetAttrs("COMPS_FileName")
    if origComp == "" then
        ret = composition:AskUser("Comp not Saved", { 
            {"save", Name="Error", "Text", ReadOnly=true, Default="You need to save the comp first."},
        })
        if ret == nil then
            return nil
        end

        comp:SaveAs()
        origComp = comp:GetAttrs("COMPS_FileName")
        if origComp == "" then
            return nil
        end
    end

    comp:Save(origComp)

    -- Create all the comps
    for i, curEntries in ipairs(csv) do
        firstEntry = ChangeTools(headerTools, curEntries)

        label = MakeLabel(i, firstEntry)

        AddFolderToSavers(saverTools, label)

        SaveCompAs(AddTrailingSlash(options.temp) .. label .. ".comp", options.render==1)
    end

    fusion:LoadComp(origComp)
    
    if options.render == 1 then
        fusion:ToggleRenderManager()
    end
    
    comp:Close()

end

Main()
