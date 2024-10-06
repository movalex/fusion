import DaVinciResolveScript as bmd

resolve = bmd.scriptapp('Resolve')
resolve.OpenPage("fusion")

fu = resolve.Fusion()
comp = fu.GetCurrentComp()
if comp:
     print(f"Found current comp: {comp}")
     tools = comp.GetToolList()
     for tool in tools.values():
          print(f"Tool ID: {tool.ID}, tool name: {tool.Name}")

else:
     print("No comp object found!")

resolve.OpenPage("edit")