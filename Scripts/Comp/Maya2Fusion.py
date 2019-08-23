
#### written by Mike McReynolds at FilmworksFX  11/7/17  http://www.filmworksfx.com
#### for questions, comments, PayPal donations: mranim8or@aol.com
#### How to use:  This script will export SELECTED animated Maya objects and camera into .comp files containing animated transforms
#### that that you can then import in Fusion.
#### source this script (or just copy into a maya script editor and execute). Then run FusionExporter()
#### If you want to call this script from another scirpt, you can also supply filenames to FusionExporter as follows:
#### FusionExporter(CameraFileName="C:/MyCameraFile.comp",ObjectFileName="C:/MyObjectFile.comp"). This will cause the
#### script to export to those files, skipping the file dialog boxes.
#### Once the script finishes, load the .comp files in a text editor, select all, copy, and paste into fusion.

import maya.cmds as mc
import os
import math

def WriteStringToFile(TheString, TheFileName):
    ####make the file path, if it doesn't exist
    TheName = os.path.basename(TheFileName)
    ThePath = TheFileName.replace(TheName, "")

    if not os.path.exists(ThePath):
        os.makedirs(ThePath)  ####if the dir doesn't exist, create it

    TheFile = open(TheFileName, "w")
    TheFile.write(TheString)
    TheFile.close()

def Round(Num,NumDigits=5):
    X =10**NumDigits
    return float(int(Num * X)) / X

def AddKeyArray(CurveName, CurveColor,DataArray,FirstFrame,LastFrame,IsLast=False ):
    if DataArray ==[]:
        return ""
    KeyArrayString = CurveName+" = BezierSpline{\n"
    KeyArrayString += "SplineColor = {"+CurveColor+"},\n"
    KeyArrayString += "NameSet = true,\n"
    KeyArrayString += "          KeyFrames = {\n"
    for Frame in range(FirstFrame, LastFrame+1 ):
        # print(Frame)
        KeyArrayString += "     [" + str(Frame) + "] = {" + str(DataArray[Frame-1]) + "},\n"
    KeyArrayString += "     }\n"
    if IsLast:
        KeyArrayString += "}\n"
    else:
        KeyArrayString += "},\n"
    return KeyArrayString


def IsCurveFlat(TheCurve):  ####checks to see if a curve's has keys but all the keys are the same
    InitialValue = TheKeyValue = mc.keyframe(TheCurve, q=True, index=(0, 0), vc=True)

    KeyCount = mc.keyframe(TheCurve, q=True, keyframeCount=True)
    for n in range(0, KeyCount):
        if (mc.keyframe(TheCurve, q=True, index=(n, n), vc=True) != InitialValue):
            return False
    return True
def FindAllKeyedAttributes(TheObj,IgnoreFlatCurves):
    KeyableAttributes=mc.listAttr(TheObj,k=True)
    TheKeyedAttributes=[]
    NonKeyedAttributes=[]
    AllAttrs=[]
    if KeyableAttributes != None:
        for ThisAttribute in KeyableAttributes:
            try:
                if ((mc.keyframe((TheObj+"."+ThisAttribute), q=True, keyframeCount=True)) != 0):
                    if IgnoreFlatCurves == True:
                        if ( not IsCurveFlat(TheObj+"."+ThisAttribute)):
                            TheKeyedAttributes.append(ThisAttribute)
                    else: TheKeyedAttributes.append(ThisAttribute)
                else:
                    NonKeyedAttributes.append(ThisAttribute)
            except:
                pass

    return ([AllAttrs,TheKeyedAttributes,NonKeyedAttributes])

def IsAnimated(TheObj):
    Temp = FindAllKeyedAttributes(TheObj,IgnoreFlatCurves=True)
    if Temp[1] == []:
        return False
    else:
        return True




