------------------------------------------------------------------------------
-- 3D - Raise Version
--
-- based on import directory script
-- 
-- reads path from selected loader and removes last directory from it, this is our search path
-- this last (removed) directory contains version number (last group of numbers in directory name)
-- search drive for all clips loadable to fusion that are on search path
-- for each loader in comp, compare loader path with search path, matching loaders are candidates to raise version
-- change paths to loaders only if all of them have higher version with the same length and no missing frames
-- 
-- Jirka Sindelar
------------------------------------------------------------------------------


-- data structures:


--- loaderTable: (list of all loaders in comp)

-- for each loader:
--       attrs (loader atributes)
--       tool (loader handle)
--       toChange (true if loader matches selected loader path)
--       knownindex  (numeric index to corresponding file in known tab (which is list of clips on harddisk)
--       versionTbl   (details about version, derived from loader clip path
--         VersionNum  (version as number -> 3)
--         FullPath  ( -> "F:\3dTemp\3D\ver_003\")
--         Version  (version as string -> "ver_003")
--         VersionStr  ( -> "ver_")
--         VersionNumPad  (version as string -> 3)
--         Element   ( -> "3D")
--         ElementPath  ( -> "F:\3dTemp\3D\")


--- known: (list of clips on harddisk)

-- for each clip:
--      file (path for loader clip, first frame for sequences -> "F:\3dTemp\3D\ver_005\masterLayer.diffuse.0001.exr")
--      term (matching pattern for sequences -> "F:\3dTemp\3D\ver_005\masterLayer.diffuse.exr")  
--      category ("seq" -> sequence of image formats / "multi" -> multiframe file format / "single" -> image format, only one frame)
--      layer (cleanname before . -> "masterLayer")
--      pass (cleanname after . -> "diffuse")
--      numMin (smallest number in sequence)
--      numMax (biggest number in sequence)
--      numSum (number of frames in sequence, for hole detection)
--      versionTbl (same as in loaderTable)
--      corresponding (table of indexes to other items in known table that are same clips with different version)
--         pos (index to other item)
--         version (same as of known[pos].versionTbl.VersionNum)
--         numbersMatch (true if numMin, numMax and numSum matches)




-- for func is_known_format
local known_extensions = { ".fbx", ".dae", ".obj", ".3ds", ".dxf" }

-- for ui - loaders with available versions
function UpdateList(list, data)
   
   list[1] = nil      -- clears the list
   local Cnt = table.getn(data)
   for i=1, Cnt do
      list[tostring(i)] = data[i]
   end
end

-- for ui - available versions
function UpdateVersionsAvailable(list, data)
   
   list[1] = nil      -- clears the list
   local Cnt = table.getn(data)
   for i=1, Cnt do
      list[tostring(i)] = data[i]
   end
end


------------------------------------------------------------------------------
-- FUNCTION is_known_format
--
-- use this function to determine if an extension matches a valid clip format for Fusion
-- expects a table of fusion registry values, and a string containing an extension, including the "."
-- returns an index of -1 if its contained within the 'known_extensions' table,
-- or the index to the entry in fmt_list that matches the extension, or nil
------------------------------------------------------------------------------


function is_known_format(ext)
   ext = string.lower(ext)
   if known_extensions[ext] then
      return -1
   end
   -- for j, ext2 in pairs(known_extensions) do
   --    if ext2 == ext then
   --       return -1
   --    end
   -- end

   for i, v in pairs(fmt_attrs) do
      for j, ext2 in pairs(v.REGST_MediaFormat_Extension) do
         if string.lower(ext2) == ext then
            return i
         end
      end
   end

   return nil
end

------------------------------------------------------------------------------
-- FUNCTION doInsert
--
-- used to determine if the table seq describes a clip we already know
-- if not, then we check to see if it is a loadable clip
-- if it is, then we return true
-- if the clip is not multi frame (like avi) and it has a sequence number then we 
-- also indicate that this should be added to the known table 
------------------------------------------------------------------------------
local function doInsert(seq, known)
   index = is_known_format(seq.Extension)

   if index then 
      if index < 0 then
         return true, nil
      else
         attrs = fmt_attrs[index]
         if attrs.REGB_MediaFormat_CanLoadMulti == true then
            info = {}
            --info.isknown = true
            info.numMin =  -1
            info.numMax =  -1
            info.numSum =  -1
            info.category =  "multi"
            info.file = seq.FullPath
            return true, info
          else
            if seq.Number == nil then
               info = {}
               --info.isknown = true
               info.numMin =  -1
               info.numMax =  -1
               info.numSum =  -1
               info.category =  "single"
               info.file = seq.FullPath
               return true, info
            else
               -- term is the clean name for comparison
               term = seq.Path..seq.CleanName..seq.Extension
               
               -- search for known file seq
               found = false
               for i, v in known do
                  if v.term == term then
                     if seq.Number < known[i].numMin then known[i].numMin = seq.Number end
                     if seq.Number > known[i].numMax then known[i].numMax = seq.Number end
                     known[i].numSum = known[i].numSum + 1
                     found = true
                  end
               end
               if found == false then
                  info = {}
                  --info.isknown = true
                  info.numMin =  seq.Number
                  info.numMax =  seq.Number
                  info.numSum =  1
                  info.category =  "seq"
                  info.term =  term
                  info.file = seq.FullPath
                  return true, info
               end
            end
         end
      end
   end
   return false, nil
end

------------------------------------------------------------------------------
-- doDirectories
--
-- function gets a path (ending in "\") and a mask (i.e. *.*)
-- recurses through the path building tables of clips, comps and settings
--
-------------------------------------------------------------------------------
function doDirectories(dir, mask)
   local path = dir..mask


   local files = readdir(path)

   if files == nil then print("   FAILED TO READ : "..string.lower(dir)) return end

   for i, f in ipairs(files) do

      if type(f)=="table" and f.IsDir == true then
      
         --if ret.Recurse == 1 then
         if true then
            doDirectories(dir..f.Name.."\\", mask)
         end

      else
         if type(f) == "table" then
            seq = eyeon.parseFilename(dir..f.Name)

            -- if we have no extension, we don't want to bother
            if seq.Extension then
               isclip, isknown = doInsert(seq, known)

               if isknown then
                  table.insert(known, isknown) 
               end
            end
         end
      end
   end
end

------------------------------------------------------------------------------
-- oneUpDirectory
--
-- example path: x:\somwhere\deep\lies\3Dfolder\charactername\ver_001\something.0001.exr
-- example out: x:\somwhere\deep\lies\3Dfolder\charactername\
-- returns empty string if error (path too short)
------------------------------------------------------------------------------

function oneUpDirectory(pth)
   
   newpath = ""
   pathParts = eyeon.split(pth, "\\")
   if table.getn(pathParts) >= 3 then
      -- get one up directory
      for i, itm in pathParts do
         if i < table.getn(pathParts)-1 then
            newpath = newpath..itm.."\\"
         end
      end
   end
   return newpath
end


------------------------------------------------------------------------------
-- splitToPathAndVersion
--
-- example path: x:\somwhere\deep\lies\3Dfolder\charactername\ver_001\
--
-- FullPath = x:\somwhere\deep\lies\3Dfolder\charactername\ver_001\
-- ElementPath = x:\somwhere\deep\lies\3Dfolder\charactername\
-- Element = charactername
-- Version = ver_001
-- VersionStr = ver_
-- VersionNum = 1
-- VersionNumPad = 3
------------------------------------------------------------------------------
function splitToPathAndVersion(pth)
   
   local out = {}
   -- no version
   version = ""
   versionSnum = ""
   versionNum = -1
   versionNumPad = -1
   versionString = ""
   -- no element
   element = ""
   
   
   -- path divide (last char is backslash)
   pathParts = eyeon.split(pth, "\\")
   if table.getn(pathParts) >= 3 then
      element = pathParts[table.getn(pathParts)-2]
      version = pathParts[table.getn(pathParts)-1]
      
      -- get one up directory
      newpath = ""
      for i, itm in pathParts do
         if i < table.getn(pathParts)-1 then
            newpath = newpath..itm.."\\"
         end
      end
   
      -- get version number
      string.gsub(version, "^(.-)(%d+)$", function(name, SNum) versionString = name versionSnum = SNum end)
      if versionSnum then
         versionNum = tonumber(versionSnum) 
         versionNumPad = string.len(versionSnum)
      end
   end
   
   -- out
   out.FullPath = pth
   out.ElementPath = newpath
   out.Element = element
   out.Version = version
   out.VersionStr = versionString
   out.VersionNum = versionNum
   out.VersionNumPad = versionNumPad
   
   return out
end

------------------------------------------------------------------------------
-- findCorrespondingClips
--
-- for every clip in known tab, add list of corresponding indexes
-- ElementPath, layer and pass must match
-- numMin, numMax, numSum match or not
------------------------------------------------------------------------------
function findCorrespondingClips(known)
   
   for i,v in pairs(known) do
      
      corresponding = {}
      for j,compareV in pairs(known) do
         -- skip self compare
         if j ~= i then
            corrItem = {}
            if compareV.versionTbl ~= nil then
               if v.versionTbl.ElementPath == compareV.versionTbl.ElementPath and v.layer == compareV.layer and v.pass == compareV.pass then
                  -- found similar path, now compare numbers
                  numbersMatch = false
                  if v.numMin == compareV.numMin and v.numMax == compareV.numMax and v.numSum == compareV.numSum then
                     numbersMatch = true
                  end
                  corrItem.pos = j
                  corrItem.numbersMatch = numbersMatch
                  corrItem.version = compareV.versionTbl.VersionNum
                  table.insert(corresponding, corrItem)
               end
            end
         end
      end
      known[i].corresponding = corresponding
   end
end

------------------------------------------------------------------------------
-- findCorrespondingClipsPlus
--
-- for every clip in known tab, add list of corresponding indexes
-- ElementPath, layer and pass must match
-- numMin, numMax, numSum match or not

-- adds also selfreference that is skipped in findCorrespondingClips
------------------------------------------------------------------------------
function findCorrespondingClipsPlus(known)
   
   for i,v in pairs(known) do
      
      corresponding = {}
      for j,compareV in pairs(known) do
            corrItem = {}
            if compareV.versionTbl ~= nil then
               if v.versionTbl.ElementPath == compareV.versionTbl.ElementPath and v.layer == compareV.layer and v.pass == compareV.pass then
                  -- found similar path, now compare numbers
                  numbersMatch = false
                  if v.numMin == compareV.numMin and v.numMax == compareV.numMax and v.numSum == compareV.numSum then
                     numbersMatch = true
                  end
                  corrItem.pos = j
                  corrItem.numbersMatch = numbersMatch
                  corrItem.version = compareV.versionTbl.VersionNum
                  table.insert(corresponding, corrItem)
               end
            end
            if j ~= i then
               known[j].VersionNum = compareV.versionTbl.VersionNum
            end
      end
      known[i].corresponding = corresponding
   end
end
------------------------------------------------------------------------------
-- makeVersionList
--
-- makes list of all versions for all selected loaders
-- loader 1 has version 1 and 2, loader2 has version 1 and 5
-- outputs sorted list -> {1,2,5}
------------------------------------------------------------------------------
function makeVersionList(loaderTable, known)
   versionList = {}
   for j, pickedLoader in loaderTable do
      if pickedLoader.toChange then
         for i, tst in known[pickedLoader.knownindex].corresponding do
            --if tst.numbersMatch then
               if versionList[tst.version] ~= nil then
                  versionList[tst.version] = versionList[tst.version] + 1
               else
                  versionList[tst.version] = 1
               end
            --end
         end
      end   
   end
   
   versionListSorted = {}
   for i, v in pairs(versionList) do
      table.insert( versionListSorted, i )   
   end
   table.sort(versionListSorted)
   
   return versionListSorted
end

------------------------------------------------------------------------------
-- makeListing
--
-- creates formated output for table of picked loaders and their versions
------------------------------------------------------------------------------
function makeListing(loaderTable, known, versionList)
   -- find min and max version
   lst = {}
   local tempList = {}
   
   -- format strings and save them to tempList
   for j, pickedLoader in loaderTable do
      if pickedLoader.toChange then
         oneline = {}
         k = known[pickedLoader.knownindex]
         verstr = tostring(k.versionTbl.VersionNum)
         nmestr = k.layer.."."..k.pass
         --line = verstr.." "..nmestr..string.rep(" ", 25 - string.len(nmestr))
         oneline.nmestr = nmestr
         oneline.verstr = verstr
         oneline.numtab = {}
         for i, v in  k.corresponding do
            holes = known[v.pos].numMax - known[v.pos].numMin + 1 - known[v.pos].numSum
            onestr = "v" .. tostring(v.version) .. " " .. tostring(known[v.pos].numMin) .. "-" .. tostring(known[v.pos].numMax) .. ":" .. tostring(known[v.pos].numSum) .. "m:" .. holes
            table.insert(oneline.numtab, onestr)
         end
         table.insert(tempList, oneline)
      end
   end
   
   -- find max chars for each column
   maxverstr = 1
   maxnmestr = 5
   maxonestr = 3
   for j, lne in tempList do
      if string.len(lne.verstr) > maxverstr then maxverstr = string.len(lne.verstr) end
      if string.len(lne.nmestr) > maxnmestr then maxnmestr = string.len(lne.nmestr) end
      for i, nm in lne.numtab do
         if string.len(nm) > maxonestr then maxonestr = string.len(nm) end
      end
   end
   maxverstr = maxverstr + 2
   maxnmestr = maxnmestr + 2
   maxonestr = maxonestr + 2
   
   -- create table with aligned columns
   for j, lne in tempList do
      line = ""
      line = "v"..lne.verstr..string.rep(" ", maxverstr - string.len(lne.verstr))
      line = line .. lne.nmestr..string.rep(" ", maxnmestr - string.len(lne.nmestr))
      for i, nm in lne.numtab do
         line = line .. nm..string.rep(" ", maxonestr - string.len(nm))
      end
      table.insert(lst, line)
   end

   return lst
end

function getNewLoaderName(v)
   -- v is one item of known list
   
   lyr = v.layer
   if v.layer == "masterLayer" then lyr = "mL" end
   if v.layer == "-" then lyr = "" end
   nm = "v"..tostring(v.VersionNum).."_"..lyr.."_"..v.pass
   
   return nm
end   
   
function changeOneLoader(pickedLoader, knownItem)

   handle = pickedLoader.tool
   clip = knownItem.file
   name = getNewLoaderName(knownItem)
   attrs = pickedLoader.attrs
   
   -- set new name
   handle:SetAttrs({TOOLB_NameSet=true})
   handle:SetAttrs({TOOLS_Name = name})
   
   -- set new clip (TODO restore pass state!!!)
   handle:SetAttrs({TOOLB_PassThrough = true})
   
   -- editing params
   cl = 1 -- ignores cliplist, expects only one clip
   tm = attrs.TOOLNT_Clip_Start[cl] 
   tm = 1
   
   if tgl_relativePaths.value == "ON" then
      handle.Clip[tm] = ReverseMapPath(clip)
   else
      handle.Clip[tm] = clip
   end

   origK = known[pickedLoader.knownindex]
   origLn = origK.numMax - origK.numMin + 1
   newLn = knownItem.numMax - knownItem.numMin + 1
   --print("origK.numMax "..origK.numMax.." knownItem.numMax "..knownItem.numMax)
   if tgl_copyTrims.value == "ON" or origLn == newLn then
      handle.GlobalOut[tm]      = attrs.TOOLNT_Clip_End[cl]
      handle.GlobalIn[tm]         = attrs.TOOLNT_Clip_Start[cl]
      handle.HoldLastFrame[tm]   = attrs.TOOLIT_Clip_ExtendLast[cl]
      handle.HoldFirstFrame[tm]   = attrs.TOOLIT_Clip_ExtendFirst[cl]
      handle.ClipTimeStart[tm]   = attrs.TOOLIT_Clip_TrimIn[cl]
      handle.ClipTimeEnd[tm]      = attrs.TOOLIT_Clip_TrimOut[cl]
   else
      diff = origLn - newLn
      globOut = attrs.TOOLNT_Clip_End[cl]
      holdLast = attrs.TOOLIT_Clip_ExtendLast[cl]
      trimOut = attrs.TOOLIT_Clip_TrimOut[cl]
      --print("gout "..globOut.." holdLast "..holdLast.." trimOut "..trimOut)
      if diff > 0 then
         -- new clip is shorter then old one, prolong to orig
         holdLast = holdLast + diff
      else
         -- new clip is longer then old one
         if trimOut == origLn then
            -- old clip had no trim out (ie trimout was clip length)
            trimOut = newLn
            globOut = globOut + (-1*diff)
         else
            if trimOut < origLn then
               -- make new clip shorter from end by as many frames as old one
               trimOut = newLn - (origLn - trimOut)
               globOut = globOut + (-1*diff) - (origLn - trimOut)
            else
               -- make new clip longer
               trimOut = newLn - (origLn - trimOut) + 1 -- trim out value is one frame less then on interface?!!
               globOut = globOut + (-1*diff) - (origLn - trimOut)
            end
         end
      end
      handle.GlobalOut[tm]      = globOut
      handle.GlobalIn[tm]         = attrs.TOOLNT_Clip_Start[cl]
      handle.HoldLastFrame[tm]   = holdLast
      handle.HoldFirstFrame[tm]   = attrs.TOOLIT_Clip_ExtendFirst[cl]
      handle.ClipTimeStart[tm]   = attrs.TOOLIT_Clip_TrimIn[cl]
      handle.ClipTimeEnd[tm]      = trimOut
      --print ("gout "..globOut.." holdLast "..holdLast.." trimOut "..trimOut)
   end
   
   if attrs.TOOLBT_Clip_Reverse then handle.Reverse[tm] =0 else handle.Reverse[tm]=1 end
   if attrs.TOOLBT_Clip_Loop then handle.Loop[tm] = 0 else handle.Loop[tm] = 1 end
      
   handle:SetAttrs({TOOLB_PassThrough = false})   
end


function changeLoaders(mode, ver, loaderTable, known)
   
   knownItem = nil
   
   for j, pickedLoader in loaderTable do
      if pickedLoader.toChange then
         
         if mode == "maxM" then
            ver = known[pickedLoader.knownindex].maxVersionMatching
            knownItem = known[known[pickedLoader.knownindex].maxVersionMatchingPos]
         end
         if mode == "max" then
            ver = known[pickedLoader.knownindex].maxVersion
            knownItem = known[known[pickedLoader.knownindex].maxVersionPos]
         end
         if mode == "maxCM"  or mode == "maxC" or mode == "usr" then
            -- ver from parameter
            -- find knownitem by version number
            corr = known[pickedLoader.knownindex].corresponding
            for i, corritm in corr do
               if corritm.version == ver then
                  knownItem = known[corritm.pos]
               end
            end
         end
         
         --       (smallest number in sequence)
         --      numMax (biggest number in sequence)
         --      numSum (number of frames in sequence, for hole detection)

         if knownItem ~= nil and ver ~= -1 then
            changeOneLoader(pickedLoader , knownItem)
         end

      end
   end
   
   if versionTool ~= nil then
      print(tostring(ver))
      versionTool.FieldValue[TIME_UNDEFINED] = "ver "..tostring(ver)
   end
end

-- for debug, dumps just picked loaders and their corresponding known item
function dumpPickedLoaders(loaderTable)
   for j, pickedLoader in loaderTable do
      if pickedLoader.toChange then
         print("*********************************")
         dump(pickedLoader.versionTbl)
         print ("---")
         dump(known[pickedLoader.knownindex])
      end   
   end
end

------------------------------------------------------------------------------
-- main
------------------------------------------------------------------------------

print("3D Raise Version script")
print("-----------------------\n")



fa = composition:GetAttrs()
loaderPathList = {}

fmt_list = fusion:GetRegList(CT_ImageFormat)
fmt_attrs = {}
for i,v in pairs(fmt_list) do
   fmt_attrs[i] = fmt_list[i]:GetAttrs()
end

loaderTable = {}
-- get all loaders
versionTool = nil
versionAttrs = nil

tllist = composition:GetToolList(false)
for i, tool in tllist do
   attrs = tool:GetAttrs()
   if attrs["TOOLS_RegID"] == "Loader" then
      oneLoader = {}
      oneLoader.tool = tool
      oneLoader.attrs = attrs
      oneLoader.toChange = false
      table.insert(loaderTable, oneLoader)
   end
   if attrs["TOOLS_RegID"] == "Fuse.SetMetaData" then
      if attrs["TOOLS_Name"] == "ANIMEVER" then
         if tool.FieldName[TIME_UNDEFINED] == "InputSerial" then
            versionTool = tool
            versionAttrs = attrs
         end
      end
   end
end

loaderTableSel = {}
-- get selected loader(s)
toollistSel = composition:GetToolList(true)
for i, tool in toollistSel do
   attrs = tool:GetAttrs()
   if attrs["TOOLS_RegID"] == "Loader" then
      table.insert(loaderTableSel, tool)
   end
end
local ldrCntSel = table.getn(loaderTableSel)

if ldrCntSel == 0 then
   print("No loader selected, exiting...")
   return
end

-- get attributes of selected loader
attrs = loaderTableSel[1]:GetAttrs()
if ldrCntSel > 1 then
   print("More than one loader selected, picked "..attrs.TOOLS_Name)
end
if attrs.TOOLST_Clip_Name[1] ~= nil then
   selLoaderPthRev = MapPath(attrs.TOOLST_Clip_Name[1])
   print("Selected loader clip path: "..selLoaderPthRev)
else
   print("Selected loader has no clip, exiting.")
   return
end
seqSrc = eyeon.parseFilename(selLoaderPthRev)
seqSrcSearch = oneUpDirectory(selLoaderPthRev)
print("File search path: "..seqSrcSearch)

-- search loaders for similar path
loadersToChangeCnt = 0
for i, item in loaderTable do
   if item.attrs.TOOLST_Clip_Name[1] then
      seqPickSearch = oneUpDirectory(MapPath(item.attrs.TOOLST_Clip_Name[1]))
      seqPick = eyeon.parseFilename(MapPath(item.attrs.TOOLST_Clip_Name[1]))
      if seqPickSearch == seqSrcSearch then
         --print("clip2replace: "..seqPick.CleanName)
         loaderTable[i].toChange = true -- mark as needed
         loaderTable[i].versionTbl = splitToPathAndVersion(seqPick.Path)
         loadersToChangeCnt = loadersToChangeCnt + 1
      end
   end
end

-- list one up directory
known = {} -- table of clips on harddrive
doDirectories(seqSrcSearch, "*.*")

-- Cleanup known
seqMax = 0
layerPlusPassMaxLn = 0
for i, v in known do
   --if v.category == "seq" then
   if true then
         -- first frame for loader
         seq = eyeon.parseFilename(v.file)
         if v.category == "seq" then
            known[i].file = seq.Path..seq.CleanName..string.format("%0"..seq.Padding.."d", v.numMin)..seq.Extension
         else
            known[i].file = v.file
         end
         
         -- find maximum length
         seqLen = v.numMax - v.numMin + 1
         if seqMax < seqLen then seqMax = seqLen end
         
         -- path divide to element and version
         fileVersionTbl = splitToPathAndVersion(seq.Path)
         known[i].versionTbl = fileVersionTbl
                  
                  
                  
                  
         -- name divide to layer and pass name
         nameParts = eyeon.split(seq.CleanName, ".")         
         proj = "-"
         layer = "-"
         renderver = "-"
         pass = "-"
         
         proj = nameParts[1]
         layer = nameParts[2]
         renderver = nameParts[3]
         if table.getn(nameParts) >= 4 then pass = nameParts[4] end

         -- insert to array
         known[i].layer = layer
         known[i].pass = pass
         lpLn = string.len(layer) + string.len(pass)
         if layerPlusPassMaxLn < lpLn then layerPlusPassMaxLn = lpLn end
         
         if v.numSum <= 1 then
            known[i].category = "single"
         end
   end
end
print("File search done, found ".. tostring(table.getn(known)) .. " clips.")

findCorrespondingClipsPlus(known)
print("---------------------------------------\n")


-- find picked loaders in known clips
allLoadersFound = true
for j, pickedLoader in loaderTable do
   if pickedLoader.toChange then
      seq = eyeon.parseFilename(MapPath(pickedLoader.attrs.TOOLST_Clip_Name[1]))
      term = seq.Path..seq.CleanName..seq.Extension
      knownindex = -1
      for i,v in pairs(known) do
         if term == v.term then
            -- path, cleanname and extension matches
            knownindex = i
            break
         end
      end
      if knownindex == -1 then allLoadersFound = false end
      loaderTable[j].knownindex = knownindex
   end
end

if allLoadersFound == false then
   print("Didn't found files for some Loaders, exiting...")
   return
end


-- find highest version (with and withouth matching numbers) for each picked loader
-- fill 
for j, pickedLoader in loaderTable do
   if pickedLoader.toChange then
      maxVersion = -1
      maxVersionPos = -1
      maxVersionMatching = -1
      maxVersionMatchingPos = -1

      corr = known[pickedLoader.knownindex].corresponding
      for i, tst in corr do
         -- set highest matching version
         if tst.version > maxVersion and not tst.numbersMatch then
            maxVersion = tst.version
            maxVersionPos = tst.pos
         end
         if tst.version > maxVersionMatching and tst.numbersMatch then
            maxVersionMatching = tst.version
            maxVersionMatchingPos = tst.pos
            maxVersion = tst.version
            maxVersionPos = tst.pos
         end
      end
      known[pickedLoader.knownindex].maxVersion = maxVersion
      known[pickedLoader.knownindex].maxVersionPos = maxVersionPos
      known[pickedLoader.knownindex].maxVersionMatching = maxVersionMatching
      known[pickedLoader.knownindex].maxVersionMatchingPos = maxVersionMatchingPos
   end
end

-- make list of versions available
versionList = makeVersionList(loaderTable, known)

-- find highest common version for all picked loaders
maxCommonVersion = -1
maxCommonVersionMatching = -1
for k, pickedVersion in versionList do
   verExistsForAll = true
   verExistsForAllandMatches = true
   for j, pickedLoader in loaderTable do
      if pickedLoader.toChange then
         corr = known[pickedLoader.knownindex].corresponding
         verExists = false
         verExistsAndMatches = false
         for i, tst in corr do
            if tst.version == pickedVersion then
               verExists = true
               if tst.numbersMatch then
                  verExistsAndMatches = true
               end
            end
            
         end
         if not verExists then
            verExistsForAll = false
         else
            maxCommonVersion = pickedVersion
         end
         if not verExistsAndMatches then
            verExistsForAllandMatches = false
         else
            maxCommonVersionMatching = pickedVersion
         end
      end
   end
end


------------------------------------------------------------------------------
-- UI

if maxCommonVersionMatching == -1 then mxCVMstr = "  (na)" else mxCVMstr = "  ("..tostring(maxCommonVersionMatching)..")" end
if maxCommonVersion == -1 then mxCVstr = "  (na)" else mxCVstr = "  ("..tostring(maxCommonVersion)..")" end

local toollist = iup.list{expand="HORIZONTAL", dropdown="NO", FONT = "lucida console::"}
local verlist  = iup.list{expand="NO", dropdown="NO", size=70, }

local ok = iup.button{title = "OK", size=90, expand="NO"}
local cancel = iup.button{title = "Cancel", size=90, expand="NO"}

local tgl_verhighestCommonMatchin = iup.toggle {title = "Highest Common Matching Version" .. mxCVMstr,  VALUE="ON",}
local tgl_verhighestCommon        = iup.toggle {title = "Highest Common Version" .. mxCVstr,            VALUE="OFF",}
local tgl_verhighestMatching      = iup.toggle {title = "Highest Matching Version",                     VALUE="OFF",}
local tgl_verhighest              = iup.toggle {title = "Highest Version",                              VALUE="OFF",}
local tgl_veruser                 = iup.toggle {title = "User Specified Version  (na)",                 VALUE="OFF",}
local radio_ver                   = iup.radio {iup.vbox {GAP="2", tgl_verhighestCommonMatchin, tgl_verhighestCommon, tgl_verhighestMatching, tgl_verhighest, tgl_veruser, EXPAND="NO"}}
frame_versionpick = iup.frame{GAP="2",radio_ver, title="Select Version(s)", MARGIN="10"}
frame_versionUsr = iup.frame{GAP="2",verlist, title="User Version:", MARGIN="10"}

-- globals .. :(
tgl_relativePaths         = iup.toggle {title = "Relative Paths", VALUE="ON",}
tgl_copyTrims         = iup.toggle {title = "Copy Trims", VALUE="OFF",}
vbox_opt =
   iup.vbox {expand="NO",
      tgl_relativePaths,
      tgl_copyTrims,
}
frame_options = iup.frame{GAP="2", vbox_opt,  title="Options:", MARGIN="10"}
hbox_topOther =
   iup.hbox {GAP="5",
      frame_versionUsr,
      iup.fill{size = "5"},
      frame_options,
}
hbox_top =
   iup.hbox {
      frame_versionpick,
      iup.fill{},
      hbox_topOther,
}

-- var for selected version
local usr_version = -1

local dlg = iup.dialog
{
   title = "3D - Raise Version",
   foreground = "YES",
   margin = "10x10",
   defaultenter = ok, defaultesc = cancel,
   border = "NO", minbox = "NO", maxbox = "NO", menubox = "NO", resize = "NO",
   bgcolor = "64 64 64", fgcolor = "192 192 192",

   iup.vbox
   {
      hbox_top,
      iup.fill{size=5},
      iup.label{title="Found Loaders With Available Versions:" },
      --iup.fill{size=5},
      toollist,
      iup.fill{size=5},
      iup.hbox
      {
         margin = "0x0",
         ok,   iup.fill{}, cancel,
      },
   },
}
iup.SetAttribute(dlg, "NATIVEPARENT", touserdata(fu:GetMainWindow()))
listing = makeListing(loaderTable, known, versionList)
UpdateList(toollist, listing)
UpdateVersionsAvailable(verlist, versionList)
tgl_veruser.title = "User Specified Version  (" .. versionList[1] .. ")"
usr_version = tonumber(versionList[1])



------------------------------------------------------------------------------
-- UI functions

function ok:action()

   if tgl_verhighestCommonMatchin.value == "ON" then
      mode = "maxCM"
      ver = maxCommonVersionMatching
   end
   if tgl_verhighestCommon.value == "ON" then
      mode = "maxC"
      ver = maxCommonVersion
   end
   if tgl_verhighestMatching.value == "ON" then
      mode = "maxM"
      ver = -1
   end
   if tgl_verhighest.value == "ON" then
      mode = "max"
      ver = -1
   end
   if tgl_veruser.value == "ON" then
      mode = "usr"
      ver = usr_version
   end

   changeLoaders(mode, ver, loaderTable, known)
   
   return iup.CLOSE
end

function cancel:action()
   return iup.CLOSE
end

function verlist:action(text, item, sel)

   usr_version = tonumber(text)
   tgl_veruser.title = "User Specified Version  (" .. text .. ")"
   return iup.DEFAULT
end

composition:Lock()
composition:StartUndo("3D Raise Version")

-- select picked loaders to show user what will be changed
flow = comp.CurrentFrame.FlowView
flow:Select()
for i, pickedLoader in loaderTable do
   if pickedLoader.toChange then
      flow:Select(loaderTable[i].tool)
   end
end

-- show ui
dlg:show()
verlist.selection = "1:1000"
status,err = pcall(iup.MainLoop)
dlg:destroy()


composition:Unlock()
composition:EndUndo(true)

if not status then
   print(err)
end
