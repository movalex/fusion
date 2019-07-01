"""
    hos_AttributeSpreadsheet

    About:
        A spreadsheet script to edit the input parameters of multiple Fusion tools at once.

    Requires:
        Python 3.6
        Fusion 9/16 (needs testing)
        PySide2, installed automatically
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

        updated for Fusion 9/16, python3 and PySide2 compatibility
        by Alex Bogomolov
        https://abogomolov.com
        2019/6/30
"""

__version__ = 6

import datetime
import sys

# import PbmdScript as eyeon
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

except ImportError:
    if sys.version_info.major == 2:
        print('Python 3.6 is required')
        sys.exit()
    print("No Pyside2 module found, trying to install...")
    try:
        from pip._internal import main as pipmain

        pipmain(["install", "PySide2", "--no-warn-script-location"])
        print("Done", "\nNow try to launch the script again")
        sys.exit()
    except ImportError:
        print('Check if pip version 10+ is installed, installation failed')
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

    # @QtCore.pyqtSlot()
    def currentIndexChanged(self):
        self.commitData.emit(self.sender())


class IntDelegate(QItemDelegate):
    """
    A delegate that places a fully functioning QSpinBox in every
    cell of the column to which it's applied
    """

    def __init__(self, parent):

        QItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        spinBox = QSpinBox(parent)
        spinBox.setMinimum(-100000)
        spinBox.setMaximum(100000)
        self.connect(spinBox, SIGNAL("valueChanged(int)"), self, SLOT("valueChanged()"))
        return spinBox

    def setEditorData(self, editor, index):
        # print('editor:', index)
        editor.blockSignals(True)
        # print('setEditorData', editor,index)
        # print(index.model().data(index))
        editor.setValue(float(index.model().data(index)))
        editor.blockSignals(False)

    def setModelData(self, editor, model, index):
        # print('setModelData', editor,index)
        # print(editor.value())
        model.setData(index, editor.value(), Qt.EditRole)

    # @QtCore.pyqtSlot()
    def valueChanged(self):
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
        # model.setData(index, editor.text(), Qt.EditRole)
        pass

    # @QtCore.pyqtSlot()
    def valueChanged(self):
        self.commitData.emit(self.sender())


class FloatDelegate(QItemDelegate):
    """
    A delegate that places a fully functioning QDoubleSpinBox in every
    cell of the column to which it's applied
    """

    def __init__(self, parent):

        QItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        doubleSpinBox = QDoubleSpinBox(parent)
        doubleSpinBox.setDecimals(5)
        doubleSpinBox.setMinimum(-100000)
        doubleSpinBox.setMaximum(100000)
        self.connect(
            doubleSpinBox, SIGNAL("valueChanged(float)"), self, SLOT("valueChanged()")
        )
        return doubleSpinBox

    def setEditorData(self, editor, index):
        editor.blockSignals(True)
        # print('setEditorData', editor,index)
        # print(index.model().data(index))
        editor.setValue(float(index.model().data(index)))
        editor.blockSignals(False)

    def setModelData(self, editor, model, index):
        model.setData(index, editor.value(), Qt.EditRole)

    def valueChanged(self):
        self.commitData.emit(self.sender())


