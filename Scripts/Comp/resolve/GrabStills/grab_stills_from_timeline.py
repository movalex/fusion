from pathlib import Path
import sys
import time
from typing import Dict, Any, List, Optional

# Ensure shared Modules/Python is on sys.path so we don't need local copies
def _bootstrap_modules_path():
    candidates = []
    try:
        # repo root is 5 levels up from this script: GrabStills -> resolve -> Comp -> Scripts -> fusion
        repo_root = Path(__file__).resolve().parents[5]
        candidates.append(repo_root / "Modules" / "Python")
    except Exception:
        pass
    # Fallback to user-provided absolute path
    candidates.append(Path(r"C:\Users\alexey.bogomolov\Documents\git\fusion\Modules\Python"))

    for p in candidates:
        try:
            if p.exists():
                sp = str(p)
                if sp not in sys.path:
                    sys.path.insert(0, sp)
                break
        except Exception:
            continue

_bootstrap_modules_path()

from resolve_utils import ResolveUtility
from ui_utils import (
    BaseUI, ConfirmationDialog, RequestDir,
)

"""
    This is a Davinci Resolve script to save all timeline clips to images.

    License: MIT
    Copyright © 2024 Alexey Bogomolov
    Email: mail@abogomolov.com
"""

STILL_FRAME_REF = 2  # 1 - First frame, 2 - Middle frame
DEFAULT_STILL_ALBUM = "STILLS"
DEFAULT_STILL_FORMAT = "jpg"

# Marker colors as in Resolve
MARKER_COLORS = [
    "Any",
    "Blue",
    "Cyan",
    "Green",
    "Yellow",
    "Red",
    "Pink",
    "Purple",
    "Fuchsia",
    "Rose",
    "Lavender",
    "Sky",
    "Mint",
    "Lemon",
    "Sand",
    "Cocoa",
    "Cream",
]

# Export formats supported by ExportStills
STILL_FORMATS = {
    "dpx": "DPX Files (*.dpx)",
    "cin": "Cineon Files (*.cin)",
    "tif": "TIFF Files (*.tif)",
    "jpg": "JPEG Files (*.jpg)",
    "png": "PNG Files (*.png)",
    "ppm": "PPM Files (*.ppm)",
    "bmp": "BMP Files (*.bmp)",
    "xpm": "XPM Files (*.xpm)",
}
STILL_FORMATS_ORDER = ["dpx", "cin", "tif", "jpg", "png", "ppm", "bmp", "xpm"]

utils = ResolveUtility()
resolve = utils.resolve
fusion = resolve.Fusion()


def get_target_folder() -> str:
    """
    Checks for target folder Resolve data,
    Shows folder request dialogue if data not found
    """
    target_folder_data = fusion.GetData("BatchResolveSaveStills.Folder")
    if not target_folder_data or target_folder_data == "":
        target_folder = RequestDir("The stills will be saved to: ", target_folder_data)
        fusion.SetData("BatchResolveSaveStills.Folder", target_folder)
        return target_folder

    return target_folder_data


def reselect_album(still_album, gallery):
    """Workaround: reselect album before export to avoid ExportStills() errors in some cases."""
    albums = gallery.GetGalleryStillAlbums()
    for album in albums:
        if album != still_album:
            gallery.SetCurrentStillAlbum(album)
            break
    gallery.SetCurrentStillAlbum(still_album)


