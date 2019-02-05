"""
remember flow position script
inspired by original tool by Michael Vorberg
python implementation with QT UI
this script stores positional data and script name in current comp metadata
Alex Bogomolov mail@abogomolov.com
MIT/X Consortium License: https://mit-license.org/
"""

flow = comp.CurrentFrame.FlowView

def show_UI(tool):
    ui = fusion.UIManager
    disp = bmd.UIDispatcher(ui)

    # Main Window
    win = disp.AddWindow({'ID': 'AskUser',
                        'WindowTitle': 'add bookmark',
                        'Geometry': [100, 300, 300, 78]},
                        [
                        ui.VGroup({'Spacing':0},
                            [
                                ui.LineEdit({'ID': 'BookmarkLine',
                                            'Text':tool.Name,
                                            'Weight': 0.5,
                                            'Events': {'ReturnPressed': True},
                                            'Alignment': {'AlignHCenter': True},
                                            }),
                                ui.HGroup(
                                    [
                                ui.HGap(0, .5),
                                ui.Button({'ID': 'AddButton',
                                        'Text': 'Add Bookmark',
                                        'Weight': 0.5, }),
                                ui.HGap(0, .5),
                                    ]
                                )
                            ]),
                        ])

    itm = win.GetItems()
    itm['BookmarkLine'].SelectAll()

    def get_bookmark():
        bm_text = itm['BookmarkLine'].GetText()
        tool_name = tool.Name
        comp.SetData('BM.{}'.format(tool_name), bm_text)

    def _func(ev):
        get_bookmark()
        # print(comp.GetData().values())
        disp.ExitLoop()
    win.On.BookmarkLine.ReturnPressed = _func

    def _func(ev):
        disp.ExitLoop()
    win.On.AskUser.Close = _func

    def _func(ev):
        get_bookmark()
        print('created bookmark:', itm['BookmarkLine'].Text)
        disp.ExitLoop()
    win.On.AddButton.Clicked = _func

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

