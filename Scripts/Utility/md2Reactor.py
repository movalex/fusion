#!/usr/bin/env python3

import re
import sys
import os
from pathlib import Path

DEFAULT_DIR = Path("~/Desktop").expanduser()
PKG_REQUIRED = "markdown"

try:
    from markdown import markdown
except ModuleNotFoundError:
    script_path = comp.MapPath("Reactor:Deploy/Scripts/Utility")
    sys.path.append(script_path)
    from install_pip_package import pip_install
    pip_install(PKG_REQUIRED)
    sys.exit()


def request_file_names(init_dir: str) -> list:
    from tkinter import filedialog, Tk

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
    with open(file_name + suffix, "w") as out:
        out.write(text)
        print(f"[md2Reactor] created {out.name}")


def main(file_path):
    if not file_path or not file_path.exists() or not file_path.suffix.lower() == ".md":
        print("no markdown file_path selected")
        return

    with open(file_path, "r") as fp:
        text = fp.read()

    file_name, _ = os.path.splitext(file_path)

    bbcode_text = markdown_to_bbcode(text)
    write_file(file_name, bbcode_text, "_bbcode.txt")

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
    comp = fu.GetCurrentComp()
    folder = fu.GetData("md2reactor.path")
    if not folder:
        folder = DEFAULT_DIR
    file_paths = request_file_names(folder)
    process(file_paths)
