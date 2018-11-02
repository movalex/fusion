-- FFMPEG Encoding Intool Script
-- 2017-07-15 10.25 AM
-- ---------------------------------------------------------------------------
-- By Andrew Hazelden <andrew@andrewhazelden.com>
-- This Fusion Intool script is used to FFMPEG encode your saver node rendered 
-- image sequences into MP4 H.264 movies with a gamma 1.0 to 2.2 conversion applied.
-- ---------------------------------------------------------------------------

-- Step 1. Install ffmpeg. 

-- Windows ffmpeg Download URL: https://ffmpeg.org/download.html

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

-- Step 3. Render a short test sequence in Fusion. You should have a new .mov movie and a log .txt file saved in the same folder as your rendered image sequence.

-- ---------------------------------------------------------------------------
-- Script Notes
-- ---------------------------------------------------------------------------
-- Currently Saver node filename based PathMaps are not resolved in the first version of this intool script.

-- ffmpeg might truncate the frame size using the EXR window data if the background image area is transparent.

-- ---------------------------------------------------------------------------
-- Todos:
-- ---------------------------------------------------------------------------

-- Add Saver PathMap translation support

-- Add audio track encoding support. I need to figure out how to read the self.SoundFilename element on a saver node so the audio track can be automatically added to the ffmpeg encoded movie:
-- print(self.SoundFilename)
-- Result: cdata<struct Text *>: 0x7f8da54f0f60

-- ---------------------------------------------------------------------------
print('[FFMPEG Encoding Intool Script]')

frameRate = 24
-- -------------------------------------------------------
-- Specify where the ffmpeg command line tool is installed
-- -------------------------------------------------------

if os.getenv('programfiles') == nil then
	print('[OS] Linux or macOS')
	-- 		Linux:
	-- ffmpegProgramPath = '/usr/bin/ffmpeg'
	-- ffmpegProgramPath = '/opt/local/bin/ffmpeg'
	-- 		MacOS:
	ffmpegProgramPath = '/usr/local/bin/ffmpeg'
	-- ffmpegProgramPath = '/Applications/ffmpeg/bin/ffmpeg'
else
	-- 		Windows
	print('[OS] Windows')
	ffmpegProgramPath = 'C:\\ffmpeg\\bin\\ffmpeg'
end
print('[FFMPEG Path] ' .. ffmpegProgramPath)

-- -------------------------------------------------------
-- Helper functions copied from the scriptlib.lua file
-- -------------------------------------------------------

function parseFilename(filename)
	local seq = {}
	seq.FullPath = filename
	string.gsub(seq.FullPath, "^(.+[/\\])(.+)", function(path, name) seq.Path = path seq.FullName = name end)
	string.gsub(seq.FullName, "^(.+)(%..+)$", function(name, ext) seq.Name = name seq.Extension = ext end)
	
	if not seq.Name then -- no extension?
		seq.Name = seq.FullName
	end
	
	string.gsub(seq.Name,     "^(.-)(%d+)$", function(name, SNum) seq.CleanName = name seq.SNum = SNum end)
	
	if seq.SNum then 
		seq.Number = tonumber( seq.SNum ) 
		seq.Padding = string.len( seq.SNum )
	else
	   seq.SNum = ""
	   seq.CleanName = seq.Name
	end
	
	if seq.Extension == nil then seq.Extension = "" end
	seq.UNC = ( string.sub(seq.Path, 1, 2) == [[\\]] )
	
	return seq
end

-- -------------------------------------------------------
-- Figure out the Saver node filenames
-- -------------------------------------------------------
seq = parseFilename(self.Clip.Filename)

-- Example: filename.%04d.exr
ffmpegImageSequenceFilename = seq.Path .. seq.CleanName .. '%0' .. seq.Padding .. "d" .. seq.Extension
print('[FFMPEG Start Frame] ' .. comp.RenderStart)
print('[FFMPEG Formatted Image Sequence] ' .. ffmpegImageSequenceFilename)

-- Example: filename.mp4
ffmpegMovieFilename = seq.Path .. seq.CleanName .. 'mov'
print('[FFMPEG Exported Movie] ' .. ffmpegMovieFilename)

-- Example: filename.txt
ffmpegLogFilename = seq.Path .. seq.CleanName .. 'txt'
print('[FFMPEG Logfile] ' .. ffmpegLogFilename)

-- A gamma 1 to 2.2 adjustment should be applied for exr output
-- Note: Your copy of FFMPEG has to support this option or you will get an "Unrecognized option 'apply_trc'." error message in the log file.
ffmpegApplyGammaCorrection = ''
if seq.Extension == '.exr' then
 print('[FFMPEG EXR Gammma 1.0 to 2.2 Transform Active] ' .. ffmpegLogFilename)
 
--  Convert a linear exr to REC 709
 ffmpegApplyGammaCorrection = '-apply_trc bt709'
  
--  or
  
--  Convert a linear exr file to sRGB
 ffmpegApplyGammaCorrection = '-apply_trc iec61966_2_1'
end

-- -------------------------------------------------------
-- Encode the image sequence into a movie using ffmpeg
-- -------------------------------------------------------
command = ffmpegProgramPath .. ' ' .. ffmpegApplyGammaCorrection .. ' -framerate '.. frameRate .. ' -f image2 -start_number ' .. comp.RenderStart .. ' -i "' .. ffmpegImageSequenceFilename .. '" -r "'.. frameRate .. '" -y -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -vcodec qtrle "' .. ffmpegMovieFilename .. '" >> "' .. ffmpegLogFilename .. '" 2>&1'
print('[Launch Command] ' .. command)
os.execute(command)

print('[Done]')
