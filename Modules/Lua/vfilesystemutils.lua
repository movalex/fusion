-- module table
filesystemutils = {}

function filesystemutils.read_file(path, mode)
    --[[
        Reads the content of a file.

        :param path: Path of a file to read.
        :type path: string

        :param mode: The file access mode: "r" for read ASCII, "rb" for read binary. Fallback is "r".
        :type mode: string

        :rtype: string
    ]]
    local fp = io.open(path, mode or "r")
    if fp == nil then
        error(string.format("file does not exist: %s", path))
    end

    local content = fp:read("*all")
    fp:close()
    return content
end

function filesystemutils.write_file(path, content, mode)
    --[[
        Writes content into a file.

        :param path: Path to write file to.
        :type path: string

        :param content: Content to write into a file.
        :type content: string

        :param mode: The file access mode: "w" for write ASCII, "wb" for write binary. Fallback is "w".
        :type mode: string
    ]]
    fp = io.open(path, mode or "w")
    if fp == nil then
        local directory = path:match("(.*[/\\])")
        error(string.format("directory does not exist: %s", directory))
    end
    fp:write(content)
    fp:close()
end

function filesystemutils.len(text)
    --[[
        Returns the length of a string.

        :param text: Text to get length for.
        :type text: str

        :rtype: number
    ]]
    local length = string.len(text)
    return length
end

function filesystemutils.parent_dir(path)
    --[[
        Returns the parent directory.

        :param path: file path
        :type path: string

        :rtype: string
    ]]

    local dir = path:match("(.*[/\\])")

    return dir
end

function filesystemutils.create_dir(path)
    --[[
        Creates a new directory.

        :param path: Folder path to create
        :type path: string

        :rtype: string
    ]]

    if path == "" then
        error("[Create Dir] The name of the directory to create is empty.")
    end

    if not bmd.direxists(self.Comp:MapPath(path)) then
        bmd.createdir(self.Comp:MapPath(path))
        if not bmd.direxists(self.Comp:MapPath(path)) then
            error(string.format("[Create Dir] Failed to create directory: %s", path))
        end
    end
end

function filesystemutils.file_copy(src_path, dest_path, create_dir)
    --[[
        Copy a file on disk
        Based upon "bmd.copyfile" from the bmd.scriptlib

        :param src_path: Path to the source file on disk
        :type src_path: str

        :param dest_path: Path to the destination file on disk
        :type dest_path: str
    ]]

    if not src_path or src_path == "" then
        error("[File Copy] The name of the source file to copy is empty.")
    elseif not dest_path or dest_path == "" then
        error("[File Copy] The name of the destination file to copy is empty.")
    end

    -- Read the source file
    local read_size = 65536
    src, errMsg = io.open(src_path, "rb")
    if src == nil then
        error(string.format("[File Copy] Source path does not exist: %s", src))
    end

    local size = src:seek("end")
    src:seek("set")

    -- print("[Create Dir]", create_dir)
    if create_dir == 1 then
        -- Create the output folder if required
        local dir = filesystemutils.parent_dir(dest_path)
        filesystemutils.create_dir(dir)
    end

    -- Write the destination file
    dest, errMsg = io.open(dest_path, "wb")
    if dest == nil then
        error(string.format("[File Copy] Destination path does not exist: %s", dest))
    end

    src_data = src:read(read_size)
    repeat
        dest:write(src_data)
        src_data = src:read(read_size)
    until src_data == nil

    src:close()
    dest:close()

    return size
end



