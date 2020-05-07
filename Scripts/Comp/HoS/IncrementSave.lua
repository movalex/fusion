--[[
  Incremental Save script

  updates from the inital release:
  
  v1.4: by Alex Bogomolov 
  - add MacOS compatibility -- 2019/01/16
  - add optional save location variable -- 2020/04/22
        set $INCREMENT_SAVE_PATH variable for custom save folder 
  v1.3:
  - add Fusion 9/16 support
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
  - Initial release by S.Neve / House of Secrets
]]--
	
if not comp then
    comp = fu:GetCurrentComp()
end

mkdir_recursive = ''
split_path = '\\'
platform = (FuPLATFORM_WINDOWS and "Windows") or (FuPLATFORM_MAC and "Mac") or (FuPLATFORM_LINUX and "Linux")
if platform == 'Mac' or platform == 'Linux' then
    mkdir_recursive = '-p '
    split_path = '/'
end

pathEnv = comp:MapPath(os.getenv('INCREMENT_SAVE_PATH'))

if pathEnv then
    rootSaveFolder = ""
else
    rootSaveFolder = "IncrementSave"
end

function getSavePath()
     -- print('env: ', pathEnv)
     if pathEnv then
         if not direxists(pathEnv) then
             print('no save directory found, creating now')
             os.execute('mkdir ' .. mkdir_recursive .. pathEnv)
         end
         return pathEnv .. split_path .. comp:GetAttrs().COMPS_Name .. '.comp'
     else
         return comp:MapPath(comp:GetAttrs().COMPS_FileName)
     end
end

fa = comp:GetAttrs()
if fa.COMPS_FileName == "" then
	comp:Save()
else
    compPath = getSavePath() 
    pf = bmd.parseFilename(compPath)

	if not direxists(pf.Path .. rootSaveFolder) then
		print("creating dir: " .. pf.Path .. rootSaveFolder .. split_path.. pf.Name)
		os.execute("mkdir ".. mkdir_recursive .. pf.Path .. rootSaveFolder .. split_path.. pf.Name)
    end
    if not direxists(pf.Path .. rootSaveFolder.. split_path .. pf.Name) then
        print("creating dir: " .. pf.Path .. rootSaveFolder .. split_path .. pf.Name)
		os.execute("mkdir ".. mkdir_recursive .. pf.Path .. rootSaveFolder .. split_path .. pf.Name)
    end

	-- search inc saves
	pathSearch = pf.Path .. rootSaveFolder .. split_path .. pf.Name .. split_path .."*.comp"
	dir = bmd.readdir(pathSearch)
	num = table.getn(dir)
	currentVersion = 0

	for i = 1,num do
		if not dir[i].IsDir then
			fileExtension = string.gsub(dir[i].Name, "[.][^.]+$", "")
			fileNumberString = string.sub(fileExtension, string.find(fileExtension, "(%d+)$", 0))
			fileNumber = tonumber(fileNumberString)
			if currentVersion < fileNumber then
				currentVersion = fileNumber
			end
		end
	end
	currentVersionString = "000" .. tostring(currentVersion + 1)
	currentVersionString = string.sub(currentVersionString, string.len(currentVersionString) - 3 , string.len(currentVersionString))

    src = comp:GetAttrs().COMPS_FileName
	dest = pf.Path .. rootSaveFolder .. split_path .. pf.Name .. split_path .. pf.Name .. "." .. currentVersionString .. ".comp"
    os.rename(src, dest)
	comp:Save(src)
end
