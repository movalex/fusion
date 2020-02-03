ui = app.UIManager

disp = bmd.UIDispatcher(ui)



local win = disp:AddWindow({

	ID = "WindowTest_Main",

	WindowTitle = "Window Test",


	ui:VGroup {
        ui:Button{
            ID = 'LaunchPrefs',
            Text = 'prefs',
            Flat = true,
            Checkable = false,
        },
	},

})

-- If we already have a window open, do not open another, activate it and return


function lauch_prefs()
    dlg = disp:AddWindow({
        ID = 'TBPrefs',
        TargetID = 'TBPrefs',
        -- WindowTitle = 'Toolbar16 Prefs',
        WindowFlags = {SplashScreen = true, NoDropShadowWindowHint = true, WindowStaysOnTopHint = false},
        Geometry = {300, 200, 200, 100},
            ui:VGroup{
            ID = 'prefs',
                ui:HGroup{
                    ui:Button{
                        ID = 'FlushData',
                        Text = 'Flush',
                    },
                },
                ui:HGroup{
                    ui:Button{
                        ID = 'PrefClose',
                        Text = 'close',
                        Flat = true,
                    },
                },
            },
        })
    function dlg.On.PrefClose.Clicked(ev)
        disp:ExitLoop()
        collectgarbage()
    end
    dlg:Show()
    disp:RunLoop()
    dlg:Hide()

end


function win.On.LaunchPrefs.Clicked(ev)
    local mywin = ui:FindWindow("TBPrefs")
    if mywin then
        print(mywin)
        mywin:Raise()
        mywin:ActivateWindow()
        -- Uncomment to toggle, by sending a close event
        --mywin:Close()
        return
    else
        lauch_prefs()
    end

end


function win.On.WindowTest_Main.Close(ev)
	disp:ExitLoop()
end


win:Show()

disp:RunLoop()