def ExportFusionCamera(Cam,TheFileName=""):  ###### for each camera, export a .comp file
    print("Exporting Camera :" + Cam)
    if TheFileName == "":
        FileTypes = "Comp Files (*.comp);;All Files (*.*)"
        TheFileName = mc.fileDialog2(cap="File name for camera comp file?", fileFilter=FileTypes, ds=1, fm=0)[0]

    ## get the shape, fov, etc of the camera
    Shapes = mc.listRelatives(Cam, s=True)
    for ThisShape in Shapes: ### find the camera shape
        if mc.nodeType(ThisShape) == "camera":
            Shape = ThisShape

    ## for every frame collect the transform data and fov data. must be done on every frame since I cant get handles in fusions to correctly support Maya's various curve types
    PositionXArray=[]
    PositionYArray=[]
    PositionZArray=[]

    RotationXArray=[]
    RotationYArray=[]
    RotationZArray=[]
    FOVArray=[]
    FirstFrame = int(mc.playbackOptions(q=True,min=True))
    LastFrame = int(mc.playbackOptions(q=True,max=True))
    try:
        mc.ogs(pause=True)  ### pauses the viewport to make it faster
    except:
        pass
    for Frame in range(FirstFrame , LastFrame+2 ):

        CurrentFrame  = mc.currentTime(q=True) ### store for later

        mc.currentTime( Frame ) ### go to every frame. Sadly, no easy way to get some parts of the data otherwise
        PositionXArray.append( Round( mc.getAttr(Cam + ".tx") ) )
        PositionYArray.append( Round( mc.getAttr(Cam + ".ty") ) )
        PositionZArray.append( Round( mc.getAttr(Cam + ".tz") ) )

        RotationXArray.append( Round( mc.getAttr(Cam + ".rx") ) )
        RotationYArray.append( Round( mc.getAttr(Cam + ".ry") ) )
        RotationZArray.append( Round( mc.getAttr(Cam + ".rz") ) )

        FOVArray.append( Round( mc.camera(Shape,q=True,hfv=True) ) )

    mc.currentTime(CurrentFrame)
    try:
        mc.ogs(pause=True)
    except:
        pass

    ## convert the collected data into a .comp file
    FileString="{\n"
    FileString += "Tools = ordered(){\n"
    FileString += Shape+" = Camera3D{\n"
    FileString += "    CtrlWZoom = false,\n"
    FileString += "                Inputs = {\n"
    FileString += "    [\"Transform3DOp.Translate.X\"] = Input{\n"
    FileString += "    SourceOp = \""+Shape+"XOffset\",\n"
    FileString += "               Source = \"Value\",\n"
    FileString += " },\n"
    FileString += "[\"Transform3DOp.Translate.Y\"] = Input{\n"
    FileString += "    SourceOp = \""+Shape+"YOffset\",\n"
    FileString += "               Source = \"Value\",\n"
    FileString += "},\n"
    FileString += "[\"Transform3DOp.Translate.Z\"] = Input{\n"
    FileString += "    SourceOp = \""+Shape+"ZOffset\",\n"
    FileString += "               Source = \"Value\",\n"
    FileString += "},\n"
    FileString += "[\"Transform3DOp.Rotate.X\"] = Input{\n"
    FileString += "    SourceOp = \""+Shape+"XRotation\",\n"
    FileString += "               Source = \"Value\",\n"
    FileString += "},\n"
    FileString += "[\"Transform3DOp.Rotate.Y\"] = Input{\n"
    FileString += "    SourceOp = \""+Shape+"YRotation\",\n"
    FileString += "               Source = \"Value\",\n"
    FileString += "},\n"
    FileString += "[\"Transform3DOp.Rotate.Z\"] = Input{\n"
    FileString += "    SourceOp = \""+Shape+"ZRotation\",\n"
    FileString += "               Source = \"Value\",\n"
    FileString += "},\n"
    FileString += "[\"Transform3DOp.ScaleLock\"] = Input{Value = 0,},\n"
    FileString += "PerspFarClip = Input\n"
    FileString += "{Value = 10000,},\n"
    FileString += "AovType = Input { Value = 1, },\n"
    FileString += "AoV = Input{\n"
    FileString += "    SourceOp = \""+Shape+"AngleofView\",\n"
    FileString += "               Source = \"Value\",\n"
    FileString += "},\n"
    FileString += "FLength = Input{Value = 23.3333333558239,},\n"
    FileString += "PlaneOfFocus = Input{Value = 5,},\n"
    FileString += "[\"Stereo.Mode\"] = Input{Value = FuID{\"Mono\"},},\n"

    ##### these are hardcoded values, based on our project
    FileString += "FilmBack = Input { Value = 1, },\n"
    FileString += "FilmGate = Input { Value = FuID { \"User\" }, },\n"
    FileString += "ApertureW = Input{Value = 1.417,},\n"
    FileString += "ApertureH = Input{Value = 0.945,},\n"
    FileString += "ResolutionGateFit = Input { Value = FuID { \"Width\" }, },\n"
    #### end of hardcoded stuff

    FileString += "[\"SurfacePlaneInputs.ObjectID.ObjectID\"] = Input{Value = 1,},\n"
    FileString += "[\"MtlStdInputs.MaterialID\"] = Input{Value = 1,},\n"
    FileString += "},\n"
    FileString += "ViewInfo = OperatorInfo{Pos = {-5.87854, -16.3528}},\n"
    FileString += "},\n"

    FileString += AddKeyArray(Shape+"XOffset", "Red = 250, Green = 59, Blue = 49",PositionXArray,FirstFrame,LastFrame ) ## add position x keys
    FileString += AddKeyArray(Shape+"YOffset", "Red = 252, Green = 131, Blue = 47 ",PositionYArray,FirstFrame,LastFrame ) ## add position y keys
    FileString += AddKeyArray(Shape+"ZOffset", "Red = 254, Green = 207, Blue = 46 ",PositionZArray,FirstFrame,LastFrame ) ## add position z keys

    FileString += AddKeyArray(Shape+"XRotation", "Red = 255, Green = 128, Blue = 12",RotationXArray,FirstFrame,LastFrame ) ## add rot x keys
    FileString += AddKeyArray(Shape+"YRotation", "Red = 128, Green = 255, Blue = 128",RotationYArray,FirstFrame,LastFrame ) ## add rot ykeys
    FileString += AddKeyArray(Shape+"ZRotation", "Red = 108, Green = 229, Blue = 117",RotationZArray,FirstFrame,LastFrame ) ## add rot z keys

    FileString += AddKeyArray(Shape+"AngleofView", "Red = 8, Green = 229, Blue = 117",FOVArray,FirstFrame,LastFrame,IsLast=True ) ## add focal length keys

    FileString += "}\n"
    FileString += "}"

    ## output the collected data
    WriteStringToFile(FileString,TheFileName)
    print("DONE EXPORTING CAMERA")


