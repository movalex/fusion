# tool script to get tool's ID. Useful if you use a ForSlash script a lot,
# and don't want to keep in memory, that Resize tool is actually a
# 'BetterResize', and MaskPaint is actually a 'PaintMask'.

import os
import platform

tool_name = tool.ID

if platform.system() in ["Darwin", "Linux"]:
    os.system("echo '{}' | tr -d '\n' | pbcopy".format(tool_name))
print(tool.ID)
