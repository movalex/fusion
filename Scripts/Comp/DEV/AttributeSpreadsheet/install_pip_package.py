import os
import sysconfig
import platform
import subprocess
from pathlib import Path
from ui_utils import ConfirmationDialog


def get_python_home() -> Path:
    """Returns Python home using PYTHONHOME environment variable or default to sysconfig."""
    python_home = os.environ.get('PYTHONHOME')
    
    if python_home:
        return Path(python_home)
    else:
        # Fallback to sysconfig as a secondary method
        import sysconfig
        return Path(sysconfig.get_config_var('base'))


def get_python_executable(python_home) -> str:
    """Determines the path of the Python executable based on the OS."""
    if platform.system() == "Windows":
        python_executable = python_home / "python.exe"
    else:
        python_executable = python_home.parent / "bin" / "python3"
    
    if not python_executable.exists():
        print(f"No Python executable found at {python_home}")
        return None
    
    return python_executable.as_posix()


def run_installation_command(python_executable, package):
    """Executes the pip install command for the given package."""
    if not python_executable:
        print("Python executable not found. Installation cannot proceed.")
        return
    
    print(f"No {package} installation found!")
    command = [python_executable, "-m", "pip", "install", package]
    print(f"Running command: {command}")
    
    try:
        process = subprocess.Popen(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        stdout, stderr = process.communicate()
        
        if process.returncode == 0:
            print(f"Successfully installed {package}:\n{stdout.decode()}")
        else:
            print(f"Error during installation of {package}:\n{stderr.decode()}")
    
    except Exception as e:
        print(f"Failed to install {package}. Exception: {e}")


def fallback_message(package_name: str, python_executable):
    print(
        f"{package_name} is required to run this script\n"
        "Please install it manually with following command:\n"
        f"{python_executable} -m pip install {package_name}"
    )


def show_confirmation_dialogue(package_name: str):
    # ask user for permission to install the package automatically

    message = f"Would you like to install {package_name} automatically?"
    title = f"Confirm package installation"
    answer = ConfirmationDialog(title, message)
    return answer


def pip_install(package: str, fusion_python_home=None):
    if fusion_python_home is None:
        fusion_python_home = get_python_home()
    
    python_executable = get_python_executable(fusion_python_home)
    if not python_executable:
        return
    installaion_confirmed = show_confirmation_dialogue(package)
    if not installaion_confirmed:
        fallback_message(package, python_executable)
        return
    print(f"Installing {package}...")
    run_installation_command(python_executable, package)
    print("Done.")
