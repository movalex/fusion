--[[
  hos_incrementalSave

  by S.Neve / House of Secrets

  some small updates from the inital release:
  v1.3 Fusion 9/16 support
  v1.2 changes:
    - Changed the way the postfix increment number for the incremental backup comp
	is searched for, as in the older version a name like 'vfx_shot_01_31-448.comp
	would break the gsub expression for some unknown reason, returning a nil value.
	
  v1.1 changes:
	- creating the backup incremental file now uses the os.rename function to move
    the file, this worked in Lightwave and seems to behave the same in Fusion,
    this prevents the DOS box popup on saving.
	
  - renamed the script to match our other script and plugin naming conventions.

  - encapsulated the DOS file names in quotation marks to make creation in and
    of directories with spaces possible.
		
  v1.0 changes:
  - Initial release
	
]]--
	
function findpattern(text, pattern, start)
	return string.sub(text, string.find(text, pattern, start))
end

if not composition then
    composition = fu:GetCurrentComp()
end


fa = composition:GetAttrs()
if fa.COMPS_FileName == "" then
	Save()
else
	pf = bmd.parseFilename(comp:MapPath(fa.COMPS_FileName))

	if not direxists(pf.Path .. "incrementalSave") then
		print("creating dir : " .. pf.Path .. "incrementalSave")
		os.execute("mkdir \"" .. pf.Path .. "incrementalSave\"")
	else
		--print("dir exists")
	end

	if not direxists( pf.Path .. "incrementalSave\\" .. pf.Name .. pf.Extension ) then
		print("creating dir : " .. pf.Path .. "incrementalSave\\" .. pf.Name .. pf.Extension)
		os.execute("mkdir \"" .. pf.Path .. "incrementalSave\\" .. pf.Name .. pf.Extension .. "\"")
	else
		--print("dir exists")
	end

	-- search inc saves
	path = pf.Path .. "incrementalSave\\" .. pf.Name .. pf.Extension .. "\\*.comp"
	dir = readdir(path)
	num = table.getn(dir)
	currentVersion = 0

	for i = 1,num do
		if not dir[i].IsDir then
			fileExtension = string.gsub(dir[i].Name, "[.][^.]*$", "")
			--fileNumberString = string.gsub( fileExtension, string.gsub( fileExtension, "[^.][0-9]+$", ""), "")
			fileNumberString = string.sub(fileExtension, string.find(fileExtension, "(%d+)$", 0))
			fileNumber = tonumber(fileNumberString)
			--print(fileNumberString)
			--print(fileNumber)
			if currentVersion < fileNumber then
				currentVersion = fileNumber
			end
		end
	end
	currentVersionString = "000" .. tostring(currentVersion + 1)
	currentVersionString = string.sub(currentVersionString, string.len(currentVersionString) - 3 , string.len(currentVersionString))

	dest =  pf.Path .. "incrementalSave\\" .. pf.Name .. pf.Extension .. "\\" .. pf.Name .. "." .. currentVersionString .. ".comp"
	src =  pf.Path .. pf.Name .. pf.Extension
	os.rename(src, dest) -- this seems to work in Lightwave, and does the same in Fusion, much cleaner isn't it?
	comp:Save(src)
end
