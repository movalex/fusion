"""
Script to convert absolute paths to relative paths in Fusion loaders.
Converts loader clip paths to use Comp: prefix for relative paths.
"""
from pathlib import Path
import platform
from typing import Dict, List, Tuple


def get_path_delimiter() -> str:
    """Return the appropriate path delimiter for the current OS."""
    return "/" if platform.system() in ["Darwin", "Linux"] else "\\"


def is_already_relative(clip_path: str) -> bool:
    """Check if the clip path is already using relative Comp: syntax."""
    return clip_path[:5].lower() == "comp:"


def save_loader_properties(tool) -> Dict:
    """Save loader properties that need to be preserved."""
    return {
        "global_in": tool.GlobalIn[0],
        "global_out": tool.GlobalOut[0],
        "clip_time_start": tool.ClipTimeStart[0],
        "clip_time_end": tool.ClipTimeEnd[0],
        "pixel_aspect": tool.PixelAspect[0],
        "custom_pixel_aspect": tool.CustomPixelAspect[0],
    }


def restore_loader_properties(tool, properties: Dict) -> None:
    """Restore loader properties after path change."""
    if tool.ID == "Loader":
        tool.GlobalIn = properties["global_in"]
        tool.GlobalOut = properties["global_out"]
        tool.ClipTimeStart = properties["clip_time_start"]
        tool.ClipTimeEnd = properties["clip_time_end"]
        tool.PixelAspect = properties["pixel_aspect"]
        tool.CustomPixelAspect = properties["custom_pixel_aspect"]


def find_common_path_parts(comp_parts: Tuple, tool_parts: Tuple) -> List[str]:
    """Find the common parts between two paths."""
    return [part for part in comp_parts if part in tool_parts]


def build_upstream_relative_path(
    clip_path: str, comp_parent: Path, tool_parent: Path, delimiter: str
) -> str:
    """Build relative path for files upstream from comp location."""
    comp_parts = comp_parent.parts
    tool_parts = tool_parent.parts
    
    common_parts = find_common_path_parts(comp_parts, tool_parts)
    if not common_parts:
        return None
    
    # Calculate the number of directories to go up
    levels_up = len(comp_parts) - len(common_parts)
    prefix = f"..{delimiter}" * levels_up
    
    # Build common path
    common_path = delimiter.join(common_parts).replace("//", "/")
    if platform.system() == "Windows":
        common_path = str(Path(common_path))
    
    # Replace common path with Comp: prefix
    relative_path = clip_path.replace(str(common_path), f"Comp:{prefix}")
    return relative_path


def convert_to_relative_path(
    tool, comp_parent: Path, delimiter: str
) -> str:
    """Convert absolute path to relative Comp: path."""
    clip_path = tool.Clip[0]
    tool_parent = Path(clip_path).parent
    
    # Check if tool is in a subdirectory of comp
    if str(tool_parent).startswith(str(comp_parent)):
        # Downstream footage - direct replacement
        return clip_path.replace(str(comp_parent), "Comp:")
    else:
        # Upstream footage - needs relative path with ../
        return build_upstream_relative_path(
            clip_path, comp_parent, tool_parent, delimiter
        )


def main():
    """Main script execution."""
    comp = fu.GetCurrentComp()
    comp_name = comp.GetAttrs()["COMPS_FileName"]
    rev_path = comp.ReverseMapPath(comp_name)
    comp_parent = Path(rev_path).parent
    delimiter = get_path_delimiter()
    
    comp.StartUndo("Convert to Relative Paths")
    
    try:
        loaders = comp.GetToolList(True, "Loader").values()
        
        for tool in loaders:
            clip_path = tool.Clip[0]
            
            # Skip if already relative
            if is_already_relative(clip_path):
                continue
            
            # Save properties before modifying
            properties = save_loader_properties(tool)
            
            # Convert to relative path
            new_path = convert_to_relative_path(tool, comp_parent, delimiter)
            
            if new_path is None:
                print(f"No common path found for: {clip_path}")
                continue
            
            # Set new path
            tool.Clip[0] = new_path
            
            # Restore properties
            restore_loader_properties(tool, properties)
            
            print(f"Converted to relative path: {new_path}")
    
    finally:
        comp.EndUndo()


if __name__ == "__main__":
    main()
