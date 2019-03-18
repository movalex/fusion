# tool script for fast save
import os
import re
from pathlib import Path


def check_loader():
    if tool.ID != 'Loader':
        print('use with loader tool only')
        return 0
    return get_name(tool)


def increment(path, name):
    list_directory = os.listdir(path)
    match_str = '^' + name + '_FX(\d{3}).*$'
    rc = re.compile(match_str)
    matches = [rc.match(i) for i in list_directory]
    incremental = {int(match.group(1)) + 1 for match in matches if match}
    if not incremental:
        return '001'
    return '{:03}'.format(max(incremental))


def save_comp(comp_name, split_name, prefix='FX'):
    folder = Path('~/Desktop/beauty/').expanduser()
    if not folder.exists():
        folder.mkdir(parents=True)
    target = Path(folder, comp_name)
    comp.Save(str(target))
    comp.Lock()
    saver = comp.Saver
    save_path = Path(
        folder,
        'save_beauty')
    if not save_path.exists():
        save_path.mkdir(parents=True)
    inc = increment(save_path, split_name[0])
    file_name = '{}_{}{}_0000{}'.format(split_name[0], prefix, inc, split_name[1])
    save_path = Path(save_path, file_name)
    saver.Clip = str(save_path)
    flow = comp.CurrentFrame.FlowView
    pos_x, pos_y = flow.GetPosTable(tool).values()
    flow.SetPos(saver, pos_x + 1, pos_y)
    saver.Input.ConnectTo(tool.Output)
    comp.Unlock()


def get_name(tool):
    name = tool.GetAttrs()['TOOLST_Clip_Name'][1]
    file_name = Path(name).name
    split_name = os.path.splitext(file_name)
    comp_name = split_name[0] + '.comp'
    save_comp(comp_name, split_name)


check_loader()