def ExportFusionObject(Objects,TheFileName=""): ###### for all non-camera selected animated objects export a .comp file
    if TheFileName == "":
        FileTypes = "Comp Files (*.comp);;All Files (*.*)"
        TheFileName = mc.fileDialog2(cap="File name for object comp file?", fileFilter=FileTypes, ds=1, fm=0)[0]


    FoundAnAnimatedObj=False
    FileString = ""
    FileString += "{\n"
    FileString += "	Tools = ordered() {\n"
    FirstFrame = int(mc.playbackOptions(q=True,min=True))
    LastFrame = int(mc.playbackOptions(q=True,max=True))

    n = 0
    for Obj in Objects:

        if IsAnimated(Obj):
            AnimatedCurves = FindAllKeyedAttributes(Obj, IgnoreFlatCurves=True)[1]

            print("Exporting Object : " + Obj)
            FoundAnAnimatedObj = True
            PositionXArray = []
            PositionYArray = []
            PositionZArray = []

            RotationXArray = []
            RotationYArray = []
            RotationZArray = []

            ScaleXArray = []
            ScaleYArray = []
            ScaleZArray = []

            for Frame in range(FirstFrame, LastFrame + 2):
                if "translateX" in AnimatedCurves: PositionXArray.append(Round(mc.getAttr(Obj + ".tx",time=Frame)))
                if "translateY" in AnimatedCurves: PositionYArray.append(Round(mc.getAttr(Obj + ".ty",time=Frame)))
                if "translateZ" in AnimatedCurves: PositionZArray.append(Round(mc.getAttr(Obj + ".tz",time=Frame)))

                if "rotateX" in AnimatedCurves: RotationXArray.append(Round(mc.getAttr(Obj + ".rx",time=Frame)))
                if "rotateY" in AnimatedCurves: RotationYArray.append(Round(mc.getAttr(Obj + ".ry",time=Frame)))
                if "rotateZ" in AnimatedCurves: RotationZArray.append(Round(mc.getAttr(Obj + ".rz",time=Frame)))

                if "scaleX" in AnimatedCurves: ScaleXArray.append(Round(mc.getAttr(Obj + ".sx", time=Frame)))
                if "scaleY" in AnimatedCurves: ScaleYArray.append(Round(mc.getAttr(Obj + ".sy", time=Frame)))
                if "scaleZ" in AnimatedCurves: ScaleZArray.append(Round(mc.getAttr(Obj + ".sz", time=Frame)))

            ### add the 'header' for this object

            FileString += "		"+Obj+" = Transform3D {\n"
            FileString += "			CtrlWZoom = false,\n"
            FileString += "			Inputs = {\n"
            if PositionXArray != []:
                FileString += "				[\"Transform3DOp.Translate.X\"] = Input {\n"
                FileString += "					SourceOp = \""+Obj+"XOffset\",\n"
                FileString += "					Source = \"Value\",\n"
                FileString += "				},\n"
            if PositionYArray != []:
                FileString += "				[\"Transform3DOp.Translate.Y\"] = Input {\n"
                FileString += "					SourceOp = \""+Obj+"YOffset\",\n"
                FileString += "					Source = \"Value\",\n"
                FileString += "				},\n"
            if PositionZArray != []:
                FileString += "				[\"Transform3DOp.Translate.Z\"] = Input {\n"
                FileString += "					SourceOp = \""+Obj+"ZOffset\",\n"
                FileString += "					Source = \"Value\",\n"
                FileString += "				},\n"
            if RotationXArray != []:
                FileString += "				[\"Transform3DOp.Rotate.X\"] = Input {\n"
                FileString += "					SourceOp = \""+Obj+"XRotation\",\n"
                FileString += "					Source = \"Value\",\n"
                FileString += "				},\n"
            if RotationYArray != []:
                FileString += "				[\"Transform3DOp.Rotate.Y\"] = Input {\n"
                FileString += "					SourceOp = \""+Obj+"YRotation\",\n"
                FileString += "					Source = \"Value\",\n"
                FileString += "				},\n"
            if RotationZArray !=[]:
                FileString += "				[\"Transform3DOp.Rotate.Z\"] = Input {\n"
                FileString += "					SourceOp = \""+Obj+"ZRotation\",\n"
                FileString += "					Source = \"Value\",\n"
                FileString += "				},\n"
            FileString += "				[\"Transform3DOp.ScaleLock\"] = Input { Value = 0, },\n"
            if ScaleXArray != []:
                FileString += "				[\"Transform3DOp.Scale.X\"] = Input {\n"
                FileString += "					SourceOp = \""+Obj+"XScale\",\n"
                FileString += "					Source = \"Value\",\n"
                FileString += "				},\n"
            if ScaleYArray != []:
                FileString += "				[\"Transform3DOp.Scale.Y\"] = Input {\n"
                FileString += "					SourceOp = \""+Obj+"YScale\",\n"
                FileString += "					Source = \"Value\",\n"
                FileString += "				},\n"
            if ScaleZArray != []:
                FileString += "				[\"Transform3DOp.Scale.Z\"] = Input {\n"
                FileString += "					SourceOp = \""+Obj+"ZScale\",\n"
                FileString += "					Source = \"Value\",\n"
                FileString += "				},\n"
            FileString += "			},\n"
            FileString += "			ViewInfo = OperatorInfo { Pos = { 0, "+str(n*35)+" } },\n"
            FileString += "	    },\n"

            ##### Add the keyframe data
            FileString += AddKeyArray(Obj + "XOffset", "Red = 250, Green = 59, Blue = 49", PositionXArray, FirstFrame,
                                      LastFrame)  ## add position x keys
            FileString += AddKeyArray(Obj + "YOffset", "Red = 252, Green = 131, Blue = 47 ", PositionYArray, FirstFrame,
                                      LastFrame)  ## add position y keys
            FileString += AddKeyArray(Obj + "ZOffset", "Red = 254, Green = 207, Blue = 46 ", PositionZArray, FirstFrame,
                                      LastFrame)  ## add position z keys

            FileString += AddKeyArray(Obj + "XRotation", "Red = 255, Green = 128, Blue = 12", RotationXArray, FirstFrame,
                                      LastFrame)  ## add rot x keys
            FileString += AddKeyArray(Obj + "YRotation", "Red = 128, Green = 255, Blue = 128", RotationYArray, FirstFrame,
                                      LastFrame)  ## add rot ykeys
            FileString += AddKeyArray(Obj + "ZRotation", "Red = 108, Green = 229, Blue = 117", RotationZArray, FirstFrame,
                                      LastFrame)  ## add rot z keys


            FileString += AddKeyArray(Obj + "XScale", "Red = 251, Green = 22, Blue = 119", ScaleXArray, FirstFrame,
                                      LastFrame)  ## add rot x keys
            FileString += AddKeyArray(Obj + "YScale", "Red = 252, Green = 21, Blue = 37", ScaleYArray, FirstFrame,
                                      LastFrame)  ## add rot ykeys
            FileString += AddKeyArray(Obj + "ZScale", "Red = 254, Green = 43, Blue = 34", ScaleZArray, FirstFrame,
                                      LastFrame)  ## add rot z keys


            #####
            if n == len(Objects)-1:
                FileString += "	 }\n"
                FileString += "}\n"
            n+=1

    if FoundAnAnimatedObj:
        WriteStringToFile(FileString,TheFileName)

    print("DONE EXPORTING Objects")

