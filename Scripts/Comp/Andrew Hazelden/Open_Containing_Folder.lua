--[[--
----------------------------------------------------------------------------
Open Containing Folder - v4.1 2019-11-04
by Andrew Hazelden
www.andrewhazelden.com
andrew@andrewhazelden.com

KartaVR
https://www.andrewhazelden.com/projects/kartavr/docs/
----------------------------------------------------------------------------
Overview:

The "Open Containing Folder" script reads the active Nodes view selection and then opens a desktop Explorer/Finder/Nautilus file browser window to show the containing folder that holds the selected media.

This script works with the following types of nodes in the Fusion 9-16.1+ and Resolve 15-16.1+ Fusion page Nodes view:

- AlembicMesh3D
- ExporterFBX
- External Matte Saver (fuse)
- FBXMesh3D
- GetFrame (fuse)
- LifeSaver (fuse)
- Loader
- MediaIn
- Metadata "Filename"
- NetLoader (fuse)
- PutFrame (fuse)
- Saver

--]]--

-- Check the current operating system platform
platform = (FuPLATFORM_WINDOWS and 'Windows') or (FuPLATFORM_MAC and 'Mac') or (FuPLATFORM_LINUX and 'Linux')

-- Add the platform specific folder slash character
osSeparator = package.config:sub(1,1)

-- Find out the current directory from a file path
-- Example: print(Dirname('/Volumes/Media/image.0000.exr'))
function Dirname(filename)
	return filename:match('(.*' .. tostring(osSeparator) .. ')')
end

-- Open a folder window up using your desktop file browser
function OpenDirectory(mediaDirName)
	path = Dirname(mediaDirName)
	-- print('[Open Containing Folder] ' .. path)
	bmd.openfileexternal('Open', path)
end

-- Check if Fusion Standalone or the Resolve Fusion page is active
host = fusion:MapPath('Fusion:/')
if string.lower(host):match('resolve') then
	hostOS = 'Resolve'
else
	hostOS = 'Fusion'
end

-- The main function
function Main()
	-- Check if Fusion is running
	if not fusion then
		print('[Error] This is a Blackmagic Fusion Lua script. It should be run from within Fusion.')
		return
	end

	local mediaDirName = nil

	-- List the selected Node in Fusion 
	if not tool then
		tool = comp.ActiveTool
	end

	local selectedNode = tool
	if selectedNode then
		toolAttrs = selectedNode:GetAttrs()

		local result = nil
		-- Read the file path data from the node
		if toolAttrs.TOOLS_RegID == 'MediaIn' then
			loadedImage = comp:MapPath(selectedNode:GetData('MediaProps.MEDIA_PATH'))
			mediaDirName = Dirname(loadedImage)
			result = '[MediaIn file] ' .. tostring(loadedImage)
		elseif toolAttrs.TOOLS_RegID == 'Loader' then
			loadedImage = comp:MapPath(toolAttrs.TOOLST_Clip_Name[1])
			mediaDirName = Dirname(loadedImage)
			result = '[Loader file] ' .. tostring(loadedImage)
		elseif toolAttrs.TOOLS_RegID == 'Saver' then
			loadedImage = comp:MapPath(toolAttrs.TOOLST_Clip_Name[1])
			mediaDirName = Dirname(loadedImage)
			result = '[Saver file] ' .. tostring(loadedImage)
		elseif toolAttrs.TOOLS_RegID == 'SurfaceFBXMesh' then
			loadedMesh = comp:MapPath(selectedNode:GetInput('ImportFile'))
			mediaDirName = Dirname(loadedMesh)
			result = '[FBXMesh3D file] ' .. tostring(loadedMesh)
		elseif toolAttrs.TOOLS_RegID == 'SurfaceAlembicMesh' then
			loadedMesh = comp:MapPath(selectedNode:GetInput('Filename'))
			mediaDirName = Dirname(loadedMesh)
			result = '[AlembicMesh3D file] ' .. tostring(loadedMesh)
		elseif toolAttrs.TOOLS_RegID == 'ExporterFBX' then
			loadedMesh = comp:MapPath(selectedNode:GetInput('Filename'))
			mediaDirName = Dirname(loadedMesh)
			result = '[ExporterFBX file] ' .. tostring(loadedMesh)
		elseif toolAttrs.TOOLS_RegID == 'Fuse.ExternalMatteSaver' then
			loadedImage = comp:MapPath(selectedNode:GetInput('Filename'))
			mediaDirName = Dirname(loadedImage)
			result = '[ExternalMatteSaver file] ' .. tostring(loadedImage)
		elseif toolAttrs.TOOLS_RegID == 'Fuse.LifeSaver' then
			loadedImage = comp:MapPath(selectedNode:GetInput('Filename'))
			mediaDirName = Dirname(loadedImage)
			result = '[LifeSaver file] ' .. tostring(loadedImage)
		elseif toolAttrs.TOOLS_RegID == 'Fuse.NetLoader' then
			loadedImage = comp:MapPath('Temp:/NetLoader/')
			mediaDirName = Dirname(loadedImage)
			result = '[NetLoader File] ' .. tostring(loadedImage)
		elseif toolAttrs.TOOLS_RegID == 'Fuse.PutFrame' then
			loadedImage = comp:MapPath(selectedNode:GetInput('Filename'))
			mediaDirName = Dirname(loadedImage)
			result = '[PutFrame file] ' .. tostring(loadedImage)
		elseif toolAttrs.TOOLS_RegID == 'Fuse.GetFrame' then
			loadedImage = comp:MapPath(selectedNode:GetInput('Filename'))
			mediaDirName = Dirname(loadedImage)
			result = '[GetFrame file] ' .. tostring(loadedImage)
		elseif toolAttrs.TOOLS_RegID == 'Fuse.LifeSaver' then
			if selectedNode.Output[comp.CurrentTime] then
				loadedImage = selectedNode.Output[comp.CurrentTime].Metadata.Filename
			else
				loadedImage = ''
			end
			mediaDirName = Dirname(loadedImage)
			result = '[LifeSaver file] ' .. tostring(loadedImage)
		else
			-- Check if there is an image Metadata "Filename" entry
			if selectedNode and selectedNode.Output[comp.CurrentTime] and selectedNode.Output[comp.CurrentTime].Metadata and selectedNode.Output[comp.CurrentTime].Metadata.Filename then
				-- Fall back for any other node by checking for a Metadata "Filename" entry
				loadedImage = selectedNode.Output[comp.CurrentTime].Metadata.Filename
				mediaDirName = Dirname(loadedImage)
				result = '[Metadata "Filename" file] ' .. tostring(loadedImage)
			else
				-- No dice. No filename support
				result = '[Invalid Node Type] '
			end
		end

		print(result .. '\t[Selected Node] '.. selectedNode.Name .. '\t[Node Type] ' .. toolAttrs.TOOLS_RegID)
		-- Check if the value is nil
		if mediaDirName then
			-- Check if the folder exists and create it if required
			if not bmd.direxists(mediaDirName) then
				bmd.createdir(mediaDirName)
				print('[Created Folder] ' .. mediaDirName .. '\n')
			end

			-- Open the folder
			if bmd.fileexists(mediaDirName) then
				OpenDirectory(mediaDirName)
			else
				print('[Folder Missing] ' .. mediaDirName .. '\n')
				return
			end
		end
	else
		print('[Open Containing Folder] No media node was selected. Please select a node in the Flow view and run this script again.')
		return
	end
end

-- Run the main function
Main()
print('[Done]')
