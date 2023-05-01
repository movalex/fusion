print('[GIF Magick End Render script]')

----------------------------------------------------------------------------------------------------
-- The script uses ImageMagick library, so the magick.exe executable should be set in $PATH environment variable.
-- By default the script creates a looped Gif file resized roughly to 640x480 and then removes rendered jpg sequence.
-- You can specify quality (-delay) and size output (-resize) in the variable called command
-- Put the file contents to the End Render script of the Saver set to render JPG sequence.
----------------------------------------------------------------------------------------------------

-- Copyright © 2022 Alexey Bogomolov

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included
-- in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
-- DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
-- OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

fusion = fu or Fusion()

-- Find out the current operating system platform. The platform local variable should be set to either "Windows", "Mac", or "Linux".
osPlatform = ' '
appPath = ' '

-- Check if the OS is Windows by searching for the Program Files folder
if string.find(fusion:MapPath('Fusion:/'), 'Program Files', 1) then
    osPlatform = 'Windows'
    appPath = "magick.exe"
    deleteCommand = "del "
-- Check if the OS is Mac by searching for the Applications folder
elseif string.find(fusion:MapPath('Fusion:/'), 'Applications', 1) then
    osPlatform = 'Mac'
    appPath = '/usr/local/bin/magick'
    deleteCommand = "rm "
else
    osPlatform = 'Linux'
    appPath = '/usr/local/bin/magick'
end

print('[OS] ' .. osPlatform)
print('[App Path] ' .. appPath)

-- -------------------------------------------------------
-- Helper functions copied from the scriptlib.lua file
-- -------------------------------------------------------

function parseFilename(filename)
    print('parsing filename...')
    local seq = {}
    seq.FullPath = filename

    print('full path ' .. seq.FullPath)

    string.gsub(seq.FullPath, "^(.+[/\\])(.+)", 
    function(path, name)
        seq.Path = path
        print('folder path: ' .. seq.Path)
        seq.FullName = name
        print('file name: ' .. seq.FullName)
    end)

    string.gsub(seq.FullName, "^(.+)(%..+)$", 
    function(name, ext)
        seq.Name = name
        print('name: ' .. seq.Name)
        seq.Extension = ext
        print('extension: ' .. seq.Extension)
    end)

    if not seq.Name then -- no extension?
    seq.Name = seq.FullName
    end
    seq.SNum = string.match(seq.Name, "%d+$")

    if seq.SNum then 
        seq.Number = tonumber( seq.SNum ) 
        seq.Padding = string.len( seq.SNum )
        seq.CleanName = string.match(seq.Name,"^(.-)%d+$" )
    else
        seq.SNum = "0000"
        seq.Number = 0
        seq.Padding = 4
        seq.CleanName = seq.Name
    end
    
    seq.CleanName = string.gsub(seq.CleanName, "%.$", "")

    print('Start number: ' .. seq.SNum)    
    print('Clean Name: ' .. seq.CleanName)

    if seq.Extension == nil then 
    seq.Extension = ""
    end

    return seq
end


saverfile = self.Clip.Filename
print('Parsing Saver file... ' .. saverfile)
seq = parseFilename(fu:MapPath(self.Clip.Filename))

-- Debug the sequence table
-- dump(seq)

-- Example: filename.%04d.jpg
imageSequenceFilename = seq.Path .. "*" .. seq.Extension
print('[Formatted Image Sequence] ' .. imageSequenceFilename)

-- Example: filename.gif
outFileName = seq.Path .. seq.CleanName .. '.gif'
print('[Exported File] ' .. outFileName)

-- -------------------------------------------------------
-- Encode the image sequence into a gif using ImageMagick
-- -------------------------------------------------------

command = appPath .. ' -monitor -delay 20 -loop 0 -dither none ' .. imageSequenceFilename .. ' -resize 640x480^ ' .. outFileName

print('[Launch Command] ' .. command)
os.execute(command)

-- -------------------------------------------------------
-- Delete rendered JPG sequence
-- -------------------------------------------------------

deleteRederedCommand = deleteCommand  .. imageSequenceFilename
print("deleting rendered sequence using command: " .. "[ "..deleteRederedCommand.." ]")
os.execute(deleteRederedCommand)
print('[Done]')
