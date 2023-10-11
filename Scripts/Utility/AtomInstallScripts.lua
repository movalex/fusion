function InstallScript()	
    dprintf("\n[Make Local] Installing Defaults File\n\n")

    osSeparator = package.config:sub(1,1)
    defaultsPath = fu:MapPath("Reactor:")..'Deploy'..osSeparator..'Defaults'..osSeparator

    -- Search Defaults pathmaps
    dprintf("[Defaults Folders] Scanning PathMaps\n")

    INSERT_STRING = [=[UserControls = ordered() {
        MakeLocal = {
            LINKS_Name = "Make Local",
            INPID_InputControl = "ButtonControl",
            BTNCS_Execute = [[
            args = { tool = comp.ActiveTool, copyTree = true }
            path = comp:MapPath("Scripts:Support/Loader_MakeLocal.lua")
            comp:RunScript(path, args)
            ]],
            IC_ControlPage = 0,
            LINKID_DataType = "Number",
            INP_Default = 0,
            },]=]
        

    function IterateDefaultSettings()
        status = false
        for i, path in ipairs(fu:MapPathSegments("defaults:")) do
            for j, file in ipairs(bmd.readdir(path .. "*.setting")) do
                if file.Name == "Loader_Loader.setting" then
                    status = true
                    file_path = path .. file.Name
                    AddUserControls(file_path)
                end
            end
        end
        return status
    end


    function AddUserControls(filePath)
        -- UserControl to be inserted into Loader_Loader.setting
        readFile = io.open(filePath, "r")
        if not readFile then
            dprintf("file not found")
            return
        end
        data = readFile:read("*all")
        -- Scan the file for a UserControls section
        findString = "UserControls = ordered%(%) {"
        k, l = string.find(data, findString)
        if l then
            -- Insert button into existing UserControls table
            dprintf("[Loader_Loader.setting] UserControls detected.\n")
            newData = string.gsub(data, findString, INSERT_STRING)
        else
            -- Insert new UserControls table
            dprintf("[Loader_Loader.setting] No UserControls.\n")
            newData = string.gsub(data, "CtrlWZoom = false,", "CtrlWZoom = false,\n			" .. INSERT_STRING .. "          },")
        end

        dprintf("data after parsing:\n", newData)
        -- Close the file, then reopen to overwrite
        readFile:close()

        rewriteFile = io.open(filePath, "wb")
        if rewriteFile then
            io.output(rewriteFile)
            io.write(newData)
            io.close(rewriteFile)
        end
    end


    function RenameTempFile(tempSetting)
        if not bmd.fileexists(tempSetting) then
            return
        end
        dprintf("[Loader_Loader.setting] No existing default files found. Renaming temp file.")
        -- Rename Loader_Loader.temp to Loader_Loader.setting
        os.rename(tempSetting, defaultsPath .. 'Loader_Loader.setting')
    end


    function DeleteTempFile(tempSetting)
        if not bmd.fileexists(tempSetting) then
            return
        end
        dprintf("[Loader_Loader.temp] Button insertion successful. Deleting temp file.")
        -- Delete Loader_Loader.temp
        os.remove(tempSetting)
    end


    defaultFound = IterateDefaultSettings()
    tempSetting = defaultsPath .. 'Loader_Loader.temp'

    if defaultFound then
    -- If setting file was successfully modified, delete the temp file in the Reactor folder. 
        DeleteTempFile(tempSetting)
    else
    -- Otherwise, rename it.
        RenameTempFile(tempSetting)
    end
end

----------------------

function UninstallScript()
    dprintf("\n[Make Local] Uninstalling Defaults File\n\n")
    local osSeparator = package.config:sub(1,1)

    -- Find all existing Loader default setting files
    dprintf("[Defaults Folders] Scanning PathMaps\n")

    function RemoveUserControls(filePath)
        dprintf("[Setting file found] "..filePath .. "\n")

        -- read file to memory
        settingsFile = io.open(filePath, "r")

        if settingsFile then
            data = settingsFile:read("*all")
            -- Delete the MakeLoader button
            startIndex, _ = string.find(data, "MakeLocal = ")
            if not startIndex then
                dprintf("[Make Local] user contols not found")
                return
            end
            newdata = data:sub(1, startIndex-1) .. data:sub(startIndex+351, #data)

            -- Close the file, then reopen to overwrite
            settingsFile:close()

            settingsRewrite = io.open(filePath, "wb")
            if settingsRewrite then
                io.output(settingsRewrite)
                io.write(newdata)
                io.close(settingsRewrite)
            end
        end
    end

    function IterateDefaultSettings()
        status = false
        for i, path in ipairs(fu:MapPathSegments("defaults:")) do
            for j, file in ipairs(bmd.readdir(path .. "*.setting")) do
                if file.Name == "Loader_Loader.setting" then
                    status = true
                    file_path = path .. file.Name
                    RemoveUserControls(file_path)
                end
            end
        end
        return status
    end

    defaultFound = IterateDefaultSettings()

    if defaultFound then
        dprintf("Uninstall script run successfully")
    end
end
