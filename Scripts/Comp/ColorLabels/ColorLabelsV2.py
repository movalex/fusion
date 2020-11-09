'''
COLOR LABELS
---------------------------------------------------------------
Version: v1.0
Last update: 17 June 2018

Description: Color Labels is a tool to assign quickly a color to
TileColor and TextColor for items on the flow. Tool is based on
the code of ui.ColorPicker snippet example from Greg Bovine.

Installation: Place ColorLabels folder in Fusion:/Scripts/Comp

Usage:  A) Run the script, then select nodes what you want assign
           color and hit the button Assign Color.
           You can assign colors from presets palette directly
           by hit its colored button.

        B) Press Store Mode button to enter in store mode, then
           you can store the color selected in the color picker
           simply pressing the colored button where you want store
           the color.

-----------------------------------------------------------------
Author: Alberto GZ
Email: albertogzgz@gmail.com
Website: albertogz.com

'''

import os
import os.path
import json
import colorsys


###  CONFIG FILE DEFINITION  ###
comp = fu.GetCurrentComp()
# pathname = os.path.dirname(sys.argv[0])
pathname = comp.MapPath('GIT:Scripts/Comp')
filename = 'ColorLabels/ColorLabels.conf'
cfg_file = os.path.join(pathname, filename)

def createConfigFile():
    global data
    # Definition default data for config file
    data = {}
    data['colors'] = []
    data['colors'].append({'R': 0.3, 'G': 0.2, 'B': 0.2})
    data['colors'].append({'R': 0.2, 'G': 0.3, 'B': 0.2})
    data['colors'].append({'R': 0.2, 'G': 0.2, 'B': 0.3})
    data['colors'].append({'R': 0.45, 'G': 0.4, 'B': 0.15})
    data['colors'].append({'R': 0.2, 'G': 0.4, 'B': 0.4})
    data['colors'].append({'R': 0.4, 'G': 0.2, 'B': 0.4})
    data['colors'].append({'R': 0.6, 'G': 0.6, 'B': 0.6})
    data['colors'].append({'R': 0.4, 'G': 0.4, 'B': 0.4})
    data['colors'].append({'R': 0.15, 'G': 0.15, 'B': 0.15})
    # Write config file
    with open(cfg_file, 'w') as outfile:
        json.dump(data, outfile)
    print('File config succesfully created.')


def readConfigFile():
    global data
    # Read config file
    with open(cfg_file) as json_file:
        data = json.load(json_file)

###  ASSIGNMENT DATA FROM CONFIG  ###


def colorVars():
    global data
    global color0
    global color1
    global color2
    global color3
    global color4
    global color5
    global color6
    global color7
    global color8
    # Assign config data to variables
    color0 = data['colors'][0]
    color1 = data['colors'][1]
    color2 = data['colors'][2]
    color3 = data['colors'][3]
    color4 = data['colors'][4]
    color5 = data['colors'][5]
    color6 = data['colors'][6]
    color7 = data['colors'][7]
    color8 = data['colors'][8]

if os.path.isfile(cfg_file) and os.access(cfg_file, os.R_OK):
    print('File config exists and is readable')
    readConfigFile()
    colorVars()
else:
    print('File config not found. Creating config file...')
    # Create new config file
    createConfigFile()
    colorVars()


# Window vars
xpos = 100
ypos = 300
width = 230
height = 450

# Color conversion vars
hsvColor = {'H': 0.5, 'S': 0.5, 'V': 0.5}
hsv2rgb = colorsys.hsv_to_rgb(hsvColor['H'], hsvColor['S'], hsvColor['V'])
rgbColor = {'R': hsv2rgb[0], 'G': hsv2rgb[1], 'B': hsv2rgb[2]}


###  UI DEFINITION  ###

ui = fu.UIManager
disp = bmd.UIDispatcher(ui)

