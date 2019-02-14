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
Target {ID = "combobox"},
Hotkeys {
        Target = "combobox",
        Defaults = true,
        ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}"
        }
})''')


def parse_data():
    # return sorted by bm
    parsed_data = sorted(data.items(), key = lambda x: x[0].lower())
    return parsed_data[1:]


def fill_checkbox(data):
    message = 'select bookmark'
    if len(data) < 2:
        message = 'add some bookmarks!'
    itm['MyCombo'].AddItem(message)
    itm['MyCombo'].InsertSeparator()
    sorted_bms = [i[0] for i in parse_data()]
    for bm in sorted_bms:
        itm['MyCombo'].AddItem(bm)


def clear_all():
    comp.SetData('BM_test')
    print('all bookmarks gone')


def delete_bookmark(key):
    comp.SetData('BM_test')
    try:
        del data[key]
        for k, v in data.items():
            comp.SetData('BM_test.{}'.format(k), v)
    except IndexError:
        pass


def _switch_UI(ev):
    choice = int(itm['MyCombo'].CurrentIndex)
    if choice <= 1:
        pass
    else:
        bm_name, tool_data = parse_data()[choice - 2]
        tool_name, scale_factor = tool_data.values()
        print('jump to', tool_name)
        source = comp.FindTool(tool_name)

#uncomment the section below to get kind of centered bookmark:
#--------------------------------------------------------------------------------
        # sx, sy = flow.GetPosTable(source).values()
        # prRelPosX = round(8 / scale_factor)
        # prRelPosY = round(6 / scale_factor)
        # pr1 = comp.AddTool("PipeRouter", sx - prRelPosX, sy - prRelPosY)
        # pr2 = comp.AddTool("PipeRouter", sx + prRelPosX + 1, sy + prRelPosY + 2)
        # comp.SetActiveTool(pr2)
        # comp.SetActiveTool(pr1)
        # flow.Select()
        # pr1.Delete()
        # pr2.Delete()
#--------------------------------------------------------------------------------

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
        bm_text = parse_data()[choice - 2][0]
        itm['MyCombo'].RemoveItem(choice)
        print('bookmark {} deleted'.format(bm_text))
        delete_bookmark(bm_text)
    except IndexError:
        print('stop hitting that button!')


if __name__ == '__main__':
    data = comp.GetData('BM_test')
    if not data:
        data = {}
        print('add some bookmarks!')

    # Main Window
    ui = fusion.UIManager
    disp = bmd.UIDispatcher(ui)
    win = disp.AddWindow({'ID': 'combobox',
                        'TargetID': 'combobox',
                        'WindowTitle': 'jump to bookmark',
                        'Geometry': [100, 300, 300, 80]},
                            [
                            ui.VGroup(
                                [
                                    ui.ComboBox({'ID': 'MyCombo',
                                                'Text': 'Choose preset'
                                                }),
                                    ui.HGroup(
                                    [
                                        ui.Button({'ID': 'rm',
                                                'Text': 'delete bookmark',
                                                'Weight': 0.5,
                                                }),
                                        ui.Button({'ID': 'rmall',
                                                'Text': 'reset',
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

    fill_checkbox(data)

    win.Show()
    disp.RunLoop()
    win.Hide()
