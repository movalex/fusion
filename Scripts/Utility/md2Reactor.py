#!/usr/bin/env python3

import re
import sys
import os
from pathlib import Path

DEFAULT_DIR = Path("~/Desktop").expanduser()
PKG_REQUIRED = ["markdown", "mistune"]

try:
    from markdown import markdown
    import mistune
    from mistune import BaseRenderer, Markdown
    from tkinter import Tk, filedialog
except ModuleNotFoundError:
    script_path = comp.MapPath("Reactor:Deploy/Scripts/Utility")
    sys.path.append(script_path)
    from install_pip_package import pip_install

    for package in PKG_REQUIRED:
        pip_install(package)
    sys.exit()


class BBCodeRenderer(BaseRenderer):
    def blank_line(self, *args, **kwargs):
        return ""

    def heading(self, text, level, **attrs):
        # {'type': 'heading', 'attrs': {'level': 1}, 'style': 'axt', 'children': [{'type': 'text', 'raw': 'First Level'}]}
        levels = {1: "size=200", 2: "size=150", 3: "size=100"}
        _level = text["attrs"]["level"]
        heading_size = levels[_level]
        raw_text = None
        if "children" in text:
            for child in text["children"]:
                if "type" in child and child["type"] == "text" and "raw" in child:
                    raw_text = child["raw"]
                    break
        return f"[{heading_size}][b]{raw_text}[/b][/size]\n"

    def parse_element_to_bbcode(self, element):
        if element["type"] == "paragraph":
            bbcode = ""
            for child in element["children"]:
                bbcode += self.parse_element_to_bbcode(child)
            return bbcode + "\n"
        elif element["type"] == "link":
            url = element["attrs"]["url"]
            bbcode = f"[url={url}]"
            for child in element["children"]:
                bbcode += self.parse_element_to_bbcode(child)
            bbcode += "[/url]"
            return bbcode
        elif element["type"] == "image":
            url = element["attrs"]["url"]
            bbcode = f"[img]{url}[/img]"
            return bbcode
        elif element["type"] == "block_quote":
            bbcode = "[quote]"
            for child in element["children"]:
                bbcode += self.parse_element_to_bbcode(child)
            bbcode += "[/quote]"
            return bbcode
        elif element["type"] == "codespan":
            bbcode = "[c]" + element["raw"] + "[/c]"
            return bbcode
        elif element["type"] == "emphasis":
            bbcode = "[i]"
            for child in element["children"]:
                bbcode += self.parse_element_to_bbcode(child)
            bbcode += "[/i]"
            return bbcode
        elif element["type"] == "strong":
            bbcode = "[b]"
            for child in element["children"]:
                bbcode += self.parse_element_to_bbcode(child)
            bbcode += "[/b]"
            return bbcode
        elif element["type"] == "double_emphasis":
            bbcode = "[b]"
            for child in element["children"]:
                bbcode += self.parse_element_to_bbcode(child)
            bbcode += "[/b]"
            return bbcode
        elif element["type"] == "text":
            return element["raw"]
        else:
            return ""

    def paragraph(self, text, state=None):
        return self.parse_element_to_bbcode(text)

    def extract_and_format_list(self, element):
        # Initialize an empty list to hold the raw text items
        list_items = []

        # Check if the 'children' key exists and is a list
        if "children" in element and isinstance(element["children"], list):
            # Loop through each child (which should be a list item)
            for child in element["children"]:
                # Recursively call this function if the child has its own 'children'
                if "children" in child:
                    list_items.extend(self.extract_and_format_list(child))
                # If the child is a 'text' type, append the 'raw' text to the list_items
                elif child.get("type") == "text" and "raw" in child:
                    list_items.append(child["raw"])
        # Return the list of raw text items
        return list_items

    def list(self, body, ordered, **attrs):
        # tag = "=1" if ordered else ""
        tag = ""
        # Extract the raw text from the data structure
        list_items = self.extract_and_format_list(body)
        # Format the list items with BBCode syntax
        formatted_list = (
            f"[list{tag}]\n"
            + "\n".join(f"[*]{item}" for item in list_items)
            + "\n[/list]\n"
        )

        return formatted_list

    def block_code(self, code, info=None):
        # {'type': 'block_code', 'raw': 'print("Hello, world!")\n', 'style': 'fenced', 'marker': '```', 'attrs': {'info': 'python'}}
        raw_code = code["raw"]
        syntax = code["attrs"].get("info", "")
        return f"[code]{raw_code}[/code]\n"

    def block_quote(self, text, state=None):
        return self.parse_element_to_bbcode(text)

    def link(self, link, title, text):
        return "[url={link}]{text}[/url]".format(link=link, text=text)

    def image(self, src, title, text):
        return "[img]{src}[/img]".format(src=src)

    # Add more methods as needed to cover the Markdown features you use


