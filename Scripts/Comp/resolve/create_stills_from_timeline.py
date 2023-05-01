from pathlib import Path
from grab_still import get_export_album, get_timeline_and_gallery, grab_still

"""
    This is a Davinci Resolve script to save all timeline clips as jpg files.
    Author: Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    Copyright: 2023
"""

STILL_FRAME_REF = 2
EXPORT_ALBUM = "export_30.04"
FORMAT = "png"



def request_dir():
    """request file UI"""
    target = fu.GetData("ResolveSaveStills.Folder")

    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow(
        {
            "ID": "RequestFolder",
            "TargetID": "RequestFolder",
            "WindowTitle": "The stills will be saved to",
            "Geometry": [800, 600, 630, 50],
        },
        ui.HGroup(
            [
                ui.Label({"Weight": 0.1, "ID": "FolderLabel", "Text": "folder:"}),
                ui.LineEdit(
                    {
                        "Weight": 0.8,
                        "Text": target or " ",
                        "ID": "FolderLine",
                        "Events": {"ReturnPressed": True},
                        "Alignment": {"AlignHCenter": True, "AlignVCenter": True},
                    }
                ),
                ui.Button({"Weight": 0.2, "ID": "FolderButton", "Text": "Browse..."}),
                ui.Button({"Weight": 0.1, "ID": "RunButton", "Text": "Run"}),
            ]
        ),
    )
    itm = win.GetItems()

    def close(ev):
        disp.ExitLoop()

    def request_folder(ev):
        target_folder = fu.RequestDir()
        itm["FolderLine"].Text = target_folder

    itm["FolderLine"].SetPlaceholderText("Select folder")
    win.On.FolderButton.Clicked = request_folder
    win.On.RequestFolder.Close = close
    win.On.RunButton.Clicked = close
    win.Show()
    disp.RunLoop()
    win.Hide()
    result = itm["FolderLine"].Text
    fu.SetData("ResolveSaveStills.Folder", result)
    return result


def grab_stills(album_name: str):
    """create stills from all clips in a timeline
    save the files to requested folder
    """
    if not fu.GetResolve():
        print("This is a script for Davinci Resolve")
        return

    timeline_name = timeline.GetName()
    video_track_count = timeline.GetTrackCount("video")
    print(video_track_count)
    stills = {}
    for track_num in range(1, video_track_count + 1):
        clips = timeline.GetItemListInTrack("video", track_num)
        for clip in clips:
            clip_name = clip.GetName()

    # stills = timeline.GrabAllStills(STILL_FRAME_REF)
    albums = gallery.GetGalleryStillAlbums()
    album = get_export_album(albums, album_name)

    if len(stills) == 0:
        print("no stills saved")
        return
    target_folder = request_dir()
    if target_folder:
        print(f"saving stills to {target_folder}")
    else:
        print("Stills folder not set. Defaulting to desktop location")
        target_folder = Path("~/Desktop/ResolveStills").expanduser()
        Path.mkdir(target_folder, exist_ok=True, parents=True)
        print(f"saving stills to {target_folder}")
    album.ExportStills(stills, target_folder.as_posix(), timeline_name, FORMAT)
    # album = gallery.GetCurrentStillAlbum()
    # album.DeleteStills(stills)
    resolve.OpenPage("edit")


if __name__ == "__main__":
    timeline, gallery = get_timeline_and_gallery(resolve)
    grab_stills(EXPORT_ALBUM)
