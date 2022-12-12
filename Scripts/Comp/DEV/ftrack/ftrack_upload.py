import os
import re
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
REPLACE_LATEST_VERSION = True


def get_shot_number(composition):
    name = composition.GetAttrs()["COMPS_Name"]
    print(f"comp name : {name}")
    try:
        shot = re.search("_(\d{4})_", name).group(1)
    except ValueError:
        return
    return shot


def post_note(session, text: str):
    user = session.query("User").first()
    note = asset_version.create_note(text, author=user)


def get_task(shot, task_name=None):
    if not task_name:
        print("no task name provided")
        return
    for task in shot["children"]:
        if task_name in task["name"].lower():
            return task


def create_asset_version(session, shot, name: str):
    asset_type = session.query('AssetType where name is "Upload"').one()
    asset = session.query(f"Asset where name is {name}").first()
    if not asset:
        asset = session.create(
            "Asset", {"name": name, "type": asset_type, "parent": shot}
        )
    latest_version = asset["latest_version"]
    if REPLACE_LATEST_VERSION and latest_version:
        print("replacing the latest version")
        session.delete(latest_version)
        print("commiting changes...")
        session.commit()
    else:
        print("creating new asset version")
    task = get_task(shot, "compositing")
    if not task:
        print("no compostiting task found")
        return
    asset_version = session.create("AssetVersion", {"asset": asset, "task": task})
    return asset_version


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
    print(f"found shot number: {shot_number}")
    server_location = session.query('Location where name is "ftrack.server"').one()

    q = session.query(f"select id from Shot where name is {shot_number}")
    shot = q.first()

    if DRY_RUN:
        print("Dry run is activated!")
        return

    asset_version = create_asset_version(session, shot, asset_name)

    if not asset_version:
        print(f"could not create an asset version")
        return
    component = asset_version.create_component(filepath, location=server_location)

    #     component = asset_version.create_component(
    #     path=filepath,
    #     data={
    #         'name': 'ftrackreview-mp4'
    #     },
    #     location=server_location
    # )

    job = asset_version.encode_media(filepath)

    # try to get the published url - not working
    # for component in job["job_components"]:
    #     print(server_location.get_url(component))

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
