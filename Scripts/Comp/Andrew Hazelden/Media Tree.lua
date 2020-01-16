-- ----------------------------------------------------------------------------
-- Media Tree for Fusion - v0.4 2017-09-04 8.21 AM 
-- by Andrew Hazelden <andrew@andrewhazelden.com>
-- www.andrewhazelden.com
-- ----------------------------------------------------------------------------

-- Overview:
-- This script works in Fusion 8.2.1+ and allows you you quickly view a list of the Fusion saver, loader, and geometry nodes in your composite in a UI Manager based Tree view list.

-- Installation:
-- Copy this script to your Fusion 8.2.1+ user preferences "Scripts/Comp/" folder.

-- The Linux copy to clipboard command is "xclip"
-- This requires a custom xclip tool install on Linux:

-- Debian/Ubuntu:
-- sudo apt-get install xclip

-- Redhat/Centos/Fedora:
-- yum install xclip

-- Usage:
-- Step 1. Save your fusion composite to disk.
-- Step 2. Select the Script > Media Tree menu item. This will open a window with a tree view list of the loader and saver nodes in your composite.
-- Step 3. Single click on a row in the tree view to copy the filepath to your clipboard. Double click on a row to open the containing folder for the media asset up in a Finder/Explorer/Nautilus folder browsing window.
-- Step 4. After the "Media Tree" window is open, any time you re-save your Fusion .comp file in Fusion's GUI the contents will be updated automatically in the window.

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
  
-- Find out if we are running Fusion 6, 7, or 8
fu_major_version = math.floor(tonumber(eyeon._VERSION))

-- Find out the current operating system platform. The platform local variable should be set to either 'Windows', 'Mac', or 'Linux'.
platform = ''
if string.find(comp:MapPath('Fusion:\\'), 'Program Files', 1) then
  -- Check if the OS is Windows by searching for the Program Files folder
  platform = 'Windows'
elseif string.find(comp:MapPath('Fusion:\\'), 'PROGRA~1', 1) then
  -- Check if the OS is Windows by searching for the Program Files folder
  platform = 'Windows'
elseif string.find(comp:MapPath('Fusion:\\'), 'Applications', 1) then
  -- Check if the OS is Mac by searching for the Applications folder
  platform = 'Mac'
else
  platform = 'Linux'
end

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 1280,600

win = disp:AddWindow({
  ID = 'MediaTreeWin',
  WindowTitle = 'Media Tree',
  Geometry = { 100, 100, width, height },
  Spacing = 0,
  
  ui:VGroup{
    ID = 'root',
    ui:Tree{ID = 'Tree', SortingEnabled=true, Events = {ItemDoubleClicked=true, ItemClicked=true}, }, 
    
    ui:HGroup{
      Weight = 0,
      -- Add your GUI elements here:
    ui:Label{ ID = 'CommentLabel', Text = 'Single click on a row to copy the filepath to your clipboard. Double click on a row to open the containing folder.', Alignment = { AlignHCenter = true, AlignTop = true }, },
    },
    
  },
})

-- The window was closed
function win.On.MediaTreeWin.Close(ev)
    disp:ExitLoop()
end

-- Add your GUI element based event functions here:
itm = win:GetItems()

-- Track the Fusion save events
ui:AddNotify('Comp_Save', comp)
ui:AddNotify('Comp_SaveVersion', comp)
ui:AddNotify('Comp_SaveAs', comp)
ui:AddNotify('Comp_SaveCopyAs', comp)
 
-- The Fusion "Save" command was used
function disp.On.Comp_Save(ev)
  print('[Update] Comp saved. Refreshing the view.')
  UpdateTree()
end

-- The Fusion "Save Version" command was used
function disp.On.Comp_SaveVersion(ev)
  print('[Update] Comp saved as a new version. Refreshing the view.')
  UpdateTree()
end

-- The Fusion "Save As" command was used
function disp.On.Comp_SaveAs(ev)
  print('[Update] Comp saved to a new file. Refreshing the view.')
  UpdateTree()
end

