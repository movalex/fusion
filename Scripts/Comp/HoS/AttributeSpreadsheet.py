"""
    hos_AttributeSpreadsheet

    About:
        A spreadsheet script to edit the input parameters of multiple Fusion tools at once.

    Requires:
        Python 3.6
        Fusion 9/16, Davinci Resolve 16
        PySide2, installed automatically on Windows, MacOs or (not tested) Linux
    Notice:
        Written by Sven Neve (sven[AT]houseofsecrets[DOT]nl)
        Copyright (c) 2013 House of Secrets
        (http://www.svenneve.com)

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

        2019/6/30
        updates by Alex Bogomolov mail@abogomolov.com
        v.6:
            -- update for Fusion 9/16
            -- Python3 (dropped Python2 support completely, sorry for that)
            -- update to PySide2 compatibility
        2019/12/17
        v.7:
            -- automatic PySide2 package installation for Windows and MacOs (Linux to be tested)
        2020/1/24
        v.8
            -- cleanup, add some useful logs
"""

__VERSION__ = 8
PKG = "PySide2"
PKG_VERSION = "5.13.2"

import datetime
import sys
import os
import subprocess
import platform
import builtins


def print(*args, **kwargs):
    """custom print() function"""
    builtins.print("[AttributeSpreadsheet] : ", end="")
    return builtins.print(*args, **kwargs)


try:
    from PySide2.QtWidgets import (
        QMainWindow,
        QApplication,
        QHBoxLayout,
        QTableWidget,
        QWidget,
        QVBoxLayout,
        QPushButton,
        QSizeGrip,
        QTableView,
        QAbstractItemView,
        QComboBox,
        QItemDelegate,
        QHeaderView,
        QDoubleSpinBox,
        QSpinBox,
        QLineEdit,
        QProgressBar,
        QToolButton,
        QCheckBox,
        QSizePolicy,
    )
    from PySide2.QtCore import (
        QSize,
        Qt,
        QAbstractTableModel,
        QModelIndex,
        SIGNAL,
        SLOT,
        QPoint,
        QObject,
        Signal,
        QRect,
        QItemSelectionModel,
        QSortFilterProxyModel,
    )
    from PySide2.QtGui import QBrush, QPainter, QColor

except (ImportError, ModuleNotFoundError):

    def run_comand(command):
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
        if pip_version < 19:
            print("updating pip")
            run_comand([python_executable, "-m", "pip", "install", "-U", "pip"])
        pyside_cmd = [
            python_executable,
            "-m",
            "pip",
            "install",
            "{}>={}".format(PKG, PKG_VERSION),
        ]
        rc = run_comand(pyside_cmd)
        if not rc:
            print("Pyside2 installation successful")
            print("Now try to launch the script again!")
            sys.exit()
        else:
            print(
                "Pyside2 installation has failed for some reason, please try again... Or not."
            )
            sys.exit()
    except ImportError:
        print("Check if pip version 10+ is installed, then launch the script again")
        sys.exit()


