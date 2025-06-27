#!/usr/bin/env python

from ui_utils import RequestDir
from pathlib import Path
from log_utils import set_logging

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


def set_stills_folder():
    target_data = fu.GetData("ResolveSaveStills.Folder")
    target_folder = RequestDir(title="Set stills location", target=target_data)
    if not target_folder or target_folder == " ":
        log.debug("Stills folder not set.")
        return
    if not Path(target_folder).exists():
        log.debug(f"Folder {target_folder} does not exist")
        return
    fu.SetData("ResolveSaveStills.Folder", target_folder)
    log.debug(f"Stills export directory is set to {target_folder}")



if __name__ == "__main__":
    set_stills_folder()