-- The Fusion "Save Copy As" command was used
function disp.On.Comp_SaveCopyAs(ev)
  print('[Update] Comp saved as a copy to a new file. Refreshing the view.')
  UpdateTree()
end

-- Copy the filepath to the clipboard when a Tree view row is clicked on
function win.On.Tree.ItemClicked(ev)
  -- Column 2 = Filepath
  sourceMediaFile = ev.item.Text[2]
	-- Copy the filepath to the clipboard
  CopyToClipboard(sourceMediaFile)
  
  -- print('[Item Selected] ' .. sourceMediaFile)
  -- print('\n')
end

-- Open up the folder where the media is located when a Tree view row is clicked on
function win.On.Tree.ItemDoubleClicked(ev)
  -- Column 2 = Filepath
  sourceMediaFile = ev.item.Text[2]
  
	-- Open up the folder where the media is located
  mediaFolder = Dirname(sourceMediaFile)
  if eyeon.fileexists(mediaFolder) then
     OpenDirectory(mediaFolder)
  end
  
  -- print('[Item Selected] ' .. sourceMediaFile)
  -- print('\n')
end


-- Update the contents of the tree view
function UpdateTree()
  -- Clean out the previous entries in the Tree view
  itm.Tree:Clear()

  -- Add the Tree headers:
  -- Loader     Loader1     /Media/Project22/Image.0000.exr     [0-144]     0/0
  hdr = itm.Tree:NewItem()
  hdr.Text[0] = 'Node'
  hdr.Text[1] = 'Name'
  hdr.Text[2] = 'Filepath'
  hdr.Text[3] = 'Frame Range'
  hdr.Text[4] = 'Node X/Y Pos'
  itm.Tree:SetHeaderItem(hdr)

  -- Number of columns in the Tree list
  itm.Tree.ColumnCount = 5

  -- Resize the header column widths
  itm.Tree.ColumnWidth[0] = 120
  itm.Tree.ColumnWidth[1] = 120
  itm.Tree.ColumnWidth[2] = 700
  itm.Tree.ColumnWidth[3] = 100
  itm.Tree.ColumnWidth[4] = 100

  -- -------------------------------------------
  -- Start adding each image element:
  -- -------------------------------------------

  -- Should the selected nodes be listed? (Otherwise all loader/saver nodes will be listed from the comp)
  --listOnlySelectedNodes = true
  listOnlySelectedNodes = false

  local toollist1 = comp:GetToolList(listOnlySelectedNodes, 'Loader')
  local toollist2 = comp:GetToolList(listOnlySelectedNodes, 'Saver')
  local toollist3 = comp:GetToolList(listOnlySelectedNodes, 'SurfaceFBXMesh')
  local toollist4 = comp:GetToolList(listOnlySelectedNodes, 'SurfaceAlembicMesh')

  -- Scan the comp to check how many Loader nodes are present
  totalLoaders = table.getn(toollist1)
  totalSavers = table.getn(toollist2)
  totalFBX = table.getn(toollist3)
  totalAlembic = table.getn(toollist4)

  totalNodes = totalLoaders + totalSavers + totalFBX + totalAlembic
  itm.MediaTreeWin.WindowTitle = 'Media Tree: ' .. totalNodes .. ' Nodes'

  -- Iterate through each of the loader nodes
  for i, tool in ipairs(toollist1) do 
    toolAttrs = tool:GetAttrs()
    toolRegID = tool:GetAttrs().TOOLS_RegID
    nodeName = tool:GetAttrs().TOOLS_Name

    -- Expression for the current frame from the image sequence
    -- It will report a 'nil' when outside of the active frame range
    sourceMediaFile = tool.Output[comp.CurrentTime].Metadata.Filename

    currentMediaStartFrameRange = toolAttrs.TOOLNT_Clip_Start[1]
    currentMediaEndFrameRange = toolAttrs.TOOLNT_Clip_End[1]
    if currentMediaStartFrameRange ~= nil and currentMediaEndFrameRange ~= nil then
      -- Perform a sanity check on the frame range value
			if currentMediaEndFrameRange <= -100000000 then
				currentMediaEndFrameRange = currentMediaStartFrameRange
			end
    
      currentMediaTimeRangeString = '[' .. currentMediaStartFrameRange .. '-' .. currentMediaEndFrameRange .. ']'
    end
    
    -- Get the node position
    flow = comp.CurrentFrame.FlowView
    nodeXpos, nodeYpos = flow:GetPos(tool)
  
    -- print('['  .. toolRegID .. '] ' .. nodeName .. '\t[Image Filename] ' .. sourceMediaFile .. '\t[Node X/Y Pos] ' .. nodeXpos .. ' / ' .. nodeYpos)
  
    -- Add an new entry to the list
    itLoader = itm.Tree:NewItem(); 
    itLoader.Text[0] = 'Loader'; 
    itLoader.Text[1] = nodeName; 
    itLoader.Text[2] = sourceMediaFile; 
    itLoader.Text[3] = currentMediaTimeRangeString;
    itLoader.Text[4] = nodeXpos .. ' / ' .. nodeYpos;
    itm.Tree:AddTopLevelItem(itLoader)
  end


  -- Iterate through each of the saver nodes
  for i, tool in ipairs(toollist2) do 
    toolRegID = tool:GetAttrs().TOOLS_RegID
    nodeName = tool:GetAttrs().TOOLS_Name

    sourceMediaFile = comp:MapPath(tool.Clip[fu.TIME_UNDEFINED])

    currentMediaStartFrameRange = comp:GetAttrs().COMPN_RenderStart
    currentMediaEndFrameRange = comp:GetAttrs().COMPN_RenderEnd
    
    -- Perform a sanity check on the frame range value
    if currentMediaEndFrameRange <= -1000000000 then
    	currentMediaEndFrameRange = currentMediaStartFrameRange
    end
    
    currentMediaTimeRangeString = '[' .. currentMediaStartFrameRange .. '-' .. currentMediaEndFrameRange .. ']'
    
    -- Get the node position
    flow = comp.CurrentFrame.FlowView
    nodeXpos, nodeYpos = flow:GetPos(tool)
  
    -- print('['  .. toolRegID .. '] ' .. nodeName .. '\t\t[Image Filename] ' .. sourceMediaFile .. '\t[Node X/Y Pos] ' .. nodeXpos .. ' / ' .. nodeYpos)
    
    -- Add an new entry to the list
    itLoader = itm.Tree:NewItem();
    itLoader.Text[0] = 'Saver'; 
    itLoader.Text[1] = nodeName; 
    itLoader.Text[2] = sourceMediaFile; 
    itLoader.Text[3] = currentMediaTimeRangeString;
    itLoader.Text[4] = nodeXpos .. ' / ' .. nodeYpos;
    itm.Tree:AddTopLevelItem(itLoader)
  end

  -- Iterate through each of the FBXMesh3D nodes
  for i, tool in ipairs(toollist3) do 
    toolRegID = tool:GetAttrs().TOOLS_RegID
    nodeName = tool:GetAttrs().TOOLS_Name
    
    sourceMediaFile = comp:MapPath(tool:GetInput('ImportFile'))
    
    -- Get the node position
    flow = comp.CurrentFrame.FlowView
    nodeXpos, nodeYpos = flow:GetPos(tool)

    -- print('['  .. toolRegID .. '] ' .. nodeName .. '\t\t[FBXMesh3D Filename] ' .. sourceMediaFile .. '\t[Node X/Y Pos] ' .. nodeXpos .. ' / ' .. nodeYpos)
  
    -- Add an new entry to the list
    itLoader = itm.Tree:NewItem(); 
    itLoader.Text[0] = 'FBXMesh3D'; 
    itLoader.Text[1] = nodeName; 
    itLoader.Text[2] = sourceMediaFile; 
    itLoader.Text[3] = 'N/A';
    itLoader.Text[4] = nodeXpos .. ' / ' .. nodeYpos;
    itm.Tree:AddTopLevelItem(itLoader)
  end
  
  -- Iterate through each of the SurfaceAlembicMesh nodes
  for i, tool in ipairs(toollist4) do 
    toolRegID = tool:GetAttrs().TOOLS_RegID
    nodeName = tool:GetAttrs().TOOLS_Name
    
    sourceMediaFile = comp:MapPath(tool:GetInput('Filename'))
    
    -- Get the node position
    flow = comp.CurrentFrame.FlowView
    nodeXpos, nodeYpos = flow:GetPos(tool)

    -- print('['  .. toolRegID .. '] ' .. nodeName .. '\t\t[AlembicMesh3D Filename] ' .. sourceMediaFile .. '\t[Node X/Y Pos] ' .. nodeXpos .. ' / ' .. nodeYpos)
  
    -- Add an new entry to the list
    itLoader = itm.Tree:NewItem(); 
    itLoader.Text[0] = 'AlembicMesh3D'; 
    itLoader.Text[1] = nodeName; 
    itLoader.Text[2] = sourceMediaFile; 
    itLoader.Text[3] = 'N/A';
    itLoader.Text[4] = nodeXpos .. ' / ' .. nodeYpos;
    itm.Tree:AddTopLevelItem(itLoader)
  end
