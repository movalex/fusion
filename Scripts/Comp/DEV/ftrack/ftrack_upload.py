import os
import re
import json
import sys
from pathlib import Path
from install_package import install_ftrack_packages

try:
    import ftrack_api
except ModuleNotFoundError:
    PKG = ["ftrack-python-api"]
    install_ftrack_packages(PKG)
    sys.exit()

comp = fu.GetCurrentComp()
DRY_RUN = False


def show_ui(asset_name: str, note_text: str):
    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow(
        {
            "ID": "FtrackUploadWindow",
            "TargetID": "FtrackUploadWindow",
            "WindowTitle": "Upload the Saver file to Ftrack",
            "Geometry": [800, 600, 450, 130],
        },
        [
            ui.VGroup(
                [
                    ui.HGroup(
                        [
                            ui.Label(
                                {
                                    "ID": "TopLabel",
                                    "Text": f"publishing shot: {asset_name}",
                                }
                            ),
                        ]
                    ),
                    ui.HGroup(
                        [
                            ui.CheckBox(
                                {
                                    "ID": "CheckBox",
                                    "Text": "Replace Latest Version",
                                }
                            ),
                        ]
                    ),
                    ui.HGroup(
                        [
                            ui.Label(
                                {"Weight": 0.1, "ID": "ShotLabel", "Text": "Add Note:"}
                            ),
                            ui.LineEdit(
                                {
                                    "Weight": 0.8,
                                    "ID": "NoteLine",
                                    "Events": {"ReturnPressed": True},
                                    "Alignment": {
                                        "AlignHCenter": True,
                                        "AlignVCenter": True,
                                    },
                                    "Text": note_text,
                                }
                            ),
                        ],
                    ),
                    ui.HGroup(
                        [
                            ui.Button({"ID": "UploadButton", "Text": "Upload"}),
                            ui.Button({"ID": "CancelButton", "Text": "Cancel"}),
                        ]
                    ),
                ],
            ),
        ],
    )
    itm = win.GetItems()

    itm["NoteLine"].SetClearButtonEnabled(True)
    itm["NoteLine"].SetPlaceholderText("Enter the note")

    def cancel(ev):
        disp.ExitLoop()
        return None

    def do_upload(ev):
        disp.ExitLoop()

    win.On.UploadButton.Clicked = do_upload
    win.On.CancelButton.Clicked = cancel
    win.On.FtrackUploadWindow.Close = cancel

    win.Show()
    disp.RunLoop()
    win.Hide()

    replace_status = itm["CheckBox"].Checked
    result = itm["NoteLine"].Text
    return replace_status, result


def get_shot_number(composition):
    name = composition.GetAttrs()["COMPS_Name"]
    try:
        shot = re.search("_(\d{4})_", name).group(1)
        print(f"found shot name: {shot}")
    except ValueError:
        return
    return shot


def post_note(text: str, asset_version, user) -> None:
    asset_version.create_note(text, author=user)


def get_task(shot, task_name=None):
    if not task_name:
        print("no task name provided")
        return
    for task in shot["children"]:
        if task_name in task["name"].lower():
            return task

def get_last_note(asset_version):
    notes = asset_version["notes"]
    try:
        note = notes[-1]
        note_text = note["content"]
        print(f"found latest note: {note_text}")
        return note_text
    except IndexError:
        print("could not retrieve latest note")
        return ""


def get_asset_version(session, parent, asset_name: str):
    asset_type = session.query('AssetType where name is "Upload"').one()
    asset = session.query(f"Asset where name is {asset_name}").first()
    if not asset:
        asset = session.create(
            "Asset", {"name": asset_name, "type": asset_type, "parent": parent}
        )
    latest_version = asset["latest_version"]
    note_text = get_last_note(latest_version)

    try:
        replace_latest, note_text = show_ui(asset_name, note_text)
    except TypeError:
        print("UI was closed and the upload was cancelled")
        sys.exit()

    if replace_latest and latest_version:
        print("replacing the latest version")
        session.delete(latest_version)
        print("commiting changes...")
        session.commit()
    else:
        print("creating new asset version")

    task = get_task(parent, "compositing")

    if not task:
        print("no compostiting task found")
        return
    asset_version = session.create("AssetVersion", {"asset": asset, "task": task})
    return asset_version, note_text


def set_component_metadata(component, data: dict):
    component["metadata"]["ftr_meta"] = json.dumps(
        {
            "frameIn": data["In"],
            "frameOut": data["Out"],
            "frameRate": data["Framerate"],
            "height": data["Width"],
            "width": data["height"],
        }
    )


def publish_ftrack_version(filepath):
    # filepath = 'R:\\PROJECTS\\ZEKE\\2210_Consumed\\WIP\\CON_1630_v02.mov'
    file_name = Path(filepath).stem
    print(f"found file : {file_name}")
    asset_name = "_".join(file_name.split("_")[:2])
    print(f"publishing {asset_name} to ftrack")

    shot_number = get_shot_number(comp)
    if not shot_number:
        print("shot number not found")
        return

    session = ftrack_api.Session()

    if not session:
        print("could not connect to API, check API settings")
        return
    print(f"connected to API session: {session.server_url} as {session.api_user}")
    server_location = session.query('Location where name is "ftrack.server"').one()

    q = session.query(f"select id from Shot where name is {shot_number}")
    shot = q.first()

    if DRY_RUN:
        print("Dry run is activated!")
        return

    asset_version, note_text = get_asset_version(session, parent=shot, asset_name=asset_name)

    if not asset_version:
        print(f"could not create an asset version")
        return

    component = asset_version.create_component(filepath, location=server_location)

    job = asset_version.encode_media(filepath)
    if note_text:
        user = session.query("User").first()
        post_note(note_text, asset_version, user)

    session.commit()
    print("Ftrack publishing -- Done!")


def main():
    tool = comp.ActiveTool
    if tool and tool.ID == "Saver":
        file_path = comp.MapPath(tool.Clip[0])
        if os.path.exists(file_path):
            publish_ftrack_version(file_path)
        else:
            print("file not found")
    else:
        print("select a saver")


main()