###  MAIN WINDOW  ###
dlg = disp.AddWindow({'ID': 'ColorLabels', 'WindowTitle': 'ColorLabels', 'Geometry': [xpos, ypos, width, height]},
    [
        ui.VGroup({'Spacing': 0, },
        [
            # Add your GUI elements here:
            ui.VGroup({'Spacing': 5, },
            [
                ui.HGroup({'Spacing': 5, },
                [
                    ui.Button({'ID': 'BGColor',
                                'Text': 'BG Color',
                                'Checkable': True,
                                }),
                    ui.Button({'ID': 'TXColor',
                                'Text': 'Text Color',
                                'Checkable': True
                                }),
                ]),

                ### HSV COLOR SELECTOR GUI ELEMENTS ###
                #
                ui.VGap(5),
                ui.VGroup({'Spacing': 5, 'Weight': 1.0},
                [
                    ui.Button({'ID': 'ColorBox',
                                'Text': '',
                                'BackgroundColor': rgbColor,
                                'Geometry': [0, 0, 30, 50 ],
                                }),

                    ui.HGroup({'Spacing': 5, 'Weight': 1.0},
                    [
                        ui.Label({'ID': 'HueLabel', 'Text': 'Hue', }),
                        ui.Slider({'ID': 'HueSlider', 'Events': {'SliderMoved': True, 'Activated': True } }),
                        ui.LineEdit({'ID': 'HueLineEdit', 'Events': {'TextEdited': True, 'Activated': True } }),
                    ]),

                    ui.HGroup({'Spacing': 5, 'Weight': 1.0},
                    [
                        ui.Label({'ID': 'SatLabel', 'Text': 'Sat', }),
                        ui.Slider({'ID': 'SatSlider', 'Events': {'SliderMoved': True, 'Activated': True } }),
                        ui.LineEdit({'ID': 'SatLineEdit', 'Events': {'TextEdited': True, 'Activated': True } }),
                    ]),

                    ui.HGroup({'Spacing': 5, 'Weight': 1.0},
                    [
                        ui.Label({'ID': 'ValLabel', 'Text': 'Val', }),
                        ui.Slider({'ID': 'ValSlider', 'Events': {'SliderMoved': True, 'Activated': True } }),
                        ui.LineEdit({'ID': 'ValLineEdit', 'Events': {'TextEdited': True, 'Activated': True } }),
                    ]),
                ]),
                ui.VGap(5),
                #
                ###

                ui.HGroup({'Spacing': 5, },
                [
                    ui.Button({'ID': 'ResetColor', 'Text': 'Reset color' }),
                    ui.Button({'ID': 'AssignColor', 'Text': 'Assign color' }),
                ]),

                ui.Label({'ID': 'L', 'Text': 'Preset colors' }),
                ui.HGroup({'Spacing': 5, },
                [
                    ui.Button({'ID': 'Store', 'Text': 'Store Mode', 'Checkable': True }),
                    ui.Button({'ID': 'DefaultConfig', 'Text': 'Default colors' }),
                ]),

                ui.HGroup({'Spacing': 8, },
                [
                    ui.VGroup({'Spacing': 8, },
                    [
                        ui.Button({'ID': 'c0', 'Text': '', 'BackgroundColor': color0, }),
                        ui.Button({'ID': 'c1', 'Text': '', 'BackgroundColor': color1, }),
                        ui.Button({'ID': 'c2', 'Text': '', 'BackgroundColor': color2, }),
                    ]),

                    ui.VGroup({'Spacing': 8, },
                    [
                        ui.Button({'ID': 'c3', 'Text': '', 'BackgroundColor': color3, }),
                        ui.Button({'ID': 'c4', 'Text': '', 'BackgroundColor': color4, }),
                        ui.Button({'ID': 'c5', 'Text': '', 'BackgroundColor': color5, }),
                    ]),

                        ui.VGroup({'Spacing': 8, },
                    [
                        ui.Button({'ID': 'c6', 'Text': '', 'BackgroundColor': color6, }),
                        ui.Button({'ID': 'c7', 'Text': '', 'BackgroundColor': color7, }),
                        ui.Button({'ID': 'c8', 'Text': '', 'BackgroundColor': color8, }),
                    ]),
                ]),

                ui.VGap(10),
                ui.HGroup({'Spacing': 5, },
                [
                    ui.Button({'ID': 'Help', 'Text': 'Help', }),
                    ui.Button({'ID': 'About', 'Text': 'About' }),
                ]),

            ]),

        ]),
    ])



