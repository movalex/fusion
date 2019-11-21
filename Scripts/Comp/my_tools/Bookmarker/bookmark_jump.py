"""
Jump to stored flow position. Use dropdown menu to switch to stored position
KEY FEATURES:
* Delete single bookmark or all of them
* All bookmarks are alphabetically sorted.
* Add a bookmark from Jump UI
* Refresh bookmarks if some was added while Jump UI is running
* If you already jumped to the tool, then moved the flow, you can jump back to the same bookmark again
* You can move single tool to the bookmark position. Just make sure one tool is selected (not active) before jump

KNOWN ISSUES:
* depending on complexity if the comp, the nodes in a flow
may temporarily disappear after bookmark jump. As a workaround to this issue
added 0.2 sec delay before jump to the tool. Hope it works for you
* the script just finds a tool in a flow and makes it active. It does not center it in the flow.
Possible workaround here:
* jump to the tool, click on the flow, press CTRL/CMD+F and then hit ENTER

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
         ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}" }})
''')


def parse_data(_data):
    # return sorted by bookmark
    strip_data = list(_data.values())
    parsed_data = sorted(
        [list(i.values()) for i in strip_data],
        key=lambda x: x[0].lower())
    return parsed_data


def prefill_checkbox():
    itm['MyCombo'].Clear()
    message = 'select bookmark'
    if not data:
        message = 'add some bookmarks!'
    itm['MyCombo'].AddItem(message)
    itm['MyCombo'].InsertSeparator()


def fill_checkbox(_data):
    prefill_checkbox()
    if _data:
        sorted_bms = [i[0] for i in parse_data(_data)]
        for bkm in sorted_bms:
            itm['MyCombo'].AddItem(bkm)


def delete_bookmark(key):
    comp.SetData('BM')
    del data[key]
    for k, v in data.items():
        comp.SetData('BM.{}'.format(k), v)


def _switch_UI(ev):
    choice = int(itm['MyCombo'].CurrentIndex)
    if choice > 1 and data:
        tool_data = parse_data(data)[choice - 2]
        bm_name, tool_name, scale_factor, _ = tool_data
        # print('jump to', tool_name)
        target = comp.FindTool(tool_name)
        active = comp.ActiveTool
        if target.GetAttrs('TOOLB_Selected'):
            # print('tool already selected, now jumping back')
            flow.Select()
        if active:
            flow.Select()
        current_tool = list(comp.GetToolList(True).values())
        flow.SetScale(scale_factor)
        time.sleep(.2)
        comp.SetActiveTool(target)
        if current_tool and len(current_tool) == 1:
            comp.StartUndo('Move tool to BM')
            pos_targetx, pos_targety = flow.GetPosTable(target).values()
            flow.SetPos(current_tool[0], pos_targetx + 1, pos_targety)
            comp.EndUndo()


def _close_UI(ev):
    disp.ExitLoop()


def _clear_all_UI(ev):
    comp.SetData('BM')
    print('all your bookmarks are belong to us')
    itm['MyCombo'].Clear()
    itm['MyCombo'].AddItem('add some bookmarks!')


def _delete_bm_UI(ev):
    choice = int(itm['MyCombo'].CurrentIndex)
    if choice > 0:
        bm_text, tool_id = parse_data(data)[choice - 2][::3]
        itm['MyCombo'].RemoveItem(choice)
        print('bookmark {} deleted'.format(bm_text))
        delete_bookmark(tool_id)
        if len(data) == 0:
            prefill_checkbox()
            print('no bookmarks left')


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
    comp.RunScript('Scripts:Comp/Bookmarker/bookmark_add.py')


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
         'Geometry': [200, 450, 300, 75]},
        [
            ui.VGroup(
                [
                    ui.HGroup(
                        [
                            ui.ComboBox({'ID': 'MyCombo',
                                         'Text': 'Choose preset',
                                         'Events': {'Activated': True},
                                         'Weight': .8}),
                            ui.Button({'ID': 'AddButton',
                                       'Flat': False,
                                       'IconSize': [12, 12],
                                       'MinimumSize': [20, 25],
                                       'Icon': ui.Icon({'File':
                                                        'Scripts:Comp/Bookmarker/icons/plus_icon.png'}),
                                       'Weight': .1
                                       }),
                            ui.Button({'ID': 'refreshButton',
                                       'Flat': False,
                                       'IconSize': [12, 12],
                                       'MinimumSize': [20, 25],
                                       'Icon': ui.Icon({'File':
                                                        'Scripts:Comp/Bookmarker/icons/refresh_icon.png',
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

    win.On.MyCombo.Activated = _switch_UI
    win.On.rm.Clicked = _delete_bm_UI
    win.On.rmall.Clicked = _clear_all_UI
    win.On.combobox.Close = _close_UI
    win.On.refreshButton.Clicked = _refresh_UI
    win.On.AddButton.Clicked = _run_add_script
    fill_checkbox(data)

    win.Show()
    disp.RunLoop()
    win.Hide()