class PointDelegate(QItemDelegate):
    """
    Need to figure out how to do this bastard.
    """

    def __init__(self, parent):

        QItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        combo = QTableWidget(1, 3, parent)
        combo.verticalHeader().setVisible(False)
        combo.horizontalHeader().setVisible(False)
        combo.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.connect(
            combo,
            SIGNAL("currentIndexChanged(int)"),
            self,
            SLOT("currentIndexChanged()"),
        )
        return combo

    def setEditorData(self, editor, index):
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
            # self.viewport().repaint()

        elif event.buttons() == Qt.LeftButton:
            self.mouseIsDown = False
            QTableView.mousePressEvent(self, event)

    def mouseReleaseEvent(self, event):
        # TODO, clean this up, so much duplicate code, it's embarrassing.
        if self.mouseIsDown:
            self.mouseIsDown = False
            idxs = self.model().mapToSource(self.indexAt(self.center))
            idxt = self.model().mapToSource(self.indexAt(self.startCenter))
            sm = self.model().sourceModel()
            if len(self.selectionModel().selection().indexes()) > 1:
                value = "=" + "%s.%s" % (
                    sm.toolDict[idxs.row() + 1].Name,
                    sm.toolsInputs[idxs.row()]
                    .get(sm.attributeNameKeys[idxs.column()])
                    .ID,
                )
                self.commitDataDo(value)
            else:
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
                    # Select the first cell by sampling the area under the first clicked mouse center
                    self.setSelection(
                        QRect(self.startCenter, self.startCenter),
                        QItemSelectionModel.SelectCurrent,
                    )
                    value = "=" + "%s.%s" % (
                        sm.toolDict[idxs.row() + 1].Name,
                        sm.toolsInputs[idxs.row()]
                        .get(sm.attributeNameKeys[idxs.column()])
                        .ID,
                    )
                    self.commitDataDo(value)
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

        # filteredKeys contains the column data types with the indices properly sorted after filtering.
        for k, v in enumerate(tm.filteredKeys):
            if v == "Point":
                self.setItemDelegateForColumn(k, PointDelegate(self))
            # elif v == 'Float':
            #    self.setItemDelegateForColumn(k, FloatDelegate(self))
            # elif v == 'Int':
            #    self.setItemDelegateForColumn(k, IntDelegate(self))
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

        # value = tm.data(self.model().mapToSource(self.currentIndex()), Qt.EditRole)

        # Use a stored edit role text
        value = tm.stored_edit_role_data
        self.commitDataDo(value)

    def commitDataDo(self, value):
        tm = self.model().sourceModel()
        # value = tm.data(self.currentIndex(), Qt.EditRole)
        # self.model().sourceModel().comp.StartUndo("Attribute Spreadsheet")
        comp.StartUndo("Attribute Spreadsheet")
        try:
            # print('tableview commit : ', value)
            for isr in self.selectionModel().selection():
                for s in isr.indexes():
                    print("multi commit ", s)
                    tm.setData(self.model().mapToSource(s), value, Qt.EditRole)
            # self.model().sourceModel().comp.EndUndo(True)
            comp.EndUndo(True)
        except Exception as e:
            # self.model().sourceModel().comp.EndUndo(True)
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

        keys = pattern.split(" ")
        self.filteredKeys = []

        index = self.sourceModel().createIndex(0, source_column)
        attrName = self.sourceModel().data(index, Qt.UserRole)
        dataType = self.sourceModel().data(index, Qt.UserRole + 1)

        # matches = 0

        for key in keys:
            if not key:
                return False
            if key.lower() in attrName.lower():
                # return True
                # matches = matches + 1
                self.filteredKeys.append(dataType)
                return True
        # print(self.filteredKeys)

        # print(matches, len(keys))
        # if matches == len(keys):
        #    return True
        # if len(self.filteredKeys):
        #    return True

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
        # for k, v in self.keyFrames.items():
        #    self.keyFrameValues[k] = fusionInput[v]
        self.hasKeyFrames = len(self.keyFrames) > 0
        # self.value = fusionInput
        self.expression = fusionInput.GetExpression()
        self.attributes = fusionInput.GetAttrs()
        self.Name = self.attributes["INPS_Name"]
        self.ID = self.attributes["INPS_ID"]

    # def __del__(self):
    #    print('deleting')
    #    del self.attributes
    #    del self.keyFrames
    #    self.fusionInput = None
    #    del self.fusionInput
    #    del self.keyFrameValues
    #    del self.Name
    #    del self.ID

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
        # if not self.cache:
        #    self.keyFrameValues[item] = self.fusionInput[item]
        # return self.keyFrameValues.get(item, self.value)
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
                print("settings expression")
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

        # self.fu = bmd.scriptapp("Fusion")
        # comp = self.fu.GetCurrentComp()

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
        for tool in list(self.toolDict.values()):
            toolInputs = {}
            toolInputsAttributes = {}
            for v in list(tool.GetInputList().values()):
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
            # else:
            #    r = self.toolsInputs[index.row()].get(self.attributeNameKeys[index.column()], None)
            #    return str(r[comp.CurrentTime]) if r else r # force it to be string so it shows EVERYTHING
            # r = self.toolsInputs[index.row()].get(self.attributeNameKeys[index.column()], None)
            return (
                str(r[comp.CurrentTime]) if r else r
            )  # force it to be string so it shows EVERYTHING

        elif role == Qt.EditRole:
            # r = self.toolsInputs[index.row()].get(self.attributeNameKeys[index.column()], None)
            return r[comp.CurrentTime] if r else r
        elif role == Qt.UserRole:
            return self.attributeNameKeys[index.column()]
        elif role == Qt.UserRole + 1:
            return self.attributeDataTypes[index.column()]
        elif role == Qt.BackgroundRole:
            return self.backgroundRoleMethod(index, role)
            # r = self.toolsInputs[index.row()].get(self.attributeNameKeys[index.column()], None)
            # if r:
            #    #if r.GetAttrs('INPB_Connected'):
            #    if(r.GetExpression()):
            #        b = QBrush()
            #        b.setStyle(Qt.Dense6Pattern)
            #        b.setColor(QColor('purple'))
            #        return b
            #    if r.GetAttrs('INPB_Connected'):
            #        b = QBrush()
            #        b.setStyle(Qt.Dense6Pattern)
            #        b.setColor(QColor('green'))
            #        #return QColor('green')
            #        return b
        else:
            return

    def noRole(self, index, role):
        return None

    def backgroundRole(self, index, role):
        r = self.toolsInputs[index.row()].get(
            self.attributeNameKeys[index.column()], None
        )
        if r:
            # if r.GetAttrs('INPB_Connected'):
            b = QBrush()
            b.setStyle(Qt.SolidPattern)
            if r.attributes.get("INPID_InputControl", None) == "SplineControl":
                b.setColor(QColor(180, 64, 92, 64))
                return b
            if r.GetExpression():
                b.setColor(QColor(92, 64, 92, 180))
                return b
            if r.GetAttrs("INPB_Connected"):
                # keyFrames = r.GetKeyFrames()
                # b = QBrush()
                # b.setStyle(Qt.Dense4Pattern)
                # b.setStyle(Qt.SolidPattern)
                # print(keyFrames)
                # print(comp.CurrentTime, r.keyFrames.values())
                if comp.CurrentTime in list(r.keyFrames.values()):
                    b.setColor(QColor(62, 92, 62, 180))
                else:
                    b.setColor(QColor(64, 78, 120, 180))

                # return QColor('green')
                return b
        return None

    # def setModelData(self, editor, model, index):
    #    model.setData(index, editor.currentIndex())

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
            # print(self.toolsAttributes[index.row()].get(self.attributeNameKeys[index.column()], []))
            r = self.toolsInputs[index.row()].get(
                self.attributeNameKeys[index.column()], None
            )
            if r:
                print("tablemodel editrole", str(value))
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
        # self.show()
        # self.loadFusionData()

    def createWidgets(self):
        self._tm = TableModel(self)
        self._tm.inputsToSkip = self.inputsToSkip
        self._tm.data_types_to_skip = self.data_types_to_skip
        self._tv = TableView(self)
        # selectionModel = QItemSelectionModel(self._tm)

        # self._tv.setSelectionMode(QAbstractItemView.ExtendedSelection)
        # self._tv.setSelectionBehavior(QAbstractItemView.MultiSelection)

        self.alwaysOnTop = QCheckBox("Always on top")
        self.alwaysOnTop.setChecked(True)
        self.drawInputInfoColors = QToolButton()
        self.drawInputInfoColors.setCheckable(True)
        self.drawInputInfoColors.setChecked(True)
        self.drawInputInfoColors.setText("Draw Color Info")
        # self.drawInputInfoColors.setFixedSize(QSize(20,20))
        self.pushButton = QPushButton()
        self.pushButton.setText("Refresh")
        self.pushButton.setFixedSize(QSize(128, 20))
        self.lineEdit = QLineEdit(self)
        # self.lineEdit.setFixedSize(QSize(256, 20))
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
        # self._tm = TableModel(self)
        # self._tm.communicate.broadcast.connect(self.progressBar.setValue)
        self._tm.load_fusion_data()
        self.proxyModel.setSourceModel(self._tm)
        # self.proxyModel.filteredKeys = self._tm.attributeNameKeys
        # self._tv.setModel(self.proxyModel)
        self._tv.setSortingEnabled(True)
        # self._tv.horizontalHeader().setSortIndicatorShown(False)
        self._tv.updateColumns()

    def reloadFusionData(self):
        # self._tm = TableModel(self)
        # self.report_memory_usage()
        self.proxyModel.setSourceModel(None)
        # self.proxyModel.blockSignals(True)
        self._tm.load_fusion_data()
        self.proxyModel.setSourceModel(self._tm)
        # self.proxyModel.filteredKeys = self._tm.attributeNameKeys
        # self.proxyModel.blockSignals(False)
        self._tv.setSortingEnabled(True)
        self._tv.updateColumns()
        # self.report_memory_usage()

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
    font: 8pt 'tahoma';\
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
    color: rgb(192, 192, 192);\
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
    fu = bmd.scriptapp("Fusion")
    if not fu:
        raise Exception("No instance of Fusion found running.")
    comp = fu.GetCurrentComp()

app = QApplication.instance()  # checks if QApplication already exists
if not app:  # create QApplication if it doesnt exist
    app = QApplication([])
app.setStyleSheet(css)
main = MainWindow()
main.setWindowTitle("Attribute Spreadsheet 0.1.r%s" % __version__)
main.setMinimumSize(QSize(640, 200))
main.show()
main.loadFusionData()
app.exec_()
