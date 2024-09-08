import os
import re
import sys
import time
from pathlib import Path


def increment(path: Path, name: str) -> str:
    """Generates a unique incrementing filename suffix."""
    match_str = re.compile(f'^{re.escape(name)}_FX(\\d{{3}}).*$')
    matches = [match for match in path.iterdir() if match_str.match(match.name)]
    if not matches:
        return '001'
    
    increments = [int(match_str.match(match.name).group(1)) for match in matches]
    return f'{max(increments) + 1:03}'


def get_name(tool) -> tuple[str, str]:
    """Extracts the filename and extension from the tool."""
    name = tool.GetAttrs().get('TOOLST_Clip_Name', [None, None])[1]
    if not name:
        raise ValueError("Tool does not have a valid name attribute.")
    return os.path.splitext(Path(name).name)


def copy_comp(tool):
    """Copies the current composition and creates a new one."""
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
    """Adds a saver to the composition and connects it to the loader."""
    folder = Path('~/Desktop/beauty').expanduser()
    folder.mkdir(parents=True, exist_ok=True)
    
    fname, ext = get_name(tool)
    comp_name = f'{fname}.comp'
    target = folder / comp_name
    cmp.Save(str(target))
    
    # Add saver tool
    cmp.Lock()
    saver = cmp.Saver
    save_path = folder / 'renders'
    save_path.mkdir(parents=True, exist_ok=True)

    # Increment file name if exists
    inc = increment(save_path, fname)
    file_name = f'{fname}_{prefix}{inc}_0000{ext}'
    saver.Clip = str(save_path / file_name)

    # Place saver next to loader
    active = cmp.ActiveTool
    flow = cmp.CurrentFrame.FlowView
    pos_x, pos_y = flow.GetPosTable(active).values()
    flow.SetPos(saver, pos_x + 1, pos_y)

    # Connect saver to loader
    saver.Input.ConnectTo(active)
    cmp.Unlock()


def main():
    if tool.ID != 'Loader':
        print('Error: This script should be used with a Loader tool only.')
        return
    
    selected_tools = comp.GetToolList(True)
    if len(selected_tools) != 1:
        print('Error: Select a single Loader tool.')
        return
    
    cmp = copy_comp(tool)
    add_saver(cmp, 'FX')


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)
