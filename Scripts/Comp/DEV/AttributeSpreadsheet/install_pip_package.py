import os
import platform
import subprocess
from pathlib import Path

import tkinter as tk
from tkinter import ttk
from tkinter.messagebox import askyesno


def get_python_home() -> Path:
    python_home = Path(os.__file__).parent.parent
    return python_home


def get_python_executable(python_home=None) -> str:
    if python_home is None:
        python_home = get_python_home()
    if platform.system() == "Windows":
        python_executable = python_home / "python.exe"
    else:
        python_executable = python_home.parent / "bin" / "python3"
    if not python_executable.exists():
        print(f"No Python executable found at {python_home}")
        return
    return python_executable.as_posix()


def run_installation_command(python_executable, package):
    print(f"No {package} installation found!")
    if not python_executable:
        return
    command = [
        python_executable,
        "-m",
        "pip",
        "install",
        package,
    ]
    print(f"running command: {command}")
    process = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    while True:
        output = process.stdout.readline().decode()
        if output == "" or process.poll() is not None:
            break
        if output:
            print(output.strip())


def fallback_message(package_name: str):
    python_executable = get_python_executable()
    print(
        f"{package_name} is required to run this script\n"
        "Please install it manually with following command:\n"
        f"{python_executable} -m pip install {package_name}"
    )


def show_confirmation_dialogue(package_name: str):
    # ask user for permission to install the package automatically

    message = f"Would you like to install {package_name} automatically?"
    title = f"Confirm package installation"
    answer = askyesno(title, message)
    return answer


def pip_install(package: str, fusion_python_home=None):
    if fusion_python_home is None:
        fusion_python_home = get_python_home()
    
    installaion_confirmed = show_confirmation_dialogue(package)
    if not installaion_confirmed:
        fallback_message(package)
        return
    python_executable = get_python_executable(fusion_python_home)
    if not python_executable:
        return
    print(f"Installing {package}...")
    run_installation_command(python_executable, package)
    print("Done.")