def FusionExporter(CameraFileName="",ObjectFileName=""):
    #### find the selected objects, sort them into cameras and other animated objects
    SelObjs = mc.ls(sl=True)
    Cameras = []
    CameraShapes=[]
    Shapes =[]
    Objects=[]

    for o in SelObjs: ### look through every object selected, find out if its a camera or other animated obj
        Shapes = mc.listRelatives(o, s=True)
        if Shapes != []:
            for Shape in Shapes:
                if mc.nodeType(Shape) == "camera":
                    Cameras.append(o)
                    CameraShapes.append(Shape)
                else:
                    if IsAnimated(o):
                        Objects.append(o)
    for Cam in Cameras:
        ExportFusionCamera(Cam,TheFileName=CameraFileName)
    if len(Objects) >0:
        ExportFusionObject(Objects,TheFileName=ObjectFileName)
    if Objects==[] and Cameras ==[]:
        print("No animated objects or cameras selected!")
    print("Fusion export completed.")

    if CameraFileName =="" and ObjectFileName=="":
        if Objects==[] and Cameras ==[]:
            mc.confirmDialog(m="No animated objects or cameras selected! Exiting.", button="OK", title="Fusion Exporter")
        else:
            mc.confirmDialog(m="Done!", button="OK",title="Fusion Exporter")
