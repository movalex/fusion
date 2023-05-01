-- ============================================================================
-- modules
-- ============================================================================
local json = self and require("dkjson") or nil

-- module table
textutils = {}

function textutils.write_file(path, content)
    --[[
        Writes content into a file.

        :param path: Path to write file to.
        :type path: string

        :param content: Content to write into a file.
        :type content: string
    ]]
    fp = io.open(path, "w")
    if fp == nil then
        local directory = path:match("(.*[/\\])")
        error(string.format("[Write Error] File or directory does not exist: %s", directory))
    end
    fp:write(content)
    fp:close()
end


function textutils.read_file(path)
    --[[
        Reads the content of a file.

        :param path: Path of a file to read.
        :type path: string

        :rtype: string
    ]]
    local fp = io.open(path, "rb")
    if fp == nil then
        error(string.format("file does not exist: %s", path))
    end

    local content = fp:read("*all")
    fp:close()
    return content
end

function textutils.read_url(url)
    --[[
        Reads data from a url.

        :param url: URL of the json file to read.
        :type url: string

        :rtype: string
    ]]

    if url and url:match('^file://') or url:match('^https?://') then
        ffi = require 'ffi'
        curl = require 'lj2curl'
        ezreq = require 'lj2curl.CRLEasyRequest'
        local req = ezreq(url)
        local body = {}

        req:setOption(curl.CURLOPT_SSL_VERIFYPEER, 0)
        req:setOption(curl.CURLOPT_WRITEFUNCTION, ffi.cast('curl_write_callback', function(buffer, size, nitems, userdata)
            table.insert(body, ffi.string(buffer, size*nitems))
            return nitems
        end))

        ok, err = req:perform()
        if ok then
            local nodeName = self.Name
            local folder = self.Comp:MapPath('Temp:/Vonk/')
            local path = self.Comp:MapPath(folder .. tostring(nodeName)  .. '_' .. tostring(bmd.createuuid())..'.txt')
            if bmd.fileexists(folder) == false then
                bmd.createdir(folder)
            end

            local content = table.concat(body)
            textutils.write_file(path, content)

            local str = textutils.read_file(path)

            os.remove(path)
            return str
        else
            error(string.format("cURL error '%s'", err))
        end
    else
      error(string.format("cURL invalid network protocol '%s'", url))
    end
end

function textutils.join(values, separator)
    --[[
        Joins an array of text with given separation character.

        :param values: String array to join.
        :type values: table[string]

        :param separator: Optional separation character, defaults to empty string.
        :type separator: string

        :rtype: string
    ]]
    local sep = separator or ""
    local joined = table.concat(values, sep)
    return joined
end

function textutils.format(format_str, values)
    --[[
        Formats a template string with values.
        
        Note: Will fail if unescaped percent signs are in the format_string input text

        :param format_str: Format template with {%d+} placeholders.
                           Example: {1}-{2}x{3}
        :type format_str: string

        :param values: Table/vector containing values to format by index.
                       Example: {1="foo", 2="bar", 3="man", 4="chu"}
        :type values: table

        :rtype: string
    ]]
    local formatted_string = format_str

    for part in string.gmatch(format_str, "{%d}+") do
        if part ~= nil and type(values) == "table" then
            -- get part to format from index
            local index = string.match(part, "%d+")
            -- print("[Capture Index]", index)
            -- print("[Values]", table.getn(values))
            -- dump(values)
            local repl = values[tonumber(index)]

            -- replace format by part
            if repl ~= nil then
                formatted_string = string.gsub(formatted_string, part, repl)
            end
        end
    end

    return formatted_string
end

function textutils.case(text, value)
    --[[
        Returns the modified case of a text string.

        :param text: Text to format.
        :type text: str
        
        :param value: 1 = "Passthrough", 2 = "Capitalize Words", 3 = "UPPER CASE", 4 = "lower case".
        :type value: integer

        :rtype: string
    ]]
    local case = text

    if value == 0 then
        case = text
    elseif value == 1 then
        local function title(first, rest)
           return first:upper() .. rest:lower()
        end
        case = text:gsub("(%a)([%w_']*)", title)
    elseif value == 2 then
        case = string.upper(text)
    elseif value == 3 then
        case = string.lower(text)
    end

    print(value)

    return case
end

function textutils.len(text)
    --[[
        Returns the length of a string.

        :param text: Text to get length for.
        :type text: str

        :rtype: number
    ]]
    local length = string.len(text)
    return length
end

function textutils.sub(text, s, e)
    --[[
        Returns a substring of a string.

        :param text: String to take substring from.
        :type text: string

        :param s: Start position of the substring. Defaults to 1.
        :type s: number

        :param e: End position of the substring. Defaults to -1.
        :type e: number

        :rtype: string
    ]]
    local start_ = s or 1
    local end_ = e or -1
    local substring = string.sub(text, start_, end_)
    return substring
