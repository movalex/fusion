## Context tool script

Mark tool as a context to view it in selected Fusion viewer. 
The idea that you can view some key nodes from entire comp, or just the very last node, without having to navigate the flow whatsoever. You can stay where you are, if you are working on something, but view in context. Or you can modify nodes in the process tree and immediately view the impact those changes have on the nodes further along in the process tree without switching to the last tool in the Flow. This is how it is implemented in [Autodesk Smoke](https://download.autodesk.com/us/systemdocs/help/2011/smoke/index.html?url=./files/WScba3ee2b36d8cb6f-54f0f461162be3def5-7fe4.htm,topicNumber=d0e79347). 

You can assign this key tools as a a context tool. So when you run `View Context` script, the tool will be shown in a selected viewer. Run View Context script again and previous tool will be loaded back to the viewer.
You can store up to 9 context. Assign Context tool with `Shift+Alt+[1-9]` shortcut. View context with `Alt+[0-9]`.

_Usage:_

1. select node and assign context with shortcut `Shift+Alt+1`. Context number should appear in tool's Comments tab.
2. click on the left or right Viewer and load context tool with `Alt+1` shotrcut.
3. click `Alt+1` once again to bring previous tool back to viewer.



