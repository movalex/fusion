import sys
import os


def load_module(module_name, file_path):
    try:
        import importlib.util
        import importlib.machinery

        loader = importlib.machinery.ExtensionFileLoader(module_name, file_path)
        spec = importlib.util.spec_from_loader(module_name, loader)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)
        return module
    except ImportError:
        # Fallback to imp if importlib is not available
        import imp

        return imp.load_dynamic(module_name, file_path)


def get_platform_paths():
    platform_paths = {
        "darwin": (
            ".so",
            [
                "./",
                "/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/",
                "/Applications/Blackmagic Fusion 18/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 18 Render Node/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 17/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 17 Render Node/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 16/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 16 Render Node/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 9/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 9 Render Node/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 8/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 8 Render Node/Fusion.app/Contents/MacOS/",
            ],
        ),
        "win32": (
            ".dll",
            [
                ".\\",
                "C:\\Program Files\\Blackmagic Design\\DaVinci Resolve\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion 18\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 18\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion 17\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 17\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion 16\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 16\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion 9\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 9\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion 8\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 8\\",
            ],
        ),
        "linux": (
            ".so",
            [
                "./",
                "/opt/resolve/libs/Fusion/",
                "/opt/BlackmagicDesign/Fusion18/",
                "/opt/BlackmagicDesign/FusionRenderNode18/",
                "/opt/BlackmagicDesign/Fusion17/",
                "/opt/BlackmagicDesign/FusionRenderNode17/",
                "/opt/BlackmagicDesign/Fusion16/",
                "/opt/BlackmagicDesign/FusionRenderNode16/",
                "/opt/BlackmagicDesign/Fusion9/",
                "/opt/BlackmagicDesign/FusionRenderNode9/",
                "/opt/BlackmagicDesign/Fusion8/",
                "/opt/BlackmagicDesign/FusionRenderNode8/",
            ],
        ),
    }

    # Default to an empty list for unsupported platforms
    return platform_paths.get(sys.platform, ("", []))


def find_and_load_module(module_name):
    ext, paths = get_platform_paths()

    # Optionally prepend a custom path from an environment variable
    modpath = os.getenv("FUSION_MODULE_PATH")
    if modpath:
        paths.insert(0, modpath)

    for path in paths:
        try:
            full_path = os.path.join(path, module_name + ext)
            module = load_module(module_name, full_path)
            if module:
                return module
        except ImportError:
            continue
    return None


fu_mod = find_and_load_module("fusionscript")

if fu_mod:
    sys.modules[__name__] = fu_mod
    print("Module loaded successfully.")
else:
    raise ImportError("Could not locate module dependencies")
