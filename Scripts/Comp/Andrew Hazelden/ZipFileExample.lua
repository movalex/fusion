    --[[--
    FuSkin Button Toolbar GUI - v1.0 2019-05-06
    by Andrew Hazelden <andrew@andrewhazelden.com>
     
    A Fusion 16/Resolve 16 compatible script that extracts a series of image resources from the zipped Fuskin file and generate a new UI Manager based toolbar GUI. This script uses the new "ZipFile()" functionality that is only present in Fu16+ Lua scripting.
     
    --]]--
     
     
    -- Get the base filename from a filepath
    function GetFilename(mediaDirName)
        local path, basename = string.match(mediaDirName, "^(.+[/\\])(.+)")
       
        return basename
    end
     
    -- Where the unzipping magic happens
    function UnzipSkinFiles(zipFilename, extractFileTable, destFolder)
        -- Create a file handler for the fuskin zipfile
        local zip = ZipFile(zipFilename, false)
       
        -- Create the output folder
        bmd.createdir(destFolder)
       
        -- Verify the zip file could be accessed
        if zip:IsOpen() then
            print("[Zip] [Opened Zip] " .. zipFilename)
     
            -- Scan through a list of files in a lua table
            for i, extractFilename in ipairs(extractFileTable) do
                -- Search for a file
                if zip:LocateFile(extractFilename, true) then
                    print("[Zip] [" .. tostring(i) .. "] [Found] " .. extractFilename)
     
                    -- Access the png image
                    if zip:OpenFile() then
                        print("[Zip]\t[Opened File] " .. tostring(zip:GetFileName()))
     
                        -- Print the file creation date as YYYY-MM-DD
                        print("[Zip]\t[File Date] " .. os.date("%Y-%m-%d", zip:GetFileTime()))
     
                        filesize = tonumber(zip:GetFileSize())
                        print("[Zip]\t[File Size] " .. tostring(filesize))
     
                        -- Create an FFI based buffer variable to hold the extracted file data
                        -- Note: You might have to increase the "BUF_SIZE" value to allow larger then 65K files to be extracted in your scripts.
                        local BUF_SIZE = 65536
                        local buf = ffi.new("char[?]", BUF_SIZE)
     
                        -- Read the file from the zip
                        -- The "zip:readfile()" size argument should be set to the value returned by "zip:GetFileSize()"
                        local len = zip:ReadFile(buf, filesize)
                        print("[Zip]\t[Bytes Read] " .. tostring(len))
     
                        -- Write the extracted file to disk
                        extractFilePath = destFolder .. GetFilename(extractFilename)
                        local extractFileOut = io.open(extractFilePath, "wb")
                        if len > 0 then
                            extractFileOut:write(ffi.string(buf, len), len)
                            print("[Zip]\t[Extracted File] " .. tostring(extractFilePath))
                        else
                            print("[Zip]\t[Extracted File is Empty] ")
                        end
                        extractFileOut:close()
     
                        -- Close the zip
                        zip:CloseFile()
                    else
                        print("[Zip]\t[Unable to Open File] " .. extractFilename)
                    end
                else
                    print("[Zip]\t[Not Found] " .. extractFilename)
                end
            end
        else
            print("[Zip] [Unable to Open Zip] " .. zipFilename)
        end
    end
     
     
    -- Build a UI Manager GUI
    function DisplayToolbar(destFolder)
        local ui = fu.UIManager
        local disp = bmd.UIDispatcher(ui)
        local width,height = 730,60
        local iconsMediumLong = {120,60}
     
        local win = disp:AddWindow({
            ID = "FuSkinToolbarWin",
            TargetID = "FuSkinToolbarWin",
            WindowTitle = "Toolbar",
            Geometry = {0, 0, width, height},
            Spacing = 0,
            Margin = 0,
     
            ui:VGroup{
                ID = "root",
               
                -- Add your GUI elements here:
                ui:HGroup{
                    ui:HGroup{
                        Weight = 0.7,
     
                        -- Add buttons that have an icon resource attached and no border shading
                        ui:Button{
                            ID = "IconButtonCamera",
                            Text = "Camera",
                            Flat = true,
                            IconSize = {60, 60},
                            Icon = ui:Icon{File = destFolder .. "camera@2x.png"},
                            MinimumSize = iconsMediumLong,
                            Checkable = false,
                        },
                        ui:Button{
                            ID = "IconButtonCube",
                            Text = "Cube",
                            Flat = true,
                            IconSize = {60, 60},
                            Icon = ui:Icon{File = destFolder .. "cube@2x.png"},
                            MinimumSize = iconsMediumLong,
                            Checkable = false,
                        },
                        ui:Button{
                            ID = "IconButtonCubeMap",
                            Text = "CubeMap",
                            Flat = true,
                            IconSize = {60, 60},
                            Icon = ui:Icon{File = destFolder .. "cubemap@2x.png"},
                            MinimumSize = iconsMediumLong,
                            Checkable = false,
                        },
                        ui:Button{
                            ID = "IconButtonDirectionalLight",
                            Text = "Directional Light",
                            Flat = true,
                            IconSize = {60, 60},
                            Icon = ui:Icon{File = destFolder .. "directional_light@2x.png"},
                            MinimumSize = iconsMediumLong,
                            Checkable = false,
                        },
                    },
                },
     
            },
        })
     
        -- The window was closed
        function win.On.FuSkinToolbarWin.Close(ev)
            disp:ExitLoop()
        end
     
        -- Add your GUI element based event functions here:
        itm = win:GetItems()
     
        function win.On.IconButtonCamera.Clicked(ev)
            print("[Camera][Button]")
            comp:AddTool("Camera3D", -32768, -32768)
        end
     
        function win.On.IconButtonCube.Clicked(ev)
            print("[Cube][Button]")
            comp:AddTool("Cube3D", -32768, -32768)
        end
     
        function win.On.IconButtonCubeMap.Clicked(ev)
            print("[CubeMap][Button]")
            comp:AddTool("CubeMap", -32768, -32768)
        end
     
        function win.On.IconButtonDirectionalLight.Clicked(ev)
            print("[Directional Light][Button]")
            comp:AddTool("LightDirectional", -32768, -32768)
        end
     
        -- The app:AddConfig() command that will capture the "Control + W" or "Control + F4" hotkeys so they will close the window instead of closing the foreground composite.
        app:AddConfig("FuSkinToolbarWin", {
            Target {
                ID = "FuSkinToolbarWin",
            },
     
            Hotkeys {
                Target = "FuSkinToolbarWin",
                Defaults = true,
     
                CONTROL_W = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}",
                CONTROL_F4 = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}",
            },
        })
     
        -- Display the window
        win:Show()
     
        -- Keep the window updating until the script is quit
        disp:RunLoop()
        win:Hide()
       
        app:RemoveConfig("FuSkinToolbarWin")
        collectgarbage()
    end
     
     
    function Main()
        -- Zip file settings
        skinZipFile = fusion:MapPath("FusionLibs:/Skins/Fusion.fuskin")
     
        -- Files to extract from the zip archive
        imageList = {
        "Tools/Icons/3d/camera@2x.png",
        "Tools/Icons/3d/cube@2x.png",
        "Tools/Icons/3d/cubemap@2x.png",
        "Tools/Icons/3d/directional_light@2x.png",
        }
     
        -- The output folder location
        outFolderPath = fusion:MapPath("Temp:/Fusion/")
     
        -- Check that Fusion/Resolve 16+ is found
        local ver = app:GetVersion()[1]
        if ver >= 16 then
            -- Extract the files from the fuskin
            UnzipSkinFiles(skinZipFile, imageList, outFolderPath)
     
            -- Display a GUI
            DisplayToolbar(outFolderPath)
        else
            print("[Error] Fusion/Resolve 16+ is required to use the Zip functionality.")
        end
       
        print("[Done]")
    end
     
     
    -- Run the main function
    Main()
     
