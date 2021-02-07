if tool and tool.StyledText:
    text = tool.StyledText[1]
    text = text.lower()
    tool.StyledText[1] = text