class GrabStillsOptionsDialog(BaseUI):
    """Options dialog using Fusion UI Manager via BaseUI."""

    def __init__(self, defaults: Optional[Dict[str, Any]] = None):
        self.defaults = defaults or {}
        # preload persistent folder if available
        self.persist_key = "BatchResolveSaveStills.Folder"
        self.default_folder = fusion.GetData(self.persist_key) or ""
        super().__init__(
            window_title="Grab Stills at Markers",
            geometry=[800, 600, 600, 230],
            id="GrabStillsOptionsDialog",
        )
        self.itm = self.win.GetItems()
        self._initialize_values()
        self._wire_events()

    def run(self) -> Optional[Dict[str, Any]]:
        """Show dialog and return selected options or None if canceled."""
        self.result = None
        self.show()
        return self.result

    def _initialize_values(self):
        # Set defaults into UI
        # Save mode
        save_per_marker = self.defaults.get("save_per_marker", True)
        self.itm["SaveModeCombo"].CurrentIndex = 0 if save_per_marker else 1

        # Marker color
        default_color = self.defaults.get("marker_color", "Any")
        try:
            self.itm["MarkersCombo"].CurrentText = default_color
        except Exception:
            self.itm["MarkersCombo"].CurrentIndex = 0

        # Export toggle
        export_on = self.defaults.get("export", True)
        self.itm["ExportCheck"].Checked = export_on
        self._toggle_export(export_on)

        # Export folder
        folder = self.defaults.get("export_to", self.default_folder)
        self.itm["ExportPath"].Text = folder

        # Format
        fmt = self.defaults.get("format", DEFAULT_STILL_FORMAT)
        # map to index
        idx = STILL_FORMATS_ORDER.index(fmt) if fmt in STILL_FORMATS_ORDER else STILL_FORMATS_ORDER.index(DEFAULT_STILL_FORMAT)
        self.itm["FormatCombo"].CurrentIndex = idx

        # Album name
        self.itm["AlbumName"].Text = self.defaults.get("album", DEFAULT_STILL_ALBUM)

        # Post options
        self.itm["DeleteStills"].Checked = self.defaults.get("delete_stills", True)
        self.itm["CleanupDRX"].Checked = self.defaults.get("cleanup_drx", True)
        self.itm["OpenEdit"].Checked = self.defaults.get("open_edit", True)

        self._update_info()

    def _wire_events(self):
        self.win.On.ExportCheck.Toggled = lambda ev: self._toggle_export(self.itm["ExportCheck"].Checked)
        self.win.On.BrowseBtn.Clicked = self._browse_folder
        self.win.On.CancelBtn.Clicked = self.close
        self.win.On.StartBtn.Clicked = self._confirm
        self.win.On.MarkersCombo.CurrentIndexChanged = lambda ev: self._update_info()
        self.win.On.SaveModeCombo.CurrentIndexChanged = lambda ev: self._update_info()

    def _toggle_export(self, enabled: bool):
        self.itm["ExportGroup"].Enabled = enabled
        # Enable Start only when export folder present if exporting
        self._update_start_enabled()

    def _browse_folder(self, ev):
        out = RequestDir("Export to:", self.itm["ExportPath"].Text)
        if out:
            self.itm["ExportPath"].Text = out
            fusion.SetData(self.persist_key, out)
        self._update_start_enabled()

    def _update_start_enabled(self):
        can_start = True
        if self.itm["ExportCheck"].Checked:
            can_start = bool(self.itm["ExportPath"].Text)
        self.itm["StartBtn"].Enabled = can_start

    def _update_info(self):
        # Optional: show hint about selection
        mode = self.itm["SaveModeCombo"].CurrentText
        color = self.itm["MarkersCombo"].CurrentText
        txt = "Saving per marker" if mode.startswith("Per marker") else "Saving per clip"
        if mode.startswith("Per marker"):
            txt += f"; filter: {color}"
        self.itm["InfoLabel"].Text = txt

    def layout(self):
        ui = self.ui
        return ui.VGroup(
            [
                ui.HGroup(
                    [
                        ui.Label({"Text": "Save mode", "MinimumSize": [100, 0], "MaximumSize": [120, 16777215]}),
                        ui.ComboBox({
                            "ID": "SaveModeCombo",
                            "Weight": 1,
                            "Editable": False,
                            "Events": {"CurrentIndexChanged": True},
                            "Items": ["Per marker", "Per clip"],
                        }),
                    ]
                ),
                ui.HGroup(
                    [
                        ui.Label({"Text": "Timeline markers", "MinimumSize": [100, 0], "MaximumSize": [120, 16777215]}),
                        ui.ComboBox({
                            "ID": "MarkersCombo",
                            "Weight": 1,
                            "Editable": False,
                            "Items": MARKER_COLORS,
                            "Events": {"CurrentIndexChanged": True},
                        }),
                    ]
                ),
                ui.HGroup([
                    ui.Label({"ID": "InfoLabel", "Text": "", "Weight": 1})
                ]),
                ui.HGap(0),
                ui.HGroup(
                    [
                        ui.Label({"Text": "", "MinimumSize": [100, 0], "MaximumSize": [120, 16777215]}),
                        ui.CheckBox({"ID": "ExportCheck", "Text": "Export grabbed stills", "Checked": True, "Events": {"Toggled": True}}),
                    ]
                ),
                ui.VGroup(
                    {
                        "ID": "ExportGroup",
                        "Enabled": True,
                    },
                    [
                        ui.HGroup(
                            [
                                ui.Label({"Text": "Export to", "MinimumSize": [100, 0], "MaximumSize": [120, 16777215]}),
                                ui.LineEdit({"ID": "ExportPath", "Weight": 1, "Text": self.default_folder or ""}),
                                ui.Button({"ID": "BrowseBtn", "Text": "Browse"}),
                            ]
                        ),
                        ui.HGroup(
                            [
                                ui.Label({"Text": "Format", "MinimumSize": [100, 0], "MaximumSize": [120, 16777215]}),
                                ui.ComboBox({
                                    "ID": "FormatCombo",
                                    "Weight": 1,
                                    "Editable": False,
                                    "Items": [STILL_FORMATS[k] for k in STILL_FORMATS_ORDER],
                                }),
                            ]
                        ),
                        ui.HGroup(
                            [
                                ui.Label({"Text": "Album name", "MinimumSize": [100, 0], "MaximumSize": [120, 16777215]}),
                                ui.LineEdit({"ID": "AlbumName", "Weight": 1, "Text": DEFAULT_STILL_ALBUM}),
                            ]
                        ),
                    ],
                ),
                ui.HGroup(
                    [
                        ui.Label({"Text": "", "MinimumSize": [100, 0], "MaximumSize": [120, 16777215]}),
                        ui.CheckBox({"ID": "DeleteStills", "Text": "Delete grabbed stills from album after export", "Checked": True}),
                    ]
                ),
                ui.HGroup(
                    [
                        ui.Label({"Text": "", "MinimumSize": [100, 0], "MaximumSize": [120, 16777215]}),
                        ui.CheckBox({"ID": "CleanupDRX", "Text": "Cleanup .drx files in export folder", "Checked": True}),
                    ]
                ),
                ui.HGroup(
                    [
                        ui.Label({"Text": "", "MinimumSize": [100, 0], "MaximumSize": [120, 16777215]}),
                        ui.CheckBox({"ID": "OpenEdit", "Text": "Open Edit page after export", "Checked": True}),
                    ]
                ),
                ui.HGroup(
                    {
                        "StyleSheet": "QPushButton { min-height: 22px; max-height: 22px; min-width: 108px; max-width: 108px; }",
                    },
                    [
                        ui.HGap(0, 1),
                        ui.Button({"ID": "CancelBtn", "Text": "Cancel"}),
                        ui.Button({"ID": "StartBtn", "Text": "Start", "Default": True}),
                    ]
                ),
            ]
        )

    def _collect(self) -> Dict[str, Any]:
        fmt = STILL_FORMATS_ORDER[self.itm["FormatCombo"].CurrentIndex]
        options = {
            "save_per_marker": self.itm["SaveModeCombo"].CurrentIndex == 0,
            "marker_color": self.itm["MarkersCombo"].CurrentText,
            "export": self.itm["ExportCheck"].Checked,
            "export_to": self.itm["ExportPath"].Text,
            "format": fmt,
            "album": self.itm["AlbumName"].Text or DEFAULT_STILL_ALBUM,
            "delete_stills": self.itm["DeleteStills"].Checked,
            "cleanup_drx": self.itm["CleanupDRX"].Checked,
            "open_edit": self.itm["OpenEdit"].Checked,
        }
        return options

    def _confirm(self, ev):
        # validate
        if self.itm["ExportCheck"].Checked and not self.itm["ExportPath"].Text:
            # keep dialog open until path set
            return
        self.result = self._collect()
        self.close()



