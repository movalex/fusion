# Loader and Saver versioning script
# Copyright: Alexey Bogomolov
# contact: mail@abogomolov.com
# License: MIT
# version: 1.0


import re


def version_down(tool):
    comp.Lock()

    old_global_in = tool.GlobalIn[fu.TIME_UNDEFINED]
    old_global_out = tool.GlobalOut[fu.TIME_UNDEFINED]
    old_clip_start = tool.ClipTimeStart[fu.TIME_UNDEFINED]
    old_clip_end = tool.ClipTimeEnd[fu.TIME_UNDEFINED]
    old_last_frame = tool.HoldLastFrame[fu.TIME_UNDEFINED]

    comp.StartUndo("Version Down")
    output_old = tool.Clip[1]

    if output_old == "":
        print("No filename specified in saver")
        return

    pattern = re.compile(r"([Vv])(\d{2,})")

    try:
        v_letter, number = re.search(pattern, output_old).groups()
    except AttributeError:
        print("No version pattern found.")
        return
    
    start_count = int(number)
    if start_count <= 1:
        return

    version_new_number = str(start_count - 1).zfill(len(number))
    new_path = re.sub(pattern, "{}{}".format(v_letter, version_new_number), output_old)
    tool.Clip[1] = new_path

    tool.GlobalIn[fu.TIME_UNDEFINED] = old_global_in
    tool.GlobalOut[fu.TIME_UNDEFINED] = old_global_out
    tool.ClipTimeStart[fu.TIME_UNDEFINED] = old_clip_start
    tool.ClipTimeEnd[fu.TIME_UNDEFINED] = old_clip_end
    tool.HoldLastFrame[fu.TIME_UNDEFINED] = old_last_frame

    print("[{}] new output: [{}]".format(tool.Name, new_path))
    comp.EndUndo()
    comp.Unlock()


if __name__ == "__main__":
    comp = fu.GetCurrentComp()
    for tool in comp.GetToolList(False, "Loader").values():
       version_down(tool)
