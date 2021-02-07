import string
if tool and tool.StyledText:
    text = tool.StyledText[1]
    text = string.capwords(text)
    tool.StyledText[1] = text