end

function textutils.replace(text, pattern, repl)
    --[[
        Replaces a substring of a string with given text.

        More info about patterns: http://lua-users.org/wiki/PatternsTutorial

        :param text: Text to replace substring of.
        :type text: string

        :param pattern: Pattern capturing the substring to replace.
        :type pattern: string

        :param repl: Text to replace the substring with.
        :type repl: string

        :rtype: string
    ]]
    local replaced = string.gsub(text, pattern, repl)
    return replaced
end

function textutils.lstrip(text, strip)
    --[[
        Removes the leading substring of a string.

        :param text: Text to strip from.
        :type text: string

        :param strip: Substring to strip.
        :type strip: string

        :rtype: string
    ]]
    local pattern = string.format("^%s", strip)
    local stripped = textutils.replace(text, pattern, "")
    return stripped
end

function textutils.rstrip(text, strip)
    --[[
        Removes the trailing substring of a string.

        :param text: Text to strip from.
        :type text: string

        :param strip: Substring to strip.
        :type strip: string

        :rtype: string
    ]]
    local pattern = string.format("%s$", strip)
    local stripped = textutils.replace(text, pattern, "")
    return stripped
end

function textutils.split(text, pattern)
    --[[
        Removes the trailing substring of a string.

        :param text: Text to strip from.
        :type text: string

        :param strip: Substring to strip.
        :type strip: string

        :rtype: string
    ]]
    local elements = {}
    
    for element in string.gmatch(text, pattern) do
        table.insert(elements, element)
    end

    return elements
end


function textutils.array_from_string(text)
    --[[
        Builds an array from a lua table

        :param mat_str: Json string to build matrix object from.
        :type mat_str: string

        :rtype: matrix
    ]]
    local array ={}
    array["array"] = text
    --array["size"] = table.getn(lua_table)
    array["size"] = table.getn(array["array"])
    --array["size"] = 1

    return json.encode(array)
end


function textutils.parse_filename(filename)
    --[[
        parseFilename() from bmd.scriptlib
        A function for ripping a filepath into little bits

        :param FullPath : The raw, original path sent to the function
        :param FullPathMap : The PathMap expanded original path sent to the function
        :param Path : The path, without filename
        :param PathMap : The PathMap expanded path, without filename
        :param FullName : The name of the clip w\ extension
        :param Name : The name without extension
        :param CleanName: The name of the clip, without extension or sequence
        :param SNum : The original sequence string, or "" if no sequence
        :param Number : The sequence as a numeric value, or nil if no sequence
        :param Extension: The raw extension of the clip
        :param Padding : Amount of padding in the sequence, or nil if no sequence
        :param UNC : A true or false value indicating whether the path is a UNC path or not

        :rtype: returns a table with the following
    ]]

    local seq = {}
    seq.FullPath = filename
    seq.FullPathMap = self.Comp:MapPath(filename)
    string.gsub(seq.FullPath, "^(.+[/\\])(.+)", function(path, name) seq.Path = path seq.FullName = name end)
    string.gsub(seq.FullPath, "^(.+[/\\])(.+)", function(path, name) seq.PathMap = self.Comp:MapPath(path) seq.FullName = name end)
    string.gsub(seq.FullName, "^(.+)(%..+)$", function(name, ext) seq.Name = name seq.Extension = ext end)

    if not seq.Name then -- no extension?
        seq.Name = seq.FullName
    end

    string.gsub(seq.Name, "^(.-)(%d+)$", function(name, SNum) seq.CleanName = name seq.SNum = SNum end)

    if seq.SNum then
        seq.Number = tonumber(seq.SNum)
        seq.Padding = string.len(seq.SNum)
    else
         seq.SNum = ""
         seq.CleanName = seq.Name
    end

    if seq.Extension == nil then seq.Extension = "" end
    seq.UNC = (string.sub(seq.Path, 1, 2) == [[\\]])

    return seq
end

function textutils.ReadLine(data, index)
    --[[
        Extracts a single line of text from a multi-line block of text

        :param data: A multi-line block of text
        :type data: string

        :param index: Line number to extract
        :type index: integer

        :rtype: string
    ]]--

    local currentLine = 0
    for i in string.gmatch(data, "[^\r\n]+") do
        currentLine = currentLine + 1; 
        -- print(currentLine, ":", i)

        if currentLine == index then
            return i
        end
    end

    return ""
end

function textutils.LineCount(data)
    --[[
        Counts the number of newlines found in a multi-line block of text

        :param data: A multi-line block of text
        :type data: string

        :rtype: integer
    ]]--

    local currentLine = 0
    for i in string.gmatch(data, "[^\r\n]+") do
        currentLine = currentLine + 1; 
        -- print(currentLine, ":", i)
    end

    return currentLine
end



-- return module table
return textutils
