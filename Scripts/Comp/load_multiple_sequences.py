# -*- coding: utf-8 -*-
# by ISOTRON, thanks to Helge, suedlich-t.com
import os
# import glob
import re
import random
import fnmatch

comp.Lock()

# Modifiy your colorranges for the loaders here ...
colordict = {"Default": {'B': 1.0, 'R': 1.0, '__flags': 256, 'G': 1.0},
             "Dark Green": {'B': 0.0, 'R': 0.0, '__flags': 256, 'G': 0.5},
             "Marine": {'B': 0.5, 'R': 0.0, '__flags': 256, 'G': 0.5},
             "Sand": {'B': 0.25, 'R': 0.5, '__flags': 256, 'G': 0.5},
             "Lavender": {'B': 1.0, 'R': 0.5, '__flags': 256, 'G': 0.5},
             "Steel": {'B': 0.75, 'R': 0.5, '__flags': 256, 'G': 0.5},
             "Grey": {'B': 0.5, 'R': 0.5, '__flags': 256, 'G': 0.5},
             "Shit": {'B': 0.0, 'R': 0.5, '__flags': 256, 'G': 0.25},
             "PreRender": {'B': 0.69, 'R': 1.0, '__flags': 256, 'G': 0.0}}


# Rename dictionary for loader renaming

rename_list = [
# Mattes
    ["_mat_a", "MAT_A"],
    ["_mat_b", "MAT_B"],
    ["_mat_c", "MAT_C"],
    ["_mat_d", "MAT_D"],
    ["_mat_e", "MAT_E"],
    ["_mat_f", "MAT_F"],

    ["_mat", "MAT"],

    # Beautys
    ["_bty_a", "BTY_A"],
    ["_bty_b", "BTY_B"],
    ["_bty_c", "BTY_C"],

    ["_bty", "BTY"],

    # Diffuse
    ["_dif_a", "DIF_A"],
    ["_dif_b", "DIF_B"],
    ["_dif_c", "DIF_C"],
    ["_diff_a", "DIF_A"],
    ["_diff_b", "DIF_B"],
    ["_diff_c", "DIF_C"],

    ["_dif", "DIF"],
    ["_diff", "DIF"],

    # Reflection
    ["_rfl_a", "RFL_A"],
    ["_rfl_b", "RFL_B"],
    ["_rfl_c", "RFL_C"],
    ["_rfl_d", "RFL_D"],

    ["_refl_a", "RFL_A"],
    ["_refl_b", "RFL_B"],
    ["_refl_c", "RFL_C"],
    ["_refl_d", "RFL_D"],

    ["_rfl", "RFL"],
    ["_refl", "RFL"],

    # Specular
    ["_spc_a", "SPC_A"],
    ["_spc_b", "SPC_B"],
    ["_spc_c", "SPC_C"],
    ["_spc_d", "SPC_D"],

    ["_spc", "SPC"],


    # Other
    ["_occ", "OCC"],
    ["_nrm", "NORMAL"],
    ["_uv", "UV"],
    ["_uv_", "MB"],
    ["_zdepth", "zDepth"],
    ["_depth", "zDepth"]
    ]

# You can edit this shit as well ... ;)

quotes = {
    1: "D'oh.",
    2: "Me fail English? That's unpossible. ",
    3: "This is the greatest case of false advertising I've seen since I sued the movie “The Never Ending Story.”",
    4: "No children have ever meddled with the Republican Party and lived to tell about it.",
    5: "Don't kid yourself, Jimmy. If a cow ever got the chance, he'd eat you and everyone you care about!",
    6: "The Internet King? I wonder if he could provide faster nudity…",
    7: "Oh, so they have Internet on computers now!",
    8: "I've done everything the Bible says — even the stuff that contradicts the other stuff!",
    9: "Your questions have become more redundant and annoying than the last three “Highlander” movies.",
    10: "Uh, no, you got the wrong number. This is 9-1…2.",
    11: "I'll be back. You can't keep the Democrats out of the White House forever, and when they get in, I'm back on the streets, with all my criminal buddies.",
    12: "When I held that gun in my hand, I felt a surge of power…like God must feel when he's holding a gun. ",
    13: "Dad didn't leave… When he comes back from the store, he's going to wave those pop-tarts right in your face!",
    14: "Remember the time he ate my goldfish? And you lied and said I never had goldfish. Then why did I have the bowl, Bart? *Why did I have the bowl?*",
    15: "Well, he's kind of had it in for me ever since I accidentally ran over his dog. Actually, replace “accidentally” with “repeatedly” and replace “dog” with “son.”",
    16: "Last night's “Itchy and Scratchy Show” was, without a doubt, the worst episode *ever.* Rest assured, I was on the Internet within minutes, registering my disgust throughout the world.",
    17: "I'm normally not a praying man, but if you're up there, please save me, Superman.",
    18: "Save me, Jeebus.",
    19: "I stand by my racial slur.",
    20: "Oh, loneliness and cheeseburgers are a dangerous mix. ",
    }
names = {
    1: "Homer:",
    2: "Ralph:",
    3: "Lionel Hutz:",
    4: "Sideshow Bob: ",
    5: "Troy McClure: ",
    6: "Comic Book Guy: ",
    7: "Homer:",
    8: "Ned Flanders:",
    9: "Comic Book Guy: ",
    10: "Chief Wiggum:",
    11: "Sideshow Bob:",
    12: "Homer:",
    13: "Nelson:",
    14: "Milhouse: ",
    15: "Lionel Hutz:",
    16: "Comic Book Guy:",
    17: "Homer:",
    18: "Homer:",
    19: "Mayor Quimby:",
    20: "Comic Book Guy:",
}

