"""
    Script for extracting frame rate and image dimensions from metadata 
    and setting the composition's frame rate, width, and height in Blackmagic Fusion.

    Copyright © 2024 Alexey Bogomolov
    Email: mail@abogomolov.com
    License: MIT
    
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
    OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
"""

def convert_to_number(data: str, to_type):
    try:
        return to_type(data)
    except ValueError:
        print(f"The value {data} could not be converted to {to_type.__name__}")
        return None

def set_comp_pref(key: str, value):
    comp.SetPrefs(key, value)

def process_metadata(metadata, key_fragment, comp_pref_key, convert_func, value_type):
    for key, value in metadata.items():
        if key_fragment in key.lower():
            converted_value = convert_func(value, value_type)
            if converted_value is not None:
                set_comp_pref(comp_pref_key, converted_value)
                print(f"{comp_pref_key.split('.')[-1]} set to {converted_value}")
                return True
    return False

def main():
    tool = comp.ActiveTool
    if not tool:
        print('Select a tool to read the metadata')
        return

    tool_metadata = tool.Output[comp.CurrentTime].Metadata
    if not tool_metadata:
        print("No metadata found")
        return

    fps_found = process_metadata(tool_metadata, "fps", "Comp.FrameFormat.Rate", convert_to_number, float)
    width_found = process_metadata(tool_metadata, "width", "Comp.FrameFormat.Width", convert_to_number, int)
    height_found = process_metadata(tool_metadata, "height", "Comp.FrameFormat.Height", convert_to_number, int)

    if not fps_found:
        print("No FPS information found in metadata")
    if not width_found:
        print("No Width information found in metadata")
    if not height_found:
        print("No Height information found in metadata")

if __name__ == "__main__":
    main()
