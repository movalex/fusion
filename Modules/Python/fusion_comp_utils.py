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

    def set_range(self, loader, use_loader_settings=False):
        """Set GlobalIn and GlobalOut according to Loader clip length."""
        if loader is None:
            print("Loader is not available")
            return

        self.comp.StartUndo("Set Range based on Loader")
        if use_loader_settings:
            in_point = loader.GlobalIn[1]
            out_point = loader.GlobalOut[1]
        else:
            in_point = self.comp.GetAttrs()["COMPN_GlobalStart"]
            out_point = loader.GetAttrs()["TOOLIT_Clip_Length"][1] - 1
        self.comp.SetAttrs({"COMPN_GlobalStart": in_point})
        self.comp.SetAttrs({"COMPN_GlobalEnd": out_point})
        self.comp.SetAttrs({"COMPN_RenderStart": in_point})
        self.comp.SetAttrs({"COMPN_RenderEnd": out_point})
        self.comp.EndUndo()
        print(f"Comp length is adjusted to [ {in_point} - {out_point} ]")

    def parse_loader_path(self, loader):
        loader_path = Path(self.comp.MapPath(loader.Clip[1]))
        return loader_path

