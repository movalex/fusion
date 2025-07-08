#!/usr/bin/env python

"""
This file serves to return a DaVinci Resolve object
"""
import sys
import os
from pathlib import Path


def load_source(module_name, file_path):
    if sys.version_info[0] >= 3 and sys.version_info[1] >= 5:
        import importlib.util

        module = None
        spec = importlib.util.spec_from_file_location(module_name, file_path)
        if spec:
            module = importlib.util.module_from_spec(spec)
        if module:
            sys.modules[module_name] = module
            spec.loader.exec_module(module)
        return module
    else:
        print(f"Failed to load module {module_name} due to unsupported Python version: {sys.version_info}")


def _get_fusion_script_path():
    """Try load BlackmagicFusion.py module from default locations."""
    if os.getenv("FUSION_SCRIPT_API"):
        return Path(os.getenv("FUSION_SCRIPT_API"))
    if sys.platform.startswith("darwin"):
        return Path("~/Library/Application Support/Blackmagic Design/Fusion/Modules/Python")
    elif sys.platform.startswith("win") or sys.platform.startswith("cygwin"):
        return Path(os.getenv("APPDATA")) / "Blackmagic Design" / "Fusion" / "Modules" / "Python"
    elif sys.platform.startswith("linux"):
        return Path("/opt/fusion/Modules/Python")
    else:
        raise RuntimeError("Unsupported platform")


def _get_resolve_script_path():
    """Try load DaVinciResolveScript.py module from default locations."""
    if os.getenv("RESOLVE_SCRIPT_API"):
        return Path(os.getenv("RESOLVE_SCRIPT_API"))
    if sys.platform.startswith("darwin"):
        return Path("/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules/")
    elif sys.platform.startswith("win") or sys.platform.startswith("cygwin"):
        return Path(os.getenv("PROGRAMDATA")) / "Blackmagic Design" / "DaVinci Resolve" / "Support" / "Developer" / "Scripting" / "Modules"
    elif sys.platform.startswith("linux"):
        return Path("/opt/resolve/Developer/Scripting/Modules/")
    else:
        raise RuntimeError("Unsupported platform")


def _import_davinci_resolve_bmd():
    try:
        import DaVinciResolveScript as bmd
        return bmd
    except ImportError:
        print("Unable to find module DaVinciResolveScript from $PYTHONPATH - trying default locations")
        try:
            expected_path = _get_resolve_script_path()
            module_path = expected_path / "DaVinciResolveScript.py"
            load_source("DaVinciResolveScript", str(module_path))
            import DaVinciResolveScript as bmd
            return bmd
        except Exception as ex:
            print("Unable to find module DaVinciResolveScript - please ensure that the module DaVinciResolveScript is discoverable by python")
            print(f"For a default DaVinci Resolve installation, the module is expected to be located in: {expected_path}")
            raise ex


def _import_fusion_bmd():
    try:
        import BlackmagicFusion as bmd
        return bmd
    except ImportError:
        print("Unable to find module BlackmagicFusion from $PYTHONPATH - trying default locations")
        try:
            expected_path = _get_fusion_script_path()
            module_path = expected_path / "BlackmagicFusion.py"
            load_source("BlackmagicFusion", str(module_path))
            import BlackmagicFusion as bmd
            return bmd
        except Exception as ex:
            print("Unable to find module BlackmagicFusion - please ensure that the module BlackmagicFusion is discoverable by python")
            print(f"For a default Fusion Studio installation, the module is expected to be located in: {expected_path}")
            raise ex


def get_bmd_object(app_name="Resolve"):
    """
    Returns the Blackmagic Design object for the specified application.
    :param app_name: Name of the application, either "Resolve" or "Fusion".
    :return: The Blackmagic Design object for the specified application.
    """
    if app_name == "Fusion":
        bmd = _import_fusion_bmd() # Fusion Studio
    else:
        bmd = _import_davinci_resolve_bmd()
    
    if not bmd:
        raise RuntimeError("Could not get bmd instance")
    
    return bmd


def get_app(app_name="Resolve"):
    bmd = get_bmd_object(app_name)
    return bmd.scriptapp(app_name)


def get_resolve_fusion():
    resolve = get_app()
    re_fusion = resolve.Fusion()
    if not re_fusion:
        raise RuntimeError("Could not get Resolve Fusion instance")
    return re_fusion
