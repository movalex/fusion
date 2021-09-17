# Author: Alexey Bogomolov
# email: mail@abogomolov.com
# donate: https://www.paypal.com/paypalme/aabogomolov/
# version: 1.0
#
# Version history:
# v.01 -- 17/09/2021 -- Initial commit
import os
import re
import mimetypes
from pathlib import Path
from pprint import pprint as pp


comp = fu.GetCurrentComp()


def is_movie_format(file_name):
    file_type = mimetypes.guess_type(file_name)
    if file_type[0]:
        return file_type[0].startswith("video")
    exts = (
        ".avi",
        ".dv",
        ".dvx",
        ".h264",
        ".m2ts",
        ".m2v",
        ".m4v",
        ".mkv",
        ".mov",
        ".movie",
        ".mp4",
        ".mp4v",
        ".mpeg",
        ".mpg",
        ".mpg2",
        ".mts",
        ".mtv",
        ".mxf",
        ".qt",
        ".ts",
        ".vid",
        ".xvid",
    )
    if Path(file_name).suffix in exts:
        return True


def get_frame_nums(seq, pattern):
    frame_nums = []
    for clip in sorted(seq):
        frame_num = pattern.search(str(clip))
        frame_nums.append(int(frame_num.group(1)))
    return frame_nums


def scan_all_loaders():
    for tool in comp.GetToolList(False, "Loader").values():
        file_path = comp.MapPath(tool.Clip[fu.TIME_UNDEFINED])
        if is_movie_format(file_path):
            print(f"{file_path} is not a sequence format")
            continue
        clip_attrs = tool.GetAttrs()
        clip_length = clip_attrs["TOOLIT_Clip_Length"][1]
        if clip_length < 2:
            if tool.Loop[fu.TIME_UNDEFINED]:
                print(f"{file_path} is a single frame Loader. Skipping")
            else:
                print(f"{file_path} has single frame an not set to loop. Skipping")
            continue
        path = Path(file_path)
        ext = path.suffix
        parent_dir = path.parent
        seq = list(parent_dir.glob(f"*{ext}"))
        seq_pattern = re.compile(r"(\d{3,})" + ext + "$", re.IGNORECASE)
        print(f"pattern: {seq_pattern.findall(file_path)}")
        sequence_length = len(seq)
        print(sequence_length)
        if sequence_length < clip_length:
            print("File length mismatch found! Checking missing frames.")
            frames_found = get_frame_nums(seq, seq_pattern)
            padding = len(seq_pattern.search(file_path).group(1))
            missing_frames = [str(i).zfill(padding) for i in range(clip_length) if i not in frames_found]
            print(", ".join(missing_frames))


if __name__ == "__main__":
    print("Check missing frames script. Version 1.0 by Alexey Bogomolov")
    scan_all_loaders()
