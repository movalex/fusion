"""
Jump to stored flow position
Use dropdown menu to switch to stored position
Delete single bookmark or all of them
All bookmarks are alphabetically sorted.

Alexey Bogomolov mail@abogomolov.com
Donations are highly appreciated: https://paypal.me/aabogomolov
Requests and issues: https://github.com/movalex/fusion_scripts/issues

MIT License: https://mit-license.org/
"""
# legacy python reporting compatibility
from __future__ import print_function

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
    parsed_data = sorted(_data.items(), key=lambda x: x[0].lower())
    return parsed_data[1:]


def fill_checkbox(_data):
    message = 'select bookmark'
    if len(data) < 2:
        message = 'add some bookmarks!'
    itm['MyCombo'].AddItem(message)
    itm['MyCombo'].InsertSeparator()

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
    if choice <= 1:
        pass
    else:
        bm_name, tool_data = parse_data(data)[choice - 2]
        tool_name, scale_factor = tool_data.values()
        print('jump to', tool_name)
        source = comp.FindTool(tool_name)

# uncomment the section below if you need centered bookmark hackaround
# Thanks @Intelligent_Machine for that:
# https://www.steakunderwater.com/wesuckless/viewtopic.php?p=22068#p22068
# However the result it too unpredictable for different scales
# and produces visible flow movements (it creates and then deletes two Dots
# on each size of the tool to try to center it).
# Also it causes tools to temporarily disappear from the flow.
# Therefore disabled by default

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
        comp.SetActiveTool(source)


def _close_UI(ev):
    disp.ExitLoop()


def _clear_all_UI(ev):
    clear_all()
    itm['MyCombo'].Clear()
    itm['MyCombo'].AddItem('all bookmarks gone')


def _clear_UI(ev):
    try:
        choice = int(itm['MyCombo'].CurrentIndex)
        bm_text = parse_data(data)[choice - 2][0]
        itm['MyCombo'].RemoveItem(choice)
        print('bookmark {} deleted'.format(bm_text))
        delete_bookmark(bm_text)
    except IndexError:
        print('stop hitting that button!')


def _refresh_UI(ev):
    global data
    check_data = comp.GetData('BM')
    if check_data and len(check_data) > len(data):
        print('updating bms')
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
                                         'Weight': .9}),
                            ui.Button({'ID': 'AddButton',
                                       'Flat': False,
                                       'IconSize': [12, 12],
                                       'MinimumSize': [20, 25],
                                       'Icon': ui.Icon({'File':
                                                        'GIT:Scripts/Comp/Bookmarker/plus_icon.png'}),
                                       'Weight': .05
                                       }),
                            ui.Button({'ID': 'refreshButton',
                                       'Flat': False,
                                       'IconSize': [12, 12],
                                       'MinimumSize': [20, 25],
                                       'Icon': ui.Icon({'File':
                                                        'GIT:Scripts/Comp/Bookmarker/refresh_icon.png',
                                                        }),
                                       'Weight': .05
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

    win.On.rm.Clicked = _clear_UI
    win.On.rmall.Clicked = _clear_all_UI
    win.On.combobox.Close = _close_UI
    win.On.MyCombo.CurrentIndexChanged = _switch_UI
    win.On.refreshButton.Clicked = _refresh_UI
    win.On.AddButton.Clicked = _run_add_script
    fill_checkbox(data)

    win.Show()
    disp.RunLoop()
    win.Hide()