### ABOUT WINDOW ###
def AboutWindow():
    url = 'http://albertogz.com'
    email = 'albertogzgz@gmail.com'
    dlg = disp.AddWindow({'ID': 'AboutWin',
                            'WindowTitle': 'About',
                            'Geometry': [ xpos, ypos, 300, 300 ],
                            'WindowFlags': {'Window': True, 'WindowStaysOnTopHint': True},
                            },
    [
        ui.VGroup({'Weight': 0, },
        [
            ui.TextEdit({'ID': 'AboutText',
                            'ReadOnly': True,
                            'Alignment': {'AlignHCenter': True, 'AlignTop': True},
                            'HTML': '<h3>COLOR LABELS</h3>\n<p>Version: v1.0\n<p>Last update: 17 June 2018\n<p>Color Labels is a tool to assign quickly a color to TileColor and TextColor for items on the flow. Tool is based on the code of ui.ColorPicker snippet example from Greg Bovine.'
                             }),
            ui.VGroup({'Weight': 0, },
            [
                ui.Label({'ID': "url",
                            'Text': 'Web: <a href="' + url + '">' + url + '</a>',
                            'Alignment': {'AlignHCenter': True, 'AlignTop': True},
                            'WordWrap': True,
                            'OpenExternalLinks': True,
                            }),

                ui.Label({'ID': "email",
                            'Text': 'Email: <a href="mailto:' + email + '">' + email + '</a>',
                            'Alignment': {'AlignHCenter': True, 'AlignTop': True},
                            'WordWrap': True,
                            'OpenExternalLinks': True,
                            }),
            ]),
            ui.VGap(10),
            ui.VGroup({'Weight': 0, },
            [
                ui.Button({'ID': 'CloseAbout', 'Text': 'Close', }),
            ]),
        ]),
    ])

    # The window was closed
    def _func(ev):
        disp.ExitLoop()
    dlg.On.AboutWin.Close = _func

    def _func(ev):
        disp.ExitLoop()
    dlg.On.CloseAbout.Clicked = _func

    dlg.Show()
    disp.RunLoop()
    dlg.Hide()


### HELP WINDOW ###
def HelpWindow():
    dlg = disp.AddWindow({'ID': 'HelpWin',
                            'WindowTitle': 'Help',
                            'Geometry': [ xpos, ypos, 300, 300 ],
                            'WindowFlags': {'Window': True, 'WindowStaysOnTopHint': True},
                            },
    [
        ui.VGroup({'Weight': 0, },
        [
            ui.TextEdit({'ID': 'HelpText',
                        'ReadOnly': True,
                        'Alignment': {'AlignHCenter': True, 'AlignTop': True},
                        'HTML': '<h3>USAGE</h3>\n<p>A) Run the script, then select nodes what you want assign color and hit the button Assign Color. <p>B) Press Store Mode button to enter in store mode, then you can store the color selected in the color picker simply pressing the colored button where you want store the color.'
                        }),

            ui.VGap(10),
            ui.VGroup({'Weight': 0, },
            [
                ui.Button({'ID': 'CloseHelp', 'Text': 'Close', }),
            ]),
        ]),
    ])

    # The window was closed
    def _func(ev):
        disp.ExitLoop()
    dlg.On.HelpWin.Close = _func

    def _func(ev):
        disp.ExitLoop()
    dlg.On.CloseHelp.Clicked = _func

    dlg.Show()
    disp.RunLoop()
    dlg.Hide()


itm = dlg.GetItems()
toollist = comp.GetToolList(True)
itm['BGColor'].Checked = True
store = 0
# HUE Slider/LineEdit default values
itm['HueSlider'].Value = hsvColor['H'] * 100
itm['HueLineEdit'].Text = str(hsvColor['H'])

itm['SatSlider'].Value = hsvColor['S'] * 100
itm['SatLineEdit'].Text = str(hsvColor['S'])

itm['ValSlider'].Value = hsvColor['V'] * 100
itm['ValLineEdit'].Text = str(hsvColor['V'])


###  FUNCTIONS DEFINITION  ###

def SetToolColors(bg, txt):
    for tool in toollist.values():
        if bg:
            tool.TileColor = bg
        if txt:
            tool.TextColor = txt

# BGColor/TXColor pseudo-MultiButton
def _func(ev):
    itm['BGColor'].Checked = True
    itm['TXColor'].Checked = False
dlg.On.BGColor.Clicked = _func


