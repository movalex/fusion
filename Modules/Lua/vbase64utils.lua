-- module table
base64utils = {}

function base64utils.read_file(path, mode)
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

function base64utils.write_file(path, content, mode)
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

function base64utils.len(text)
    --[[
        Returns the length of a string.

        :param text: Text to get length for.
        :type text: str

        :rtype: number
    ]]
    local length = string.len(text)
    return length
end




function base64utils.create_dir(path)
    --[[
        Copy a file on disk

        :param src_path: Path to the source file on disk
        :type src_path: str

        :param dest_path: Path to the destination file on disk
        :type dest_path: str
    ]]

    if not bmd.direxists(path) then
        bmd.createdir(path)
        if not bmd.direxists(path) then
            error(string.format("Failed to create directory: %s", directory))
        end
    end
end

function base64utils.file_copy(src_path, dest_path)
    --[[
        Copy a file on disk
        Based upon "bmd.copyfile" from the bmd.scriptlib

        :param src_path: Path to the source file on disk
        :type src_path: str

        :param dest_path: Path to the destination file on disk
        :type dest_path: str
    ]]

    local read_size = 65536
    src, errMsg = io.open(src_path, "rb")
    if src == nil then
        error(string.format("Source path does not exist: %s", src))
    end

    local size = src:seek("end")
    src:seek("set")

    dest, errMsg = io.open(dest_path, "wb")
    if dest == nil then
        error(string.format("Destination path does not exist: %s", dest))
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

function base64utils.base64encode(data)
    --[[--
        Base64 encodes a Fusion Text object.

        :param data: data to encode.
        :type data: string

        :rtype: string
    --]]--

    if data ~= nil then
        -- Encode Base64 script from: http://lua-users.org/wiki/BaseSixtyFour
        -- Base64 Character Look Up
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

        -- Process the data
        return ((data:gsub('.', function(x) 
            local r, b = '', x:byte()
            for i = 8, 1, -1 do
                r = r .. (b % 2^ i - b % 2^ (i - 1) > 0 and '1' or '0')
            end
            return r;
        end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c = 0
            for i = 1, 6 do 
                c = c + (x:sub(i, i) == '1' and 2^(6 - i) or 0)
            end
            return b:sub(c + 1,c + 1)
        end) .. ({ '', '==', '=' })[#data % 3 + 1])
    else
        return ''
    end
end

function base64utils.base64decode(data)
    --[[--
        Base64 decodes data into a Fusion Text object.

        :param data: data to decode.
        :type data: string

        :rtype: string
    --]]--
    if data ~= nil then
        -- Decode Base64 script from: http://lua-users.org/wiki/BaseSixtyFour
        -- Base64 Character Look Up
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    else
        return ''
    end
end

-- return module table
return base64utils
