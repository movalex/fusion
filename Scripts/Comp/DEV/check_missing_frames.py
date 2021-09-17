# Author: Alexey Bogomolov
# email: mail@abogomolov.com
# donate: https://www.paypal.com/paypalme/aabogomolov/
# MIT License -- https://opensource.org/licenses/MIT
#
# Version history:
# 09/17/2021
#     v1.0 -- Initial commit
#     v1.1 -- bug fixing, add frames number concatenation


import re
import mimetypes
from pathlib import Path

comp = fu.GetCurrentComp()
VERSION = 1.1
GLOBAL_START = comp.GetAttrs()["COMPN_GlobalStart"]
GLOBAL_END = comp.GetAttrs()["COMPN_GlobalEnd"]
RENDER_END = comp.GetAttrs()["COMPN_RenderEnd"]

# if RENDER_END < GLOBAL_END:
#     GLOBAL_END = RENDER_END


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
        sequence_length = len(seq)
        if sequence_length < clip_length:
            print(f"{path}: File length mismatch found!\nMissing frames:")
            frames_found = get_frame_nums(seq, seq_pattern)
            # padding = len(seq_pattern.search(file_path).group(1))
            missing_frames = [i for i in range(int(GLOBAL_START), int(GLOBAL_END)) if i not in frames_found]
            print("-" * 18)
            print(get_line_numbers_concat(missing_frames))
            print("-" * 18)


if __name__ == "__main__":
    print(f"Check Missing Frames script. Version {VERSION}\nCopyright 2021 Alexey Bogomolov. MIT License")
    scan_all_loaders()
    print("Done!")
