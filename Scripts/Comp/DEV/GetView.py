view = comp.CurrentFrame.CurrentView
print(view.GetID())
print(view.ID)
print(dir(view))
preview = view.GetPreview()
print(dir(preview))
print("preview Name: ", preview.Name)
print("ID: ", preview.ID)
tool = comp.ActiveTool
preview.ViewOn(tool)
# comp.CurrentFrame.ViewOn(tool, 4)