end


-- Open a folder window up using your desktop file browser
function OpenDirectory(mediaDirName)
  command = nil
  dir = Dirname(mediaDirName)

  -- Open a folder view using the os native command
  if platform == 'Windows' then
    -- Running on Windows
    command = 'explorer "' .. dir .. '"'
    
    -- print("[Launch Command] ", command)
    os.execute(command)
  elseif platform == 'Mac' then
    -- Running on Mac
    command = 'open "' .. dir .. '" &'
          
    -- print("[Launch Command] ", command)
    os.execute(command)
  elseif platform == 'Linux' then
    -- Running on Linux
    command = 'nautilus "' .. dir .. '" &'
          
    -- print("[Launch Command] ", command)
    os.execute(command)
  else
    print('[Platform] ', platform)
    print('There is an invalid platform defined in the local platform variable at the top of the code.')
  end
  
  print('[Opening Directory] ' .. dir)
end


-- Find out the current directory from a file path
-- Example: print(Dirname("/Users/Shared/file.txt"))
function Dirname(mediaDirName)
-- LUA Dirname command inspired by Stackoverflow code example:
-- http://stackoverflow.com/questions/9102126/lua-return-directory-path-from-path
  sep = ''
  
  if platform == 'Windows' then
    sep = '\\'
  elseif platform == 'Mac' then
    sep = '/'
  else
    -- Linux
    sep = '/'
  end
  
  return mediaDirName:match('(.*' .. sep .. ')')
