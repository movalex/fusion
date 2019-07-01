###############################################################################
##                    Connect Single Node to Many                            ##
##                                                                           ##
## Created by Andrez Aguayo @ DKStudios Chicago                              ##
## 3/13/15                                                                   ##
## More info Coming soon                                                     ##
###############################################################################


flow = comp.CurrentFrame.FlowView


# Helper Functions
def get_selection_for_use():
    """ This function seperates the left most tool from the tool list
        return the left most object and a list of all other selected tools
        """
    # get the selected Tools
    toolList = list(comp.GetToolList(True).values())
    # Check to see if the list is empty, if so, return None type
    if toolList != []:
        # get the left most
        leftMost = get_left_most_tool(toolList)
        toolList.remove(leftMost)
        # Check to see if the tool list is empty
        if toolList == []:
            toolList = None
    else:
        leftMost = None
        toolList = None
    return leftMost, toolList


def get_left_most_tool(toolList):
    """ This funcion uses the flow to find the left most selected
        tool using the X and Y Cordanents"""
    # get all selected tools
    # toolList = comp.GetToolList(True).values()

    # loop thourgh and sort tools in a dictionary by the X cordantes
    ToolListDic = {}
    for tool in toolList:
        # cords = flow.GetPosTable(theTool)
        toolX = flow.GetPosTable(tool)[1.0]
        # add tools to Dic with Xcords being the Key Value
        ToolListDic[toolX] = tool

    minKey = min(ToolListDic.keys())

    leftMostTool = ToolListDic[minKey]
    # print "This is the Left Most Tool {0}".format(leftMostTool)
    return leftMostTool


def get_output_list(theTool):
    """ This funcion will return a list of output values, starting with
                the most common outputs if any.
                (fusionToolObject)---> returns List of string names	"""

    annymore_main_outputs = True
    inc = 1
    mainOutputs = []
    while annymore_main_outputs:
        MainOutput = theTool.FindMainOutput(inc)
        inc += 1
        if MainOutput is not None:
            mainOutputs.append(MainOutput.Name)
        else:
            annymore_main_outputs = False

    # get a dictionary of all the outputs!
    outPutList = theTool.GetOutputList()

    # magic sauce, combind the main outputs with all outputs, mainoutputs first
    for op in list(outPutList.values()):
        if op.Name not in mainOutputs:
            mainOutputs.append(op.Name)

    return mainOutputs


def get_input_list(theTool):
    """ This funcion will return a list of input values, starting with
                the most common outputs if any.
                (fusionToolObject)---> returns List of string names	"""

    annymore_main_inputs = True
    inc = 1
    mainInputs = []
    while annymore_main_inputs:
        MainInput = theTool.FindMainInput(inc)
        inc += 1
        if MainInput is not None:
            mainInputs.append(MainInput.Name)
        else:
            annymore_main_inputs = False

    # get a dictionary of all the outputs!
    inPutList = theTool.GetInputList()

    # Check for Effect Mask because it is a commen thing inside
    for ip in list(inPutList.values()):
        if ip.Name == "Effect Mask":
            mainInputs.append("Effect Mask")

    # magic sauce, combind the main outputs with all outputs, mainoutputs first
    for ip in list(inPutList.values()):
        if ip.Name not in mainInputs:
            mainInputs.append(ip.Name)

    return mainInputs


def remove_repeted_tools_from_list(toolList):
    """ This function will remove all repeted tool types from the given list
        using the TOOLS_RegID attribute"""
    # Make a new list to collect the uniuqe tools
    symplifiedList = []
    toolIDList = []
    for tool in toolList:
        # get tool ID
        ToolID = tool.GetAttrs()["TOOLS_RegID"]
        if ToolID not in toolIDList:
            symplifiedList.append(tool)

    return symplifiedList


def make_list_to_fusion_style_dictionary(theList):
    """ for some reason fusion uses a lot of dictionarys with keys 1.0, 2.0, 3.0...
        so this fucion is a quick way to make a dictionary like that out of a list"""

    nuberedList = []
    for i in range(len(theList)):
        nuberedList.append(float(i))
    fusion_style_dictionary = dict(list(zip(nuberedList, theList)))

    return fusion_style_dictionary