function filesystemutils.list_dirs(path, pattern, exportFullpath, expandPathMaps, skipHiddenFiles)
    --[[
        Lists the sub-folders in the specified folder.

        :example: dump(filesystemutils.list_dirs("Comp:", "*", true, true))
        :example: dump(filesystemutils.list_dirs("Comp:", "*.exr", true, true))

        :param path: Path of a folder.
        :type path: string

        :param pattern: 
        :type mode: string

        :param exportFullpath: Should the full folder path be appended to the filename
        :type exportFullpath: int

        :param expandPathMaps: Should the file relative PathMap be expanded on export
        :type expandPathMaps: int

        :param skipHiddenFiles: Should hidden folders be shown in the listing?
        :type skipHiddenFiles: int

        :param path: Path of a folder.
        :type path: string


        :rtype: string
    ]]
    -- Add the platform specific folder slash character
    local osSeparator = package.config:sub(1,1)

    -- Expand the virtual PathMap segments and parse the output into a list of files
    -- mp = MultiPath('FileSystem:')
    
    -- Create a Lua table that holds a (fake) virtual PathMap table for the folder
    -- mp:Map({['FileSystem:'] = path .. "/"})
    
    -- Scan the folder recursively
    -- Example: mp:ReadDir(string pattern, boolean recursive, boolean flat hierarchy)
    -- local dir = mp:ReadDir(pattern, true, true)

    local dir = bmd.readdir(self.Comp:MapPath(path .. osSeparator .. pattern))
    -- dump(dir)

    local ret = {}

    for i, file in ipairs(dir) do
        if file.IsDir then
            if (skipHiddenFiles == 1) and (file.Name:sub(1, 1) == ".") then
                -- Hide files that start with a period
                -- print("[Hidden File]", file.Name)
            else
                if exportFullpath == 1 then
                    if expandPathMaps == 1 then
                        table.insert(ret, self.Comp:MapPath(path .. file.Name))
                    else
                        table.insert(ret, path .. file.Name)
                    end
                else
                    table.insert(ret, file.Name)
                end
            end
        end
    end

    -- Sort the table
    table.sort(ret)
    -- print("[Sorted]")
    -- dump(ret)

    local str = table.concat(ret, "\n")
    -- dump(str)

    return str
end


function filesystemutils.list_files(path, pattern, exportFullpath, expandPathMaps, skipHiddenFiles)
    --[[
        Lists the files in the specified folder.

        :example: dump(filesystemutils.list_files("Comp:", "*", true, true))
        :example: dump(filesystemutils.list_files("Comp:", "*.exr", true, true))

        :param path: Path of a folder.
        :type path: string

        :param pattern: 
        :type mode: string

        :param exportFullpath: Should the full folder path be appended to the filename
        :type exportFullpath: int

        :param expandPathMaps: Should the file relative PathMap be expanded on export
        :type expandPathMaps: int

        :param skipHiddenFiles: Should hidden files like .DS_Store or Thumbs.db be hidden from the file listing?
        :type skipHiddenFiles: int

        :param path: Path of a folder.
        :type path: string


        :rtype: string
    ]]
    -- Add the platform specific folder slash character
    local osSeparator = package.config:sub(1,1)

    -- Expand the virtual PathMap segments and parse the output into a list of files
    -- mp = MultiPath('FileSystem:')
    
    -- Create a Lua table that holds a (fake) virtual PathMap table for the folder
    -- mp:Map({['FileSystem:'] = path .. "/"})
    
    -- Scan the folder recursively
    -- Example: mp:ReadDir(string pattern, boolean recursive, boolean flat hierarchy)
    -- local dir = mp:ReadDir(pattern, true, true)

    local dir = bmd.readdir(self.Comp:MapPath(path .. osSeparator .. pattern))
    -- dump(dir)

    local ret = {}

    for i, file in ipairs(dir) do
        if not file.IsDir then
            if skipHiddenFiles == 1 and (file.Name == ".DS_Store" or file.Name == "Thumbs.db" or file.Name:sub(1, 1) == ".") then
                -- Hide files that start with a period, or are thumbnail resources
                -- print("[Hidden File]", file.Name)
            else
                if exportFullpath == 1 then
                    if expandPathMaps == 1 then
                        table.insert(ret, self.Comp:MapPath(path .. file.Name))
                    else
                        table.insert(ret, path .. file.Name)
                    end
                else
                    table.insert(ret, file.Name)
                end
            end
        end
    end

    -- Sort the table
    table.sort(ret)
    -- print("[Sorted]")
    -- dump(ret)

    local str = table.concat(ret, "\n")
    -- dump(str)

    return str
end

function filesystemutils.file_size(path)
    --[[
        Lists the size of a file in bytes

        :param path: Path of a file.
        :type path: string

        :rtype: integer
    ]]

    local dir = bmd.readdir(self.Comp:MapPath(path))
    -- dump(dir)

    local ret = {}

    for i, file in ipairs(dir) do
        if not file.IsDir then
            -- print("[File]", file.Name, "[Size]", file.Size)
            return file.Size
        end
    end

    return 0
end


-- return module table
return filesystemutils
