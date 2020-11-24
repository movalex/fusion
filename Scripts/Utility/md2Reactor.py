#!/usr/bin/env python

import re
import sys
import os
from pathlib import Path

try:
    import BlackmagicFusion as bmd

    fu = bmd.scriptapp("Fusion")
except ImportError:
    print("no Fusion app found running")
    bmd = None

DEFAULT_DIR = Path("~/Desktop").expanduser()


def request_file_name(path):
    try:
        from tkinter import filedialog, Tk
    except ImportError:
        print("no tkinter lirary found")
        return
    root = Tk()
    root.withdraw()
    md_file = filedialog.askopenfilename(
        initialdir=path, filetypes=[("Markdown files", ".md .MD")]
    )
    return md_file


def markdown_to_bbcode(s):
    links = {}
    codes = []

    def gather_link(m):
        links[m.group(1)] = m.group(2)
        return ""

    def replace_link(m):
        return "[url=%s]%s[/url]" % (links[m.group(2) or m.group(1)], m.group(1))

    def gather_code(m):
        codes.append(m.group(3))
        return "[c=%d]" % len(codes)

    def replace_code(m):
        return "%s" % codes[int(m.group(1)) - 1]

    def translate(p="%s", g=1):
        def inline(m):
            s = m.group(g)
            s = re.sub(r"(`+)(\s*)(.*?)\2\1", gather_code, s)
            s = re.sub(r"\[(.*?)\]\[(.*?)\]", replace_link, s)
            s = re.sub(r"\[(.*?)\]\((.*?)\)", "[url=\\2]\\1[/url]", s)
            # s = re.sub(r"(https?:\S+)", "[url=\\1]\\1[/url]", s)
            s = re.sub(r"\B([*_]{2})\b(.+?)\1\B", "[b]\\2[/b]", s)
            return p % s

        return inline

    s = re.sub(r"(?m)^\[(.*?)]:\s*(\S+).*$", gather_link, s)
    s = re.sub(r"(?m)^\s{4}(.*)$", "~[code]\\1[/code]", s)
    s = re.sub(r"(?m)(`)(.*?)(`)", "[c]\\2[/c]", s)
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
    s = re.sub(r"(?m)\[/code]\n\[code(=.*?)?]", "\n", s)
    s = re.sub(r"(?m)\[/quote]\n\[quote]", "\n", s)
    s = re.sub(r"(?m)\[/list]\n\[list(=1)?]\n", "", s)
    s = re.sub(r"(?m)\[code=(\d+)]", replace_code, s)

    return s


def write_file(file_name, text, suffix=None, do_markdown=False):
    with open(file_name + suffix, "w") as out:
        if do_markdown:
            try:
                from markdown import markdown

                text = markdown(text)
            except ImportError:
                print(
                    "to convert text to HTML, install markdown package with `pip"
                    " install markdown` command"
                )
        out.write(text)
        print(f"created {out.name}")


def main(folder_name):
    if len(sys.argv) == 2:
        file_path = Path(sys.argv[1]).absolute()
        if not file_path.exists():
            print(f"file {file_path} not found")
            return
    else:
        file_path = request_file_name(folder_name)
        if file_path and bmd:
            fu.SetData("md2reactor.path", file_path)

    if not file_path:
        print("no markdown file selected")
        return

    file_name, ext = os.path.splitext(file_path)
    with open(file_path, "r") as fp:
        text = fp.read()

    bbcode = markdown_to_bbcode(text)
    write_file(file_name, bbcode, "_bbcode.txt")
    write_file(file_name, text, "_atom.html", True)

    print("Done!")


if __name__ == "__main__":
    folder = ""
    if bmd:
        folder = fu.GetData("md2reactor.path")
    if not folder:
        folder = DEFAULT_DIR
    main(folder)
