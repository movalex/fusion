-- FFMPEG Encoding Intool End Render Script v0.3
-- By Andrew Hazelden <andrew@andrewhazelden.com>
-- optimized for Fusion9 by Alexey Bogomolov <mail@abogomolov.com>
-- This Fusion Intool script is used to FFMPEG encode your saver node rendered 
-- image sequences into MOV ProRes movies with a gamma 1.0 to 2.2 conversion applied
-- --------------------------------------------------------------
-- Step 1. Install ffmpeg. 

-- Windows ffmpeg Download URL: https://ffmpeg.org/download.html
-- * open https://ffmpeg.zeranoe.com/builds/, choose Achitecture (32/64 bit) and choose Linking --> Shared
-- * unzip file contents to C:\ffmpeg

-- MacOS Homebrew Based Install:
-- brew install ffmpeg

-- CentOS Install:
-- sudo yum -y install ffmpeg

-- Ubuntu Install:
-- sudo add-apt-repository ppa:mc3man/trusty-media
-- sudo apt-get update
-- sudo apt-get dist-upgrade
-- sudo apt-get -y install ffmpeg 

-- Step 2. Paste the FFMPEG Encoding Intool Script into your Saver node's "End Render Script" text field.

-- Step 3. Change the script's "ffmpegProgramPath" variable to point to the absolute filepath of the installed copy of ffmpeg.
-- (On Mac/Linux you can find the active ffmpeg path out using: "which ffmpeg")

-- Step 4. Render a short test sequence in Fusion. You should have a new .mp4 movie and a log .txt file saved in the same folder as your rendered image sequence. If you have a saver node based Sound Filename entered it will be added automatically as an audio track to the encoded movie file.
print('[FFMPEG Encoding Intool Script]')

fusion = fu or Fusion()

-- -------------------------------------------------------
-- Specify how audio is handled
-- -------------------------------------------------------
-- Should ffmpeg trim the Movie to the shortest clip duration of the audio or the video track?
audioTrimtoShortestClip = 1
-- audioTrimtoShortestClip = 0

-- Where is the audio track coming from in the Comp:

-- Don't use any audio
-- audioFilename = ' '
-- Don't have any audio offset
-- audioOffset = ' '

-- Use the current Saver node based audio file
audioFilename = self.SoundFilename[0].Value
-- Use the current Saver node based audio offset (measured in frames)
audioOffset = self.SoundOffset

-- or 

-- Use the Fusion timeline based audio file
-- audioFilename = comp:GetAttrs().COMPS_AudioFilename
-- Use the Fusion timeline based audio offset (measured in frames)
-- audioOffset = comp:GetAttrs().COMPN_AudioOffset

-- -------------------------------------------------------
-- Specify where the ffmpeg command line tool is installed
-- -------------------------------------------------------

-- Find out the current operating system platform. The platform local variable should be set to either "Windows", "Mac", or "Linux".
osPlatform = ' '
ffmpegProgramPath = ' '
-- Check if the OS is Windows by searching for the Program Files folder
if string.find(fusion:MapPath('Fusion:/'), 'Program Files', 1) then
  osPlatform = 'Windows'

ffmpegProgramPath = 'C:\\ffmpeg\\bin\\ffmpeg'
-- Check if the OS is Windows by searching for the Program Files folder
elseif string.find(fusion:MapPath('Fusion:/'), 'PROGRA~1', 1) then
  osPlatform = 'Windows'

ffmpegProgramPath = 'C:\\ffmpeg\\bin\\ffmpeg'
-- Check if the OS is Mac by searching for the Applications folder
elseif string.find(fusion:MapPath('Fusion:/'), 'Applications', 1) then
  osPlatform = 'Mac'
  ffmpegProgramPath = '/usr/local/bin/ffmpeg'

else
  osPlatform = 'Linux'
  ffmpegProgramPath = '/usr/bin/ffmpeg'
end

print('[OS] ' .. osPlatform)
print('[FFMPEG Path] ' .. ffmpegProgramPath)

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

print('Start number: ' .. seq.SNum)    
print('Clean Name: ' .. seq.CleanName)

if seq.Extension == nil then 
seq.Extension = ""
end

return seq
end

