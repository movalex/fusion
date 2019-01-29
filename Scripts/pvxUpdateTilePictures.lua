logo = [[

    ____           _    ___  __
   / __ \_________| |  / / |/ /
  / /_/ / ___/ __ \ | / /|   / 
 / ____/ /  / /_/ / |/ //   |  
/_/   /_/   \____/|___//_/|_|  
      pvxUpdateTilePicture v0.1
                by Blazej Floch
-------------------------------]]
-- License --
-- http://creativecommons.org/licenses/by-sa/4.0/
--
-- Description --
-- Updates the specified tool types in the composition.
-- This results in rendering and therefore updating the
-- tilepictures.
--
-- Release notes --
-- v0.1 14.03.2015 - bfloch: Initial release
print (logo)

-- User Settings
----------------------------------------------------------------------
-- Output information to the console
VERBOSE = true

-- Add tool types to be updated here.
-- Use the tools TOOLS_RegID set to any non-nil value
FILTER_TOOL_IDS = { 
	["Loader"]=true,
	["TextPlus"]=true,
}

-- Main Code
----------------------------------------------------------------------
-- Get all tools and filter later on
tools = comp:GetToolList(false)

count = 0
for i, tool in ipairs(tools) do
	if FILTER_TOOL_IDS[tool:GetAttrs().TOOLS_RegID] ~= nil then
		-- In case tools were in the filter without an output
		out = tool:FindMainOutput(1)
		if out ~= nil then 
			if VERBOSE == true then
				print ("Updating " .. tool.Name)
			end
			out:GetValue()
			count = count + 1
		end
	end
end

if VERBOSE == true then
	if count < 1 then
	print ("No tools updated.")
	end
	print ("------------- END -------------")
end
