-- module table
local typeutils = {}

function typeutils.to_fusion_text(str)
    --[[
        Creates a Fusion Text object from a Lua string.

        :param str: Lua string to build Fusion Text object from.
        :type str: string

        :rtype: Text
    ]]
    local fu_text = Text(str)
    return fu_text
end

function typeutils.to_fusion_number(num)
    --[[
        Creates a Fusion Number object from a Lua number.

        :param str: Lua number to build Fusion Number object from.
        :type str: number

        :rtype: Number
    ]]
    local fu_number = Number(num)
    return fu_number
end

-- return module table
return typeutils