## rename


### ... and now to something completely different:

def rename():
    for i in range (0, len(rename_list)):
        if rename_list[i][0] in longfilename.lower(): ## Name ist in Matrix
            newname = rename_list[i][1]
            print(rename_list[i][0]+ " soll werden: " + rename_list[i][1])
            loader.SetAttrs({'TOOLS_Name': str(rename_list[i][1]), 'TOOLB_NameSet':True})
            return

print('\n|------  Starting Import Script \n|')

randomnumber = random.randint(1,len(quotes))
randomquote = quotes[randomnumber]
randomname = names[randomnumber]

dropdict = {0.0: "Default", 1.0: "Dark Green", 2.0: "Marine", 3.0: "Sand", 4.0: "Lavender", 5.0: "Steel", 6.0: "Grey", 7.0: "Shit", 8.0: "PreRender"}

input = comp.AskUser("Suedlich-t  >>>  Import Some Sequences",
                        {1.0: {1.0: "filepath", 2.0: "PathBrowse", 'Name': "Select Path: ", 'Default':'',},
                         2.0: {1.0: "seqdigits", 2.0: "Slider", 'Name': "Sequence has at least so many digits: ", 'Default': 3, 'Integer': True, 'Min': 2, 'Max': 5},
                         3.0: {1.0: "preselect", 2.0: "Checkbox", 'Name': "Preselect all sequences", 'Default':1,},
                         4.0: {1.0: "color", 2.0: "Dropdown", 'Name': "Color", 'Default':0, 'Options': dropdict},
                         5.0: {1.0: "rename", 2.0: "Checkbox", 'Name': "Try to shorten names?", 'Default':1,},
                         })


if input:
    path = input['filepath']
    path = comp.MapPath(path)
    seqdigits = str(int(input['seqdigits']))
    preselect = str(input['preselect'])

    print("| Path to search: " + str(path))
    print("| Sequence with " + seqdigits + " or more digits.")

    # Dictionary
    sequencedict ={0.0 : "Kann nix, weiss nix, leck mich!"}
    orgnamedict = {}
    listing = os.listdir(path)



    for infile in listing:
        # check: is file?
        if fnmatch.fnmatch(infile, '*.*'):
            #print(infile + " ist eine datei")

            seqname = re.sub(r'\d{'+seqdigits+',}', "", infile)

            if not seqname in sequencedict.values():
                # ins dict einsetzen
                sequencedict[float(len(sequencedict))] =  seqname
                if not seqname in orgnamedict.keys():
                    #ins orgdict einsetzen
                    orgnamedict[seqname] = infile


        #print(str(seqname) + " wird zu " + str(infile))

    #print("jetzt kommt des dict:")
    #print(sequencedict)

    sequencelength = len(sequencedict)
    print("| Found "+str(sequencelength-1)+" sequence(s)/single file(s) in that folder.")

    # neuen dialog erstellen ...

    mycode = 'seqlist = comp.AskUser("Import Some Sequences", {'

    for i in range(1,sequencelength):
        mycode = mycode + str(float(i)) + ': {1.0: "sequence_' + str(i) + '", 2.0: "Checkbox", \'Name\':sequencedict[' + str(float(i)) + '], \'Default\':' + preselect + ',}, '
    mycode = mycode + str(float(sequencelength+1)) + ': {1.0: "bla", 2.0: "Text", \'Name\':"' + randomname +'", \'Default\': "' + randomquote + '", \'ReadOnly\': True, \'Wrap\': True,},'
    mycode = mycode+'})'

    # ... und den dialog ausführen!
    exec (mycode)

    if seqlist:
        # loader herholen
        # comp.Lock()
        for i in range(1,sequencelength):
            if seqlist['sequence_'+str(i)] == 1:
                # loader = comp.Loader
                shortfilename = sequencedict[float(i)]
                # print("kurz: "+ shortfilename)
                longfilename = orgnamedict[shortfilename]
                # print("lang: "+ longfilename)
                # rename if desired
                print(longfilename)

                if input['rename'] == 1:
                    loader = comp.Loader()
                    loader.Clip = os.path.join(path + longfilename)
                    rename()
                   # for i in range (0, len(rename_list)):
                   #     if rename_list[i][0] in longfilename.lower(): ## Name ist in Matrix
                   #         newname = rename_list[i][1]
                   #         print(rename_list[i][0]+ " soll werden: " + rename_list[i][1])
                   #         loader.SetAttrs({'TOOLS_Name': str(rename_list[i][1]), 'TOOLB_NameSet':True})
                   #         return
                else:  # keine Umbenennung:
                    loader = comp.Loader()
                    loader.Clip = os.path.join(path + longfilename)
                    if longfilename.lower() in rename_list:
                        print(longfilename.lower() + " hat es!!!")

                if input['color'] != 0.0:
                    loader.TileColor = colordict[str(dropdict[input['color']])]
        print("|\n|------  Import done.\n")
    else:
        print("|\n|------  Import canceled.\n")

else:
    print("|\n|------  Import canceled.\n")
comp.Unlock()
print("|\n|------  unlocked.\n")