def cleanup_drx_from_folder(folder: Path):
    print(
        "CLEANUP DRX is enabled, all .drx files in the stills location will be erased"
    )
    answer = ConfirmationDialog(
        title="DRX files deletion!",
        request=f"Do you wish to delete all DRX files\nin'{folder}' folder?",
    )

    if answer:
        for file in folder.iterdir():
            if file.suffix == ".drx":
                file.unlink()


def post_processing(stills: list, still_album, gallery, options: Dict[str, Any], target_folder: Optional[Path] = None):
    if options.get("delete_stills", True):
        still_album_name = gallery.GetAlbumName(still_album)
        print(
            f"Please note, that DELETE_STILLS is set to True, so new stills in '{still_album_name}' album will be erased"
        )
        answer = ConfirmationDialog(
            "Stills Deletion!",
            f"Do you want to delete stills\nin '{still_album_name}' album?",
        )
        if answer:
            still_album.DeleteStills(stills)

    if options.get("cleanup_drx", True) and target_folder:
        cleanup_drx_from_folder(target_folder)

    if options.get("open_edit", True):
        utils.resolve.OpenPage("edit")


def grab_stills_from_markers(current_timeline, still_album, color_filter: str = "Any") -> List[Any]:
    """Create stills from timeline markers"""
    markers = current_timeline.GetMarkers()
    if not markers:
        print("No markers found in timeline")
        return []
    # sort markers by frame
    stills = []
    for frame_id in sorted(markers.keys()):
        marker_data = markers[frame_id]
        if color_filter and color_filter != "Any":
            if marker_data.get("color") != color_filter:
                continue
        # Navigate and grab
        current_timeline.SetCurrentTimecode(utils.frame_to_timecode(frame_id))
        print(f"Processing marker at timecode: {current_timeline.GetCurrentTimecode()}")
        time.sleep(0.2)  # small delay for stability
        still = current_timeline.GrabStill()
        marker_name = marker_data.get("name", "Unnamed")
        try:
            still_album.SetLabel(still, marker_name)
        except Exception:
            pass
        print(f"Grabbed still from marker at frame {frame_id}: {marker_name}")
        stills.append(still)

    if stills:
        updated_stills = still_album.GetStills()
        return updated_stills
    return []

