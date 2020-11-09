"""
    AttributeSpreadsheet

    About:
        A spreadsheet script to edit the input parameters of multiple Fusion tools at once.

    Requires:
        Python 3.6
        Fusion 9/16, Davinci Resolve 16
        PySide2, installed automatically on first launch
    Notice:
        Written by Sven Neve (sven[AT]houseofsecrets[DOT]nl)
        Copyright (c) 2013 House of Secrets
        (http://www.svenneve.com)
    Updates:
        by Alexey Bogomolov
        (mail@abogomolov.com)
        v.0.1.6:
        2019/6/30
            -- update for Fusion 9/16 and Davinci Resolve (tested in v16)
            -- update to PySide2
            -- Python3 is required
        2019/12/17
        v.0.1.7:
            -- automatic PySide2 package installation for Windows and MacOs (Linux to be tested, but should work too)
        2020/1/24
        v.0.1.8:
            -- code cleanup, add some useful logs
        2020/10/23
        v.0.1.9:
            -- implement PointDelegate with some crazy hacks
            -- add math operations for Point data
            -- set FuID (Comboboxes) data to be line edit, until proper ComboDelegate is implemented
            -- further improve logging
            -- better error handling
        2020/10/24
        V.0.2:
            -- reset sorting by clicking corner button (default Fusion sorting order used)
            -- do not select all tools when the corner button is pressed
            -- set font to 12pt for MacOS (looks better on Retina Display)
            -- add clear search button
            -- remove enable/disable chache button, cache does not speed anything up
            -- auto hide progress bar
        2020/11/5
        V.0.2.1
            -- add tool Name and ID to a table. Now it is possible to sort tool inputs by tool name or tool ID.
            -- prevent linking tool to itself
            -- add expressions to a Point data: 
    License:
        The authors hereby grant permission to use, copy, and distribute this
        software and its documentation for any purpose, provided that existing
        copyright notices are retained in all copies and that this notice is
        included verbatim in any distributions. Additionally, the authors grant
        permission to modify this software and its documentation for any
        purpose, provided that such modifications are not distributed without
        the explicit consent of the authors and that existing copyright notices
        are retained in all copies.

        IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
        DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
        OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY DERIVATIVES
        THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF
        SUCH DAMAGE.

        THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
        INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
        THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND
        DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
        UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
"""

__VERSION__ = 2.1
PKG = "PySide2"
PKG_VERSION = "5.13.2"

import datetime
import os
import platform
import re
import subprocess
import sys
from pprint import pprint as pp


def dprint(string):
    """override print() function"""
    __builtins__.print(f"[AS] : {string}")

print = dprint

try:
    from PySide2.QtWidgets import (
        QAbstractItemView,
        QAbstractButton,
        QApplication,
        QCheckBox,
        QComboBox,
        QHBoxLayout,
        QHeaderView,
        QItemDelegate,
        QLineEdit,
        QMainWindow,
        QProgressBar,
        QPushButton,
        QSizeGrip,
        QSizePolicy,
        QSpinBox,
        QTableView,
        QTableWidget,
        QTableWidgetItem,
        QToolButton,
        QVBoxLayout,
        QWidget,
    )
    from PySide2.QtCore import (
        QAbstractTableModel,
        QItemSelectionModel,
        QModelIndex,
        QObject,
        QPoint,
        QRect,
        QSize,
        QSortFilterProxyModel,
        Qt,
        SIGNAL,
        SLOT,
        Signal,
    )
    from PySide2.QtGui import (
        QBrush,
        QPainter,
        QColor,
    )