def request_file_names(init_dir: str) -> list:
    root = Tk()
    root.withdraw()
    md_files = filedialog.askopenfilenames(
        initialdir=init_dir, filetypes=[("Markdown files", ".md .MD")]
    )
    if md_files:
        return md_files


def translate(pattern: str, g=1):
    def inline(match):
        s = match.group(g)
        return pattern.format(s)

    return inline


def mistune_to_bbcode(markdown_text):
    # Initialize the Markdown parser with our BBCode renderer
    renderer = BBCodeRenderer()
    markdown_parser = Markdown(renderer=renderer)

    # Convert Markdown to BBCode
    bbcode_text = markdown_parser(markdown_text)
    return bbcode_text


def markdown_to_bbcode(s):
    s = re.sub(r"(?m)\[(.*?)\]\((https?:\/\/\S+)\)", "[url=\\2]\\1[/url]", s)
    s = re.sub(r"(?m)([*_]{2})(\w+?)\1", "[b]\\2[/b]", s)
    s = re.sub(r"(?m)(?:^| )[^@#\s_`]?_([^_]+)_", "[i]\\1[/i]", s)
    s = re.sub(r"(?m)\B([*])\b(\S.+?)\1", "[i]\\2[/i]", s)
    s = re.sub(r"(?m)\B@(.*?)(['\s.,:!?\"])", "[mention]\\1[/mention]\\2", s)
    s = re.sub(r"(?m) {4}(.*)$", "~[code]\\1[/code]", s)
    s = re.sub(r"(?m)^!\[\]\((.*?)\)$", "~[img]\\1[/img]", s)
    s = re.sub(r"(?m)^(\S.*)\n=+\s*$", translate("~[size=200][b]{}[/b][/size]"), s)
    s = re.sub(r"(?m)(`)(.*?)(`)", "[c]\\2[/c]", s)
    s = re.sub(r"(?m)^(\S.*)\n-+\s*$", translate("~[size=100][b]{}[/b][/size]"), s)
    s = re.sub(r"(?m)^#\s+(.*?)\s*#*$", translate("~[size=200][b]{}[/b][/size]"), s)
    s = re.sub(r"(?m)^##\s+(.*?)\s*#*$", translate("~[size=100][b]{}[/b][/size]"), s)
    s = re.sub(r"(?m)^###\s+(.*?)\s*#*$", translate("~[b]{}[/b]"), s)
    s = re.sub(r"(?m)^> (.*)$", translate("~[quote]{}[/quote]"), s)
    s = re.sub(r"(?m)^[-+*]\s+(.*)$", translate("~[list]\n[*]{}\n[/list]"), s)
    s = re.sub(r"(?m)^\d+\.\s+(.*)$", translate("~[list=1]\n[*]{}\n[/list]"), s)
    s = re.sub(r"(?m)^((?!~).*)$", translate("{}"), s)
    s = re.sub(r"(?m)^~\[", "[", s)
    s = re.sub(r"(?m)\[/code]\n\[code(=.*?)?]", "\n", s)
    s = re.sub(r"(?m)\[code(=.*?)?]\[/code]", "", s)
    s = re.sub(r"(?m)\[/quote]\n\[quote]", "\n", s)
    s = re.sub(r"(?m)\[/list]\n\[list(=1)?]\n", "", s)

    return s


def write_file(file_name, text, suffix):
    with open(file_name + suffix, "w", encoding="utf-8") as out:
        out.write(text)
        print(f"[md2Reactor] created {out.name}")


def main(file_path):
    if not file_path or not file_path.exists() or not file_path.suffix.lower() == ".md":
        print("no markdown file_path selected")
        return

    with open(file_path, "r", encoding="utf-8") as fp:
        text = fp.read()

    file_name, _ = os.path.splitext(file_path)

    bbcode_text = mistune_to_bbcode(text)
    write_file(file_name, bbcode_text, "_mistune_bbcode.txt")

    atom_text = markdown(text)
    if atom_text:
        write_file(file_name, atom_text, "_atom.html")

    print("Done!")


def process(file_list):
    if not file_list:
        return
    for file_path in file_list:
        file_path = Path(file_path).absolute()
        if not file_path.exists():
            return
        main(file_path)
    fu.SetData("md2reactor.path", str(file_path.parent))


if __name__ == "__main__":
    # comp = fu.GetCurrentComp()
    # folder = fu.GetData("md2reactor.path")
    # if not folder:
    #     folder = DEFAULT_DIR
    # file_paths = request_file_names(folder)
    # process(file_paths)
    main(Path("/Users/videopro/Desktop/test note.md"))