def grab_timeline_stills(options: Optional[Dict[str, Any]] = None):
    """create stills from all clips in a timeline or from markers
    save the files to requested folder. Currently GetGalleryStillAlbums() is used,
    so we are unable to add a label to each still.
    """
    options = options or {}
    if not utils.resolve:
        print("This is a script for Davinci Resolve")
        return

    gallery = utils.get_gallery()

    current_timeline = utils.get_current_timeline()
    timeline_name = current_timeline.GetName()
    video_track_count = current_timeline.GetTrackCount("video")

    print(f"Found {video_track_count} tracks")

    album_name = options.get("album", DEFAULT_STILL_ALBUM)
    still_album = utils.get_still_album(gallery, album_name)
    still_album_name = gallery.GetAlbumName(still_album)
    save_per_marker = options.get("save_per_marker", True)

    if save_per_marker:
        print("Saving stills per marker")
        color_filter = options.get("marker_color", "Any")
        stills = grab_stills_from_markers(current_timeline, still_album, color_filter=color_filter)
    else:
        print("Saving stills per clip")
        stills = current_timeline.GrabAllStills(STILL_FRAME_REF)

    if len(stills) == 0:
        print("No stills saved")
        return

    export_enabled = options.get("export", True)
    if export_enabled:
        target_folder = options.get("export_to") or get_target_folder()
        if not target_folder:
            print("Target folder is not set, aborting export.")
            return

        target_folder = Path(target_folder, still_album_name)
        try:
            utils.create_folder(target_folder)
        except Exception:
            utils.reset_global_data("ResolveSaveStills.Folder")
            return

        print(f"Saving stills to {target_folder}")

        # Workaround: reselect album before export
        reselect_album(still_album, gallery)
        export_format = options.get("format", DEFAULT_STILL_FORMAT)
        # Use empty prefix to let Resolve use still labels as filenames
        still_album.ExportStills(
            stills, target_folder.as_posix(), "", export_format
        )
        post_processing(stills, still_album, gallery, options, target_folder)
    else:
        print("Export disabled; leaving grabbed stills in the album.")
        post_processing(stills, still_album, gallery, options, None)


if __name__ == "__main__":
    # Show options dialog and run
    defaults = {
        "save_per_marker": True,
        "marker_color": "Any",
        "export": True,
        "export_to": fusion.GetData("BatchResolveSaveStills.Folder") or "",
        "format": DEFAULT_STILL_FORMAT,
        "album": DEFAULT_STILL_ALBUM,
        "delete_stills": True,
        "cleanup_drx": True,
        "open_edit": True,
    }
    dlg = GrabStillsOptionsDialog(defaults)
    options = dlg.run()  # BaseUI.run returns when window closes; our subclass returns None; adjust
    # Since BaseUI.run doesn't return a result, use attribute
    options = getattr(dlg, "result", None)
    if options is None:
        # Cancelled
        pass
    else:
        grab_timeline_stills(options)
