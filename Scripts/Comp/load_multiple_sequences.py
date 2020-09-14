
# -*- coding: utf-8 -*-

# Original script provided by ISOTRON, thanks to Helge, suedlich-t.com
# This version walks forward through the folders recursively and loads all the sequences
# update: by Alexey Bogomolov
# email: mail@abogomolov.com
# version: 1.0 09/13/2020
# license: MIT
# Features:
# - walk forward through the folders recursively and load all the sequences or single files 
# - saves last accessed folder to a Fusion data
# - set minimum digits the script should look for at the end of the file
# - use preselect checkbox it you want all the sequences to be marked to import (on by default)


import os
import re

comp = fu.GetCurrentComp()

# Modifiy your colorranges for the loaders here ...
colordict = {
    "Default": {"B": 1.0, "R": 1.0, "__flags": 256, "G": 1.0},
    "Dark Green": {"B": 0.0, "R": 0.0, "__flags": 256, "G": 0.5},
    "Marine": {"B": 0.5, "R": 0.0, "__flags": 256, "G": 0.5},
    "Sand": {"B": 0.25, "R": 0.5, "__flags": 256, "G": 0.5},
    "Lavender": {"B": 1.0, "R": 0.5, "__flags": 256, "G": 0.5},
    "Steel": {"B": 0.75, "R": 0.5, "__flags": 256, "G": 0.5},
    "Grey": {"B": 0.5, "R": 0.5, "__flags": 256, "G": 0.5},
    "PreRender": {"B": 0.69, "R": 1.0, "__flags": 256, "G": 0.0},
}

print("\n|------  Starting Import Script \n|")

dropdict = {
    0.0: "Default",
    1.0: "Dark Green",
    2.0: "Marine",
    3.0: "Sand",
    4.0: "Lavender",
    5.0: "Steel",
    6.0: "Grey",
    7.0: "PreRender",
}

saved_path = fu.GetData("LMPath")

input = comp.AskUser(
    "Load Sequences",
    {
        1.0: {
            1.0: "filepath",
            2.0: "PathBrowse",
            "Name": "Select Path: ",
            "Default": saved_path or "",
        },
        2.0: {
            1.0: "seqdigits",
            2.0: "Slider",
            "Name": "has digits: ",
            "Default": 3,
            "Integer": True,
            "Min": 2,
            "Max": 5,
        },
        3.0: {
            1.0: "preselect",
            2.0: "Checkbox",
            "Name": "Checkbox sequences?",
            "Default": 1,
        },
        4.0: {
            1.0: "color",
            2.0: "Dropdown",
            "Name": "Color",
            "Default": 0,
            "Options": dropdict,
        },
    },
)


def run_folder(input):
    path = input["filepath"]
    path = comp.MapPath(path)
    seqdigits = str(int(input["seqdigits"]))
    preselect = str(input["preselect"])

    print("| Path to search: " + str(path))
    print("| Sequence with " + seqdigits + " or more digits.")

    gen = os.walk(path)
    full_names_dict = {}
    short_seqs = {}

    for root, dir, files in os.walk(path):
        for name in files:
            if not os.path.splitext(name)[1] in [
                ".mov",
                ".mp4",
                ".avi",
                ".mkv",
                ".mxf",
            ]:
                seqname = re.sub(r"\d{" + seqdigits + ",}(\.\w+)$", r"\g<1>", name)
                if not seqname in short_seqs.values():
                    short_seqs[float(len(short_seqs) + 1)] = seqname
                    if not seqname in full_names_dict.keys():
                        full_names_dict[seqname] = os.path.join(root, name)
            else:
                if not name in short_seqs.values():
                    short_seqs[float(len(short_seqs) + 1)] = name
                    if not name in full_names_dict.keys():
                        full_names_dict[name] = os.path.join(root, name)

    sequencelength = len(short_seqs) + 1

    print(
        "| Found "
        + str(sequencelength - 1)
        + " sequence(s)/single file(s) in that folder."
    )

    mycode = 'seqlist = comp.AskUser("Load Sequences", {'

    for i in range(1, sequencelength):
        mycode = (
            mycode
            + str(float(i))
            + ': {1.0: "sequence_'
            + str(i)
            + '", 2.0: "Checkbox", \'Name\':short_seqs['
            + str(float(i))
            + "], 'Default':"
            + preselect
            + ",}, "
        )
    mycode += "})"
    return mycode, full_names_dict, short_seqs


if input:
    fu.SetData("LMPath", input["filepath"])
    command, full_names_dict, short_seqs = run_folder(input)
    exec(command)
    if seqlist:
        comp.Lock()
        for i, short_seq in enumerate(short_seqs.values(), 1):
            if seqlist["sequence_" + str(i)] == 1:
                file_name_without_seq = short_seq
                print("importing: ", file_name_without_seq)
                file_name_with_seq = full_names_dict[file_name_without_seq]
                loader = comp.Loader()
                loader.Clip = file_name_with_seq
                if input["color"] != 0.0:
                    loader.TileColor = colordict[str(dropdict[input["color"]])]
        comp.Unlock()
        print("|\n|------  Import done.\n")
else:
    print("|\n|------  Import canceled.\n")

