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

# close UI on ESC button
comp.Execute('''app:AddConfig("AskUser",
{
    Target  {ID = "AskUser"},
    Hotkeys {Target = "AskUser",
             Defaults = true,
             ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}" }})
''')


def get_bookmark():
    bm_text = itm['BookmarkLine'].GetText()
    if bm_text[0].isdigit():
        print('bookmark name starts with digit, now prepending with _')
        bm_text = '_' + bm_text
    print('created bookmark:', bm_text)
    current_scale = flow.GetScale()
    tool_name = tool.Name
    # tool_ID = 'tool_{}'.format(int(tool.GetAttrs('TOOLI_ID')))
    comp.SetData('BM.{}'.format(bm_text), [tool_name, current_scale])


def get_tool():
    active = comp.ActiveTool
    if not active:
        selected_nodes = list(comp.GetToolList(True).values())
        if len(selected_nodes) == 0:
            print('select node to bookmark')
            return None
        return selected_nodes[0]
    return active


def _close_UI(ev):
    disp.ExitLoop()


def _choose_bm_UI(ev):
    get_bookmark()
    disp.ExitLoop()


if __name__ == '__main__':
    tool = get_tool()
    if tool:
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
                                                'Text': tool.Name,
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
        comp.SetData('BM._', '')

        win.On.AddButton.Clicked = _choose_bm_UI
        win.On.BookmarkLine.ReturnPressed = _choose_bm_UI
        win.On.AskUser.Close = _close_UI

        win.Show()
        disp.RunLoop()
        win.Hide()