end


-- Copy text to the operating system's clipboard
-- Example: CopyToClipboard('Hello World!')
function CopyToClipboard(textString)
  -- The system temporary directory path (Example: $TEMP/Fusion/)
  outputDirectory = comp:MapPath('Temp:\\Fusion\\')
  clipboardTempFile = outputDirectory .. 'ClipboardText.txt'

  -- Create the temp folder if required
  os.execute('mkdir "' .. outputDirectory .. '"')

  -- Open up the file pointer for the output textfile
  outClipFile, err = io.open(clipboardTempFile,'w')
  if err then
    print("[Error Opening Clipboard Temporary File for Writing]")
    return
  end

  outClipFile:write(textString,'\n')

  -- Close the file pointer on the output textfile
  outClipFile:close()

  if platform == 'Windows' then
    -- The Windows copy to clipboard command is "clip"
    command = 'clip < "' .. clipboardTempFile .. '"'
  elseif platform == 'Mac' then
    -- The Mac copy to clipboard command is "pbcopy"
    command = 'pbcopy < "' .. clipboardTempFile .. '"'
  elseif platform == 'Linux' then
    -- The Linux copy to clipboard command is "xclip"
    -- This requires a custom xclip tool install on Linux:
 
    -- Debian/Ubuntu:
    -- sudo apt-get install xclip
 
    -- Redhat/Centos/Fedora:
    -- yum install xclip
    command = 'cat "' .. clipboardTempFile .. '" | xclip -selection clipboard &'
  end

  print('[Copy to Clipboard] ' .. textString)
  os.execute(command)
end


-- Update the contents of the tree view
UpdateTree()

win:Show()
disp:RunLoop()
win:Hide()
