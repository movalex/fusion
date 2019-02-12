"""
Remember flow position script
Inspired by original tool by Michael Vorberg
Python implementation with QT UI
This script stores tool's name and bookmark in current comp metadata.

Alexey Bogomolov mail@abogomolov.com
Donations are highly appreciated: https://paypal.me/aabogomolov
Requests and issues: https://github.com/movalex/fusion_scripts/issues

MIT License: https://mit-license.org/
"""
from __future__ import print_function

flow = comp.CurrentFrame.FlowView


def show_UI(tool):
    ui = fusion.UIManager
    disp = bmd.UIDispatcher(ui)

    # Main Window
    win = disp.AddWindow({'ID': 'AskUser',
                          'TargetID': 'AskUser',
                          'WindowTitle': 'add bookmark',
                          'Geometry': [200, 600, 300, 75]},
                        [
                        ui.VGroup(
                            [
                                ui.LineEdit({'ID': 'BookmarkLine',
                                             'Text':tool.Name,
                                             'Weight': 0.5,
                                             'Events': {'ReturnPressed': True},
                                             'Alignment': {'AlignHCenter': True},
                                            }),
                                ui.HGroup(
                                    [
                                        ui.HGap(0, .25),
                                        ui.Button({'ID': 'AddButton',
                                                   'Text': 'OK',
                                                   'Weight': 0.5, }),
                                        ui.HGap(0, .25),
                                    ]
                                )
                            ]),
                        ])

    itm = win.GetItems()
    itm['BookmarkLine'].SelectAll()
    comp.SetData('BM.default_value', '')


    def get_bookmark():
        bm_text = itm['BookmarkLine'].GetText()
        current_scale = flow.GetScale()
        tool_name = tool.Name
        comp.SetData('BM.{}'.format(tool_name), [bm_text, current_scale])

    def _func(ev):
        disp.ExitLoop()
    win.On.AskUser.Close = _func

    def _func(ev):
        get_bookmark()
        print('created bookmark:', itm['BookmarkLine'].Text)
        disp.ExitLoop()
    win.On.AddButton.Clicked = _func
    win.On.BookmarkLine.ReturnPressed = _func

# close UI on ESC button
    comp.Execute('''app:AddConfig("AskUser",
    { Target {ID = "AskUser"},
    Hotkeys { Target = "AskUser",
    Defaults = true,
    ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}" }})
                 ''')

    win.Show()
    disp.RunLoop()
    win.Hide()


def get_tool():
    active = comp.ActiveTool
    if not active:
        selected_nodes = list(comp.GetToolList(True).values())
        if len(selected_nodes) == 0:
            print('select node to bookmark')
            return None
        return selected_nodes[0]
    return active


tool = get_tool()
if tool:
    show_UI(tool)