def _func(ev):
    itm['BGColor'].Checked = False
    itm['TXColor'].Checked = True
dlg.On.TXColor.Clicked = _func


# Open About window
def _func(ev):
    AboutWindow()
dlg.On.About.Clicked = _func

# Open Help window
def _func(ev):
    HelpWindow()
dlg.On.Help.Clicked = _func

# The window was closed
def _func(ev):
    disp.ExitLoop()
dlg.On.ColorLabels.Close = _func

# Restore default colors
def reasignColorsToButtons():
    color = [color0, color1, color2, color3, color4, color5, color6, color7, color8]
    btnid = ['c{}'.format(x) for x in range(9)]
    for i in range(len(color)):
        itm[btnid[i]].BackgroundColor = color[i]
        print(i)

def _func(ev):
    os.remove(cfg_file)
    createConfigFile()
    readConfigFile()
    colorVars()
    reasignColorsToButtons()
dlg.On.DefaultConfig.Clicked = _func

##############  HSV COLOR SELECTOR  ############

# HUE slider
def _func(ev):
    global hsvColor
    global rgbColor
    hsvColor['H'] = ev['Value'] / 100
    hsv2rgb = colorsys.hsv_to_rgb(hsvColor['H'], hsvColor['S'], hsvColor['V'])
    rgbColor = {'R': hsv2rgb[0], 'G': hsv2rgb[1], 'B': hsv2rgb[2]}
    itm['ColorBox'].BackgroundColor = rgbColor
    itm['HueLineEdit'].Text = str(hsvColor['H'])
dlg.On.HueSlider.SliderMoved = _func

# Set HueSlider position from HueLineEdit value
def _func(ev):
    global hsvColor
    global rgbColor
    try:
        hsvColor['H'] = float(ev['Text'])
    except (ValueError, Exception):
        print('No valid')
    hsv2rgb = colorsys.hsv_to_rgb(hsvColor['H'], hsvColor['S'], hsvColor['V'])
    rgbColor = {'R': hsv2rgb[0], 'G': hsv2rgb[1], 'B': hsv2rgb[2]}
    itm['ColorBox'].BackgroundColor = rgbColor
    itm['HueSlider'].Value = hsvColor['H'] * 100
dlg.On.HueLineEdit.TextEdited = _func

# SATURATION slider
def _func(ev):
    global hsvColor
    global rgbColor
    hsvColor['S'] = ev['Value'] / 100
    hsv2rgb = colorsys.hsv_to_rgb(hsvColor['H'], hsvColor['S'], hsvColor['V'])
    rgbColor = {'R': hsv2rgb[0], 'G': hsv2rgb[1], 'B': hsv2rgb[2]}
    itm['ColorBox'].BackgroundColor = rgbColor
    itm['SatLineEdit'].Text = str(hsvColor['S'])
dlg.On.SatSlider.SliderMoved = _func

# Set SatSlider position from SatLineEdit value
def _func(ev):
    global hsvColor
    global rgbColor
    try:
        hsvColor['S'] = float(ev['Text'])
    except (ValueError, Exception):
        print('No valid')
    hsv2rgb = colorsys.hsv_to_rgb(hsvColor['H'], hsvColor['S'], hsvColor['V'])
    rgbColor = {'R': hsv2rgb[0], 'G': hsv2rgb[1], 'B': hsv2rgb[2]}
    itm['ColorBox'].BackgroundColor = rgbColor
    itm['SatSlider'].Value = hsvColor['S'] * 100
dlg.On.SatLineEdit.TextEdited = _func

# VALUE slider
def _func(ev):
    global hsvColor
    global rgbColor
    hsvColor['V'] = ev['Value'] / 100
    hsv2rgb = colorsys.hsv_to_rgb(hsvColor['H'], hsvColor['S'], hsvColor['V'])
    rgbColor = {'R': hsv2rgb[0], 'G': hsv2rgb[1], 'B': hsv2rgb[2]}
    itm['ColorBox'].BackgroundColor = rgbColor
    itm['ValLineEdit'].Text = str(hsvColor['V'])
dlg.On.ValSlider.SliderMoved = _func

