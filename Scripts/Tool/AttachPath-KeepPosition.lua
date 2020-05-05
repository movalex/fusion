---------------------------------------------
-- USE: Run the tool script on a tool with a point modifier,
-- select the point control to modify, 
-- select the path, and click okay.  The script will create an offset position 
-- that will keep the tool locked in its current position, instead of having it
-- thrown to wherever the path's center is.
-- The tool will then animate along the path's center.  
-- based on the old "attach mask - xf- stroke tp path - keep position tool" script by (eyeon)/blackmagic

-- Used with permission by Frantic Films (http://www.franticfilms.com)
-- written by Sean Konrad (sean@eyeonline.com)
-- Created May 5, 2005.
-- updated : Sept 27, 2005
-- changes : updated for 5
-- upodated: January, 4th 2017 Michael Vorberg (mv@empty98.de) to check for XYPath and PolyPath
-- updated: July, 21 2018 Michael Vorberg (mv@empty98.de) to work with any tool with a point control, updated to the new UIManager of fusion9 and Resolve15




-----------------------------------------------------
-- isin(t, val)
--
-- scans table t and returns true if the string val is
-- found in the table.
--
-- introduced bmd.dfscriptlib v1.0
-----------------------------------------------------
function bmd.isin(t, val)
	if type(t) == "table" then
		for i,v in pairs(t) do
			if (type(v) == "string") and (type(val) == "string") then
				if string.lower(v) == string.lower(val) then
					return true
				end
			else
				if v == val then
					return true
				end
			end
		end
	end

	return false
end





selectedTool = tool or comp.ActiveTool
x = selectedTool:GetInputList()

toollist = composition:GetToolList()
masklist = {}
pathlist = {}
pathcount=0
nomasks = true
nopaths=true
maskcount=0
maskdump={}
pathdump={}
trackercount=0
trackerlist={}
trackerdump={}

PointInputList = {}
PointInputListUser = {}
PointInputListID = {}
PointInputListCount = 0

path_ids = {}
pathid = "PolyPath"
table.insert(path_ids, "PolyPath")
table.insert(path_ids, "XYPath")



local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 400,100

win = disp:AddWindow({
  ID = 'MyWin',
  WindowTitle = 'Attach Path, keep position',
  Geometry = {100, 100, width, height},
  Spacing = 10,
  
  ui:VGroup{
    ID = 'root',
    
    -- Add your GUI elements here:
    ui:ComboBox{ID = 'PointsCombo', Text = 'Points Menu',},
	ui:ComboBox{ID = 'PathCombo', Text = 'Paths Menu',},
	ui:Button{ID = 'OKButton', Text = 'Ok',},
  },
})

-- The window was closed


-- Add your GUI element based event functions here:
itm = win:GetItems()

-- Add the items to the ComboBox menu
--find if the tool has a point input
for i, inp in pairs(x) do
    if inp:GetAttrs().INPS_IC_Name and string.sub(inp:GetAttrs().INPS_IC_Name, 1,6) == "Stroke" then
        dump(inp:GetAttrs())
    end
	if inp:GetAttrs().INPS_DataType == "Point" then
		PointInputListUser[PointInputListCount] = inp:GetAttrs().INPS_Name
		PointInputList[PointInputListCount] = inp:GetAttrs().INPS_ID
		itm.PointsCombo:AddItem(inp:GetAttrs().INPS_Name)
		PointInputListCount = PointInputListCount+1
	end
end

if PointInputListCount == 0 then
   print("ERROR: There is no Point control to modify.")
   itm.PointsCombo:AddItem("no point control on this node found to modify")
   --return
end 


-- Get all the paths and add them to the combo box
for i = 1, table.getn(toollist) do
   local var1 = toollist[i]:GetAttrs()
   if bmd.isin (path_ids, var1.TOOLS_RegID) then
      
      pathcount=pathcount+1
      -- Store the name to display to the user.
      pathlist[pathcount]=var1.TOOLS_Name
      pathdump[pathcount]=toollist[i]
	  itm.PathCombo:AddItem(var1.TOOLS_Name)
      -- If it found at least one path, set the "nopaths" variable to false.
      nopaths=false
   end
end

if nopaths then
	itm.PathCombo:AddItem("no path found to attach")
end



function win.On.OKButton.Clicked(ev)
    if PointInputListCount == 0 then
        disp:ExitLoop()
    end
	  inpname = itm.PointsCombo.CurrentText
	  print (tool[inpname])
	  tool[inpname] = nil
		 -- Just to make sure the center is connected to nil
	   tool[inpname] = nil
	   
	   -- Create a list of all the offsets in the composition so that when the user makes a new 
	   -- offset, they're able to track which one it was for manipulation.  
	   offsetcount=0
	   offsetdump={}
	   offsetlist={}
	   
	   -- Reset the toollist variable.  Because now that we've deleted any old offsets
	   -- the toollist will have to be refreshed in case Fusion's naming handlers see that 
	   -- the old offset position is the same name as the new one.
	   toollist=composition:GetToolList()
	   for i = 1, table.getn(toollist) do
		  k = toollist[i]:GetAttrs()
		  if k.TOOLS_RegID == "Offset" then
			 offsetcount=offsetcount+1
			 offsetdump[offsetcount]=toollist[i]
			 offsetlist[offsetcount]=k.TOOLS_Name
			 
		  end
	   end
	   print (pathdump[1])
	   thisisthepath=pathdump[itm.PathCombo.CurrentIndex+1]
	   -- Find out the original center of the masks and
	   -- add a modify Position to the center.
	   -- Also start the undo action.
	   composition:StartUndo("Attach Masks to Tracker")
	   oldcenter={}
	   tool[inpname] = nil
	   oldcenter[1] = tool[inpname][comp.CurrentTime][1]
	   oldcenter[2] = tool[inpname][comp.CurrentTime][2]
	   var10=composition:GetAttrs()
	   
	   
	   -- Now, add an offset position to the center.  
	   tool[inpname] = comp:Offset({Offset = {0,0}})
	   toollist2 = composition:GetToolList()
	   for m = 1, table.getn(toollist2) do
		  k = toollist2[m]:GetAttrs()
		  if k.TOOLS_RegID == "Offset" then
			 inarray=false
						 
			 for l = 1, offsetcount do
				if k.TOOLS_Name == offsetlist[l] then
				   inarray=true
				end
			 end
			 if inarray == true then
			 else
				-- Position the offset based on the old center's difference from the new center.
				-- Also let the user know what we're doing.
				
				print("   Connecting " .. tool:GetAttrs().TOOLS_Name .. " to " .. thisisthepath:GetAttrs().TOOLS_Name..".")
				offsetcount=offsetcount+1
				
				-- Connect the path to the offset position.
				--check if its a PolyPath or an XYPath
				if thisisthepath:GetAttrs().TOOLS_RegID == "PolyPath" then
					toollist2[m].Position = thisisthepath.Position
				else
					toollist2[m].Position = thisisthepath.Value
				end
				newcenter={}
				newcenter[1]=tool[inpname][comp.CurrentTime][1]
				newcenter[2]=tool[inpname][comp.CurrentTime][2]
				
				offsetx = (oldcenter[1]-newcenter[1])
				offsety = (oldcenter[2]-newcenter[2])
				toollist2[m].Offset = {offsetx, offsety}
				offsetdump[offsetcount]=toollist2[m]
				offsetlist[offsetcount]=k.TOOLS_Name
				
				-- The above code should position the tool properly.
			 end
		  end
	   end
  disp:ExitLoop()
end

function win.On.MyWin.Close(ev)
    disp:ExitLoop()
end


win:Show()
disp:RunLoop()
win:Hide()
