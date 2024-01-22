'''
Gyroflow Fusion

Video Stabilization Using Gyroscope Data

Overview:
Converts your Gyroflow stabilization into a CSV file that is compatible with the "Vonk Ultra" data nodes in Fusion.

Make sure to choose "including processed gyro data" when saving your project in Gyroflow. By default, Gyroflow saves out the rotations as Euler rotation (ZYX). It also saves out the data in your footages' native frame rate.

Requirements:
Resolve/Fusion v18.1+ and Python 3.6+ are required to use this script.

Credits:
Gyroflow to CSV Python script by Jacob Danell of Emberlight

Gyroflow Fusion "UI Manager" GUI wrapper by Andrew Hazelden of Kartaverse

'''

import json, zlib, sys, struct, csv, os, math, argparse, webbrowser
from pprint import pprint


# Arg variables
csv_fields = ["timestamp", "x", "y", "z"]
all_timestamps = False
add_nodes = True
csv_path = ""

global gyroflow_dragdrop
# print(globals())

# Quaternions
def process(gyroflow_path, quaternion_type, convert_to_euler, all_timestamps):
    if not os.path.exists(gyroflow_path):
        print("\n[Gyroflow Error] [File] \"", gyroflow_path, "\" was not found")
        return
    f = open(gyroflow_path)
    data = json.load(f)
    csv_rows = []
    csv_file = os.path.split(gyroflow_path)
    csv_file = os.path.abspath(os.path.join(csv_file[0], os.path.splitext(csv_file[1])[0] + ".csv"))
    frame_as_microsec = 1/(data['video_info']['fps']/1000000)

    print("Decompress quaternion")
    try:
        raw = zlib.decompress(decode(data['gyro_source'][quaternion_type]))
    except Exception as e:
        print("\n[Gyroflow Error] No quaternions found. Make sure you have saved out your CineFlow file including processed gyro data")
        return
        
    offsets = []
    try:
        offsets = data['offsets']
        for key, val in offsets.items(): # Convert from milliseconds to microseconds
            offsets[key] = val*1000
    except Exception as e:
        pass

    print("Unpacking")
    length = struct.unpack('<Q', raw[:8])[0]
    old_percentage = 0
    gyro_data = list(struct.iter_unpack('<qQdddd', raw[8:]))
    gyro_data = convert_to_dict(gyro_data)

    item_length = len(gyro_data)
    
    printProgressBar(0, item_length, prefix = 'Processing gyro data:', suffix = 'Complete', length = 50)
    if all_timestamps:
        for i, (timestamp, val) in enumerate(gyro_data.items()):

            data = [timestamp]
            if convert_to_euler:
                data.extend(quaternion_to_euler_angle(val[0], val[1], val[2], val[3]))
            else:
                data.extend([val[0], val[1], val[2], val[3]])
            csv_rows.append(data)

            printProgressBar(i + 1, item_length, prefix = 'Processing gyro datas:', suffix = 'Complete', length = 50)
    else:

        num_frames = data['video_info']['num_frames']

        for i in range(num_frames):
            cur_microsec = frame_as_microsec * i
            offset = offset_at_timestamp(offsets, cur_microsec)
            item = closest2(gyro_data, cur_microsec - offset)

            data = [item[0]]
            if convert_to_euler:
                data.extend(quaternion_to_euler_angle(item[1], item[2], item[3], item[4]))
            else:
                data.extend([item[1], item[2], item[3], item[4]])
            csv_rows.append(data)

            printProgressBar(i + 1, num_frames, prefix = 'Processing gyro data:', suffix = 'Complete', length = 50)

    print("\n[Gyroflow Fusion] Writing to CSV")
    with open(csv_file, 'w', newline='') as csvfile: 
        # creating a csv writer object 
        csvwriter = csv.writer(csvfile) 
            
        # writing the fields 
        csvwriter.writerow(csv_fields) 
            
        # writing the data rows 
        csvwriter.writerows(csv_rows)
    print("\n[Gyroflow Fusion][Writing Complete]")

    return csv_file

# Global variables
base91_alphabet = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '!', '#', '$',
    '%', '&', '(', ')', '*', '+', ',', '.', '/', ':', ';', '<', '=',
    '>', '?', '@', '[', ']', '^', '_', '`', '{', '|', '}', '~', '"']

decode_table = dict((v,k) for k,v in enumerate(base91_alphabet))

