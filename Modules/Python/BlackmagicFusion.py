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
from pathlib import Path
import logging


LOG_LEVEL = logging.INFO
# Supported Fusion versions in descending order (newest first)
SUPPORTED_FUSION_VERSIONS = [20, 19, 18]

if not logging.getLogger().hasHandlers():
    logging.basicConfig(
        level=LOG_LEVEL,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
else:
    for handler in logging.getLogger().handlers:
        handler.setLevel(LOG_LEVEL)
        handler.setFormatter(logging.Formatter(
            "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        ))

logger = logging.getLogger("BlackmagicFusion")


def load_dynamic(module_name, file_path):
    if sys.version_info[0] >= 3 and sys.version_info[1] >= 8:
        import importlib.machinery
        import importlib.util

        module = None
        spec = None
        loader = importlib.machinery.ExtensionFileLoader(module_name, file_path)
        if loader:
            spec = importlib.util.spec_from_loader(module_name, loader)
        if spec:
            module = importlib.util.module_from_spec(spec)
        if module:
            loader.exec_module(module)
        return module
    else:
        print(f"Failed to load module {module_name} due to unsupported Python version: {sys.version_info}")
        return None


def get_fusion_platform_paths(versions=SUPPORTED_FUSION_VERSIONS):
    platform_templates = {
        "darwin": {
            "extension": ".so",
            "fusion_template": "/Applications/Blackmagic Fusion {version}/Fusion.app/Contents/MacOS/",
            "render_node_template": "/Applications/Blackmagic Fusion {version} Render Node/Fusion.app/Contents/MacOS/",
        },
        "win32": {
            "extension": ".dll",
            "fusion_template": "C:\\Program Files\\Blackmagic Design\\Fusion {version}\\",
            "render_node_template": "C:\\Program Files\\Blackmagic Design\\Fusion Render Node {version}\\",
        },
        "linux": {
            "extension": ".so",
            "fusion_template": "/opt/BlackmagicDesign/Fusion{version}/",
            "render_node_template": "/opt/BlackmagicDesign/FusionRenderNode{version}/",
        },
    }
    
    platform_config = platform_templates.get(sys.platform)
    logger.debug(f"Detected platform: {sys.platform}")
    if not platform_config:
        logger.error("Fusion paths not found for your platform. Please ensure that the module fuscript is discoverable by Python")
        return ("", [])
    
    paths = []
    for version in versions:
        fusion_path = platform_config["fusion_template"].replace("{version}", str(version))
        render_node_path = platform_config["render_node_template"].replace("{version}", str(version))
        logger.debug(f"Adding Fusion path: {fusion_path}")
        logger.debug(f"Adding Render Node path: {render_node_path}")
        paths.append(fusion_path)
        paths.append(render_node_path)
    logger.debug(f"Extension: {platform_config['extension']}, Paths: {paths}")
    return (platform_config["extension"], paths)


def find_fusion_studio_module(module_name):
    ext, paths = get_fusion_platform_paths()
    logger.debug(f"Looking for module '{module_name}' with extension '{ext}' in paths: {paths}")

    # Optionally prepend a custom path from an environment variable
    modpath = os.getenv("FUSION_MODULE_PATH")
    if modpath:
        logger.debug(f"Prepending custom FUSION_MODULE_PATH: {modpath}")
        paths.insert(0, modpath)

    for path in paths:
        module_path = Path(path, module_name + ext)
        logger.debug(f"Checking path: {module_path}")
        if module_path.exists():
            logger.debug(f"Found module at: {module_path}")
            return module_path

    logger.warning(f"Module '{module_name}' not found in any known paths.")
    return None


module_name = "fusionscript"
full_module_path = find_fusion_studio_module(module_name)
module = load_dynamic(module_name, str(full_module_path))


if module:
    sys.modules[__name__] = module
    logger.info("Module loaded successfully.")
else:
    logger.critical("Could not locate module dependencies")
    raise ImportError("Could not locate module dependencies")