def make_that_connection(conecter, conecterOutput, conecty, conectyInput):
    """ """
    OPL = conecter.GetOutputList()
    IPL = conecty.GetInputList()

    for object in list(OPL.values()):
        if object.Name == conecterOutput:
            theOutput = object

    for objects in list(IPL.values()):
        if objects.Name == conectyInput:
            theInput = objects

    myConBoolean = theInput.ConnectTo(theOutput)
    # print "this is my Connection: ", myConBoolean
    return myConBoolean


#<---------------------------   UI  Dialog Def.   ------------------------->##
def make_dialog(leftMost, outputlist, toolList, listOfListOfInputs):
    outPutDropdown = make_list_to_fusion_style_dictionary(outputlist)
    inputDropdown = make_list_to_fusion_style_dictionary(listOfListOfInputs[0])

    dialog = {}
    dialog[1.0] = {1: " ", 2: "Text", "Default": "", "ReadOnly": True, "Width": 2}
    dialog[2.0] = {
        1: "Output",
        2: "Dropdown",
        "Name": leftMost.GetAttrs()["TOOLS_RegID"] + " Output:",
        "Options": outPutDropdown,
        "Width": 0.5,
    }
    dialog[3.0] = {
        1: "Input",
        2: "Dropdown",
        "Name": toolList[0].GetAttrs()["TOOLS_RegID"] + " Input:",
        "Options": inputDropdown,
        "Width": 0.5,
    }
    dialog[4.0] = {
        1: "OutPutOverride",
        2: "Text",
        "Name": "Output Override:",
        "Default": "",
        "Width": 0.5,
    }
    dialog[5.0] = {
        1: "InputOverride",
        2: "Text",
        "Name": "Input Override:",
        "Default": "",
        "Width": 0.5,
    }
    return dialog, outPutDropdown, inputDropdown


def process_userInfo(userInfo, outPutDropdown, inputDropdown):
    # Check for manual output  override on from user
    if userInfo["OutPutOverride"] != "":
        conecterOutput = userInfo["OutPutOverride"]
    else:
        conecterOutput = outPutDropdown[userInfo["Output"]]

    # Check for manual output  override on from user
    if userInfo["InputOverride"] != "":
        conectyInput = userInfo["InputOverride"]
    else:
        conectyInput = inputDropdown[userInfo["Input"]]

    return conecterOutput, conectyInput


def do_it():
    # Get the selection and seperate out the left most tool
    leftMost, toolList = get_selection_for_use()
    # check that there actually is something in the selection
    if leftMost is not None:
        # Get the list of output connections
        outputlist = get_output_list(leftMost)
        # check that there more than one thing in the selection
        if toolList is not None:
            # Get a list of all the tools without repeting tool types
            symplifiedOutputList = remove_repeted_tools_from_list(toolList)

            # Make a list of list for all the the different inputs
            listOfListOfInputs = []

            for theTool in symplifiedOutputList:
                aInputList = get_input_list(theTool)
                listOfListOfInputs.append(aInputList)
            # Make UI
            dialog, outPutDropdown, inputDropdown = make_dialog(
                leftMost, outputlist, toolList, listOfListOfInputs
            )

            userInfo = comp.AskUser("Connect Single Node to Many", dialog)

            if userInfo is not None:
                conecterOutput, conectyInput = process_userInfo(
                    userInfo, outPutDropdown, inputDropdown
                )

                # OK LETS MAKE THE CONNECTIONS!
                for tool in toolList:
                    myConBoolean = make_that_connection(
                        leftMost, conecterOutput, tool, conectyInput
                    )
                    if not myConBoolean:
                        print(
                            "Was not able to connect {0}.{1} with {2}.{3}".format(
                                leftMost.Name, conecterOutput, tool.Name, conectyInput
                            )
                        )

            else:
                print("User has cancelled out of Connect Node Dialog")

        else:
            print(
                "Only ONE object is selected, you need at least two nodes to make a connection"
            )

    else:
        print("Nothing selected can not make connections!")


# Run da Script Gurrrrllllll!
if __name__ == "__main__":
    do_it()
