--------------------------------------------------------
-- Proxy Fusion (up to version 7) Deadline Submission Script
--------------------------------------------------------

--------------------------------------------------------
-- Helper Functions
--------------------------------------------------------
function MessageBox( msg, title )
	local d = {}
	d[1] = {"Msg", Name = msg, "Text", ReadOnly = true, Lines = 0 }
	comp:AskUser( title, d )
end

local function iswindows()
	return (package.config:sub(1,1) == "\\")
end

local function rtrim(s)
  local n = #s
  while n > 0 and s:find("^%s", n) do n = n - 1 end
  return s:sub(1, n)
end

local function getDeadlineCommand()
	deadlineCommand = ""
	deadlinePath = os.getenv( "DEADLINE_PATH" )
	
	if not iswindows() and ( deadlinePath == nil or deadlinePath == "" ) then
		if fileexists( "/Users/Shared/Thinkbox/DEADLINE_PATH" ) then
			input = assert( io.open( "/Users/Shared/Thinkbox/DEADLINE_PATH", 'r' ) )
			deadlinePath = assert( input:read( '*a' ) )
			input:close()
			
			deadlinePath = rtrim( deadlinePath )
		end
	end
	
	if deadlinePath == nil or deadlinePath == "" then
		deadlineCommand = "deadlinecommand"
	else
		deadlineCommand = deadlinePath .."/deadlinecommand"
	end
		
	return deadlineCommand
end

local function RunDeadlineCommand( options )

	deadlineCommand = getDeadlineCommand()
	local command, commandOutput = "", ""
	local input;

	if iswindows() then
		--io.popen Strips the first and last Quote in a command if there are more then 2 quotes so we wrap everything in quotes to guarantee this will not fail.
		command = "\"\"" .. deadlineCommand .. "\" " .. options .. "\""
		input = assert( io.popen( command, 'r' ) )
		commandOutput = assert( input:read( '*a' ) )
		input:close()
	else
		-- On *nix systems io.popen doesn't grab stdout, so we use os.execute and pipe the results into a file that we read.
		local tempFile = os.tmpname()
		
		command = "\"" .. deadlineCommand .. "\" " .. options .. " > \"" .. tempFile .. "\""
		os.execute( command )
		input = assert( io.open( tempFile, 'r' ) )
		commandOutput = assert( input:read( '*a' ) )
		input:close()
		
		os.remove( tempFile )
	end
	
	return rtrim(commandOutput)
end

function GetDeadlineRepositoryFilePath()
	
	local path = ""
	
	-- iup is the Fusion < 9 UI framework. Here we are doing feature detection for version checking
	if( iup == nil ) then
		path = RunDeadlineCommand( "-GetRepositoryFilePath submission/Fusion/Main/SubmitToDeadlineMonitor.lua" )
	else
		path = RunDeadlineCommand( "-GetRepositoryFilePath submission/Fusion/Main/SubmitToDeadline.eyeonscript" )
	end
	 
	if ( path == "" or path == nil ) then
		MessageBox( "Failed to get repository path from deadlinecommand", "Submit to Deadline Proxy" )
		return nil
	else
		return path
	end
end

--------------------------------------------------------
-- Main Script
--------------------------------------------------------
scriptPath = GetDeadlineRepositoryFilePath()
scriptMessage = string.format("Running script \"%s\"\n", scriptPath)
print(scriptMessage);
if not fileexists( scriptPath ) then
	d = {}
	d[1] = {"Msg", Name = "Submit to Deadline Proxy", "Text", ReadOnly = true, Lines = 10, Default = "The SubmitToDeadline.eyeonscript script could not be\nfound in the Deadline Repository. Please make sure\nthat the Deadline Client has been installed on this\nmachine, that the Deadline Client bin folder is set in the DEADLINE_PATH\nenvironment variable, and that the Deadline Client has been\nconfigured to point to a valid Repository." }
	comp:AskUser( "Submit to Deadline Proxy" , d )
	
	return nil
end

dofile( scriptPath )
