"""
Jump to stored flow position. Use dropdown menu to switch to stored position
KEY FEATURES:
* Delete single bookmark or all of them
* All bookmarks are alphabetically sorted.
* Add a bookmark from Jump UI
* Refresh bookmarks if some was added while Jump UI is running

KNOWN ISSUES: 
* depending on complexity if the comp, the nodes in a flow
may temporarily disappear after bookmark jump. As a workaround to this issue
added 0.1 sec delay before jump to the tool. Hope it works for you :)
* the script just finds a tool in a flow and makes it active. It does not center it in the flow.
There's two possible workarounds here:
    1) after jumping to the tool, click on the flow, press CTRL(CMD)+F and then hit ENTER (recommended)
    2) use a PipeRouter hackaround (see commented section below)

Alexey Bogomolov mail@abogomolov.com
Requests and issues: https://github.com/movalex/fusion_scripts/issues
Donations are highly appreciated: https://paypal.me/aabogomolov

MIT License: https://mit-license.org/
"""
# legacy python reporting compatibility
from __future__ import print_function
import time
flow = comp.CurrentFrame.FlowView

# close UI on ESC button
comp.Execute('''app:AddConfig("combobox",
{
Target  {ID = "combobox"},
Hotkeys {Target = "combobox",
         Defaults = true,
         ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}" } })
''')


def parse_data(_data):
    # return sorted by bookmark
    strip_data = list(_data.values())
    parsed_data = sorted([list(i.values()) for i in strip_data], key=lambda x: x[0].lower())
    return parsed_data


def prefill_checkbox():
    itm['MyCombo'].Clear()
    message = 'select bookmark'
    if len(data) == 0:
        message = 'add some bookmarks!'
    itm['MyCombo'].AddItem(message)
    itm['MyCombo'].InsertSeparator()


def fill_checkbox(_data):
    prefill_checkbox()
    sorted_bms = [i[0] for i in parse_data(_data)]
    for bkm in sorted_bms:
        itm['MyCombo'].AddItem(bkm)


def clear_all():
    comp.SetData('BM')
    print('all bookmarks gone')


def delete_bookmark(key):
    comp.SetData('BM')
    try:
        del data[key]
        for k, v in data.items():
            comp.SetData('BM.{}'.format(k), v)
    except IndexError:
        pass


def _switch_UI(ev):
    choice = int(itm['MyCombo'].CurrentIndex)
    if choice > 0:
        tool_data = parse_data(data)[choice - 2]
        bm_name, tool_name, scale_factor, _ = tool_data
        print('jump to', tool_name)
        source = comp.FindTool(tool_name)

# uncomment the section below if you need centered bookmark hackaround
# Thanks @Intelligent_Machine for pointing this out:
# https://www.steakunderwater.com/wesuckless/viewtopic.php?p=22068#p22068
# However the result it too unpredictable for different scales
# and produces visible flow movements (it zooms in, creates and then deletes
# two Dots on each side of the tool to try to center it).
# Therefore this option is disabled by default

# --------------------------------------------------------------------------------
        # sx, sy = flow.GetPosTable(source).values()
        # flow.SetScale(4)
        # pr1 = comp.AddTool("PipeRouter", sx - 1, sy - .5)
        # pr2 = comp.AddTool("PipeRouter", sx + 3, sy + .5)
        # comp.SetActiveTool(pr2)
        # comp.SetActiveTool(pr1)
        # flow.Select()
        # pr1.Delete()
        # pr2.Delete()
# --------------------------------------------------------------------------------

        flow.SetScale(scale_factor)
        time.sleep(.1)
        comp.SetActiveTool(source)


def _close_UI(ev):
    disp.ExitLoop()


def _clear_all_UI(ev):
    clear_all()
    itm['MyCombo'].Clear()
    itm['MyCombo'].AddItem('all bookmarks gone')


def _delete_bm_UI(ev):
    try:
        choice = int(itm['MyCombo'].CurrentIndex)
        if choice > 0:
            bm_text, tool_id = parse_data(data)[choice - 2][::3]
            itm['MyCombo'].RemoveItem(choice)
            print('bookmark {} deleted'.format(bm_text))
            delete_bookmark(tool_id)
            if len(data) == 0:
                prefill_checkbox()
    except IndexError:
        print('stop hitting that button!')


def _refresh_UI(ev):
    global data
    check_data = comp.GetData('BM')
    if check_data and check_data != data:
        print('updating bookmarks')
        itm['MyCombo'].Clear()
        data = check_data
        fill_checkbox(data)
    else:
        print('nothing changed')


def _run_add_script(ev):
    comp.RunScript('GIT:/Scripts/Comp/Bookmarker/bookmark_add.py')


if __name__ == '__main__':
    data = comp.GetData('BM')
    if not data:
        data = {}
        print('add some bookmarks!')

    # Main Window
    ui = fusion.UIManager
    disp = bmd.UIDispatcher(ui)
    btn_icon_size = 0
    win = disp.AddWindow(
        {'ID': 'combobox',
         'TargetID': 'combobox',
         'WindowTitle': 'jump to bookmark',
         'Geometry': [200, 450, 300, 80]},
        [
            ui.VGroup(
                [
                    ui.HGroup(
                        [
                            ui.ComboBox({'ID': 'MyCombo',
                                         'Text': 'Choose preset',
                                         # 'Events': {'Activated': True},
                                         'ShowPopup': True,
                                         'Weight': .8}),
                            ui.Button({'ID': 'AddButton',
                                       'Flat': False,
                                       'IconSize': [12, 12],
                                       'MinimumSize': [20, 25],
                                       'Icon': ui.Icon({'File':
                                                        'GIT:Scripts/Comp/Bookmarker/icons/plus_icon.png'}),
                                       'Weight': .1
                                       }),
                            ui.Button({'ID': 'refreshButton',
                                       'Flat': False,
                                       'IconSize': [12, 12],
                                       'MinimumSize': [20, 25],
                                       'Icon': ui.Icon({'File':
                                                        'GIT:Scripts/Comp/Bookmarker/icons/refresh_icon.png',
                                                        }),
                                       'Weight': .1 
                                       }),
                        ]),
                    ui.HGroup(
                        [
                            ui.Button({'ID': 'rm',
                                       'Text': 'delete bookmark',
                                       'Weight': 0.5,
                                       }),
                            ui.Button({'ID': 'rmall',
                                       'Text': 'reset all',
                                       'Weight': 0.5,
                                       }),
                        ])
                ]),
        ])

    itm = win.GetItems()

    win.On.rm.Clicked = _delete_bm_UI
    win.On.rmall.Clicked = _clear_all_UI
    win.On.combobox.Close = _close_UI
    win.On.MyCombo.CurrentIndexChanged = _switch_UI
    win.On.refreshButton.Clicked = _refresh_UI
    win.On.AddButton.Clicked = _run_add_script
    fill_checkbox(data)

    win.Show()
    disp.RunLoop()
    win.Hide()
