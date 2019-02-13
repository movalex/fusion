------------------------------------------------------------
-- Attach Mask to path, keep position (Tool).lua, Revision: 2.0

-- USE: Run the tool script on a mask with a center position, 
-- select the path, and click okay. The script will create an offset position 
-- that will keep the tool locked in its current position, instead of having it
-- thrown to wherever the path's center is.
-- The mask will then animate along the path's center. Also works for transforms
--
-- Used with permission by Frantic Films (http://www.franticfilms.com)
-- written by Sean Konrad (sean@eyeonline.com)
-- Created May 5, 2005.
-- updated : Sept 27, 2005
-- changes : updated for 5
------------------------------------------------------------



print("\n\n----------------------------------------------\nATTACH MASK KEEP POSITION:\n----------------------------------------------\n")

-- Define what the RegIDs for every mask are.
mask_ids = {}
table.insert(mask_ids, "PolylineMask") -- polygon
table.insert(mask_ids, "BSplineMask") -- polygon
table.insert(mask_ids, "RectangleMask") -- rectangle
table.insert(mask_ids, "EllipseMask") -- ellipse
--table.insert(mask_ids, 1934455380) -- triangle 
table.insert(mask_ids, "Transform") -- Transform another newer addition that was originally from another separate script
-- Triangles were eliminated as they have no "center" points.
-- Same with wands.
table.insert(mask_ids, "BitmapMask") -- bitmap
table.insert(mask_ids, "Stroke")
-- Define the Path ID
pathid = "PolyPath"

--Determine what tools are Masks
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

tool = comp.ActiveTool
local var1 = tool:GetAttrs()
-- Check to see if the tool is even a mask.
if not bmd.isin(mask_ids, var1.TOOLS_RegID) then
   print("ERROR: This is not a Mask / Paint Stroke.")
   return
end 


-- Connect the center to nil so that if there was a path or an offset position
-- on the tool, there no longer is one.
tool.Center:ConnectTo(nil)

-- Get all the paths.
for i = 1, table.getn(toollist) do
   local var1 = toollist:GetAttrs()
      if var1.TOOLS_RegID == pathid then

      pathcount=pathcount+1
      -- Store the name to display to the user.
      pathlist[pathcount]=var1.TOOLS_Name
      pathdump[pathcount]=toollist
      -- If it found at least one path, set the "nopaths" variable to false.
      nopaths=false
   end
end

-- Check to see if the user has at least one path.
if nopaths then
   d = {}
   d = {"Msg", Name = "Warning", "Text", ReadOnly = true, Lines = 5, Default = errormsg }
   composition:AskUser("You've got no paths.", d)
else
-- Find out what path values they want to attach the tool to.
   d = {}
   counter = 0
   stringset={}
for i = 1, pathcount do
   table.insert(stringset, pathlist)
end
d[1] = {"Dropdown", Name = "Path", "Dropdown", Options=stringset, Default = 0}
ret = {}
ret= composition:AskUser("Select Your Path", d)


-- Just to make sure the center is connected to nil
tool.Center=nil
tool.Center = nil

-- Create a list of all the offsets in the composition so that when the user makes a new 
-- offset, they're able to track which one it was for manipulation. 
offsetcount=0
offsetdump={}
offsetlist={}


-- Reset the toollist variable. Because now that we've deleted any old offsets
-- the toollist will have to be refreshed in case Fusion's naming handlers see that 
-- the old offset position is the same name as the new one.
toollist=composition:GetToolList()
   for i = 1, table.getn(toollist) do
      k = toollist:GetAttrs()
   if k.TOOLS_RegID == "Offset" then
      offsetcount=offsetcount+1
      offsetdump[offsetcount]=toollist
      offsetlist[offsetcount]=k.TOOLS_Name

   end
end
thisisthepath=pathdump[ret.Dropdown+1]
-- Find out the original center of the masks and
-- add a modify Position to the center.
-- Also start the undo action.
composition:StartUndo("Attach Masks to Tracker")
oldcenter={}
tool.Center = nil
oldcenter[1] = tool.Center[CurrentTime][1]
oldcenter[2] = tool.Center[CurrentTime][2]
var10=composition:GetAttrs()


-- Now, add an offset position to the center. 
tool.Center = Offset({Offset = {0,0}})
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

print(" Connecting " .. tool:GetAttrs().TOOLS_Name .. " to " .. thisisthepath:GetAttrs().TOOLS_Name..".")
offsetcount=offsetcount+1

-- Connect the path to the offset position.
toollist2[m].Position = thisisthepath.Position
newcenter={}
newcenter[1]=tool.Center[CurrentTime][1]
newcenter[2]=tool.Center[CurrentTime][2]

offsetx = (oldcenter[1]-newcenter[1])
offsety = (oldcenter[2]-newcenter[2])
toollist2[m].Offset = {offsetx, offsety}
offsetdump[offsetcount]=toollist2[m]
offsetlist[offsetcount]=k.TOOLS_Name

-- The above code should position the tool properly.
end
end
end
end
composition:EndUndo(true)