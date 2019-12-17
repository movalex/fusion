## Freeze Cam tool script
## by Stefan Ihringer, stefan@bildfehler.de
##
## version 1.0, 2012-11-20
## This tool script creates a projection camera from a selected Camera3D tool, freezing
## its animation on the current frame.

# change the default projection mode here: 0 = Light, 1 = Ambient Light, 2 = Texture
PROJECTIONMODE = 2
# set this to False if you don't want to add a comment that contains the source camera's
# name and the frozen frame number. The camera will still be renamed appropriately.
ADDCOMMENT = True

try:
	
	try:
		if tool is None:
			tool = comp.ActiveTool
	except NameError:
		tool = comp.ActiveTool

	if (not tool) or (tool.ID != "Camera3D"):
		raise Exception("You must select a Camera3D tool in the flow to run this script.")

	# can't just use Copy() and Paste() because this would only copy spline animations, not connections to
	# any other kind of modifier that might currently exist on the camera's inputs.
	tpos = comp.CurrentFrame.FlowView.GetPosTable(tool)
	comp.SetActiveTool()
	frozen = comp.AddTool("Camera3D", tpos[1]+2, tpos[2]+2)

	# rename camera
	frozen.SetAttrs({"TOOLS_Name": "%s_ProjectFrame%03d" % (tool.Name, comp.CurrentTime), "TOOLB_NameSet": True})
	if ADDCOMMENT:
		frozen.Comments[comp.TIME_UNDEFINED] = "%s @ frame %d" % (tool.Name, comp.CurrentTime)

	# copy a snapshot of all inputs
	for inp in frozen.GetInputList().itervalues():
		if inp.GetAttrs()["INPS_DataType"] == "Number":
			inp[comp.TIME_UNDEFINED] = tool[inp.ID][comp.CurrentTime]

	# enable projection, disable image plane
	frozen.ProjectionEnabled = 1
	frozen.ProjectionFitMethod = frozen.ResolutionGateFit[comp.CurrentTime]
	frozen.ProjectionMode = PROJECTIONMODE
	frozen.ImagePlaneEnabled = 0

	# reconnect image input?
	if tool.ImageInput.GetConnectedOutput() is not None:
		frozen.ImageInput.ConnectTo(tool.ImageInput.GetConnectedOutput())


except Exception as e:
	print e
	
# fin
