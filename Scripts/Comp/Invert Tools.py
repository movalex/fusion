## Tool Inverter version 1.0
## by Stefan Ihringer, stefan@bildfehler.de
##
## Intended as a replacement for Fusion's standard Ctrl-W hotkey, which swaps
## foreground and background inputs of all selected tools. This script, however,
## has an additional convenient feature: use it on a ColorSpace, Gamut or
## CineonLog to invert the conversion. Erode gets turned into dilate, and on masks
## or transforms the "invert" checkbox will be toggled.
## Place it in the Comp or HotkeyScripts directory and assign a hotkey like SHIFT_X.

try:
	
	selected = comp.GetToolList(True)

	if len(selected) == 0:
		raise Exception("No tools selected to invert.")

	for tool in selected.itervalues():		
		composition.StartUndo("Invert Tools")
		undo = False

		if tool.FindMainInput(2) != None:
			# tool has a foreground input: regular swap (if data types match)
			bg = tool.FindMainInput(1)
			fg = tool.FindMainInput(2)
			if bg.GetAttrs()['INPS_DataType'] == fg.GetAttrs()['INPS_DataType']:
				# this makes the script smarter than Fusion's ctrl-W :-)
				bg_upstream = bg.GetConnectedOutput()
				fg_upstream = fg.GetConnectedOutput()
				fg.ConnectTo(None)
				bg.ConnectTo(fg_upstream)
				fg.ConnectTo(bg_upstream)
				undo = True

		else:
			# special handling of certain tools
			if tool.ID == 'GamutConvert':
				temp = tool.SourceSpace[comp.CurrentTime]
				tool.SourceSpace = tool.OutputSpace[comp.CurrentTime]
				tool.OutputSpace = temp
				temp = tool.RemoveGamma[comp.CurrentTime]
				tool.RemoveGamma = tool.AddGamma[comp.CurrentTime]
				tool.AddGamma = temp
				undo = True
			elif tool.ID == 'ColorSpace' and tool.ColorSpaceConversion[comp.CurrentTime] > 0.5:
				tool.ColorSpaceConversion = 3 - tool.ColorSpaceConversion[comp.CurrentTime]
				undo = True
			elif tool.ID == 'BrightnessContrast':
				tool.Direction = 1 - tool.Direction[comp.CurrentTime]
				undo = True
			elif tool.ID == 'CineonLog':
				tool.Mode = 1 - tool.Mode[comp.CurrentTime]
				undo = True
			elif tool.ID == 'ErodeDilate':
				tool.XAmount = -tool.XAmount[comp.CurrentTime]
				tool.YAmount = -tool.YAmount[comp.CurrentTime]
				undo = True
			elif tool.ID == 'Transform':
				tool.InvertTransform = 1 - tool.InvertTransform[comp.CurrentTime]
				undo = True
			elif tool.ID == 'CoordSpace':
				tool.Shape = 1 - tool.Shape[comp.CurrentTime]
				undo = True
			elif (tool.Invert != None) and (tool.Invert.GetAttrs()['INPID_InputControl'] == 'CheckboxControl'):
				# maybe tool has an "Invert" checkbox that we can toggle?
				tool.Invert = 1 - tool.Invert[comp.CurrentTime]
				undo = True
			elif (tool.Inverted != None) and (tool.Inverted.GetAttrs()['INPID_InputControl'] == 'CheckboxControl'):
				tool.Inverted = 1 - tool.Inverted[comp.CurrentTime]
				undo = True
			elif (tool.InvertMatte != None) and (tool.InvertMatte.GetAttrs()['INPID_InputControl'] == 'CheckboxControl'):
				tool.InvertMatte = 1 - tool.InvertMatte[comp.CurrentTime]
				undo = True

		composition.EndUndo(undo)

except Exception as e:
	print e
	
	
# fin
