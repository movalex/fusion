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

stored_data = comp.GetData('BM_test')
if not stored_data:
    stored_data = {}
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


def fill_checkbox(data):
    message = 'select bookmark'
    if len(data) < 2:
        message = 'add some bookmarks!'
    itm['MyCombo'].AddItem(message)
    itm['MyCombo'].InsertSeparator()
    # print(data)
    sorted_bms = sorted([i[1] for i in data.values() if i])
    for bm in sorted_bms:
        itm['MyCombo'].AddItem(bm)

    # for name in sorted(data.values(), key=lambda x: x.lower()):
    #     if name:
    #         itm['MyCombo'].AddItem(name)


fill_checkbox(stored_data)


def clear_all():
    comp.SetData('BM_test')
    print('all bookmarks gone')


def delete_bookmark(key):
    comp.SetData('BM_test')
    try:
        del stored_data[key]
        for k, v in stored_data.items():
            comp.SetData('BM_test.{}'.format(k), v)
    except IndexError:
        pass


def get_values():
    value_sorted = sorted(stored_data.items(), key=lambda v: v[1].lower())
    return value_sorted


def _main_func(ev):
    choice = int(itm['MyCombo'].CurrentIndex)
    if choice <= 1:
        pass
    else:
        toolName = get_values()[choice-1][0]
        print('jump to', toolName)
        source = comp.FindTool(toolName)
        # position of bookmarked node
        sx, sy = flow.GetPosTable(source).values() 
        # would be nice to store the scale with each bookmark and reference here
        # the actual SetScale value also used 
        scaleFactor = 1.25 
        # to place temp PipeRouters for the hack
        # we have the position of the bookmarked node
        # (if multiple nodes then we could first get average X
        # and Y of all selected -- list, add up, divide by count)
        prRelPosX = round(8 / scaleFactor) # an amount to offset in X - temp PipeRouter from the bookmarked tool
        prRelPosY = round(6 / scaleFactor) # an amount to offset in Y 
        pr1 = comp.AddTool("PipeRouter", sx - prRelPosX, sy - prRelPosY)
        # additional added to favor top left
        pr2 = comp.AddTool("PipeRouter", sx + prRelPosX + 1, sy + prRelPosY + 2)
        flow.SetScale(scaleFactor)
        comp.SetActiveTool(pr2)
        comp.SetActiveTool(pr1)
        flow.Select()
        pr1.Delete()
        pr2.Delete()
        comp.SetActiveTool(source)
        
win.On.MyCombo.CurrentIndexChanged = _main_func


def _func(ev):
    disp.ExitLoop()
win.On.combobox.Close = _func

def _func(ev):
    clear_all()
    itm['MyCombo'].Clear()
    itm['MyCombo'].AddItem('all bookmarks gone')
win.On.rmall.Clicked = _func

def _func(ev):
    try:
        choice = int(itm['MyCombo'].CurrentIndex)-1
        tool_name, bm_text = get_values()[choice]
        itm['MyCombo'].RemoveItem(choice+1)
        print('bookmark {} deleted'.format(bm_text))
        delete_bookmark(tool_name)
    except IndexError:
        print('stop hitting that button!')
win.On.rm.Clicked = _func

# close UI on ESC button
comp.Execute('''app:AddConfig("combobox",
{ Target {ID = "combobox"},
Hotkeys { Target = "combobox",
Defaults = true,
ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}" }})
''')

win.Show()
disp.RunLoop()
win.Hide()
