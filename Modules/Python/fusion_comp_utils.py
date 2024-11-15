from pathlib import Path

class CompUtils:
    def __init__(self, comp):
        self.comp = comp

    def get_loader(self):
        """Get selected loader."""
        try:
            loader = self.comp.GetToolList(True, "Loader")[1]
            return loader
        except KeyError:
            print("No Loader selected")
            return None

    def set_range(self, loader):
        """Set GlobalIn and GlobalOut according to Loader clip length."""
        if loader is None:
            print("Loader is not available")
            return

        self.comp.StartUndo("Set Range based on Loader")
        clip_in = loader.GlobalIn[1]
        clip_out = loader.GlobalOut[1]
        self.comp.SetAttrs({"COMPN_GlobalStart": clip_in})
        self.comp.SetAttrs({"COMPN_GlobalEnd": clip_out})
        self.comp.EndUndo()
        print(f"Comp length is adjusted to [ {clip_in} - {clip_out} ]")

    def parse_loader_path(self, loader):
        loader_path = Path(self.comp.MapPath(loader.Clip[1]))
        return loader_path

