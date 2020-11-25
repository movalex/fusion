#!/usr/bin/env python3

import re
import sys
import os
from pathlib import Path

try:
    import BlackmagicFusion as bmd

    fu = bmd.scriptapp("Fusion")
except ImportError:
    # no Fusion found
    pass

DEFAULT_DIR = Path("~/Desktop").expanduser()


def request_file_name(folder):
    from tkinter import filedialog, Tk

    root = Tk()
    root.withdraw()
    md_file = filedialog.askopenfilename(
        initialdir=folder, filetypes=[("Markdown files", ".md .MD")]
    )
    return Path(md_file)


def markdown_to_bbcode(s):
    codes = []

    # def gather_code(m):
    #     codes.append(m.group(3))
    #     return "[code=%d]" % len(codes)

    # def replace_code(m):
    #     return "%s" % codes[int(m.group(1)) - 1]

    def translate(pattern="%s", g=1):
        def inline(m):
            s = m.group(g)
            # s = re.sub(r"(`{3})(\s*)(.*?)\2\1", gather_code, s)
            s = re.sub(r"\B([*_]{2})\b(.+?)\1\B", "[b]\\2[/b]", s)
            return pattern % s

        return inline

    s = re.sub(r"(?m)^!\[\]\((.*?)\)$", "~[img]\\1[/img]", s)
    s = re.sub(r"(?m)\[(.*?)\]\((https?://\S+)\)", "[url=\\2]\\1[/url]", s)
    s = re.sub(r"(?m)(`)(.*?)(`)", "[c]\\2[/c]", s)
    # s = re.sub(r"(?m)    {4}(.*)$", "~[code]\\1[/code]", s)
    s = re.sub(r"(?m)\b([*_]{1})(.*?)\1\b", "[i]\\2[/i]", s)
    s = re.sub(r"(?m)^(\S.*)\n=+\s*$", translate("~[size=200][b]%s[/b][/size]"), s)
    s = re.sub(r"(?m)^(\S.*)\n-+\s*$", translate("~[size=100][b]%s[/b][/size]"), s)
    s = re.sub(r"(?m)^#\s+(.*?)\s*#*$", translate("~[size=200][b]%s[/b][/size]"), s)
    s = re.sub(r"(?m)^##\s+(.*?)\s*#*$", translate("~[size=100][b]%s[/b][/size]"), s)
    s = re.sub(r"(?m)^###\s+(.*?)\s*#*$", translate("~[b]%s[/b]"), s)
    s = re.sub(r"(?m)^> (.*)$", translate("~[quote]%s[/quote]"), s)
    s = re.sub(r"(?m)^[-+*]\s+(.*)$", translate("~[list]\n[*]%s\n[/list]"), s)
    s = re.sub(r"(?m)^\d+\.\s+(.*)$", translate("~[list=1]\n[*]%s\n[/list]"), s)
    s = re.sub(r"(?m)^((?!~).*)$", translate(), s)
    s = re.sub(r"(?m)^~\[", "[", s)
    # s = re.sub(r"(?m)\[/code]\n\[code(=.*?)?]", "\n", s)
    s = re.sub(r"(?m)\[/quote]\n\[quote]", "\n", s)
    s = re.sub(r"(?m)\[/list]\n\[list(=1)?]\n", "", s)
    # s = re.sub(r"(?m)\[code=(\d+)]", replace_code, s)

    return s


def markdown_to_html(text=None):
    try:
        from markdown import markdown

        text = markdown(text)
    except ImportError:
        print(
            "to convert text to HTML, install markdown package with\n"
            "`pip install markdown`"
        )
    return text


def write_file(file_name, text, suffix):
    with open(file_name + suffix, "w") as out:
        out.write(text)
        print(f"created {out.name}")


def main(file_path):
    print(file_path)

    with open(file_path, "r") as fp:
        text = fp.read()

    file_without_extension = os.path.splitext(file_path)[0]

    bbcode_text = markdown_to_bbcode(text)
    write_file(file_without_extension, bbcode_text, "_bbcode.txt")
    atom_text = markdown_to_html(text)
    if atom_text:
        write_file(file_without_extension, atom_text, "_atom.html")

    print("Done!")


if __name__ == "__main__":
    if len(sys.argv) == 2:
        file_path = Path(sys.argv[1]).absolute()
    else:
        folder = ""
        if fu:
            folder = fu.GetData("md2reactor.path")
        if not folder:
            folder = DEFAULT_DIR
        file_path = request_file_name(folder)
    if file_path and file_path.exists():
        if fu:
            fu.SetData("md2reactor.path", file_path.parent)
        if file_path.suffix.lower() == ".md":
            main(file_path)
        else:
            print("no markdown file selected")
