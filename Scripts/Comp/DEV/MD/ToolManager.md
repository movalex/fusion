# Tool Manager
This is a comment based tool manager for making basic operations with Fusion nodes, such as: _disable, enable, toggle passthrough (disabled tools become enabled and vice versa), select, lock_

_Description:_

You can group different tools by assigning a special comment to them. And tool manager will operate only tools with given comment. List of the comments will be listed in the middle section. If no comment assigned to selected tool, the script will be managing all other tools of the same kind. 

_Usage:_

1. Select single Merge tool, click 'Disable' and all Merge tools in a comp will be disabled.
2. Select some nodes, i.e. last two merges, then fill the text field: "_my favorite merges_". 
3. Click `Set or Replace comment` or hit `Enter`. The given comment will be applied to the selected tools. ALso this comment will appear in comments list. Next time you click Disable, only these two tools will be disabled. 
4. The comment added to the tool will be prepended with `@` symbol. Thus ToolManager will not affect other commented tools. 
5. To clear the comment, press clear button in text field, then with tools selected press Set comment. The comments will be cleared. This can be applied no any tools with comments, not only the managed ones.
6. Doubleclick on comments list to refresh it

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com)

_License:_ [MIT](https://mit-license.org/)

_Version:_ v.1.1 - [2020/11/08]

_Donations:_ [PayPal.me](https://paypal.me/aabogomolov/5usd)