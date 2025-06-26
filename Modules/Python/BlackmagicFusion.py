"""
Import Fusion scripting module using importlib
Helps finding scripting fusion module for Fusion versions from 8 to 19

Copyright © 2024 Alexey Bogomolov

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""


import sys
import os


def load_module(module_name, file_path):
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
        # Fallback to imp if importlib is not available
        import imp
        return imp.load_source(module_name, file_path)


def get_platform_paths():
    platform_paths = {
        "darwin": (
            ".so",
            [
                "./",
                "/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/",
                "/Applications/Blackmagic Fusion 19/Fusion.app/Contents/MacOS/",
                "/Applications/Blackmagic Fusion 19 Render Node/Fusion.app/Contents/MacOS/",
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
                "C:\\Program Files\\Blackmagic Design\\Fusion 19\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 19\\"
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
                "/opt/BlackmagicDesign/Fusion19/",
                "/opt/BlackmagicDesign/FusionRenderNode19/",
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
    paths = platform_paths.get(sys.platform, ("", []))
    if not paths[1]:
        print("Fusion paths not found for your platform. Please ensure that the module fuscript is discoverable by Python")
    return paths


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