# Set ValSlider position from ValLineEdit value
def _func(ev):
    global hsvColor
    global rgbColor
    try:
        hsvColor['V'] = float(ev['Text'])
    except (ValueError, Exception):
        print('No valid')
    hsv2rgb = colorsys.hsv_to_rgb(hsvColor['H'], hsvColor['S'], hsvColor['V'])
    rgbColor = {'R': hsv2rgb[0], 'G': hsv2rgb[1], 'B': hsv2rgb[2]}
    itm['ColorBox'].BackgroundColor = rgbColor
    itm['ValSlider'].Value = hsvColor['V'] * 100
dlg.On.ValLineEdit.TextEdited = _func


# Assign color to already selected items
# def _func(ev):
    # SetToolColors(ev['Color'], None)
    # global currentColor
    # currentColor = ev['Color']
# dlg.On.Color.ColorChanged = _func

# Assign color to selected items after open window
def _func(ev):
    toollist = comp.GetToolList(True).values()
    global currentColor
    currentColor = rgbColor
    for tool in toollist:
        if itm['BGColor'].Checked:
            tool.TileColor = currentColor
            print('Backgroundcolor: ' + str(currentColor))
        elif itm['TXColor'].Checked:
            tool.TextColor = currentColor
            print('Textcolor: ' + str(currentColor))
dlg.On.AssignColor.Clicked = _func


# Reset color to selected items after open window
def _func(ev):
    toollist = comp.GetToolList(True).values()
    for tool in toollist:
        if itm['BGColor'].Checked:
            tool.TileColor = None
            print('BackgroundColor setted to default')
        elif itm['TXColor'].Checked:
            tool.TextColor = None
            print('TextColor setted to default')
dlg.On.ResetColor.Clicked = _func


# Switch store mode
def _func(ev):
    global store
    if store == 0:
        store = 1
        print('Mode assign color')
        # Deactivate buttons
        itm['BGColor'].Enabled = False
        itm['TXColor'].Enabled = False
        itm['AssignColor'].Enabled = False
        itm['ResetColor'].Enabled = False
    elif store == 1:
        store = 0
        print('Mode store color')
        # Activate buttons
        itm['BGColor'].Enabled = True
        itm['TXColor'].Enabled = True
        itm['AssignColor'].Enabled = True
        itm['ResetColor'].Enabled = True
    #print(store)
dlg.On.Store.Clicked = _func


# Selection from preset colors
color = [color0, color1, color2, color3, color4, color5, color6, color7, color8]
btnid = ['c{}'.format(x) for x in range(9)]


def selColor(n):
    toollist = comp.GetToolList(True).values()
    global currentColor
    currentColor = rgbColor
    if store == 0:
        for tool in toollist:
            if itm['BGColor'].Checked:
                tool.TileColor = color[n]
                print('Backgroundcolor: ' + str(color[n]))
            elif itm['TXColor'].Checked:
                tool.TextColor = color[n]
                print('Textcolor: ' + str(color[n]))
    elif store == 1:
        color[n] = currentColor
        itm[btnid[n]].BackgroundColor = currentColor
        #Store preset color in config file
        with open(cfg_file, 'r+') as f:
            data = json.load(f)
            data['colors'][n] = color[n]
            f.seek(0)
            f.write(json.dumps(data))
            f.truncate()


# Preset colors buttons events

def _func(ev):
    n = 0
    selColor(n)
dlg.On.c0.Clicked = _func

def _func(ev):
    n = 1
    selColor(n)
dlg.On.c1.Clicked = _func

def _func(ev):
    n = 2
    selColor(n)
dlg.On.c2.Clicked = _func

def _func(ev):
    n = 3
    selColor(n)
dlg.On.c3.Clicked = _func

def _func(ev):
    n = 4
    selColor(n)
dlg.On.c4.Clicked = _func

def _func(ev):
    n = 5
    selColor(n)
dlg.On.c5.Clicked = _func

def _func(ev):
    n = 6
    selColor(n)
dlg.On.c6.Clicked = _func

def _func(ev):
    n = 7
    selColor(n)
dlg.On.c7.Clicked = _func

def _func(ev):
    n = 8
    selColor(n)
dlg.On.c8.Clicked = _func


dlg.SetAttribute('WA_TranslucentBackground', False)
dlg.Show()
disp.RunLoop()
dlg.Hide()
