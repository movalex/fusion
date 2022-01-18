-- Enable Loader's single frame loop based on the filename.
-- Install to the Scripts:Tool folder, rightclick on the Loader(s) and use Script --> make_single_frame
--
-- Author: Alexey Bogomolov
-- email: mail@abogomolov.com
-- donate: https://www.paypal.com/paypalme/aabogomolov/
-- MIT License -- https://opensource.org/licenses/MIT
--
-- Version history:
-- 01/18/2022
--   v1.0 -- Initial commit


function MakeSingleFrame(tool)
    local parseFile = bmd.parseFilename(tool.Clip[1])
    -- dump(parseFile)
    if not parseFile.SNum then
        print("no sequence serialization found")
        return
    end 
    local loopFrame = tonumber(parseFile.SNum)
    tool.ClipTimeStart[1] = loopFrame
    tool.ClipTimeEnd[1] = loopFrame
    tool.Loop[1] = 1    
end
   

if tool and tool.ID == "Loader" then
    MakeSingleFrame(tool)
end
