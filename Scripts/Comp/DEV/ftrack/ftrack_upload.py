import os
import platform
import subprocess
import re
from pathlib import Path

DRY_RUN = False
REPLACE_LAST_VERSION = True


def get_python_executable() -> str:
    lib_path = Path(os.__file__).parent.parent
    if platform.system() == "Windows":
        python_executable = lib_path / "python.exe"
    else:
        python_executable = lib_path / "python3"
    return str(python_executable)


def output_to_console(process):
    while True:
        output = process.stdout.readline().decode()
        if output == "" or process.poll() is not None:
            break
        if output:
            print(output.strip())


def run_pip_install(package, print_to_console=True):
    python_executable = get_python_executable()
    command = [
        python_executable,
        "-m",
        "pip",
        "install",
        f"{package}",
    ]
    print(f"running command: {command}")
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if print_to_console:
        output_to_console(process)
    rc = process.poll()
    return rc


def install_ftrack_api():
    print("Installing ftrack libraries")
    PKG = ["ftrack-python-api"]
    # PKG = ["ftrack-python-api", "tqdm"]
    # rc = run_pip_install(" ".join(PKG))
    for package in PKG:
        rc = run_pip_install(package)
        if not rc:
            print(f"Package {package} installed\n")
        else:
            print(
                f"{package} installation has failed for some reason"
                "\nCheck if internet connection is available."
                "\nPlease report this issue: mail@abogomolov.com"
            )
    print("Now relaunch the script, please")
    sys.exit()
    

try:
    import ftrack_api
    # from tqdm import tqdm
except ModuleNotFoundError:
    install_ftrack_api()

comp = fu.GetCurrentComp()


def get_shot(composition):
    name = composition.GetAttrs()["COMPS_Name"]
    print(f"comp name : {name}")
    try:
        shot = re.search("_(\d{4})_", name).group(1)
    except ValueError:
        return
    return shot


def publish_ftrack_version(filepath):
    # filepath = 'R:\\PROJECTS\\ZEKE\\2210_Consumed\\WIP\\CON_1630_v02.mov'
    file_name = Path(filepath).stem
    print(f"found file : {file_name}")
    asset_name = "_".join(file_name.split("_")[:2])
    print(f"publishing {asset_name} to ftrack")

    shot_number = get_shot(comp)
    if not shot_number:
        print("shot number not found")
        return

    session = ftrack_api.Session()

    if not session:
        print("could not connect to API, check API settings")
        return
    user = session.query("User").first()
    print(f"connected to API session: {session.server_url} as {session.api_user}")
    print(f"found shot number: {shot_number}")
    server_location = session.query('Location where name is "ftrack.server"').one()

    q = session.query(f"select id from Shot where name is {shot_number}")
    shot = q.first()
    version = session.query("AssetVersion", shot["id"]).first()

    for child in shot["children"]:
        if child["name"] == "compositing":
            task = child
            break
    if not task:
        print("no Compositing ftrack task found")
        return
    if DRY_RUN:
        print("Dry run is actuvated!")
        return
    asset_type = session.query('AssetType where name is "Upload"').one()
    asset_parent = task["parent"]
    asset = session.query(f"Asset where name is {asset_name}").first()
    if not asset:
        asset = session.create(
            "Asset", {"name": asset_name, "type": asset_type, "parent": asset_parent}
        )
    last_asset_version = asset["latest_version"]
    if REPLACE_LAST_VERSION and last_asset_version:
        print("replacing the last version")
        session.delete(last_asset_version)
        session.commit()
    asset_version = session.create("AssetVersion", {"asset": asset, "task": task})
    asset_version.create_component(filepath, location=server_location)

    # pbar = tqdm(desc="Upload progress")
    job = asset_version.encode_media(filepath)

    # for component in job["job_components"]:
    #     print(server_location.get_url(component))
    # message = "Uploaded with API"
    # note = asset_version.create_note(message, author=user)
    # session.commit()
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

# component = version.create_component(
#     path=filepath,
#     data={
#         'name': 'ftrackreview-mp4'
#     },
#     location=server_location
# )

# component['metadata']['ftr_meta'] = json.dumps({
#     'frameIn': 1000,
#     'frameOut': 1049,
#     'frameRate': 23.976,
#     'height': 2048,
#     'width': 802
# })
