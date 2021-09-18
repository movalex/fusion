# Author: Alexey Bogomolov
# email: mail@abogomolov.com
# donate: https://www.paypal.com/paypalme/aabogomolov/
# MIT License -- https://opensource.org/licenses/MIT
#
# Version history:
# 09/17/2021
#   v1.0 -- Initial commit
#   v1.1 -- bug fixing, add frames number concatenation
#   v1.2 -- use file range instead of comp range
#   v1.3 -- work correctly with multiple sequences in the same folder


import re
import mimetypes
from pathlib import Path

comp = fu.GetCurrentComp()
VERSION = 1.3


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
    if Path(file_name).suffix.lower() in exts:
        return True


def get_frame_nums(seq, pattern):
    frame_nums = []
    for clip in sorted(seq):
        frame_num = pattern.search(str(clip))
        frame_nums.append(int(frame_num.group(1)))
    return frame_nums


def get_line_numbers_concat(line_nums):
    seq = []
    final = []
    last = 0

    for index, val in enumerate(line_nums):
        if last + 1 == val or index == 0:
            seq.append(val)
            last = val
        else:
            if len(seq) > 1:
                final.append(str(seq[0]) + '..' + str(seq[len(seq) - 1]))
            else:
                final.append(str(seq[0]))
            seq = []
            seq.append(val)
            last = val

        if index == len(line_nums) - 1:
            if len(seq) > 1:
                final.append(str(seq[0]) + '..' + str(seq[len(seq) - 1]))
            else:
                final.append(str(seq[0]))
    final_str = ', '.join(final)
    return final_str


def scan_all_loaders():
    for tool in comp.GetToolList(False, "Loader").values():
        file_path = comp.MapPath(tool.Clip[fu.TIME_UNDEFINED])
        if is_movie_format(file_path):
            # print(f"{file_path} is not a sequence format")
            continue
        clip_attrs = tool.GetAttrs()
        start_frame = int(clip_attrs["TOOLIT_Clip_StartFrame"][1])
        clip_length = int(clip_attrs["TOOLIT_Clip_Length"][1])
        if clip_length < 2:
            if tool.Loop[fu.TIME_UNDEFINED]:
                print(f"{file_path} is a single frame Loader. Skipping")
            else:
                print(f"{file_path} has single frame an not set to loop. Skipping")
            continue
        path = Path(file_path)
        ext = path.suffix
        parent_dir = path.parent
        stem = re.sub("\d+$", "", path.stem)
        seq = list(parent_dir.glob(f"*{stem}*{ext}"))
        seq_pattern = re.compile(r"(\d{3,})" + ext + "$", re.IGNORECASE)
        sequence_length = len(seq)
        if sequence_length < clip_length:
            print(f"{path}: File length mismatch found!\nMissing frames:")
            frames_found = get_frame_nums(seq, seq_pattern)
            missing_frames = [i for i in range(start_frame, start_frame + clip_length) if i not in frames_found]
            print("-" * 18)
            print(get_line_numbers_concat(missing_frames))
            print("-" * 18)


if __name__ == "__main__":
    print(f"Check Missing Frames script. Version {VERSION}\nCopyright 2021 Alexey Bogomolov. MIT License")
    try:
        scan_all_loaders()
    except AttributeError:
        print("no loaders found")
    print("Done!")
