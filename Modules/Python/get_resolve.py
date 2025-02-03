#!/usr/bin/env python

"""
This file serves to return a DaVinci Resolve object
"""
import sys
import os
from pathlib import Path
import importlib.util


def load_source(module_name, file_path):
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    if spec and spec.loader:
        module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = module
        spec.loader.exec_module(module)
        return module
    raise ImportError(f"Could not load module {module_name} from {file_path}")


def get_default_module_path():
    if sys.platform.startswith("darwin"):
        return Path("/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules/")
    elif sys.platform.startswith("win") or sys.platform.startswith("cygwin"):
        return Path(os.getenv("PROGRAMDATA")) / "Blackmagic Design" / "DaVinci Resolve" / "Support" / "Developer" / "Scripting" / "Modules"
    elif sys.platform.startswith("linux"):
        return Path("/opt/resolve/Developer/Scripting/Modules/")
    else:
        raise RuntimeError("Unsupported platform")


def import_davinci_resolve_script():
    try:
        import DaVinciResolveScript as bmd
        return bmd
    except ImportError:
        print("Unable to find module DaVinciResolveScript from $PYTHONPATH - trying default locations")
        try:
            default_path = get_default_module_path()
            module_path = default_path / "DaVinciResolveScript.py"
            load_source("DaVinciResolveScript", str(module_path))
            import DaVinciResolveScript as bmd
            return bmd
        except Exception as ex:
            print("Unable to find module DaVinciResolveScript - please ensure that the module DaVinciResolveScript is discoverable by python")
            print(f"For a default DaVinci Resolve installation, the module is expected to be located in: {default_path}")
            raise ex


def GetResolve():
    bmd = import_davinci_resolve_script()
    return bmd.scriptapp("Resolve")
