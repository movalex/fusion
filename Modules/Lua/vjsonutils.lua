-- ============================================================================
-- modules
-- ============================================================================
local json = self and require("dkjson") or nil

-- module table
jsonutils = {}

-- private
function jsonutils._read_file(path)
    --[[
        Reads the content of a file.

        :param path: Path of a file to read.
        :type path: string

        :rtype: string
    ]]
    local fp = io.open(path, "r")
    if fp == nil then
        error(string.format("file does not exist: %s", path))
    end

    local content = fp:read("*all")
    fp:close()
    return content
end

function jsonutils._write_file(path, content)
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
        error(string.format("directory does not exist: %s", directory))
    end
    fp:write(content)
    fp:close()
end

function jsonutils.create_dir(path)
    --[[
        Copy a file on disk

        :param src_path: Path to the source file on disk
        :type src_path: string

        :param dest_path: Path to the destination file on disk
        :type dest_path: string
    ]]

    if not bmd.direxists(path) then
        bmd.createdir(path)
        if not bmd.direxists(path) then
            error(string.format("Failed to create directory: %s", path))
        end
    end
end

function jsonutils._decode(json_string)
    --[[
        Decodes a json string into a json table.

        :param json_string: JSON string to decode.
        :type json_string: string

        :rtype: table
    ]]
    local json_table = json.decode(json_string)
    return json_table
end

function jsonutils._encode(json_table)
    --[[
        Encodes a json table into a json string.

        :param json_table: JSON table to encode.
        :type json_table: table

        :rtype: string
    ]]
    local json_string = json.encode(json_table)
    return json_string
end

function jsonutils._encode_indent(json_table, indent_int)
    --[[
        Encodes a json table into a json string.

        :param json_table: JSON table to encode.
        :type json_table: table
        :param indent_int: indentation state
        :type indent_int: integer


        :rtype: string
    ]]
    local json_string = json.encode(json_table, {indent = indent_int})
    return json_string
end

function jsonutils._is_json_string_valid(json_string)
    --[[
        Returns whether a json string is valid or not.
        Checks for nil and empty string.

        :param json_string: JSON string to verify.
        :type json_string: string

        :rtype: bool
    ]]
    local is_valid = not not json_string
    return is_valid
end

function jsonutils._is_json_table_valid(json_table)
    --[[
        Returns whether a json table is valid or not.
        Checks for nil and empty table.

        :param json_table: JSON table to verify.
        :type json_table: table

        :rtype: bool
    ]]
    local is_valid = not not json_table
    return is_valid
end

-- public
function jsonutils.decode(json_string)
    --[[
        Decodes a json string into a table.

        :param json_string: JSON string to decode.
        :type json_string: string

        :rtype: table
    ]]
    local is_string_valid = jsonutils._is_json_string_valid(json_string)
    if not is_string_valid then
        error(string.format("invalid json string: %s", json_string))
    end

    local json_table = jsonutils._decode(json_string)

    local is_table_valid = jsonutils._is_json_table_valid(json_table)
    if not is_table_valid then
        error(string.format("cannot decode json string: %s", json_string))
    end

    return json_table
end

function jsonutils.encode(json_table)
    --[[
        Encodes a json table into a json string.

        :param json_table: JSON table to encode.
        :type json_table: table

        :rtype: string
    ]]
    local is_table_valid = jsonutils._is_json_table_valid(json_table)
    if not is_table_valid then
        error("invalid json table")
    end

    local json_string = jsonutils._encode(json_table)

    local is_string_valid = jsonutils._is_json_string_valid(json_string)
    if not is_string_valid then
        error(string.format("invalid json string: %s", json_string))
    end

    return json_string
end

function jsonutils.encode_indent(json_table, indent_int)
    --[[
        Encodes a json table into a json string with indentations.

        :param json_table: JSON table to encode.
        :type json_table: table

        :rtype: string
    ]]
    local is_table_valid = jsonutils._is_json_table_valid(json_table)
    if not is_table_valid then
        error("invalid json table")
    end

    local json_string = jsonutils._encode_indent(json_table, true)

    local is_string_valid = jsonutils._is_json_string_valid(json_string)
    if not is_string_valid then
        error(string.format("invalid json string: %s", json_string))
    end

    return json_string
end


function jsonutils.is_json_string_valid(json_string)
    --[[
        Returns whether a json string is valid or not.

        :param json_string: JSON string to verify.
        :type json_string: string

        :rtype: bool
    ]]
    -- if json_string == nil then
    --     return false
    -- end
    local is_string_valid = jsonutils._is_json_string_valid(json_string)
    if not is_string_valid then
        return false
    end

    local json_table = jsonutils._decode(json_string)
    local is_table_valid = jsonutils._is_json_table_valid(json_table)
    return is_table_valid
end

function jsonutils.validate_json_string(json_string)
    --[[
        Raises an error if a json string is invalid.

        :param json_string: JSON string to validate.
        :type json_string: string
    ]]
    local is_valid = jsonutils.is_json_string_valid(json_string)
    if not is_valid then
        error(string.format("invalid json string: %s", json_string))
    end
end

function jsonutils.read_json_url(url)
    --[[
        Reads a json string from a url.

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
            local path = self.Comp:MapPath(folder .. tostring(nodeName)  .. '_' .. tostring(bmd.createuuid())..'.json')
            if bmd.fileexists(folder) == false then
                bmd.createdir(folder)
            end

            local content = table.concat(body)
            jsonutils._write_file(path, content)

            local json_string = jsonutils._read_file(path)
            jsonutils.validate_json_string(json_string)

            os.remove(path)
            return json_string
        else
            error(string.format("cURL error '%s'", err))
        end
    else
      error(string.format("cURL invalid network protocol '%s'", url))
    end
end

function jsonutils.read_json_string(path)
    --[[
        Reads a json string from a file.

        :param path: Path of the json file to read.
        :type path: string

        :rtype: string
    ]]
    local json_string = jsonutils._read_file(path)
    jsonutils.validate_json_string(json_string)
    return json_string
end

function jsonutils.write_json_string(json_string, path)
    --[[
        Writes a json string into a file.

        :param json_string: JSON string to write into file.
        :type json_string: string

        :param path: Path to write a json file to.
        :type path: string
    ]]
    jsonutils.validate_json_string(json_string)
    jsonutils._write_file(path, json_string)
end

function jsonutils.get(t, key)
    --[[
        Returns the value of a key in a table.

        :param t: Table to get key value for.
        :type t: table

        :param key: Key to get value of.
        :type key: string

        :rtype: ?
    ]]
    local value = nil
    local found = false

    for k, v in pairs(t) do
        if k == key then
            value = v
            found = true
            break
        end
    end

    if not found then
        error(string.format("no key '%s' found in json table", key))
    end

    return value
end

-- return module table
return jsonutils
