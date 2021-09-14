import sys
import imp
import os

fu_mod = None

try:
    import fusionscript as fu_mod

except ImportError:
    ext = ""

    if sys.platform.startswith("darwin"):
        ext = ".so"
        paths = [
            "./",
            "/Applications/DaVinci Resolve/DaVinci"
            " Resolve.app/Contents/Libraries/Fusion/",
            "/Applications/Blackmagic Fusion 17/Fusion.app/Contents/MacOS/",
            "/Applications/Blackmagic Fusion 17 Render Node/Fusion.app/Contents/MacOS/",
            "/Applications/Blackmagic Fusion 16/Fusion.app/Contents/MacOS/",
            "/Applications/Blackmagic Fusion 16 Render Node/Fusion.app/Contents/MacOS/",
            "/Applications/Blackmagic Fusion 9/Fusion.app/Contents/MacOS/",
            "/Applications/Blackmagic Fusion 9 Render Node/Fusion.app/Contents/MacOS/",
            "/Applications/Blackmagic Fusion 8/Fusion.app/Contents/MacOS/",
            "/Applications/Blackmagic Fusion 8 Render Node/Fusion.app/Contents/MacOS/",
        ]
    elif sys.platform.startswith("win") or sys.platform.startswith("cygwin"):
        ext = ".dll"
        paths = [
            "./",
            "C:\\Program Files\\Blackmagic Design\\Fusion 9\\",
            "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 9\\",
            "C:\\Program Files\\Blackmagic Design\\Fusion 8\\",
            "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 8\\",
            "C:\\Program Files\\Blackmagic Design\\DaVinci Resolve\\",
            "C:\\Program Files\\Blackmagic Design\\Fusion 17\\",
            "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 17\\",
            "C:\\Program Files\\Blackmagic Design\\Fusion 16\\",
            "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 16\\",
        ]
    elif sys.platform.startswith("linux"):
        ext = ".so"
        paths = [
            "./",
            "/opt/resolve/libs/Fusion/",
            "/opt/BlackmagicDesign/Fusion17/",
            "/opt/BlackmagicDesign/FusionRenderNode17/",
            "/opt/BlackmagicDesign/Fusion16/",
            "/opt/BlackmagicDesign/FusionRenderNode16/",
            "/opt/BlackmagicDesign/Fusion9/",
            "/opt/BlackmagicDesign/FusionRenderNode9/",
            "/opt/BlackmagicDesign/Fusion8/",
            "/opt/BlackmagicDesign/FusionRenderNode8/",
        ]

    modpath = os.getenv("FUSION_MODULE_PATH")
    if modpath:
        paths.insert(0, modpath)

    for path in paths:
        import importlib
        module = "fusionscript"
        full_path = path + "fusionscript" + ext
        if not os.path.exists(full_path):
            continue
        loader = importlib.machinery.SourceFileLoader(module, full_path)
        spec = importlib.util.spec_from_loader(module, loader)
        fu_mod = importlib.util.module_from_spec(spec)
        try:
            loader.exec_module(fu_mod)
        except ValueError as e:
            print("unable to execute module\n", e) 

if fu_mod:
    sys.modules[__name__] = fu_mod
else:
    raise ImportError("could not locate module dependencies")
