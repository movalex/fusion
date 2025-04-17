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
import platform # Import platform module
import importlib.machinery # Import machinery


# Print Python version and architecture
print(f"Python Version: {sys.version}")
print(f"Python Architecture: {platform.architecture()[0]}")
print(f"OS Platform: {sys.platform}")
# Print recognized extension module suffixes
print(f"Recognized Extension Suffixes: {importlib.machinery.EXTENSION_SUFFIXES}")


def load_module(module_name, file_path):
    print(f"Attempting load_module for {module_name} at {file_path}")
    if sys.version_info[0] >= 3 and sys.version_info[1] >= 5:
        # import importlib.util # Already imported below
        module = None
        spec = None
        try:
            print(f"  Creating spec for {module_name}...")
            # Ensure importlib.util is imported here if not globally
            import importlib.util
            spec = importlib.util.spec_from_file_location(module_name, file_path)
        except Exception as e:
            print(f"  Error creating spec: {e}")
            return None

        if spec:
            print(f"  Spec found: {spec.name}")
            try:
                print(f"  Creating module from spec...")
                module = importlib.util.module_from_spec(spec)
            except Exception as e:
                print(f"  Error creating module from spec: {e}")
                return None
        else:
            # More specific message when spec is None
            print(f"  Spec not found. Importlib might not recognize the file type or extension for {file_path}")
            return None

        if module:
            print(f"  Module created: {module.__name__}")
            sys.modules[module_name] = module
            try:
                print(f"  Executing module {module_name}...")
                spec.loader.exec_module(module)
                print(f"  Module {module_name} executed successfully.")
                return module
            except Exception as e:
                print(f"  Error executing module {module_name}: {e}")
                # Remove the partially loaded module if execution fails
                if module_name in sys.modules:
                    del sys.modules[module_name]
                return None
        else:
            # This case should ideally be caught earlier
            print(f"  Module could not be created.")
            return None
    else:
        # Fallback to imp if importlib is not available
        print("  Using fallback 'imp' module (Python < 3.5)")
        import imp
        try:
            return imp.load_source(module_name, file_path)
        except Exception as e:
            print(f"  Error loading with imp: {e}")
            return None


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
            ".pyd",
            [
                ".\\",
                "C:\\Users\\videopro\\Desktop",
                "C:\\Program Files\\Blackmagic Design\\DaVinci Resolve\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion 19\\",
                "C:\\Program Files\\Blackmagic Design\\Fusion Render Node 19\\",
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
        print(f"Prepending FUSION_MODULE_PATH: {modpath}")
        paths.insert(0, modpath)
    # print(paths) # Consider uncommenting this to verify paths

    print(f"Searching for {module_name}{ext} in paths:")
    for i, path in enumerate(paths):
        print(f"  {i+1}. {path}")

    for path in paths:
        full_path = os.path.join(path, module_name + ext)
        # Check existence clearly
        if not os.path.exists(full_path):
            # This print is already added by user, keep it for verbosity if desired
            print(f"Module not found at: {full_path}")
            continue

        print(f"\nFound potential module at: {full_path}")
        try:
            # load_module now has internal printing
            module = load_module(module_name, full_path)
            if module:
                print(f"Successfully loaded {module_name} from {full_path}")
                return module
            else:
                # load_module failed, reasons should have been printed internally
                print(f"Failed to load module from {full_path} (see details above).")
        except ImportError as e:
            # This might catch errors from 'imp' or other unexpected import issues
            print(f"ImportError encountered for {full_path}: {e}")
            continue
        except Exception as e:
            # Catch other potential exceptions during loading attempt
            print(f"An unexpected error occurred trying path {full_path}: {e}")
            continue

    print(f"\nFinished searching paths. Module '{module_name}' not loaded.")
    return None


fu_mod = find_and_load_module("fusionscript")

if fu_mod:
    sys.modules[__name__] = fu_mod
    print("Module loaded successfully.")
else:
    raise ImportError("Could not locate module dependencies")
