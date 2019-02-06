"""
jump to stored flow position
use dropdown menu to switch to stored position
Alex Bogomolov mail@abogomolov.com
MIT/X Consortium License: https://mit-license.org/
"""

flow = comp.CurrentFrame.FlowView

stored_data = comp.GetData('BM')
if not stored_data:
    stored_data = {}
    print('add some bookmarks')

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
                                            'Text':'Choose preset'
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
                                ]
                                )
                            ]),
                        ])

itm = win.GetItems()

def fill_checkbox(data):
    message = 'select bookmark'
    if len(data) < 2:
        message = 'add some bookmarks'
    itm['MyCombo'].AddItem(message)
    itm['MyCombo'].InsertSeparator()
    for name in sorted(data.values(), key=lambda x: x.lower()):
        if name:
            itm['MyCombo'].AddItem(name)

fill_checkbox(stored_data)

def clear_all():
    comp.SetData('BM')
    print('all bookmarks gone')

def delete_bookmark(key):
    global stored_data
    comp.SetData('BM')
    try:
        del stored_data[key]
        for k,v in stored_data.items():
            comp.SetData('BM.{}'.format(k), v)
    except IndexError:
        print('index error')
        stored_data = {}

def get_values():
    value_sorted = sorted(stored_data.items(), key=lambda v: v[1].lower())
    print(value_sorted)
    return value_sorted

def _func(ev):
    choice = int(itm['MyCombo'].CurrentIndex)
    print('choice: ', choice)
    if choice <= 1:
        pass
    else:
        tool_name = get_values()[choice-1][0]
        print('jump to', tool_name)
        source = comp.FindTool(tool_name)
        flow.SetScale(2)
        comp.SetActiveTool(source)
win.On.MyCombo.CurrentIndexChanged = _func

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
        delete_bookmark(tool_name)
    except IndexError:
        raise
        print('damn')
win.On.rm.Clicked = _func


fusion.AddConfig({'combobox':
                  [{'Target':{'ID':'combobox'}},
                    {'Hotkeys':

                        {'Target':'combobox',
                        'Defauts': True,
                        'ESCAPE': 'Execute{cmd = [[fusion.UIManager:QueueEvent(obj, "Close", {})]]}'
                        }

                    }]
                  })

win.Show()
disp.RunLoop()
win.Hide()