except (ImportError, ModuleNotFoundError):

    def run_command(command):
        process = subprocess.Popen(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        while True:
            output = process.stdout.readline().decode()
            if output == "" or process.poll() is not None:
                break
            if output:
                print(output.strip())
        rc = process.poll()
        return rc

    if sys.version_info.major < 3:
        print("Python 3.6 is required")
        sys.exit()
    print("No Pyside2 module found, trying to install...")

    if platform.system() == "Windows":
        python_executable = os.path.join(os.__file__.split("lib")[0], "python.exe")
    elif platform.system() in ["Darwin", "Linux"]:
        python_executable = os.path.join(os.__file__.split("lib/")[0], "bin", "python3")
    try:
        import pip
        pip_version = int(pip.__version__.split(".")[0])
        if pip_version < 20:
            print("updating pip")
            run_command([python_executable, "-m", "pip", "install", "-U", "pip"])
        pyside_cmd = [
            python_executable,
            "-m",
            "pip",
            "install",
            "{}>={}".format(PKG, PKG_VERSION),
        ]
        rc = run_command(pyside_cmd)
        if not rc:
            print("Pyside2 is installed")
            print("Now try to launch the script again!")
            sys.exit()
        else:
            print(
                "Pyside2 installation has failed for some reason, please try again..."
                " Check if internet connection is available."
                " Please report this issue: mail@abogomolov.com"
            )
            sys.exit()
    except ImportError:
        print("Check if pip version 10+ is installed, then launch the script again")
        sys.exit()


class FUIDComboDelegate(QItemDelegate):
    """
    A delegate that places a fully functioning QComboBox in every
    cell of the column to which it's applied

    TODO: make it work
    """

    def __init__(self, parent):

        QItemDelegate.__init__(self, parent)
        self.items = ["None"]

    def createEditor(self, parent, option, index):
        combo = QComboBox(parent)
        combo.addItems(self.items)
        self.connect(
            combo,
            SIGNAL("currentIndexChanged(int)"),
            self,
            SLOT("currentIndexChanged()"),
        )
        return combo

    def setEditorData(self, editor, index):
        editor.blockSignals(True)
        # TODO: implement ComboBox editor
        # print(index.model().data(index))
        # editor.setCurrentIndex(self.items.index(str(index.model().data(index))))
        # editor.setData("Domain")
        editor.blockSignals(False)

    def setModelData(self, editor, model, index):
        model.setData(index, editor.currentIndex())

    def currentIndexChanged(self):
        self.commitData.emit(self.sender())


class LineEditDelegate(QItemDelegate):
    """
    A delegate that places a fully functioning QLineEdit in every
    cell of the column to which it's applied
    """

    def __init__(self, parent):
        QItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        lineEdit = QLineEdit(parent)
        self.connect(
            lineEdit, SIGNAL("valueChanged(int)"), self, SLOT("valueChanged()")
        )
        return lineEdit

    def setEditorData(self, editor, index):
        editor.blockSignals(True)
        editor.setText(index.model().data(index))
        editor.blockSignals(False)

    def setModelData(self, editor, model, index):
        # We don't set the model data, the TableView does that for us.
        # Rather, we set what the value from the editor is as the data that the FusionInput needs to use to process the
        # actual values. This allows us to do things like compound assignments or setting/editing expressions.
        model.sourceModel().stored_edit_role_data = editor.text()
        pass


class PointDelegate(QItemDelegate):
    """
    Create a Table Widget with Point(x, y) data.
    """

    def __init__(self, parent):

        QItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        qtable_widget = QTableWidget(1, 2, parent)
        qtable_widget.verticalHeader().setVisible(False)
        qtable_widget.setMinimumHeight(30)
        qtable_widget.horizontalHeader().setVisible(False)
        qtable_widget.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.connect(
            qtable_widget,
            SIGNAL("currentIndexChanged(int)"),
            self,
            SLOT("currentIndexChanged()"),
        )
        return qtable_widget

    def setEditorData(self, editor, index):
        point_data = str(index.model().data(index))
        try:
            substring = re.sub("[{} ]", "", point_data)
            dict_point = dict(ss.split(":") for ss in substring.split(","))
            a = QTableWidgetItem(dict_point["1.0"])
            b = QTableWidgetItem(dict_point["2.0"])
            editor.blockSignals(True)
            editor.setItem(0, 0, a)
            editor.setItem(0, 1, b)
            editor.blockSignals(False)
        except ValueError:
            for i in range(2):
                editor.setItem(0, i, QTableWidgetItem("-x"))

    def setModelData(self, editor, model, index):
        try:
            x = editor.item(0,0).text()
            y = editor.item(0,1).text()
            data = [x, y]
            model.sourceModel().stored_edit_role_data = data
        except AttributeError:
            print("Point data not applicable here")


class TableView(QTableView):
    """
    We inherit the QTableView so we can write our own item delegation and multi select editing data commit.
    """

    def __init__(self, parent):
        QTableView.__init__(self, parent)
        self.resizeRowsToContents()
        self.verticalHeader().setDefaultSectionSize(20)
        self.setVerticalScrollMode(QAbstractItemView.ScrollPerPixel)
        self.setHorizontalScrollMode(QAbstractItemView.ScrollPerPixel)
        self.center = QPoint(-10, -10)
        self.startCenter = QPoint(-10, -10)
        self.mouseIsDown = False

    def paintEvent(self, event):
        if self.mouseIsDown:
            painter = QPainter(self.viewport())
            painter.drawLine(self.center, self.startCenter)
        QTableView.paintEvent(self, event)

    def mousePressEvent(self, event):
        if event.buttons() == Qt.MiddleButton:
            self.mouseIsDown = True
            self.center = self.startCenter = QPoint(event.pos().x(), event.pos().y())

        elif event.buttons() == Qt.LeftButton:
            self.mouseIsDown = False
            QTableView.mousePressEvent(self, event)

    def create_value(self, sm, idxs):
        target_tool = sm.toolDict[idxs.row() + 1].Name
        try:
            value = "={}.{}".format(
                target_tool,
                sm.toolsInputs[idxs.row()].get(sm.attributeNameKeys[idxs.column()]).ID,
            )
            self.commitDataDo(value)
        except KeyError:
            pass

    def mouseReleaseEvent(self, event):
        if self.mouseIsDown:
            self.mouseIsDown = False
            idxs = self.model().mapToSource(self.indexAt(self.center))
            sm = self.model().sourceModel()
            if len(self.selectionModel().selection().indexes()) <= 1:
                idxt = self.model().mapToSource(self.indexAt(self.startCenter))
                if idxs.row() == idxt.row() and idxs.column() == idxt.column():
                    print("cannot link the input to itself")
                    return
                if (
                    idxs.row() > -1
                    and idxs.column() > -1
                    and idxt.row() > -1
                    and idxt.column() > -1
                ):
                    fusionInput = sm.toolsInputs[idxt.row()].get(
                        sm.attributeNameKeys[idxt.column()]
                    )
                    fusionOutput = sm.toolsInputs[idxs.row()].get(
                        sm.attributeNameKeys[idxs.column()]
                    )
                    # Select the first cell by sampling the area
                    # under the first clicked mouse center
                    self.setSelection(
                        QRect(self.startCenter, self.startCenter),
                        QItemSelectionModel.SelectCurrent,
                    )
            self.create_value(sm, idxs)
            self.viewport().repaint()
        QTableView.mouseReleaseEvent(self, event)

    def mouseMoveEvent(self, event):
        if self.mouseIsDown:
            self.center = QPoint(event.pos().x(), event.pos().y())
            self.viewport().repaint()
        QTableView.mouseMoveEvent(self, event)

    def updateColumns(self):
        """
        updateColumns sets the QItemDelegates for the columns 
        (this way we can make a distinction between various data types for Fusion)

        The columns are grouped by their attribute/parameter names, so tools with attributes that have conflicting
        parameter/input data types might (and probably will) error out.

        There's also the added problem that expression are basically strings attached to inputs, which makes this an
        even more troublesome task (we may have to forget per column item delegates all together and look for an
        alternative.)
        """
        tm = self.model()

        # filteredKeys contains the column data types with the indices properly sorted after filtering.
        for k, v in enumerate(tm.filteredKeys):
            # print(f"{k} : {v}")
            if v == "Point":
                self.setItemDelegateForColumn(k, PointDelegate(self))
            # elif v == "FuID":
            #     self.setItemDelegateForColumn(k, FUIDComboDelegate(self))
            elif v in ["Number", "Float", "Int", "Clip", "Text", "FuID"]:
                self.setItemDelegateForColumn(k, LineEditDelegate(self))
        self.resizeColumnsToContents()

    def commitData(self, editor):
        """
        commitData makes sure all multiselecteed cells get the same values applied as the edited cell.
        """
        super(TableView, self).commitData(editor)
        # We need to remap the model index from the filtered proxymodel indices to the source model indices
        tm = self.model().sourceModel()  # mapToSource(self.currentIndex()).model()
        # Use a stored edit role text
        value = tm.stored_edit_role_data
        self.commitDataDo(value)

    def commitDataDo(self, value):
        tm = self.model().sourceModel()
        comp.StartUndo("Attribute Spreadsheet")
        try:
            for isr in self.selectionModel().selection():
                for s in isr.indexes():
                    input_name = self.model().headerData(s.column(), Qt.Horizontal, Qt.DisplayRole)
                    tool_name = self.model().headerData(s.row(), Qt.Vertical, Qt.DisplayRole)
                    input_name = input_name.replace("\n", " ").strip()
                    if isinstance(value, list) and len(value) == 2:
                        try:
                            x, y = [float(i) for i in value]
                        except ValueError:
                            x, y = value
                        print(f"setting {tool_name} [{input_name}] to [{x} : {y}]")
                    else:
                        print(f"setting {tool_name} [{input_name}] to {value}")
                    tm.setData(self.model().mapToSource(s), value, Qt.EditRole)
            comp.EndUndo(True)
        except Exception as e:
            comp.EndUndo(True)
            raise e


class TableSortFilterProxyModel(QSortFilterProxyModel):
    """
    We inherit QSortFilterProxyModel so we can filter columns by attribute data type and rows by tool name
    """

    def __init__(self, parent=None):
        QSortFilterProxyModel.__init__(self, parent)
        self.filteredKeys = []

    def filterAcceptsRow(self, source_row, source_parent):
        return True

    def filterAcceptsColumn(self, source_column, source_parent):
        pattern = self.filterRegExp().pattern()
        if pattern == "":
            self.filteredKeys = self.sourceModel().attributeDataTypes
            return True

        index = self.sourceModel().createIndex(0, source_column)
        attrName = self.sourceModel().data(index, Qt.UserRole)
        dataType = self.sourceModel().data(index, Qt.UserRole + 1)

        keys = pattern.split(" ")
        for key in keys:
            if not key:
                return False
            if key.lower() in attrName.lower():
                self.filteredKeys.append(dataType)
                return True
        return False


class FusionInput():
    """
    A Fusion Input cache/wrapper around the actual Input retrieved from the tool input list.
    """

    def __init__(self, fusionInput):
        self.fusionInput = fusionInput
        self.cache = False
        self.keyFrames = fusionInput.GetKeyFrames()
        self.keyFrameValues = dict()
        self.hasKeyFrames = len(self.keyFrames) > 0
        self.expression = fusionInput.GetExpression()
        self.attributes = fusionInput.GetAttrs()
        self.Name = self.attributes["INPS_Name"]
        self.ID = self.attributes["INPS_ID"]

    def Refresh(self):
        self.GetAttrs()
        self.GetKeyFrames()

    def GetAttrs(self, attr=None):
        if attr:
            if self.cache:
                return self.attributes.get(attr, None)
            else:
                return self.fusionInput.GetAttrs(attr)
        else:
            if self.cache:
                return self.attributes
            else:
                return self.fusionInput.GetAttrs()

    def GetKeyFrames(self):
        if self.cache:
            return self.keyFrames
        else:
            return self.fusionInput.GetKeyFrames()

    def GetExpression(self):
        if self.cache:
            return self.expression
        else:
            return self.fusionInput.GetExpression()

    def SetExpression(self, expression):
        self.expression = expression
        self.fusionInput.SetExpression(expression)
        self.Refresh()

    def __getitem__(self, item):
        return self.fusionInput[item]

    def __setitem__(self, key, value):
        # debug - print input attributes  
        if value == "p":
            pp(self.attributes)
            return

        if self.GetExpression():
            if value == "-x" or "-x" in value:
                print("Expression cleared")
                self.SetExpression(None)
            else:
                print("This input is linked by expression. Use '-x' to clear expression")
            return

        if not isinstance(value, list) and value[0] == "=":
             self.SetExpression(value.lstrip("="))
             return

        if self.attributes["INPS_DataType"] == "Number":
            if value[0:2] in ["+=", "-=", "*=", "/=", "%="] and len(value) >= 3:
                # expecting an compound assignment
                print("math:", value[2:])
                if self.is_number(value[2:]):
                    operator = value[0]
                    value = float(value[2:])
                    if operator == "+":
                        value = float(self.fusionInput[key] + value)
                    elif operator == "-":
                        value = float(self.fusionInput[key] - value)
                    elif operator == "/":
                        value = float(self.fusionInput[key] / value)
                    elif operator == "*":
                        value = float(self.fusionInput[key] * value)
                    elif operator == "%":
                        value = float(self.fusionInput[key] % value)
            if self.attributes["INPID_InputControl"] == "MultiButtonIDControl":
                if value.lower() in ["0", "no", "off", "false"]:
                    value = 0
                elif value.lower() in ["1", "yes", "on", "true"]:
                    value = 1
                elif self.is_number(value):
                    value = round(min(1, max(0, float(value))))
                else:
                    value = self.fusionInput[key]
            if self.is_number(value):
                value = float(value)
            else:
                print("this field requires number input")
                value = self.fusionInput[key]

        if self.attributes["INPS_DataType"] == "Point":
            if value[0] == "p":
                pp(self.attributes)
                return
            math_ops = ["+=", "-=", "*=", "/=", "%="]
            compute_values = []
            for i, v in enumerate(value):
                if any(op in v[:2] for op in math_ops) and len(v) >= 3:
                    # expecting an compound assignment
                    if self.is_number(v[2:]):
                        operator = v[0]
                        v = float(v[2:])
                        if operator == "+":
                            v = float(self.fusionInput[key][float(i+1)] + v)
                        elif operator == "-":
                            v = float(self.fusionInput[key][float(i+1)] - v)
                        elif operator == "/":
                            v = float(self.fusionInput[key][float(i+1)] / v)
                        elif operator == "*":
                            v = float(self.fusionInput[key][float(i+1)] * v)
                        elif operator == "%":
                            v = float(self.fusionInput[key][float(i+1)] % v)
                    else:
                        v = self.fusionInput[key]
                compute_values.append(v)
            try:
                value = [float(i) for i in compute_values]
            except ValueError:
                x, y = value
                if x[0] == "=" or y[0] == "=" and len(value) > 1:
                    value = [v.lstrip("=") for v in value]
                    self.SetExpression(f"Point({value[0]}, {value[1]})")
                else:
                    print("Point data accepts only numbers and expressions")
                return
        self.fusionInput[key] = value
        self.keyFrames = self.fusionInput.GetKeyFrames()
        self.value = self.fusionInput[key]

    @staticmethod
    def is_number(s):
        try:
            float(s)
            return True
        except ValueError:
            return False


class Communicate(QObject):
    broadcast = Signal(object)

    def __init__(self):
        QObject.__init__(self)

    def send(self, value):
        self.broadcast.emit(value)


class TableModel(QAbstractTableModel):
    """
    We inherit the QAbstractTableModel so we can do our own QItemDelegates and display en setData roles
    """

    def __init__(self, parent):
        QAbstractTableModel.__init__(self, parent)

        self.communicate = Communicate()

        self.inputsToSkip = {}
        self.data_types_to_skip = {}

        self.backgroundRoleMethod = self.backgroundRole

        self.toolDict = dict()

        self.attributeNameKeys = list()  # List of unique attribute name keys
        self.attributeDataTypes = list()  # this list is coupled to the key list

        self.toolsInputs = list()
        self.toolsAttributes = list()

        # this stores the editrole data for multi commits (this way we get inline math to work)
        self.stored_edit_role_data = None

    def load_fusion_data(self):
        self.communicate.send("loading tools and inputs")
        startTime = datetime.datetime.now()

        comp = fu.GetCurrentComp()
        if not comp:
            print("No comp data found. Probably both Resolve and Fusion are loaded?")
            sys.exit()
        self.toolDict.clear()
        self.toolDict = comp.GetToolList(True)
        self.attributeNameKeys = []  # List of unique attribute name keys
        self.attributeDataTypes = []  # this list is coupled to the key list
        self.toolsInputs = []
        self.toolsAttributes = []
        progress = 0
        for tool in self.toolDict.values():
            toolInputs = {}
            toolInputsAttributes = {}
            for v in tool.GetInputList().values():
                f = FusionInput(v)
                if f.attributes["INPS_DataType"] not in self.data_types_to_skip:
                    key = f.Name
                    toolInputs[key] = f
                    attributeDataType = f.attributes["INPS_DataType"]
                    toolInputsAttributes[key] = f.attributes
                    self.appendUnique(key, attributeDataType)
            if len(toolInputs):
                self.toolsInputs.append(toolInputs)
                self.toolsAttributes.append(toolInputsAttributes)
                pass
            self.appendUnique("Name")
            self.appendUnique("ID")
            toolInputs["Name"] = tool.Name
            toolInputs["ID"] = tool.ID
            progress += 1
            self.communicate.send((100.0 / (len(self.toolDict))) * progress)
        self.communicate.send(
            "Done loading, execution time : " + str(datetime.datetime.now() - startTime)
        )

    def appendUnique(self, str_to_add, type_to_add=None):
        """
        Helper method to add unique tool name and unique attributes to some lists
        """
        if str_to_add not in self.attributeNameKeys:
            self.attributeNameKeys.append(str_to_add)
            self.attributeDataTypes.append(type_to_add)

    def rowCount(self, parent=QModelIndex()):
        return len(self.toolDict)

    def columnCount(self, parent=QModelIndex()):
        return len(self.attributeNameKeys)

    def data(self, index, role=Qt.DisplayRole):
        """
        Default data method with some extra UserRoles and BackgroundRoles for drawing keyframes.
        This method needs some extra work as a lot of stuff is not written optimal.
        """
        if not index.isValid():
            return None

        r = self.toolsInputs[index.row()].get(
            self.attributeNameKeys[index.column()], None
        )

        if role == Qt.DisplayRole:
            if isinstance(r, str):
                return r
            if not r or r.attributes.get("INPID_InputControl") == "SplineControl":
                return None
            return (
                str(r[comp.CurrentTime]) if r else r
            )  # force it to be string so it shows EVERYTHING

        elif role == Qt.EditRole:
            return r[comp.CurrentTime] if r else r
        elif role == Qt.UserRole:
            return self.attributeNameKeys[index.column()]
        elif role == Qt.UserRole + 1:
            return self.attributeDataTypes[index.column()]
        elif role == Qt.BackgroundRole:
            return self.backgroundRoleMethod(index, role)
        else:
            return

    def noRole(self, index, role):
        return None

    def backgroundRole(self, index, role):
        r = self.toolsInputs[index.row()].get(
            self.attributeNameKeys[index.column()], None
        )
        if r:
            b = QBrush()
            b.setStyle(Qt.SolidPattern)
            if isinstance(r, str):
                return None
            if r.attributes.get("INPID_InputControl", None) == "SplineControl":
                b.setColor(QColor(180, 64, 92, 64))
                return b
            if r.GetExpression():
                b.setColor(QColor(92, 64, 92, 180))
                return b
            if r.GetAttrs("INPB_Connected"):
                if comp.CurrentTime in list(r.keyFrames.values()):
                    b.setColor(QColor(62, 92, 62, 180))
                else:
                    b.setColor(QColor(64, 78, 120, 180))
                return b
        return None

    def headerData(self, section, orientation, role):
        if role == Qt.DisplayRole:
            if orientation == Qt.Horizontal:
                return self.splitHeaderName(self.attributeNameKeys[section])
            if orientation == Qt.Vertical:
                return self.toolDict[section + 1].Name
        return None

    def setData(self, index, value, role=Qt.DisplayRole):
        """
        Set our data, we use the tool's attribute MinAllowed and MaxAllowed where possible (as Fusion sometimes allows
        to set data outside legal values (on Booleans for example), resulting in 'buggy' behaviour.

        A good idea might be to move the sensitization to the fusionInput class.

        Needs more work
        """
        if not index.isValid():
            return
        elif role == Qt.EditRole:
            r = self.toolsInputs[index.row()].get(
                    self.attributeNameKeys[index.column()], None
                    )
            if r:
                if isinstance(value, list):
                    # print("setting point data: ", value)
                    r[comp.CurrentTime] = value
                else:
                    # print("setting string data: ", str(value))
                    r[comp.CurrentTime] = str(value)
        return True

    def flags(self, index):
        if not index.isValid():
            return Qt.ItemIsEnabled
        return Qt.ItemIsEditable | Qt.ItemIsSelectable | Qt.ItemIsEnabled

    def splitHeaderName(self, key):
        """
        Helper method for QHeaderView labels
        We split our horizontal headers to use 2 lines of text
        """
        header_name_list = key.split(" ")
        header_name = ""
        c = 0
        if len(header_name_list) == 2:
            header_name = "\n".join(header_name_list)
        else:
            for a in header_name_list:
                if c < 8:
                    header_name += " " + a if len(a) > 1 else "" + a
                    c += len(a) + 1
                else:
                    header_name += "\n" + a
                    c = 0
        return header_name


class MainWindow(QMainWindow):
    def __init__(self, parent=None):
        QMainWindow.__init__(self, parent)
        self.inputsToSkip = {
            "SceneInput": 0,
            "MaterialInput": 1,
            "Diffuse Color Material": 2,
        }
        self.data_types_to_skip = {
            "Image": 0,
            "ColorCurves": 1,
            "Histogram": 2,
            "Mask": 3,
            "DataType3D": 4,
            "Gradient": 5,
            "MtlGraph3D": 6,
        }
        self.createWidgets()
        self.setWindowFlags(
            self.windowFlags() | Qt.CustomizeWindowHint | Qt.WindowStaysOnTopHint
        )

    def createWidgets(self):
        self._tm = TableModel(self)
        self._tm.inputsToSkip = self.inputsToSkip
        self._tm.data_types_to_skip = self.data_types_to_skip
        self._tv = TableView(self)
        self.alwaysOnTop = QCheckBox("Always on top")
        self.alwaysOnTop.setChecked(True)
        self.clearButton = QPushButton()
        self.clearButton.setText("Clear")
        self.clearButton.setFixedSize(QSize(70, 20))
        self.refreshButton = QPushButton()
        self.refreshButton.setText("Refresh")
        self.refreshButton.setFixedSize(QSize(130, 20))
        self.searchLine = QLineEdit(self)
        self.searchLine.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        self.statusBar().showMessage("System Status | Normal")
        # self.cacheButton = QToolButton()
        # self.cacheButton.setCheckable(True)
        # self.cacheButton.setChecked(False)
        # self.cacheButton.setText('use cache')


        v_box = QVBoxLayout()
        h_box = QHBoxLayout()
        h_box.setAlignment(Qt.AlignRight)
        h_box.addWidget(self.alwaysOnTop)
        h_box.addWidget(self.clearButton)
        h_box.addWidget(self.searchLine)
        h_box.addWidget(self.refreshButton)
        # h_box.addWidget(self.cacheButton)
        h_box.setContentsMargins(0, 0, 0, 0)
        v_box.addLayout(h_box)
        v_box.addWidget(self._tv)

        self.corner = self._tv.findChild(QAbstractButton)

        sizeGrip = QSizeGrip(self)
        v_box.setContentsMargins(2, 2, 2, 2)
        sizeGrip.setWindowFlags(Qt.WindowStaysOnTopHint)
        sizeGrip.move(0, 200)

        central_widget = QWidget()
        central_widget.setLayout(v_box)
        self.setCentralWidget(central_widget)
        self.statusBar()

        self.proxyModel = TableSortFilterProxyModel()
        self.proxyModel.setFilterCaseSensitivity(Qt.CaseInsensitive)
        self.proxyModel.setSortCaseSensitivity(Qt.CaseInsensitive)
        self.proxyModel.setDynamicSortFilter(True)
        self._tv.setModel(self.proxyModel)

        self.progressBar = QProgressBar()
        self.statusBar().addPermanentWidget(self.progressBar)
        # This is simply to show the bar
        self.progressBar.setValue(0)

        # Connections
        # self.cacheButton.clicked.connect(self.setCacheMode)
        self.alwaysOnTop.stateChanged.connect(self.changeAlwaysOnTop)
        self.searchLine.textChanged.connect(self.filterRegExpChanged)
        self.clearButton.pressed.connect(self.clear_search)
        self.refreshButton.pressed.connect(self.reloadFusionData)
        self._tm.communicate.broadcast.connect(self.communication)
        self.corner.clicked.connect(self.reset_sorting)

    def reset_sorting(self):
        """
        WIP, current behavior: reset sorting to initial state
        """
        self.proxyModel.sort(-1)
        self._tv.clearSelection()

    def clear_search(self):
        self.searchLine.clear()

    def changeAlwaysOnTop(self):
        if self.alwaysOnTop.checkState():
            self.setWindowFlags(
                self.windowFlags() | Qt.CustomizeWindowHint | Qt.WindowStaysOnTopHint
            )
            self.show()
        else:
            self.setWindowFlags(
                self.windowFlags() ^ (Qt.CustomizeWindowHint | Qt.WindowStaysOnTopHint)
            )
            self.show()

    def communication(self, value):
        if not value:
            return
        if isinstance(value, float):
            self.progressBar.setValue(value)
        if isinstance(value, str):
            self.statusBar().showMessage(value)
        self.progressBar.setVisible(True)
        if self.progressBar.value() in [0, 100]:
            self.progressBar.setVisible(False)

    def loadFusionData(self):
        self._tm.load_fusion_data()
        self.proxyModel.setSourceModel(self._tm)
        self._tv.setSortingEnabled(True)
        self._tv.updateColumns()

    def reloadFusionData(self):
        self.proxyModel.setSourceModel(None)
        self._tm.load_fusion_data()
        self.proxyModel.setSourceModel(self._tm)
        self._tv.setSortingEnabled(True)
        self._tv.updateColumns()

    def setCacheMode(self):
        # Not sure where this goes, is it a method for the TableModel? or should we inherit the dict that has all
        # the fusion input caches and have that cycle through all contained fusion inputs?
        # Cache does not seem to speed up things. For now we just disable it

        cache_status = self.cacheButton.isChecked()
        for input_list in self._tm.toolsInputs:
            for tool_input in list(input_list.values()):
                try:
                    tool_input.cache = cache_status
                except AttributeError:
                    # pass str values
                    pass

    def filterRegExpChanged(self):
        """
        This makes sure that the ItemDelegates for the TableView columns get updated, we have to do this as for some
        reason Qt has TableView column delegates decoupled from the underlying ProxyModel and indices get out of sync
        during sorting and filtering.
        """

        regExp = self.searchLine.text()
        self.proxyModel.filteredKeys = []
        self.proxyModel.setFilterRegExp(regExp)
        self._tv.updateColumns()

# increase font size for Retina Display on Mac
font_size = 12 if platform.system() == "Darwin" else 9

css = f"""
*, QTableCornerButton::section {{
    font: {font_size}pt 'tahoma';
    color: rgb(192, 192, 192);
    background-color: rgb(52, 52, 52);
    }}

QMainWindow {{
    border-top: 1px solid rgb(80,80,80);
    border-left: 1px solid rgb(80,80,80);
    border-right: 1px solid rgb(33,33,33);
    border-bottom: 1px solid rgb(33,33,33);
    }}

QTableView {{
    background-color: rgb(52, 52, 52);
    border-color: rgb(33, 33, 33);
    border-bottom-color: rgb(34, 34, 34);
    color: rgb(192, 192, 192);
    gridline-color: rgb(34, 34, 34);
    }}

QHeaderView::section {{
    background-color: rgb(100, 100, 100);
    color: rgb(0,0,0);
    padding: 0;
    }}

QTableView::item {{
    border: 0px;
    padding-left: 8px;
    }}

QToolButton {{
    background-color: rgb(52, 52, 52);
    }}

QToolButton:checked {{
    background-color: rgb(70, 86, 134);
    }}

QTableWidget::item {{
    text-align: top center;
    border-style: outset;
    border-width: 4px;
    background-color: rgb(30,30,30);
    }}
"""

# We define fu and comp as globals so we can basically run the same script from console as well from within Fusion
# If both Resolve and Fusion are running, Fusion data may load improperly. So we check for scriptapp,
# and the script would not load if there's a confusion about which instance of Fusion to use. 

if __name__ == "__main__":
    fu = bmd.scriptapp("Fusion")

    if not fu:
        raise Exception("No instance of Fusion found running.")
    comp = fu.GetCurrentComp()

    main_app = QApplication.instance()  # checks if QApplication already exists. Seems to be always None
    if not main_app:  # create QApplication if it doesnt exist
        main_app = QApplication([])
    main_app.setStyleSheet(css)
    main = MainWindow()
    main.setWindowTitle("Attribute Spreadsheet")
    main.setMinimumSize(QSize(640, 200))
    main.show()
    main.loadFusionData()
    main_app.exec_()
