from pathlib import Path
import sys
import logging

class CompUtils:
    def __init__(self, comp=None):
        self.comp = comp
        if comp is None:
            self.fusion = self.get_fusion()
            if self.fusion:
                self.comp = self.get_fusion_comp(self.fusion)
    
    @staticmethod
    def get_fusion(fusion_host=None):
        """Retrieve the Fusion application object."""
        try:
            import BMDFusion as bmd
            # Print module representation and sys.path for clues
            print(f"BlackmagicFusion module object: {bmd}")
            # print(f"sys.path: {sys.path}")
            # You could also try printing dir(bmd) to see available attributes:
            print(f"Attributes of bmd: {dir(bmd)}")
            fu = bmd.scriptapp("Fusion")
            if not fu:
                logging.error("Failed to get Fusion instance")
            return fu
        except ModuleNotFoundError:
            logging.warning("No BlackmagicFusion module found")
        except Exception as e:
            logging.error(f"Error connecting to Fusion: {e}")
        return None

    @staticmethod
    def get_fusion_comp(fusion_object):
        """Retrieve the current composition from the Fusion instance."""
        if not fusion_object:
            logging.warning("No Fusion instance found")
            return None

        try:
            comp = fusion_object.GetCurrentComp()
            if not comp:
                logging.warning("No active composition in Fusion")
            return comp
        except AttributeError:
            logging.error("Failed to retrieve the current composition. Ensure Fusion is running and accessible.")
            return None

    def ensure_comp(self):
        """Ensure we have a valid composition object"""
        if self.comp is None:
            logging.error("No valid composition available")
            return False
        return True

    def get_comp_attribute(self, attr: str):
        """Get composition attribute"""
        if not self.ensure_comp():
            return None
        try:
            comp_attributes = self.comp.GetAttrs()
            return comp_attributes.get(attr)
        except Exception as e:
            logging.error(f"Error getting composition attribute {attr}: {e}")
            return None

    def get_comp_name(self):
        """Get the name of the current composition"""
        if not self.ensure_comp():
            return None
        try:
            file_name = self.get_comp_attribute("COMPS_FileName")
            if not file_name:
                return None
            comp_name = Path(self.comp.MapPath(file_name))
            if not comp_name or comp_name.name == "Composition1":
                return None
            return comp_name
        except Exception as e:
            logging.error(f"Error getting composition name: {e}")
            return None

    def get_tool_list(self, selected=False, tool_type=None):
        """
        Get a list of tools from the composition.
        
        Args:
            selected (bool): True to get only selected tools, False to get all tools
            tool_type (str): Filter by tool type (e.g., "Loader", "Saver", etc.)
                             None to get all tool types
                             
        Returns:
            dict: Dictionary of tools or None if no valid composition
        """
        if not self.ensure_comp():
            return None
            
        try:
            tools = self.comp.GetToolList(selected, tool_type)
            return tools
        except Exception as e:
            logging.error(f"Error getting tools: {e}")
            return None
    
    def get_tools(self, selected=False, tool_type=None):
        """
        Get tool values as a list.
        
        Args:
            selected (bool): True to get only selected tools, False to get all tools
            tool_type (str): Filter by tool type (e.g., "Loader", "Saver", etc.)
                             None to get all tool types
                             
        Returns:
            list: List of tool values or empty list if no tools found
        """
        tools = self.get_tool_list(selected, tool_type)
        if not tools:
            return []
        return list(tools.values())

    def get_loader(self):
        """Get first selected loader."""
        tools = self.get_tools(True, "Loader")
        if not tools:
            logging.warning("No Loader tools selected")
            return None
        return tools[0]  # First selected loader

    def get_all_loaders(self):
        """Get all loaders in the composition."""
        return self.get_tools(False, "Loader")
        
    def get_all_savers(self):
        """Get all savers in the composition."""
        return self.get_tools(False, "Saver")

    def set_range(self, loader, use_loader_settings=False):
        """Set GlobalIn and GlobalOut according to Loader clip length."""
        if not self.ensure_comp() or loader is None:
            logging.error("Loader is not available")
            return

        try:
            self.comp.StartUndo("Set Range based on Loader")
            clip_length = loader.GetAttrs()["TOOLIT_Clip_Length"][1]
            if use_loader_settings:
                in_point = loader.GlobalIn[1]
                out_point = loader.GlobalOut[1]
            else:
                in_point = self.comp.GetAttrs()["COMPN_GlobalStart"]
                out_point = clip_length + in_point - 1
            self.comp.SetAttrs({"COMPN_GlobalStart": in_point})
            self.comp.SetAttrs({"COMPN_GlobalEnd": out_point})
            self.comp.SetAttrs({"COMPN_RenderStart": in_point})
            self.comp.SetAttrs({"COMPN_RenderEnd": out_point})
            self.comp.EndUndo()
            logging.info(f"Comp length is adjusted to [ {in_point} - {out_point} ]")
        except Exception as e:
            logging.error(f"Error setting range: {e}")
            self.comp.EndUndo(True)  # Cancel undo if error

    def get_loader_path(self, loader):
        """Get the file path of the loader"""
        if not self.ensure_comp() or loader is None:
            return None
        try:
            clip_path = loader.Clip[1]
            if not clip_path:
                return None
            loader_path = Path(self.comp.MapPath(clip_path))
            return loader_path
        except Exception as e:
            logging.error(f"Error getting loader path: {e}")
            return None


comp = CompUtils().comp
print(comp)