# Author: Alexey Bogomolov
# email: mail@abogomolov.com
# donate: https://www.paypal.com/paypalme/aabogomolov/
# MIT License -- https://opensource.org/licenses/MIT
#
# Version history from 09/17/2021:
#   v1.0 -- Initial commit
#   v1.1 -- bug fixing, add frames number concatenation
#   v1.2 -- use file range instead of comp range
#   v1.3 -- work correctly with multiple sequences in the same folder
#   v1.4 -- process selected loader, refactoring


import re
import mimetypes
from pathlib import Path

comp = fu.GetCurrentComp()
VERSION = 1.4


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

def scan_for_missing_frames(tool):
    file_path = comp.MapPath(tool.Clip[fu.TIME_UNDEFINED])
    print(file_path)
    if not tool.ID == "Loader":
        print("Not a loader")
        return
    if not file_path or is_movie_format(file_path):
        print(f"File path is not found in {tool.Name} or {loader.Name} is not a sequence format")
        return
    clip_attrs = tool.GetAttrs()
    try:
        start_frame = int(clip_attrs["TOOLIT_Clip_StartFrame"][1])
        clip_length = int(clip_attrs["TOOLIT_Clip_Length"][1])
    except KeyError:
        print(f"skipping Loader [{tool.Name}] with missing clip attributes")
        return
    if clip_length < 2:
        if loader.Loop[fu.TIME_UNDEFINED]:
            print(f"{file_path} is a single frame Loader. Skipping")
        else:
            print(f"{file_path} has single frame an not set to loop. Skipping")
        return
    print(f"Clip Length: {clip_length}")
    path = Path(file_path)
    ext = path.suffix
    print(f"Extension: {ext}")
    parent_dir = path.parent
    print(f"Parent Folder: {parent_dir}")
    stem = re.sub("\d+$", "", path.stem)
    print(f"Path Stem: {path.stem}")
    print(f"File Stem: {stem}")
    # Use pathlib's glob to find files in the directory
    all_files = parent_dir.glob('*')

    pattern = re.compile(f'{stem}\d+{ext}$')
    target_sequence = [str(f) for f in all_files if pattern.match(f.name)]
    # Filter files matching the pattern
    seq_pattern = re.compile(r"(\d{3,})" + ext + "$", re.IGNORECASE)
    sequence_length = len(target_sequence)
    print(f"SEQ Length: {sequence_length}")
    if sequence_length < clip_length:
        # print(f"{path}: \nMissing frames:")
        frames_found = get_frame_nums(target_sequence, seq_pattern)
        missing_frames = [i for i in range(start_frame, start_frame + clip_length) if i not in frames_found]
        print("-" * 18)
        print(get_line_numbers_concat(missing_frames))
        even_numbers = [i for i in missing_frames if i % 2 == 0]
        print("-" * 18)
        print(f"Found missing even frames: {even_numbers}")
        return True


def scan_all_loaders():
    missing_counter = 0
    loaders = comp.GetToolList(False, "Loader")
    if not loaders:
        print("No loaders found")
        return
    total = len(loaders)
    if total == 0:
        print("No loaders found in the comp")
        return

    for loader in loaders.values():
        counter = scan_for_missing_frames(loader)
        if counter:
            missing_counter += 1


    print(f"found {missing_counter} loaders with missing frames")



if __name__ == "__main__":
    print(f"Check Missing Frames script. Version {VERSION}\nCopyright 2021 Alexey Bogomolov. MIT License")
    active_tool = comp.ActiveTool
    if active_tool:
        scan_for_missing_frames(active_tool)
    else:
        scan_all_loaders()
    print("Done!")