-- -------------------------------------------------------
-- Figure out the comp Audio clip
-- -------------------------------------------------------

ffmpegAudioPrefixCommands = ' '
ffmpegAudioPostfixCommands = ' '
if audioFilename == nil then
  print('[FFMPEG Audio Filename] No Audio Track Active')
else
  if string.len(audioFilename) > 3 then
    -- print('[FFMPEG Audio Filename] ' .. audioFilename)
    print('[FFMPEG Audio Filename] ' .. cmp:MapPath(audioFilename))
    if audioOffset == nil then
      print('[FFMPEG Audio Offset] No Time Offset')
    else
      print('[FFMPEG Audio Offset] ' .. audioOffset)
    end
  
    -- Build the audio track commands
    --ffmpegAudioPrefixCommands = '-i "' .. audioFilename .. '"'
    ffmpegAudioPrefixCommands = '-i "' .. cmp:MapPath(audioFilename) .. '"'
  
    -- Trim the Movie to the shortest clip duration of the audio or the video track
    if audioTrimtoShortestClip == 1 then
      print('[FFMPEG Trim Clip to Shortest Duration] Active')
      ffmpegAudioPostfixCommands = ' ' .. '-shortest' .. ' '
    end
  else
    -- Error: The audio filename is less then three characters long
    print('[FFMPEG Audio Filename] No Audio Track Active')
  end
end
-- -------------------------------------------------------
-- Figure out the Saver node filenames
-- -------------------------------------------------------

-- seq = parseFilename(self.Clip.Filename)
saverfile = self.Clip.Filename
print('Parsing Saver file... ' .. saverfile)
seq = parseFilename(fu:MapPath(self.Clip.Filename))


-- Debug the sequence table
-- dump(seq)

-- Example: filename.%04d.exr
ffmpegImageSequenceFilename = seq.Path .. seq.CleanName .. '%0' .. seq.Padding .. "d" .. seq.Extension
print('[FFMPEG Start Frame] ' .. comp.RenderStart)
print('[FFMPEG Formatted Image Sequence] ' .. ffmpegImageSequenceFilename)

-- Example: filename.mp4
ffmpegMovieFilename = seq.Path .. seq.CleanName .. '.mov'
print('[FFMPEG Exported Movie] ' .. ffmpegMovieFilename)

-- Example: filename.txt
ffmpegLogFilename = seq.Path .. seq.CleanName .. '.txt'
print('[FFMPEG Logfile] ' .. ffmpegLogFilename)

-- A gamma 1 to 2.2 adjustment should be applied for exr output
-- Note: Your copy of FFMPEG has to support the "-apply_trc" option or you will get an "Unrecognized option 'apply_trc'." error message in the log file.

ffmpegApplyGammaCorrection = ' '
if seq.Extension == '.exr' then
    print('[FFMPEG EXR Gammma 1.0 to 2.2 Transform Active] [Image Format]' .. seq.Extension)
    -- Convert a linear exr to REC 709
    -- ffmpegApplyGammaCorrection = '-apply_trc bt709'
    -- or
    -- Convert a linear exr file to sRGB
    ffmpegApplyGammaCorrection = '-apply_trc iec61966_2_1'
end

-- Set the frame rate for the encoded movie
frameRate = comp:GetPrefs("Comp.FrameFormat.Rate")
if frameRate == nil then
    frameRate = 25
end

print('[FFMPEG Frame Rate] ' .. frameRate)

-- -------------------------------------------------------
-- Encode the image sequence into a movie using ffmpeg
-- -------------------------------------------------------

command = ffmpegProgramPath .. ' ' .. ffmpegAudioPrefixCommands .. ' ' .. ffmpegApplyGammaCorrection .. ' -framerate ' .. frameRate .. ' -f image2 -start_number ' .. comp.RenderStart .. ' -i "' .. ffmpegImageSequenceFilename .. '" -r ' .. frameRate .. ' -y -vcodec prores_ks -profile:v 3 -acodec pcm_s16le -ar 48000 -ac 2 ' .. ffmpegAudioPostfixCommands .. ' -strict -2  "' .. ffmpegMovieFilename .. '" >> "' .. ffmpegLogFilename .. '" 2>&1'
print('[Launch Command] ' .. command)
os.execute(command)

print('[Done]')