class FUIDComboDelegate(QItemDelegate):
    """
    A delegate that places a fully functioning QComboBox in every
    cell of the column to which it's applied
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
        editor.setCurrentIndex(int(float(index.model().data(index))))
        editor.blockSignals(False)

    def setModelData(self, editor, model, index):
        model.setData(index, editor.currentIndex())

    def currentIndexChanged(self):
        self.commitData.emit(self.sender())


class NumberDelegate(QItemDelegate):
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

    def valueChanged(self):
        self.commitData.emit(self.sender())


class PointDelegate(QItemDelegate):
    """
    Need to figure out how to do this bastard.
    """

    def __init__(self, parent):

        QItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        combo = QTableWidget(1, 2, parent)
        combo.verticalHeader().setVisible(False)
        combo.horizontalHeader().setVisible(False)
        combo.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.connect(
            combo,
            SIGNAL("currentIndexChanged(int)"),
            self,
            SLOT("currentIndexChanged()"),
        )
        print("combo: ", combo)
        return combo

    def setEditorData(self, editor, index):
        print("index", index)
        editor.blockSignals(True)
        editor.setCurrentIndex(int(index.model().data(index)))
        editor.blockSignals(False)

    def setModelData(self, editor, model, index):
        model.setData(index, editor.currentIndex())

    def currentIndexChanged(self):
        self.commitData.emit(self.sender())


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
        # startTime = datetime.datetime.now()
        if self.mouseIsDown:
            painter = QPainter(self.viewport())
            # painter.drawEllipse(self.center,10,10)
            painter.drawLine(self.center, self.startCenter)
        QTableView.paintEvent(self, event)
        # print('Update time : ' + str(datetime.datetime.now()-startTime))

    def mousePressEvent(self, event):
        if event.buttons() == Qt.MiddleButton:
            self.mouseIsDown = True
            self.center = self.startCenter = QPoint(event.pos().x(), event.pos().y())

        elif event.buttons() == Qt.LeftButton:
            self.mouseIsDown = False
            QTableView.mousePressEvent(self, event)

    def create_value(self, sm, idxs):
        value = "={}.{}".format(
            sm.toolDict[idxs.row() + 1].Name,
            sm.toolsInputs[idxs.row()].get(sm.attributeNameKeys[idxs.column()]).ID,
        )
        self.commitDataDo(value)

    def mouseReleaseEvent(self, event):
        if self.mouseIsDown:
            self.mouseIsDown = False
            idxs = self.model().mapToSource(self.indexAt(self.center))
            sm = self.model().sourceModel()
            if len(self.selectionModel().selection().indexes()) <= 1:
                idxt = self.model().mapToSource(self.indexAt(self.startCenter))
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
        updateColumns sets the QItemDelegates for the columns (this way we can make a distinction between various
        data types for Fusion.

        The columns are grouped by their attribute/parameter names, so tools with attributes that have conflicting
        parameter/input data types might (and probably will) error out.

        There's also the added problem that expression are basically strings attached to inputs, which makes this an
        even more troublesome task (we may have to forget per column item delegates all together and look for an
        alternative.)
        """
        tm = self.model()
        # print(tm.filteredKeys)

        # filteredKeys contains the column data types with the indices properly sorted after filtering.
        for k, v in enumerate(tm.filteredKeys):
            if v == "Point":
                self.setItemDelegateForColumn(k, PointDelegate(self))
            elif v == "FuID":
                self.setItemDelegateForColumn(k, FUIDComboDelegate(self))
            elif v in ["Number", "Float", "Int"]:
                self.setItemDelegateForColumn(k, NumberDelegate(self))
        pass
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
        # print(f'got value: {value}')
        tm = self.model().sourceModel()
        comp.StartUndo("Attribute Spreadsheet")
        try:
            for isr in self.selectionModel().selection():
                for s in isr.indexes():
                    print(
                        f"setting value {value} at row {s.row()+1}, column {s.column()+1}"
                    )
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


class FusionInput(object):
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
        # print('__setitem__: ', value)

        # Some debugging values
        if value == "p":
            print(self.attributes.keys())
            return

        if self.GetExpression() or value[0] == "=":
            if value == "=-x":
                self.SetExpression(None)
            else:
                # print("settings expression")
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
                    print("setting a math value")
                else:
                    value = self.fusionInput[key]
            else:
                if self.attributes["INPID_InputControl"] == "CheckboxControl":
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
                    value = self.fusionInput[key]
            if self.attributes["INPB_Integer"]:
                value = int(value)
            value = min(
                self.attributes["INPN_MaxAllowed"],
                max(self.attributes["INPN_MinAllowed"], value),
            )

        self.fusionInput[key] = value
        self.keyFrames = self.fusionInput.GetKeyFrames()
        self.value = self.fusionInput[key]

    def is_number(self, s):
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

        # We optimize drawing speeds by using Python's immutability to assign a method to steer backgroundRole behaviour
        self.backgroundRoleMethod = self.backgroundRole
        # self.backgroundRoleMethod = self.noRole

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
                # if f.Name not in self.inputsToSkip:
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
            progress += 1
            self.communicate.send((100.0 / (len(self.toolDict))) * progress)

        # print('Total execution time : ' + str(datetime.datetime.now()-startTime))
        self.communicate.send(
            "Done loading, execution time : " + str(datetime.datetime.now() - startTime)
        )

    def appendUnique(self, str_to_add, type_to_add):
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
                # print("tablemodel editrole", str(value))
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
        self.drawInputInfoColors = QToolButton()
        self.drawInputInfoColors.setCheckable(True)
        self.drawInputInfoColors.setChecked(True)
        self.drawInputInfoColors.setText("Draw Color Info")
        self.pushButton = QPushButton()
        self.pushButton.setText("Refresh")
        self.pushButton.setFixedSize(QSize(128, 20))
        self.lineEdit = QLineEdit(self)
        self.lineEdit.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        self.statusBar().showMessage("System Status | Normal")
        self.cacheButton = QToolButton()
        self.cacheButton.setCheckable(True)
        self.cacheButton.setChecked(False)
        self.cacheButton.setText("use cache")

        v_box = QVBoxLayout()
        h_box = QHBoxLayout()
        h_box.setAlignment(Qt.AlignRight)
        h_box.addWidget(self.alwaysOnTop)
        h_box.addWidget(self.lineEdit)
        h_box.addWidget(self.pushButton)
        h_box.addWidget(self.drawInputInfoColors)
        h_box.addWidget(self.cacheButton)
        h_box.setContentsMargins(0, 0, 0, 0)
        v_box.addLayout(h_box)
        v_box.addWidget(self._tv)

        sizeGrip = QSizeGrip(self)
        # sizeGrip.setParent(self)
        # v_box.addWidget(sizeGrip)
        # v_box.setAlignment(sizeGrip, Qt.AlignBottom | Qt.AlignRight)
        v_box.setContentsMargins(2, 2, 2, 2)
        # v_box.setSpacing(0)
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
        self.drawInputInfoColors.setChecked(True)

        # self.lineEdit.textChanged.connect(self._tv.updateColumns)

        # self.proxyModel.setSourceModel(self._tm)
        # self.proxyModel.filteredKeys = self._tm.attributeNameKeys
        self._tv.setModel(self.proxyModel)

        self.progressBar = QProgressBar()
        self.statusBar().addPermanentWidget(self.progressBar)
        # This is simply to show the bar
        # self.progressBar.setGeometry(30, 40, 200, 25)
        self.progressBar.setValue(0)

        # Connections
        self.alwaysOnTop.stateChanged.connect(self.changeAlwaysOnTop)
        self.lineEdit.textChanged.connect(self.filterRegExpChanged)
        self.drawInputInfoColors.clicked.connect(
            self.changeTableModelBackgroundRoleMethod
        )
        self.cacheButton.clicked.connect(self.changeCacheMode)
        self.pushButton.pressed.connect(self.reloadFusionData)
        self._tm.communicate.broadcast.connect(self.communication)

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

    def changeCacheMode(self):
        # Not sure where this goes, is it a method for the TableModel? or should we inherit the dict that has all
        # the fusion input caches and have that cycle through all contained fusion inputs?

        # For now we do it here
        c = self.cacheButton.isChecked()
        for input_list in self._tm.toolsInputs:
            for tool_input in list(input_list.values()):
                tool_input.cache = c

    def changeTableModelBackgroundRoleMethod(self):
        if self.drawInputInfoColors.isChecked():
            self._tm.backgroundRoleMethod = self._tm.backgroundRole
        else:
            self._tm.backgroundRoleMethod = self._tm.noRole

    def filterRegExpChanged(self):
        """
        This makes sure that the ItemDelegates for the TableView columns get updated, we have to do this as for some
        reason Qt has TableView column delegates decoupled from the underlying ProxyModel and indices get out of sync
        during sorting and filtering.
        """

        regExp = self.lineEdit.text()

        self.proxyModel.filteredKeys = []
        self.proxyModel.setFilterRegExp(regExp)
        self._tv.updateColumns()


