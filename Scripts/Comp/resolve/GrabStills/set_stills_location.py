#!/usr/bin/env python

from pathlib import Path
import sys

# Ensure shared Modules/Python is on sys.path before importing utilities
def _bootstrap_modules_path():
    candidates = []
    try:
        here = Path(__file__).resolve()
    except Exception:
        here = Path.cwd()
    # Walk upwards to locate Modules/Python in the repo
    for parent in [here.parent] + list(here.parents):
        mod_path = parent / "Modules" / "Python"
        if mod_path.exists():
            candidates.append(mod_path)
            break
    # Fallback to user absolute path
    candidates.append(Path(r"C:\Users\alexey.bogomolov\Documents\git\fusion\Modules\Python"))

    for p in candidates:
        try:
            if p and p.exists():
                sp = str(p)
                if sp not in sys.path:
                    sys.path.insert(0, sp)
                break
        except Exception:
            continue

_bootstrap_modules_path()

from ui_utils import RequestDir, get_fusion_module
from log_utils import set_logging
from bmd_utils import get_resolve_fusion

"""
    This is a Davinci Resolve script to set stills saving location
    for grab_still and create_stills_from_timeline scripts.

    LICENSE:
    Copyright © 2022 Alexey Bogomolov (mail@abogomolov.com)
    
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
log = set_logging(script_name="Set Stills Location")

# Try to obtain Fusion instance (fu) via Resolve first, then fallbacks
try:
    fu = get_resolve_fusion()
except Exception:
    fu = None
    try:
        _bmd, _fusion = get_fusion_module()
        fu = _fusion
    except Exception:
        fu = globals().get("fusion")  # last resort: global injected by Resolve

def set_stills_folder():
    print("Opening Set Stills Location dialog...")
    if not fu:
        print("Fusion instance not available. Cannot read/write Resolve data.")
        # You can still choose a folder, but it won't be saved to Resolve data keys
        target_folder = RequestDir(title="Set stills location", target=None)
        if target_folder:
            print(f"Chosen folder (not saved): {target_folder}")
        return
    # Read either new or legacy key for compatibility
    target_data = fu.GetData("BatchResolveSaveStills.Folder") or fu.GetData("ResolveSaveStills.Folder")
    target_folder = RequestDir(title="Set stills location", target=target_data)
    if not target_folder or target_folder == " ":
        print("Stills folder not set.")
        return
    if not Path(target_folder).exists():
        print(f"Folder {target_folder} does not exist")
        return
    # Persist to both keys to keep scripts in sync
    fu.SetData("BatchResolveSaveStills.Folder", target_folder)
    fu.SetData("ResolveSaveStills.Folder", target_folder)
    print(f"Stills export directory is set to: {target_folder}")



def _run():
    try:
        set_stills_folder()
    except Exception as e:
        print(f"Failed to set stills location: {e}")


# Auto-run inside Resolve (fu available), with fallback to direct execution
try:
    if fu:
        _run()
except Exception:
    if __name__ == "__main__":
        _run()
