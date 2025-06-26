#!/usr/bin/env python
"""WIP, seems does not work"""

import time
from ui_utils import ConfirmationDialog
from resolve_utils import ResolveUtility

utils = ResolveUtility()

def process_clips():
    """Main function to process all clips in the timeline."""
    clips = utils.get_clips_in_timeline("Video", 4)
    if not clips:
        return
    
    answer = ConfirmationDialog("Switch ages", "Do you want to proceed?")
    if answer:
        for n, clip in enumerate(clips[1:10]):
            print(f"Processing clip {n}")
            clip.ImportFusionComp(r"D:\YandexDisk\Шансон ТВ (общая)\БОГОМОЛОВ Алексей\LOGO\age\fusion\age.comp")
            time.sleep(1)


if __name__ == "__main__":
    process_clips()
