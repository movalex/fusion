import re
LIMIT = 15


def rename_text(txt):
    txt = re.sub("(^\d+)",r"_\1", txt)
    txt = re.sub("\n|\s|\W", r"_", txt)
    text = txt[:LIMIT]
    # print(txt)
    comp.StartUndo("Rename text node")
    tool.SetAttrs({"TOOLS_Name": text})
    comp.EndUndo("Rename text node")


if __name__ == "__main__":
    if tool.ID == "TextPlus":
        rename_text(tool.StyledText[fu.TIME_UNDEFINED])