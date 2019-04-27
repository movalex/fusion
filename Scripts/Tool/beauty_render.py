# tool script to create Saver from loader
# and put copy of existing comp to specified directory

import os
import re
import sys
import time
from pathlib import Path


def increment(path, name):
    list_directory = os.listdir(path)
    match_str = '^' + name + '_FX(\d{3}).*$'
    rc = re.compile(match_str)
    matches = [rc.match(i) for i in list_directory]
    incremental = {int(match.group(1)) + 1 for match in matches if match}
    if not incremental:
        return '001'
    return '{:03}'.format(max(incremental))


def get_name(tool):
    name = tool.GetAttrs()['TOOLST_Clip_Name'][1]
    file_name = Path(name).name
    split_name = os.path.splitext(file_name)
    return split_name


def copy_comp(tool):
    c = tool.GetOutputList()[1]
    if c.GetConnectedInputs():
        comp.RunScript('Scripts:Tool/sel_forward.py')
        time.sleep(1)

    tools = comp.GetToolList(True)
    comp.Copy(tools)
    fu.NewComp()
    newcomp = fu.GetCurrentComp()
    newcomp.Paste()
    return newcomp


def add_saver(cmp, prefix=None):

    print("--------- save comp -----------")
    folder = Path('~/Desktop/beauty').expanduser()
    if not folder.exists():
        Path.mkdir(folder, parents=True)
    split_name = get_name(tool)
    fname, ext = split_name
    comp_name = fname + '.comp'
    target = Path(folder, comp_name)
    cmp.Save(str(target))

    print("--------- add saver  -----------")
    cmp.Lock()
    # add saver
    saver = cmp.Saver
    print(folder)
    save_path = Path(folder, 'renders')
    Path.mkdir(save_path, parents=True, exist_ok=True)
    # increment file number if exists
    inc = increment(save_path, fname)
    file_name = f'{fname}_{prefix}{inc}_0000{ext}'
    # set saver filename
    saver.Clip = str(Path(save_path, file_name))
    # place saver next to loader
    active = cmp.ActiveTool
    flow = cmp.CurrentFrame.FlowView
    pos_x, pos_y = flow.GetPosTable(active).values()
    flow.SetPos(saver, pos_x + 1, pos_y)
    # connect saver to loader
    saver.Input.ConnectTo(active)
    cmp.Unlock()


def main():
    if tool.ID != 'Loader':
        print('use with loader tool only')
    elif len(comp.GetToolList(True)) > 1:
        print('select single Loader!\n')
    else:
        cmp = copy_comp(tool)
        add_saver(cmp, 'FX')

if __name__ == '__main__':
    main()

