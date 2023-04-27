#!/usr/bin/env python

    -- This is a Davinci Resolve script switch text+ versions
    -- Author: Alexey Bogomolov
    -- Email: mail@abogomolov.com
    -- License: MIT
    -- Copyright: 2022


FONT_STYLE = "Mongoose"




function switch_font()
    if not fu:GetResolve() then
        print("This is a script for Davinci Resolve")
        return
    end

    project = resolve:GetProjectManager():GetCurrentProject()
    timeline = project:GetCurrentTimeline()
    clips = timeline:GetItemListInTrack('Video', 2)


    for i, clip in ipairs(clips) do
        comp = clip:GetFusionCompByName("Composition 1")
        text = comp:FindTool("NSC_Credits")
        text.Input2[1] = FONT_STYLE
    end

end


switch_font()
