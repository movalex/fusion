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


def _get_resolve_script_paths():
    """Return candidate locations for DaVinciResolveScript.py."""
    paths = []
    env = os.getenv("RESOLVE_SCRIPT_API")
    if env:
        paths.append(Path(env))
    if sys.platform.startswith("darwin"):
        paths.append(Path("/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules/"))
        paths.append(Path("/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Resources/Developer/Scripting/Modules"))
    elif sys.platform.startswith("win") or sys.platform.startswith("cygwin"):
        programdata = os.getenv("PROGRAMDATA", r"C:\ProgramData")
        paths.append(Path(programdata) / "Blackmagic Design" / "DaVinci Resolve" / "Support" / "Developer" / "Scripting" / "Modules")
        programfiles = os.getenv("PROGRAMFILES", r"C:\Program Files")
        paths.append(Path(programfiles) / "Blackmagic Design" / "DaVinci Resolve" / "Developer" / "Scripting" / "Modules")
    elif sys.platform.startswith("linux"):
        paths.append(Path("/opt/resolve/Developer/Scripting/Modules/"))
    else:
        raise RuntimeError("Unsupported platform")
    return paths


def _ensure_in_syspath(path: Path):
    try:
        if path and path.exists():
            sp = str(path)
            if sp not in sys.path:
                sys.path.insert(0, sp)
            return True
    except Exception:
        pass
    return False


def _import_davinci_resolve_bmd():
    try:
        import DaVinciResolveScript as bmd
        return bmd
    except ImportError:
        # Try known locations and add to sys.path first; only print if totally failing
        candidates = _get_resolve_script_paths()
        loaded = False
        last_expected = None
        for base in candidates:
            last_expected = base
            # Prefer sys.path addition and a regular import to mimic embedded behavior
            if _ensure_in_syspath(base):
                try:
                    import DaVinciResolveScript as bmd
                    return bmd
                except ImportError:
                    # fall back to direct load from file in the same base
                    module_path = base / "DaVinciResolveScript.py"
                    if module_path.exists():
                        load_source("DaVinciResolveScript", str(module_path))
                        import DaVinciResolveScript as bmd  # noqa: F401
                        loaded = True
                        return bmd
        # If we reach here, fail with guidance
        print("Unable to find module DaVinciResolveScript - ensure it is discoverable by Python.")
        if last_expected:
            print(f"Tried locations like: {last_expected}")
        print("You can set RESOLVE_SCRIPT_API env var to the '.../Scripting/Modules' directory.")
        raise


def _import_fusion_bmd():
    try:
        import BlackmagicFusion as bmd
        return bmd
    except ImportError:
        # Try default/user locations and add to sys.path
        expected_path = _get_fusion_script_path()
        tried = [expected_path]
        # Also consider Program Files installation on Windows
        if sys.platform.startswith("win") or sys.platform.startswith("cygwin"):
            pf = os.getenv("PROGRAMFILES", r"C:\Program Files")
            tried.append(Path(pf) / "Blackmagic Design" / "Fusion Studio" / "Modules" / "Python")
        for base in tried:
            if _ensure_in_syspath(base):
                try:
                    import BlackmagicFusion as bmd
                    return bmd
                except ImportError:
                    module_path = base / "BlackmagicFusion.py"
                    if module_path.exists():
                        load_source("BlackmagicFusion", str(module_path))
                        import BlackmagicFusion as bmd  # noqa: F401
                        return bmd
        print("Unable to find module BlackmagicFusion - please ensure it is discoverable by Python.")
        print(f"Tried locations like: {expected_path}")
        raise


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
