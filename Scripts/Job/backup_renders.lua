[[
Backup Savers Render Job script.
The script creates backup of rendered files in the given directory, retaining the folder structure. Missing folders will be created.
Should be placed to Scripts:Job folder.

Version: 1.0

Description:
0. add the script to Scripts:Job folder (such as %AppData%\Roaming\Blackmagic Design\Fusion\Scripts\Job)
1. click Pause Render before adding the comp to the queue
2. add the comp to the queue, right click the render job and click Script — Render End — copy_files
3. resume the render
4. all files listed in the active savers will be backed up to the folders specified in backupFolder variable

TODO: 
- add Choose Backup Folder user interface
- autoload the script to the new render jobs


Copyright © 2022 Alexey Bogomolov

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-------------------------
-- parse filename scriptlib function
-- folowing filepath format should be parsed correctly:
-- 101_064_040..exr
-------------------------

function parseFilename(filename)
    print('parsing filename...')
    local seq = {}
    seq.FullPath = filename


    string.gsub(seq.FullPath, "^(.+[/\\])(.+)", 
    function(path, name)
        seq.Path = path
        seq.FullName = name
    end)

    string.gsub(seq.FullName, "^(.+)(%..+)$", 
    function(name, ext)
        seq.Name = name
        seq.Extension = ext
    end)

    if not seq.Name then -- no extension?
    seq.Name = seq.FullName
    end

    seq.SNum = string.match(seq.Name, "%d+$")

    if seq.SNum then 
        seq.Number = tonumber( seq.SNum ) 
        seq.Padding = string.len( seq.SNum )
        seq.CleanName = string.match(seq.Name,"^(.-)%d+$")
    else
        renderStart = comp:GetAttrs().COMPN_RenderStart
        seq.SNum = tostring(renderStart)
        seq.Number = 0
        seq.Padding = 4
        seq.CleanName = seq.Name
    end

    if seq.Extension == nil then 
    seq.Extension = ""
    end

    return seq
end

-------------------------
-- check if movie format scriptlib function
-------------------------

function isMovieFormat(extension)
	if extension ~= nil then
		if		( extension == ".avi" ) or ( extension == ".vdr" ) or ( extension == "wav" ) or
				( extension == ".dvs" ) or
				( extension == ".fb"  ) or
				( extension == ".omf" ) or ( extension == ".omfi" ) or
				( extension == ".stm" ) or
				( extension == ".tar" ) or
				( extension == ".vpv" ) or
				( extension == ".mp4" ) or
				( extension == ".mov" ) then
			return true
		end
	end
	return false
end

-------------------------
-- backup location
-- should be set with fusion data and UI manager later
-------------------------

backupFolder = [[D:\RENDER\BACKUP\Renders]]

-------------------------
-- main function
-------------------------

function doBackup(saverList)
    sep = package.path:match( "(%p)%?%." )
    for i, saver in ipairs(savers) do
        if not saver:GetAttrs().TOOLB_PassThrough then
            parse = parseFilename(saver.Clip[1])
            fullPath = comp:MapPath(parse.FullPath)
            parent = comp:MapPath(parse.Path)
            target = string.gsub(parent, "(.*)Renders(.*)", backupFolder.."%2")
            print("[TARGET FOLDER: ]"..target)
            if not bmd.direxists(target) then
                os.execute("mkdir " .. target)
            end
            if not isMovieFormat(parse.Extension) then
                -- Example: filename..exr
                sequencePattern = parse.Path .. parse.CleanName .. "*" .. parse.Extension
                sequencePattern = comp:MapPath(sequencePattern)
                sequencePath = parse.Path .. parse.CleanName .. parse.SNum .. parse.Extension
                print('sequence found: ' .. sequencePattern)
                dir = bmd.readdir(sequencePattern)
                print("found ".. #dir .. " files")
                
                for i=1, #dir do
                    if not dir[i].IsDir then
                        print(dir.Parent .. sep .. dir[i].Name)
                        bmd.copyfile(dir.Parent..dir[i].Name, target..dir[i].Name)
                    end
                end
            else
                -- Example: filename.mp4
                print("movie file found: " .. comp:MapPath(fullPath))
                bmd.copyfile(comp:MapPath(fullPath), target..parse.FullName)
            end
        end
    end
end


comp = fu:GetCurrentComp()
savers = comp:GetToolList(false, "Saver")
doBackup(savers)
