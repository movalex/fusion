This is a tool manager script for making basic operations with Fusion nodes, such as:

* disable
* enable
* toggle passthrough (disabled tools become enabled and vice versa)
* select 
* lock

You can group different tools by assigning a special comment to them. And tool manager will operate only tools with given comment. List of the comments will be listed in the middle section. If no comment assigned to selected tool, the script will be managing all other tools of the same kind. 

_Usage:_

1. Select single Merge tool, click 'Disable' and all Merge tools in a comp will be disabled.
2. Select last two merges in a comp, then fill the text field at the bottom of the script: 'last two merges' and click `Set or Replace comment`. The given comment will be applied to the selected tools, ath this comment text will appear in comments list. Next time you click Disable, only these two tools will be disabled. 
3. This script is a great companion for Attribute spreadsheet script. Use Select button to batch-manage inputs groups of nodes.
4. The comment added to the tool will be prepended with `@` symbol. Thus ToolManager will not operate other commented tools. 
5. To clear the comment, press clear button in text field, then with tools selected press Set comment. The comments will be cleared.
6. Doubleclick on comments list to refresh it