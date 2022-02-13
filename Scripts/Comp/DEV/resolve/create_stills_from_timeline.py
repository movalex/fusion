import time

project = resolve.GetProjectManager().GetCurrentProject()
timeline = project.GetCurrentTimeline()
timeline_name = timeline.GetName()
gallery = project.GetGallery()


def request_dir():
    """request file UI"""
    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow({
            "ID": "AddBookmark",
            "TargetID": "AddBookmark",
            "WindowTitle": "Add Bookmark",
            "Geometry": [800, 600, 300, 75],
        },
        [
        ui.HGroup(
                [
                    ui.Label(
                        "ID": "FolderLabel",
                        "Text": "Folder:",
                    ),
                    ui.LineEdit(
                        {
                        "ID": "FolderLine",
                        "Events": {"ReturnPressed": True},
                        "Alignment": {"AlignHCenter": True, "AlignVCenter": True},
                        }
                    ),
                    ui.Button(
                        {
                        "ID": "FolderButton",
                        "Text": "Browse..."
                        }
                    )
                ]
            ),
        ]
    )
    itm = win.GetItems()
    
    itm["FolderLine"].SetPlaceholderText("Select folder")






def grab_stills(source_frame=2):
    """create stills from all clips in a timeline
    save the files to requested folder
    """
    stills = timeline.GrabAllStills(source_frame)



    time.sleep(2)
    album = gallery.GetCurrentStillAlbum()  
    album.DeleteStills(stills)



grab_stills(2)

