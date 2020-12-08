# Tool Tagger
This is a comp data driven tool manager for making basic operations with groups Fusion nodes, such as: _disable, enable, toggle passthrough_ (disabled tools become enabled and vice versa), _select_ and _lock_.

_Description:_

This is a companion script to the `ToolManager`. This script operates with comp data, and does not change tool comments at all. The idea belongs to @PingKing, here's his proof of concept video: [https://www.youtube.com/watch?v=RmlzyVVHkIM](https://www.youtube.com/watch?v=RmlzyVVHkIM). You can group different tools by assigning a special tag to them. The main difference with ToolManager - you can assign any number of tags to the same tool. So you can manage, say, `Merge1` and `Merge2` with tag "Merges", and `Merge1`, `Merge3` and `Merge4` with different tag. This would be virtually impossible to do with a comment driven script. Unfortunately, unlike ToolManager, there won't be any visual representation of the tagged tools in a flow. 

List of the comments will be shown in the middle section. If the text field is empty, the script will be managing tools of the same ID. 

_Usage:_

1. Select single Merge tool, click 'Disable' and all Merge tools in a comp will be disabled.
2. Select some nodes, i.e. last two merges, then fill the text field: "_my favorite merges_". 
3. Click `Set Tag` or hit `Enter` to add tag to selected tools. The tag will appear in comments list. 
4. Now click Disable, and only tools with assigned tag will be disabled. 
4. Press `Delete Tag` button to delete the tag from the list and from the comp data.

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com)

_License:_ [MIT](https://mit-license.org/)

_Version:_ v.1.0 - [2020/12/08]

_Donations:_ [PayPal.me](https://paypal.me/aabogomolov/5usd)