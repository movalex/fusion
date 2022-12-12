import os
import platform
import subprocess
from pathlib import Path


def get_python_executable() -> str:
    lib_path = Path(os.__file__).parent.parent
    if platform.system() == "Windows":
        python_executable = lib_path / "python.exe"
    else:
        python_executable = lib_path.parent / "bin" / "python3"
    if not python_executable.exists():
        print("No Python executable found. Please report this.")
        return
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
    if not python_executable:
        return
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


def install_ftrack_packages(packages: list):
    print("Installing ftrack libraries")
    for package in packages:
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
