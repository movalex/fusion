import re
import sys
import os


def process(file_path, tool_name):
    with open(file_path, "r") as file:
        name, ext = os.path.splitext(file_path)
        out = name + "_out"
        out_file = out + ext
        print(out_file)
        file_read = file.readlines()
        with open(out_file, "w") as output:
            source_string = f"""\t\t\t\t["PaintApplyRubThrough.SourceTool"] = Input {{\n\t\t\t\t\tSourceOp = "{tool_name}",\n\t\t\t\t\tSource = "Output",\n\t\t\t\t}},\n"""
            for line in file_read:
                # print(line)
                result = re.search("ApplyMode =.+PaintApplyRubThrough.*", line)
                output.write(line)
                if result:
                    output.write(source_string)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        file_name, tool_name = sys.argv[1:]
        file_name = os.path.abspath(file_name)
        process(file_name, tool_name)