css = "*, QTableCornerButton::section {\
    font: 9pt 'tahoma';\
    color: rgb(192, 192, 192);\
    background-color: rgb(52, 52, 52);\
}\
\
QMainWindow {\
    border-top: 1px solid rgb(80,80,80);\
    border-left: 1px solid rgb(80,80,80);\
    border-right: 1px solid rgb(33,33,33);\
    border-bottom: 1px solid rgb(33,33,33);\
}\
\
QTableView {\
    background-color: rgb(52, 52, 52);\
    border-color: rgb(33, 33, 33);\
    border-bottom-color: rgb(34, 34, 34);\
    color: rgb(192, 192, 192);\
    gridline-color: rgb(34, 34, 34);\
}\
\
QHeaderView::section {\
    background-color: rgb(100, 100, 100);\
    color: rgb(0,0,0);\
    padding: 0;\
}\
QTableView::item {\
    border: 0px;\
    padding-left: 8px;\
}\
\
QToolButton {\
    background-color: rgb(52, 52, 52);\
}\
QToolButton:checked {\
    background-color: rgb(70, 86, 134);\
}\
QHeaderView::down-arrow {\
    /*image: url(TriangleDown.png);*/\
    width: 4 px;\
    height: 8 px;\
    padding-right: 4px;\
}\
\
QHeaderView::up-arrow {\
    /*image: url(TriangleUp.png);*/\
    width: 4 px;\
    height: 8 px;\
    padding-right: 4px;\
}\
"

# We define fu and comp as globals so we can basically run the same script from console as well from within Fusion
if __name__ == "__main__":
    # fu = bmd.scriptapp("Fusion")
    # if fu.GetResolve():
    #     print('This script works only with standalone Fusion')
    #     sys.exit()
    if not fu:
        raise Exception("No instance of Fusion found running.")
    comp = fu.GetCurrentComp()

main_app = QApplication.instance()  # checks if QApplication already exists
if not main_app:  # create QApplication if it doesnt exist
    main_app = QApplication([])
main_app.setStyleSheet(css)
main = MainWindow()
main.setWindowTitle("Attribute Spreadsheet 0.1.r{}".format(__VERSION__))
main.setMinimumSize(QSize(640, 200))
main.show()
main.loadFusionData()
main_app.exec_()
