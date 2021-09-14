import sys
import os
import re


def main(file_name):
    with open(file_name) as f:
        frames = []
        for line in f.readlines():
            if "macbook" in line:
                frame = re.search("completed frame (\d+)", line)
                try:
                    frames.append(frame.group(1))
                except AttributeError:
                    pass
    return frames


if __name__ == "__main__":
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
        name = os.path.expanduser(file_path)
        frames_list = main(name)
        print(", ".join(frames_list))
