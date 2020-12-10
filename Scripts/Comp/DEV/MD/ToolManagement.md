# Tool Management scripts
This submission installs two scripts that allow to manage multiple tools at once. They essentially do the same job, but internally work differently, so you can choose, which tool to use. 
The main difference between them: `Tool Tagger` uses comp data to store tool tags and select them based on this data. `Tool Comment Manager` works on a per-tool basis and stores tags in a tool's comments section. Thus, you can have a visible representation of the tagged tools in a flow (if you hover with the mouse over the tool, you'll see the tag, assigned to it, prepended with `%` symbol). This tool will erase any comment already assigned to the tagged tool, so don't use it if you want them to be intact.

Either of these scripts is a great companion to a recently released to Reactor [Attribute Spreadseet script](https://www.steakunderwater.com/wesuckless/viewtopic.php?p=35321#p35321). Tag some tools with a Tool Management script and select these tools to adjust inputs with the `Attribute spreadsheet`. This is a very convenient workflow once you get used to it.

## Tool Comment Manager
This is a comment based tool manager for making basic operations with Fusion nodes, such as: _disable, enable, toggle passthrough_ (disabled tools become enabled and vice versa), _select_ and _lock_. 

_Description:_

This script is an evolution of @SirEdric's [Priority Passthrough script](https://www.steakunderwater.com/VFXPedia/96.0.243.189/images/SE_PriorityPassthrough.eyeonscript). You can group different tools by assigning a special comment to them. The tool manager will operate only tools with a given comment. List of the comments will be shown in the middle section. If the text field underneath is empty, the script will be managing all tools of the same ID. The script tags tools with a comment rather than internal tool data, in order the tagged tools would be visible in a Flow.

_Usage:_

1. Select single Merge tool, click 'Disable' and all Merge tools in a comp will be disabled.
2. Select some nodes, i.e. last two merges, then fill the text field: "_my favorite merges_". 
3. Click `Set or Replace comment` or hit `Enter`. The given comment will be applied to the selected tools. ALso, this comment will appear in comments list. Next time you click Disable, only these two tools will be disabled. 
4. The comment added to the tool will be prepended with `@` symbol. Thus, ToolManager will not list other commented tools. 
5. To clear the comment, press clear button in text field, then with tools selected press Set comment. The comments will be cleared. This can be applied to any tools with comments, not only the managed ones.
6. Doubleclick on comments list to manually refresh it. I will probably replace this redundant function later to show the list of tagged tools in a console, just like the `Tool Tagger` does.

## Tool Tagger
This is a comp data driven tool manager for making basic operations with groups Fusion nodes, such as: _disable, enable, toggle passthrough_ (disabled tools become enabled and vice versa), _select_ and _lock_. 

I wrote this script when I realized I would like to keep comments in some tools. This script has some advantages over the comment manager (see in description), and I actually prefer using it. 

_Description:_

This script operates with comp data, and does not change tool comments at all. The [idea](https://www.steakunderwater.com/wesuckless/viewtopic.php?p=22734#p22734) belongs to @PingKing. Here's his proof of concept video: [https://www.youtube.com/watch?v=RmlzyVVHkIM](https://www.youtube.com/watch?v=RmlzyVVHkIM). You can group different tools by assigning a special tag to them. The main difference with `Tool Comment Manager` - you can assign any number of tags to the same tool. So you can manage, say, `Merge1` and `Merge2` with a tag _"My favorite Merges"_, and `Merge1`, `Merge3` and `Merge4` with _"Some Merges I'm slowly starting to hate"_ tag. This would be virtually impossible to do with a comment driven script. Unfortunately, unlike Tool Comment Manager, there won't be any visual representation of the tagged tools in a flow.

List of the tags will be shown in the middle section. If the text field underneath is empty, the script will be managing all tools of the same ID.

_Usage:_

1. Select single Merge tool, click 'Disable' and all Merge tools in a comp will be disabled.
2. Select some nodes, i.e. last two merges, then fill the text field: "_my favorite merges_".
3. Click `Set Tag` or hit `Enter` to add tag to selected tools. The tag will appear in comments list.
4. Now click Disable, and only tools with assigned tag will be disabled.
5. Press `Delete Tag` button to delete the tag from the list and from the comp data.
6. Doubleclick on a tag to see in the console which tools are assigned to this tag.

_Copyright:_ Alexey Bogomolov (mail@abogomolov.com)

_License:_ [MIT](https://mit-license.org/)

_Version:_ v.1.0 - [2020/12/08]

_Donations:_ [PayPal.me](https://paypal.me/aabogomolov/5usd)