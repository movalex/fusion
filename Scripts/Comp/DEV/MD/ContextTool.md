# Context tool script

**Mark tool as a context to view it in selected Fusion viewer.**

The idea that you can view some key nodes from an entire comp without having to navigate the flow whatsoever. You can stay where you are, if you are working on something, but view in context. Or you can modify nodes in the process tree and immediately view the impact those changes have on the nodes further along in the process tree without switching to the last tool in the Flow. This is how it is implemented in [Autodesk Smoke](https://download.autodesk.com/us/systemdocs/help/2011/smoke/index.html?url=./files/WScba3ee2b36d8cb6f-54f0f461162be3def5-7fe4.htm,topicNumber=d0e79347).

_Description:_

Assign Context tool with `Shift+Alt+[1-9]` shortcut. When you run `View Context` script, the tool will be shown in a selected viewer. You should activate a viewer before running a script. Run View Context script again and previous tool will be loaded back to this viewer.
You can store up to 9 contexts.  View context with `Alt+[1-9]` shortcuts.

_Usage example:_

1. Select node and assign context #1 with shortcut `Shift+Alt+1`. Context number should appear in tool's Comments tab.
2. Click on the left or right Viewer and load context tool with `Alt+1` shortcut. At least one Fusion viewer has to be activated. 
3. Click `Alt+1` once again to bring previous tool back to viewer.

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com)

_License:_ [MIT](https://mit-license.org/)

_Version:_ v.1.0 - [2020/11/29]

_Donations:_ [PayPal.me](https://paypal.me/aabogomolov/10usd)