# tool script to get tool's ID. Useful if you do expressions
# or use a Reactor 'Slash For' script a lot
# and you don't want to keep in memory, that Resize tool is actually a 'BetterResize',
# and MaskPaint is actually a 'PaintMask'.

import os
import platform

tool_name = tool.ID

if platform.system() in ["Darwin", "Linux"]:
    os.system("echo '{}' | tr -d '\n' | pbcopy".format(tool_name))

print(tool_name)