# Global functions
def decode(encoded_str):
    ### Decode Base91 string to a bytearray ###
    v = -1
    b = 0
    n = 0
    out = bytearray()
    for strletter in encoded_str:
        if not strletter in decode_table:
            continue
        c = decode_table[strletter]
        if(v < 0):
            v = c
        else:
            v += c*91
            b |= v << n
            n += 13 if (v & 8191)>88 else 14
            while True:
                out += struct.pack('B', b&255)
                b >>= 8
                n -= 8
                if not n>7:
                    break
            v = -1
    if v+1:
        out += struct.pack('B', (b | v << n) & 255 )
    return out

def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = '█', printEnd = "\r"):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        length      - Optional  : character length of bar (Int)
        fill        - Optional  : bar fill character (Str)
        printEnd    - Optional  : end character (e.g. "\r", "\r\n") (Str)
    """
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print(f'\r{prefix} |{bar}| {percent}% {suffix}', end = printEnd)
    # Print New Line on Complete
    if iteration == total: 
        print()

def quaternion_to_euler_angle(x, y, z, w):
    ysqr = y * y

    t0 = +2.0 * (w * x + y * z)
    t1 = +1.0 - 2.0 * (x * x + ysqr)
    X = math.degrees(math.atan2(t0, t1))

    t2 = +2.0 * (w * y - z * x)
    t2 = +1.0 if t2 > +1.0 else t2
    t2 = -1.0 if t2 < -1.0 else t2
    Y = math.degrees(math.asin(t2))

    t3 = +2.0 * (w * z + x * y)
    t4 = +1.0 - 2.0 * (ysqr + z * z)
    Z = math.degrees(math.atan2(t3, t4))

    return [X, Y, Z]

def closest(ref, first, second):
    result = min(abs(ref-first), abs(ref-second))
    if result == abs(ref-first):
        return first
    else:
        return second

# Closest number in a list
def closest2(lst, K):
    if lst.get(K):
        return (K,) + lst.get(K)
    else:
        closest_key = min(lst.keys(), key = lambda key: abs(key-K))
        return (closest_key,) + lst[closest_key]

def offset_at_timestamp(offsets, timestamp_ms):
    if len(offsets) == 0:
        return 0.0
    elif len(offsets) == 1:
        return list(offsets.values())[0]
    else:
        first_ts = int(list(offsets.keys())[0])
        last_ts = int(list(offsets.keys())[-1])

        lookup_ts = min(max(timestamp_ms, first_ts), last_ts)

        offs1 = None
        for key, val in offsets.items():
            if int(key) <= lookup_ts:
                offs1 = int(key)
        if offs1 == lookup_ts:
            return offsets[str(offs1)]
        offs2 = None
        for key, val in offsets.items():
            if int(key) > lookup_ts:
                offs2 = int(key)
                break
        time_delta = offs2 - offs1
        fract = (timestamp_ms - offs1) / time_delta
        return offsets[str(offs1)] + (offsets[str(offs2)] - offsets[str(offs1)]) * fract

def convert_to_dict(data_list):
    data_dict = {}
    for item in data_list:
        data_dict.update({int(item[0]): item[2::]})
    return data_dict

# Vonk data node content as a Fusion .setting formatted macro snippet
def paste_macro():
    global csv_path

    txt = '''
{
	Tools = ordered() {
		vNumberCompReqTime1 = Fuse.vNumberCompReqTime {
			NameSet = true,
			ViewInfo = OperatorInfo { Pos = { -275, -82.5 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		vTextFromFile1 = Fuse.vTextFromFile {
			CtrlWZoom = false,
			NameSet = true,
			Inputs = {
				Input = Input { Value = [[''' + str(csv_path) + ''']], },
			},
			ViewInfo = OperatorInfo { Pos = { -275, -16.197 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		PipeRouter1 = PipeRouter {
			Inputs = {
				Input = Input {
					SourceOp = "vTextFromFile1",
					Source = "Output",
				},
			},
			ViewInfo = PipeRouterInfo { Pos = { -165, -16.5 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		yGyro_vNumberFromCSV1 = Fuse.vNumberFromCSV {
			NameSet = true,
			Inputs = {
				Row = Input {
					SourceOp = "vNumberAdd1",
					Source = "Output",
				},
				Column = Input { Value = 3, },
				IgnoreHeaderRow = Input { Value = 1, },
				Input = Input {
					SourceOp = "PipeRouter1",
					Source = "Output",
				},
			},
			ViewInfo = OperatorInfo { Pos = { -55, -16.5 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		xGyro_vNumberFromCSV1 = Fuse.vNumberFromCSV {
			NameSet = true,
			Inputs = {
				Row = Input {
					SourceOp = "vNumberAdd1",
					Source = "Output",
				},
				Column = Input { Value = 2, },
				IgnoreHeaderRow = Input { Value = 1, },
				Input = Input {
					SourceOp = "PipeRouter1",
					Source = "Output",
				},
			},
			ViewInfo = OperatorInfo { Pos = { -55, -49.5 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		vNumberAdd1 = Fuse.vNumberAdd {
			NameSet = true,
			Inputs = {
				Term1 = Input {
					SourceOp = "vNumberCompReqTime1",
					Source = "Output",
				},
				Term2 = Input { Value = 1, },
				ShowInput = Input { Value = 1, },
			},
			ViewInfo = OperatorInfo { Pos = { -55, -82.5 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		zGyro_vNumberFromCSV1 = Fuse.vNumberFromCSV {
			NameSet = true,
			Inputs = {
				Row = Input {
					SourceOp = "vNumberAdd1",
					Source = "Output",
				},
				Column = Input { Value = 4, },
				IgnoreHeaderRow = Input { Value = 1, },
				Input = Input {
					SourceOp = "PipeRouter1",
					Source = "Output",
				},
			},
			ViewInfo = OperatorInfo { Pos = { -55, 16.5 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		zGyro1 = Fuse.vNumberMultiply {
			NameSet = true,
			CustomData = {
				Settings = {
					[2] = {
						Tools = ordered() {
							zGyro = Fuse.vNumberMultiply {
								Inputs = {
									ShowInput = Input { Value = 1 },
									Factor2 = Input { Value = -1 },
									Factor1 = Input {
										SourceOp = "vNumberFromText1_2",
										Source = "Output"
									}
								},
								CtrlWZoom = false,
								NameSet = true,
								ViewInfo = OperatorInfo { Pos = { 1265, 16.5 } },
								CustomData = {
								}
							}
						}
					},
				}
			},
			Inputs = {
				Factor1 = Input {
					SourceOp = "zGyro_vNumberFromCSV1",
					Source = "Output",
				},
				Factor2 = Input { Value = 1, },
				ShowInput = Input { Value = 1, },
			},
			ViewInfo = OperatorInfo { Pos = { 55, 16.5 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		yGyro1 = Fuse.vNumberMultiply {
			NameSet = true,
			CustomData = {
				Settings = {
					[2] = {
						Tools = ordered() {
							yGyro = Fuse.vNumberMultiply {
								Inputs = {
									ShowInput = Input { Value = 1 },
									Factor2 = Input { Value = -1 },
									Factor1 = Input {
										SourceOp = "vNumberFromText1",
										Source = "Output"
									}
								},
								CtrlWZoom = false,
								NameSet = true,
								ViewInfo = OperatorInfo { Pos = { 1265, -16.5 } },
								CustomData = {
								}
							}
						}
					}
				}
			},
			Inputs = {
				Factor1 = Input {
					SourceOp = "yGyro_vNumberFromCSV1",
					Source = "Output",
				},
				Factor2 = Input { Value = 1, },
				ShowInput = Input { Value = 1, },
			},
			ViewInfo = OperatorInfo { Pos = { 55, -16.5 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		xGyro1 = Fuse.vNumberMultiply {
			NameSet = true,
			CurrentSettings = 2,
			CustomData = {
				Settings = {
					[1] = {
						Tools = ordered() {
							xGyro = Fuse.vNumberMultiply {
								Inputs = {
									ShowInput = Input { Value = 1 },
									Factor2 = Input { Value = 1 },
									Factor1 = Input {
										SourceOp = "vNumberFromText1_1",
										Source = "Output"
									}
								},
								CtrlWZoom = false,
								NameSet = true,
								ViewInfo = OperatorInfo { Pos = { 1265, -49.5 } },
								CustomData = {
								}
							}
						}
					}
				}
			},
			Inputs = {
				Factor1 = Input {
					SourceOp = "xGyro_vNumberFromCSV1",
					Source = "Output",
				},
				Factor2 = Input { Value = -1, },
				ShowInput = Input { Value = 1, },
			},
			ViewInfo = OperatorInfo { Pos = { 55, -49.5 } },
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		},
		CSV_Underlay1 = Underlay {
			NameSet = true,
			ViewInfo = UnderlayInfo {
				Pos = { -110, -115.5 },
				Size = { 509.151, 191.757 }
			},
			Colors = { TileColor = { R = 0.886274509803922, G = 0.662745098039216, B = 0.109803921568627 }, }
		}
	}
}

'''

    return bmd.readstring(txt)


def main():
    comp = fu.GetCurrentComp()
    flow = comp.CurrentFrame.FlowView
    ui = fu.UIManager
    disp = bmd.UIDispatcher(ui)

    # UI Preset Values
    
    global gyroflow_dragdrop
    try:
        gyroflow_path = gyroflow_dragdrop
    except NameError:
        gyroflow_path = ""

    smoothed = 1
    quaternions = 0

    # Hotkey bindings
    comp.Execute("""
