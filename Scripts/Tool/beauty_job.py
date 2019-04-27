# tool script for fast save
import os
import re
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

def create_folder(*file_path):
    folder = Path.mkdir(*file_path).mkdir(parents=True, exist_ok=True)
    return folder

def save_comp(tool, prefix=None):
    folder = create_folder('~/Desktop/beauty').expanduser()
    print(folder)
    split_name = get_name(tool)
    fname, ext = split_name
    comp_name = fname + '.comp'
    target = Path(folder, comp_name)
    comp.Save(str(target))

    print("--------- processing -----------")
    comp.Lock()
    # add saver
    saver = comp.Saver
    save_path = create_folder(folder, 'renders')
    # increment file numver if exists
    inc = increment(save_path, fname)
    file_name = f'{fname}_{prefix}{inc}_0000{ext}'
    # set saver filename
    saver.Clip = str(save_path) + file_name
    # place saver next to loader
    flow = comp.CurrentFrame.FlowView
    pos_x, pos_y = flow.GetPosTable(tool).values()
    flow.SetPos(saver, pos_x + 1, pos_y)
    # connect saver to loader
    saver.Input.ConnectTo(tool.Output)
    comp.Unlock()


def check_loader():
    if tool.ID != 'Loader':
        print('use with loader tool only')
        return 0
    return save_comp(tool, 'FX')


check_loader()