app:AddConfig('SplashWin', {
    Target {
        ID = 'SplashWin',
    },
    Hotkeys {
        Target = 'SplashWin',
        Defaults = true,

        CONTROL_W = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
        CONTROL_F4 = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
        ESCAPE = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
    },
})""")


    comp.Execute("""
app:AddConfig('GFWin', {
    Target {
        ID = 'GFWin',
    },
    Hotkeys {
        Target = 'GFWin',
        Defaults = true,

        CONTROL_W = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
        CONTROL_F4 = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
        ESCAPE = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
    },
})""")

    # Splash Screen Window
    sdlg = disp.AddWindow({"WindowTitle": "Emberlight | Gyroflow To Fusion", "ID": "SplashWin", "TargetID" : "SplashWin", "Geometry": [25, 140, 600, 300], "Spacing": 0,},[
        ui.VGroup({"ID": "root",},[
            ui.Button({
                "ID": "LogoButton",
                "Flat": True,
                "IconSize": [360, 86],
                "Icon": ui.Icon({"File": "Scripts:/Comp/Gyroflow Fusion/gyroflow_logo.png"}),
                "Weight": 0.01,
            }),
            ui.Label({
                "ID": "CaptionLabel",
                "Text": "Video Stabilization Using Gyroscope Data",
                "Alignment": {
                    "AlignHCenter": True,
                    "AlignTop": True
                },
                'Font': ui.Font({
                    'Family': 'Droid Sans Mono',
                    'PixelSize': 24,
                    'MonoSpaced': True,
                }),
                "Weight": 0.01,
            }),
            ui.Label({
                "ID": "DescriptionLabel",
                "Text": "Converts your Gyroflow stabilization into a CSV file that is compatible with the \"Vonk Ultra\" data nodes in Fusion.\n\nMake sure to choose \"including processed gyro data\" when saving your project in Gyroflow. By default, Gyroflow saves out the rotations as Euler rotation (ZYX). It also saves out the data in your footages' native frame rate.",
                'Font': ui.Font({
                    'Family': 'Droid Sans Mono',
                    'MonoSpaced': True,
                }),
                "WordWrap": True,
                "Weight": 1.0,
            }),
            ui.Button({
                "ID": "ContinueButton",
                "Text": "Continue",
                "Weight": 0.01,
            }),
        ]),
    ])

    itm = sdlg.GetItems()

    # The window was closed
    def CloseFunc(ev):
        disp.ExitLoop()
    sdlg.On.SplashWin.Close = CloseFunc

    # The Go button was clicked
    def ContinueButtonFunc(ev):
        disp.ExitLoop()
    sdlg.On.ContinueButton.Clicked = ContinueButtonFunc

    # The Gyroflow Logo button was clicked
    def LogoButtonFunc(ev):
        url = "https://github.com/gyroflow/gyroflow"
        print("[Gyroflow] [Open URL]", url)
        webbrowser.open(url)
    sdlg.On.LogoButton.Clicked = LogoButtonFunc


    # File Dialog Window
    dlg = disp.AddWindow({"WindowTitle": "Emberlight | Gyroflow Fusion", "ID": "GFWin", "TargetID" : "GFWin", "Geometry": [25, 155, 500, 180], "Spacing": 0,},[
        ui.VGroup({"ID": "root", "Weight": 10.0,},[
            ui.HGroup({"Weight": 0.0,},[
                ui.Label({
                    "ID": "Label", 
                    "Text": "Gyroflow Filename", 
                    "Weight": 0.1
                }),
                ui.LineEdit({
                    "ID": "GyroflowPath", 
                    "Text": gyroflow_path, 
                    "PlaceholderText": "Please enter a filepath to a \".gyroflow\" file.", 
                    "Weight": 0.9
                }),
                ui.Button({"ID": "BrowseButton", 
                    "Text": "Browse", 
                    "Geometry": [0, 0, 30, 50], 
                    "Weight": 0.1
                }),
            ]),
            ui.CheckBox({
                "ID": "SmoothedCheckbox",
                "Text": "Calculate from smoothed quaternions",
                "Checked": smoothed,
                "Weight": 0.01,
            }),
            ui.CheckBox({
                "ID": "QuaternionsCheckbox",
                "Text": "Save data as quaternions",
                "Checked": quaternions,
                "Weight": 0.01,
            }),
            ui.CheckBox({
                "ID": "AllTimestampsCheckbox",
                "Text": "Save all timestamps instead of FPS converted",
                "Checked": all_timestamps,
                "Weight": 0.01,
            }),
            ui.CheckBox({
                "ID": "AddNodesToCompCheckbox",
                "Text": "Add \"Gyroflow CSV\" Nodes to Comp",
                "Checked": add_nodes,
                "Weight": 0.01,
            }),
            ui.Button({
                "ID": "GoButton",
                "Text": "Go",
                "Weight": 0.01,
            }),
        ]),
    ])

    itm = dlg.GetItems()

    # The window was closed
    def CloseFunc(ev):
        disp.ExitLoop()
    dlg.On.GFWin.Close = CloseFunc

    # The Gyroflow Logo button was clicked
    def LogoButtonFunc(ev):
        print("[Gyroflow] https://github.com/gyroflow/gyroflow")
    dlg.On.LogoButton.Clicked = LogoButtonFunc

    # Display a File browsing dialog
    def BrowseButtonFunc(ev):
        selectedPath = fu.RequestFile("", "SETECL", {
            "FReqS_Filter": "Gyroflow Files (*.gyroflow)|*.gyroflow",
            "FReqS_Title": "Choose a .gyroflow file"
            })
        if selectedPath:
            itm['GyroflowPath'].Text = str(selectedPath)
    dlg.On.BrowseButton.Clicked = BrowseButtonFunc

    # The Go button was clicked
    def GoButtonFunc(ev):
        gyroflow_path = str(app.MapPath(itm["GyroflowPath"].Text or ""))
        smoothed = itm["SmoothedCheckbox"].Checked
        quaternions = itm["QuaternionsCheckbox"].Checked
        all_timestamps = itm["AllTimestampsCheckbox"].Checked
        add_nodes = itm["AddNodesToCompCheckbox"].Checked

        print("[Gyroflow Path]", gyroflow_path)
        print("[Smoothed]", smoothed)
        print("[Quaternions]", quaternions)
        print("[All Timestamps]", all_timestamps)
        print("[Add Nodes to Comp]", add_nodes)

        disp.ExitLoop()

        if smoothed:
            quaternion_type = "smoothed_quaternions"
        else:
            quaternion_type = "integrated_quaternions"

        if quaternions:
            convert_to_euler = False
            csv_fields.append("w")
        else:
            convert_to_euler = True

        if all_timestamps:
            all_timestamps = True
        else:
            all_timestamps = False

        if add_nodes:
            add_nodes = True
        else:
            add_nodes = False

        # Convert the Gyroflow file to a CSV document
        global csv_path
        csv_path = process(gyroflow_path, quaternion_type, convert_to_euler, all_timestamps)

        # Add an initial Vonk Ultra vTextCreate Node
        if comp and add_nodes and itm["QuaternionsCheckbox"].Checked == False:
            print("[Add Nodes to Comp] Enabled")

            # Start the undo item
            comp.StartUndo("Gyroflow Fusion")

            # Stop Loader/Saver node file dialogs from showing
            comp.Lock()

            # Paste the macro as a Python dict into the comp
            comp.Paste(paste_macro())

            # Allow Loader/Saver node file dialogs to show up again
            comp.Unlock()

            # Complete Undo item
            comp.EndUndo(True)
        else:
            print("[Add Nodes to Comp] Skipping")
    dlg.On.GoButton.Clicked = GoButtonFunc

    def QuartCheckboxFunc(ev):
        if itm["QuaternionsCheckbox"].Checked == True:
            print("[Save data as quaternions] Disabling this control means the \"Add Nodes to Comp\" control cannot be used.")
            itm["AddNodesToCompCheckbox"].Enabled = False
            #itm["AddNodesToCompCheckbox"].Visible = False
        else:
            itm["AddNodesToCompCheckbox"].Enabled = True
            #itm["AddNodesToCompCheckbox"].Visible = True
    dlg.On.QuaternionsCheckbox.Clicked = QuartCheckboxFunc

    # Display the Splash screen
    sdlg.Show()
    disp.RunLoop()
    sdlg.Hide()

    # Display the main dialog
    dlg.Show()
    disp.RunLoop()
    dlg.Hide()

    print("[Done]")

if __name__=="__main__":
    main()
