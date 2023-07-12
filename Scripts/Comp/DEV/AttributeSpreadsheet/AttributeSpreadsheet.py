"""
    Attribute Spreadsheet script

    About:
        A spreadsheet script to edit the input parameters of multiple Fusion tools at once.

    Requires:
        Python >= 3.6
        Fusion 9/16, Davinci Resolve 16
        PySide2, installed automatically on first launch
    Notice:
        Written by Sven Neve (sven[AT]houseofsecrets[DOT]nl)
        Copyright (c) 2013 House of Secrets
        (http://www.svenneve.com)
    Updates:
        by Alexey Bogomolov
        (mail@abogomolov.com)
        Donate: https://paypal.me/aabogomolov
        v.0.1.6:
        2019/6/30
            -- update for Fusion 9/16+ and Davinci Resolve 16+
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
            -- add expressions to a Point data
        2020/11/16
        V.0.2.2
            -- compatible with Fusion 17 and Davinci Resolve 17
            -- set active tool on row selection
        2020/11/29
        V.0.2.3
            -- use as standalone script
            -- provide a remote machine IP as an argument to do remote management (a bit slow but working)
        V.0.2.4
            -- set empty value to Text inputs, such as Comments
            -- cache is enabled by default
            -- catch wrong Python version early
        V.0.2.5
            -- fix compatibility issue with non-Studio Fusion versions
            -- catch some exceptions with remote Fusion management
            -- disable refresh button while processing tools
            -- catch the comp name on comp switch only
        v 0.2.6
            -- fix disable refresh button bug if some tools are pre-selected
        v 0.3
            -- cleanup, separate pip_install script
            -- PySide6 initial support
        v 0.3.1
            -- disable table update during search
            -- cleanup
            -- refactoring pip_install script
            -- fix pyside6 compatibility for table models

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

import datetime
import os
import platform
import re
import subprocess
import sys
from pprint import pprint

__VERSION__ = 3.1
__beta__ = False
__license__ = "MIT"
__copyright__ = "2011-2013, Sven Neve <sven[AT]houseofsecrets[DOT]nl>,\
2019-2023 additions by Alexey Bogomolov <mail@abogomolov.com>"


PKG_REQUIRED = "PySide6"
REMOTE_FUSION_ACCESS = False
DEFAULT_HOST = "localhost"

# Do not auto-load the spreadsheet on startup if more than given number of tools selected
LOAD_SELECTED_TOOLS_LIMIT = 10

print("_____________________\nAttribute Spreadsheet version 0.{}".format(__VERSION__))


def get_fusion(fusion_host):
    try:
        import BlackmagicFusion as bmd

        return bmd.scriptapp("Fusion", fusion_host)
    except ModuleNotFoundError:
        print("No BlackmagicFusion module found")


def get_fusion_comp(fusion_object):
    if not fusion_object:
        print("No Fusion instance found or Fusion is not a Studio version")
        sys.exit()
    return fusion_object.GetCurrentComp()


def compatible_python():
    """Only Python 3.8 or higher is supported"""

    compatible = False
    if sys.version_info.major == 3 and sys.version_info.minor >= 8:
        compatible = True
    return compatible


def print(*args, **kwargs):
    """override print() function"""

    __builtins__.print("[AS] : ", *args, **kwargs)


def pip_install_dialogue():
    script_path = comp.MapPath("Reactor:Deploy/Scripts/Utility")
    sys.path.append(script_path)
    from install_pip_package import (
        pip_install,
        show_confirmation_dialogue,
        fallback_message,
    )

    print(f"No {PKG_REQUIRED} installation found!")

    installaion_confirmed = show_confirmation_dialogue(comp, PKG_REQUIRED)
    if installaion_confirmed:
        print(f"Installing {PKG_REQUIRED}...")
        pip_install(PKG_REQUIRED)

    sys.exit()


try:
    from PySide6.QtWidgets import (
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
    from PySide6.QtCore import (
        QAbstractTableModel,
        QCoreApplication,
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
    from PySide6.QtGui import (
        QBrush,
        QPainter,
        QColor,
    )

except ImportError:

    pip_install_dialogue()


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
        print(index.model().data(index))
        editor.setCurrentIndex(self.items.index(str(index.model().data(index))))
        editor.setData("Domain")
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
        line_edit = QLineEdit(parent)
        self.connect(
            line_edit, SIGNAL("valueChanged(int)"), self, SLOT("valueChanged()")
        )
        return line_edit

    def setEditorData(self, editor, index):
        editor.blockSignals(True)
        editor.setText(index.model().data(index))
        editor.blockSignals(False)

    def setModelData(self, editor, model, index):
        # We don't set the model data, the TableView does that for us.
        # Rather, we set what the value from the editor is as the data that the FusionInput needs to use to process the
        # actual values. This allows us to do things like compound assignments or setting/editing expressions.
        model.sourceModel().stored_edit_role_data = editor.text()


class PointDelegate(QItemDelegate):
    """
    Create a Table Widget with Point(x, y) data.
    """

    def __init__(self, parent):

        QItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        qtable_widget = QTableWidget(1, 2, parent)
        qtable_widget.verticalHeader().setVisible(False)
        qtable_widget.setMinimumHeight(40)
        qtable_widget.horizontalHeader().setVisible(False)
        qtable_widget.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        return qtable_widget

    def setEditorData(self, editor, index):
        point_data = str(index.model().data(index))
        try:
            # parsing string like '{1:0.5, 2:0.5, 3:0.0}'
            # first remove curly braces and spaces to make it '1.0:0.1,2.0:0.5,3.0:0.0',
            substring = re.sub("[{} ]", "", point_data)
            # split by colon and convert to dictionary {'1.0': '0.5', '2.0': '0.5', '3.0': '0.0'}
            dict_point = dict(ss.split(":") for ss in substring.split(","))
            dict_point = {int(k): v for k, v in dict_point.items()}
            x_value = QTableWidgetItem(dict_point[1])
            y_value = QTableWidgetItem(dict_point[2])
            editor.blockSignals(True)
            editor.setItem(0, 0, x_value)
            editor.setItem(0, 1, y_value)
            editor.blockSignals(False)
        except ValueError:
            print(
                "error occurred while parsing the point data. Setting values to default"
            )
            for i in range(2):
                editor.setItem(0, i, QTableWidgetItem("0.5"))

    def setModelData(self, editor, model, index):
        try:
            x = editor.item(0, 0).text()
            y = editor.item(0, 1).text()
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
        self.verticalHeader().sectionPressed.disconnect()  # disable row selection
        self.verticalHeader().sectionClicked.connect(self.activate_tool)
        self.setVerticalScrollMode(QAbstractItemView.ScrollPerPixel)
        self.setHorizontalScrollMode(QAbstractItemView.ScrollPerPixel)
        self.center = QPoint(-10, -10)
        self.startCenter = QPoint(-10, -10)
        self.mouseIsDown = False

    def activate_tool(self, section):
        """
        set active tool when vertical header clicked
        """
        comp = fu.GetCurrentComp()
        tool_name = self.model().headerData(section, Qt.Vertical, Qt.DisplayRole)
        tool = comp.FindTool(tool_name)
        comp.SetActiveTool(tool)

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

    def create_value(self, source_model, index):
        target_tool = source_model.tool_dict[index.row() + 1].Name
        target_input_id = (
            source_model.tools_inputs[index.row()]
            .get(source_model.attribute_name_keys[index.column()])
            .ID
        )
        try:
            value = "={}.{}".format(target_tool, target_input_id)
            self.commitDataDo(value)
        except KeyError:
            pass

    def mouseReleaseEvent(self, event):
        table_model = self.model()
        if self.mouseIsDown:
            self.mouseIsDown = False
            index_source = table_model.mapToSource(self.indexAt(self.center))
            source_model = table_model.sourceModel()
            if len(self.selectionModel().selection().indexes()) <= 1:
                index_target = table_model.mapToSource(self.indexAt(self.startCenter))
                if (
                    index_source.row() == index_target.row()
                    and index_source.column() == index_target.column()
                ):
                    print("cannot link the input to itself")
                    return
                if (
                    index_source.row() > -1
                    and index_source.column() > -1
                    and index_target.row() > -1
                    and index_target.column() > -1
                ):
                    # Select the first cell by sampling the area under the first clicked mouse center
                    self.setSelection(
                        QRect(self.startCenter, self.startCenter),
                        QItemSelectionModel.SelectCurrent,
                    )
            self.create_value(source_model, index_source)
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
            if v == "Point":
                self.setItemDelegateForColumn(k, PointDelegate(self))
            # elif v == "FuID":
            #     self.setItemDelegateForColumn(k, FUIDComboDelegate(self))
            elif v in ["Number", "Float", "Int", "Clip", "Text", "FuID"]:
                self.setItemDelegateForColumn(k, LineEditDelegate(self))
        self.resizeColumnsToContents()
        self.resizeRowsToContents()

    def commitData(self, editor):
        """
        commitData makes sure all multiselected cells
        get the same values applied as the edited cell.
        """

        super(TableView, self).commitData(editor)
        tm = self.model().sourceModel()
        value = tm.stored_edit_role_data
        self.commitDataDo(value)

    def commitDataDo(self, value):
        table_model = self.model()
        source_model = table_model.sourceModel()
        comp.StartUndo("Attribute Spreadsheet")
        try:
            for isr in self.selectionModel().selection():
                for s in isr.indexes():
                    input_name = self.model().headerData(
                        s.column(), Qt.Horizontal, Qt.DisplayRole
                    )
                    tool_name = self.model().headerData(
                        s.row(), Qt.Vertical, Qt.DisplayRole
                    )
                    input_name = input_name.replace("\n", " ").strip()
                    if isinstance(value, list) and len(value) == 2:
                        # working with XY point data
                        try:
                            # convert XY data to float
                            x, y = [float(i) for i in value]
                        except ValueError:
                            # expression found?
                            x, y = value
                        print(
                            "setting {} [{}] to [{} : {}]".format(
                                tool_name, input_name, x, y
                            )
                        )
                    else:
                        print(
                            "setting {} [{}] to {}".format(tool_name, input_name, value)
                        )
                    source_model.setData(table_model.mapToSource(s), value, Qt.EditRole)
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
        pattern = self.filterRegularExpression().pattern()
        if pattern == "":
            self.filteredKeys = self.sourceModel().attribute_data_types
            return True

        index = self.sourceModel().createIndex(0, source_column)
        attr_name = self.sourceModel().data(index, Qt.UserRole)
        data_type = self.sourceModel().data(index, Qt.UserRole + 1)

        keys = pattern.split(" ")
        for key in keys:
            if not key:
                return False
            if key.lower() in attr_name.lower():
                self.filteredKeys.append(data_type)
                return True
        return False


class FusionInput:
    """
    A Fusion Input cache/wrapper around the actual Input retrieved from the tool input list.
    """

    def __init__(self, fusion_input):
        self.fusion_input = fusion_input
        self.keyframes = fusion_input.GetKeyFrames()
        self.keyframe_values = dict()
        self.has_keyframes = len(self.keyframes) > 0
        self.expression = fusion_input.GetExpression()
        self.attributes = fusion_input.GetAttrs()
        self.Name = self.attributes["INPS_Name"]
        self.ID = self.attributes["INPS_ID"]

    def Refresh(self):
        self.get_attributes()
        self.get_keyframes()

    def get_attributes(self, attr=None):
        if attr:
            return self.attributes.get(attr, None)
        else:
            return self.attributes

    def get_keyframes(self):
        return self.keyframes

    def get_expression(self):
        return self.expression

    def set_expression(self, expression):
        self.expression = expression
        self.fusion_input.SetExpression(expression)
        self.Refresh()

    def __getitem__(self, item):
        return self.fusion_input[item]

    def __setitem__(self, key, value):
        if value == "p":
            # debug-print input attributes
            pprint(self.attributes)
            return

        if value == "":
            if self.attributes["INPS_DataType"] in ["Text", "Clip"]:
                self.fusion_input[key] = value
            return

        if self.get_expression():
            if value == "-x" or "-x" in value:
                print("Expression cleared")
                self.set_expression(None)
            else:
                print(
                    "This input is linked by expression. Use '-x' to clear expression"
                )
            return

        if isinstance(value, str) and value.startswith("="):
            self.set_expression(value.lstrip("="))
            return

        if self.attributes["INPS_DataType"] == "Number":
            if value[0:2] in ["+=", "-=", "*=", "/=", "%="] and len(value) >= 3:
                # expecting an compound assignment
                if self.is_number(value[2:]):
                    operator = value[0]
                    value = float(value[2:])
                    if operator == "+":
                        value = float(self.fusion_input[key] + value)
                    elif operator == "-":
                        value = float(self.fusion_input[key] - value)
                    elif operator == "/":
                        value = float(self.fusion_input[key] / value)
                    elif operator == "*":
                        value = float(self.fusion_input[key] * value)
                    elif operator == "%":
                        value = float(self.fusion_input[key] % value)
            if self.attributes["INPID_InputControl"] == "MultiButtonIDControl":
                if value.lower() in ["0", "no", "off", "false"]:
                    value = 0
                elif value.lower() in ["1", "yes", "on", "true"]:
                    value = 1
                elif self.is_number(value):
                    value = round(min(1, max(0, float(value))))
                else:
                    value = self.fusion_input[key]
            if self.is_number(value):
                value = float(value)
            else:
                print("this field requires number input")
                value = self.fusion_input[key]

        if self.attributes["INPS_DataType"] == "Point":
            if value[0] == "p":
                pprint(self.attributes)
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
                            v = float(self.fusion_input[key][float(i + 1)] + v)
                        elif operator == "-":
                            v = float(self.fusion_input[key][float(i + 1)] - v)
                        elif operator == "/":
                            v = float(self.fusion_input[key][float(i + 1)] / v)
                        elif operator == "*":
                            v = float(self.fusion_input[key][float(i + 1)] * v)
                        elif operator == "%":
                            v = float(self.fusion_input[key][float(i + 1)] % v)
                    else:
                        v = self.fusion_input[key]
                compute_values.append(v)
            try:
                value = [float(i) for i in compute_values]
            except ValueError:
                if isinstance(value, list):
                    try:
                        x, y = value
                        if x[0] == "=" or y[0] == "=" and len(value) > 1:
                            value = [v.lstrip("=") for v in value]
                            self.set_expression(
                                "Point({}, {})".format(value[0], value[1])
                            )
                        else:
                            print("Point data accepts only numbers and expressions")
                    except Exception:
                        print("value should contain 2 elements")
                return
        self.fusion_input[key] = value
        self.keyframes = self.fusion_input.GetKeyFrames()
        self.value = self.fusion_input[key]

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
        self.inputs_to_skip = {}
        self.data_types_to_skip = {}
        self.background_role_method = self.backgroundRole
        self.tool_dict = dict()
        self.attribute_name_keys = []  # List of unique attribute name keys
        self.attribute_data_types = []  # this list is coupled to the key list
        self.tools_inputs = []
        self.tools_attributes = []

        # this stores the editrole data for multi commits (this way we get inline math to work)
        self.stored_edit_role_data = None

    def load_fusion_data(self):
        self.communicate.send("loading tools and inputs")
        start_time = datetime.datetime.now()
        try:
            comp = fu.GetCurrentComp()
        except NameError:
            comp = get_fusion_comp()
        global current_comp_name
        comp_name = comp.GetAttrs()["COMPS_Name"]
        if comp_name and comp_name != current_comp_name:
            print("currently working with {}".format(comp_name))
            current_comp_name = comp_name
        if not comp:
            print("No comp data found. Probably both Resolve and Fusion are loaded?")
        self.attribute_name_keys = []  # List of unique attribute name keys
        self.attribute_data_types = []  # this list is coupled to the key list
        self.tools_inputs = []
        self.tools_attributes = []
        progress = 0
        self.tool_dict.clear()
        self.tool_dict = comp.GetToolList(True)
        if not self.tool_dict.values():
            self.communicate.send("Select some tools and click Refresh button")
            return
        # disable refresh button during reload process
        try:
            refresh_button = main.refresh_button
            refresh_button.setEnabled(False)
            refresh_button.setStyleSheet("color: rgb(128,128,128);")
        except NameError:
            refresh_button = None
            # app is not initiated
            pass

        for tool in self.tool_dict.values():
            tool_inputs = {}
            tool_inputs_attributes = {}
            for v in tool.GetInputList().values():
                QApplication.processEvents()
                f = FusionInput(v)
                if f.attributes["INPS_DataType"] not in self.data_types_to_skip:
                    key = f.Name
                    tool_inputs[key] = f
                    attribute_data_type = f.attributes["INPS_DataType"]
                    tool_inputs_attributes[key] = f.attributes
                    self.appendUnique(key, attribute_data_type)
            if len(tool_inputs):
                self.tools_inputs.append(tool_inputs)
                self.tools_attributes.append(tool_inputs_attributes)
            self.appendUnique("Tool Name")
            self.appendUnique("Tool ID")
            tool_inputs["Tool Name"] = tool.Name
            tool_inputs["Tool ID"] = tool.ID
            progress += 1
            self.communicate.send((100.0 / (len(self.tool_dict))) * progress)

        if refresh_button:
            refresh_button.setEnabled(True)
            refresh_button.setStyleSheet("color: rgb(192,192,192);")

        self.communicate.send(
            "Done loading, execution time : "
            + str(datetime.datetime.now() - start_time)
        )

    def appendUnique(self, str_to_add, type_to_add=None):
        """
        Helper method to add unique tool name and unique attributes to some lists
        """
        if str_to_add not in self.attribute_name_keys:
            self.attribute_name_keys.append(str_to_add)
            self.attribute_data_types.append(type_to_add)

    def rowCount(self, parent=QModelIndex()):
        return len(self.tool_dict)

    def columnCount(self, parent=QModelIndex()):
        return len(self.attribute_name_keys)

    def data(self, index, role=Qt.DisplayRole):
        """
        Default data method with some extra UserRoles and BackgroundRoles for drawing keyframes.
        This method needs some extra work as a lot of stuff is not written optimal.
        """
        if index.isValid():
            fusion_input = self.tools_inputs[index.row()].get(
                self.attribute_name_keys[index.column()]
            )
            if role == Qt.DisplayRole:
                if isinstance(fusion_input, str):
                    return fusion_input
                if (
                    not fusion_input
                    or fusion_input.attributes.get("INPID_InputControl")
                    == "SplineControl"
                ):
                    return None
                # force it to be string so it shows EVERYTHING
                return (
                    str(fusion_input[comp.CurrentTime])
                    if fusion_input
                    else fusion_input
                )
            elif role == Qt.EditRole:
                return fusion_input
            elif role == Qt.UserRole:
                return self.attribute_name_keys[index.column()]
            elif role == Qt.UserRole + 1:
                return self.attribute_data_types[index.column()]
            elif role == Qt.BackgroundRole:
                return self.background_role_method(index, role)

    def backgroundRole(self, index, role=None):
        if index.isValid():
            fusion_input = self.tools_inputs[index.row()].get(
                self.attribute_name_keys[index.column()]
            )
            b = QBrush()
            b.setStyle(Qt.SolidPattern)
            if fusion_input:
                if isinstance(fusion_input, str):
                    return None
                if (
                    fusion_input.attributes.get("INPID_InputControl", None)
                    == "SplineControl"
                ):
                    b.setColor(QColor(180, 64, 92, 64))
                    return b
                if fusion_input.get_expression():
                    b.setColor(QColor(92, 64, 92, 180))
                    return b
                if fusion_input.attributes.get("INPB_Connected"):
                    if comp.CurrentTime in list(fusion_input.keyframes.values()):
                        b.setColor(QColor(62, 92, 62, 180))
                    else:
                        b.setColor(QColor(64, 78, 120, 180))
                    return b

    def headerData(self, section, orientation, role):
        if role == Qt.DisplayRole:
            if orientation == Qt.Horizontal:
                return self.splitHeaderName(self.attribute_name_keys[section])
            if orientation == Qt.Vertical:
                return self.tool_dict[section + 1].Name

    def setData(self, index, value, role=Qt.DisplayRole):
        """
        Set our data, we use the tool's attribute MinAllowed and MaxAllowed where possible (as Fusion sometimes allows
        to set data outside legal values (on Booleans for example), resulting in 'buggy' behaviour.

        A good idea might be to move the sensitization to the fusionInput class.

        Needs more work
        """
        if index.isValid() and role == Qt.EditRole:
            fusion_input = self.tools_inputs[index.row()].get(
                self.attribute_name_keys[index.column()], None
            )
            if not fusion_input:
                return
            if not isinstance(value, list):
                value = str(value)
            fusion_input[comp.CurrentTime] = value

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
        self.inputs_to_skip = {
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
        self._tm = TableModel(self)
        self._tm.inputs_to_skip = self.inputs_to_skip
        self._tm.data_types_to_skip = self.data_types_to_skip
        self._tv = TableView(self)
        self.always_on_top = QCheckBox("Always on top")
        self.always_on_top.setChecked(True)
        self.clear_button = QPushButton()
        self.clear_button.setText("Clear")
        self.clear_button.setFixedSize(QSize(70, 30))
        self.refresh_button = QPushButton()
        self.refresh_button.setText("Refresh")
        self.refresh_button.setFixedSize(QSize(140, 30))
        self.search_line = QLineEdit(self)
        self.search_line.setFixedHeight(30)
        self.search_line.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)

        v_box = QVBoxLayout()
        h_box = QHBoxLayout()
        h_box.setAlignment(Qt.AlignRight)
        h_box.addWidget(self.always_on_top)
        h_box.addWidget(self.clear_button)
        h_box.addWidget(self.search_line)
        h_box.addWidget(self.refresh_button)
        h_box.setContentsMargins(0, 0, 0, 0)
        v_box.addLayout(h_box)
        v_box.addWidget(self._tv)

        # find the corner button
        self.corner = self._tv.findChild(QAbstractButton)

        v_box.setContentsMargins(2, 2, 2, 2)

        central_widget = QWidget()
        central_widget.setLayout(v_box)
        self.setCentralWidget(central_widget)
        self.status_bar = self.statusBar()

        self.proxy_model = TableSortFilterProxyModel()
        self.proxy_model.setFilterCaseSensitivity(Qt.CaseInsensitive)
        self.proxy_model.setSortCaseSensitivity(Qt.CaseInsensitive)
        self.proxy_model.setDynamicSortFilter(True)
        self._tv.setModel(self.proxy_model)

        # show the progressbar
        self.progress_bar = QProgressBar()
        self.status_bar.addPermanentWidget(self.progress_bar)
        self.progress_bar.setValue(0)
        self.progress_bar.setVisible(False)

        # Connections
        self.always_on_top.stateChanged.connect(self.changeAlwaysOnTop)
        self.search_line.returnPressed.connect(self.refresh_button.click)
        self.search_line.textChanged.connect(self.filterRegExpChanged)
        self.clear_button.pressed.connect(self.clear_search)
        self.clear_button.pressed.connect(self.reload_fusion_data)
        self.refresh_button.clicked.connect(self.reload_fusion_data)
        self._tm.communicate.broadcast.connect(self.communication)
        self.corner.clicked.connect(self.reset_sorting)

        self.setWindowFlags(
            self.windowFlags() | Qt.CustomizeWindowHint | Qt.WindowStaysOnTopHint
        )
        self.tool_list = comp.GetToolList(True)
        if not self.tool_list:
            self.status_bar.showMessage("Select some tools and click Refresh button")
        if len(self.tool_list.values()) >= LOAD_SELECTED_TOOLS_LIMIT:
            self.status_bar.showMessage("Click Refresh button to load selected tools")
        else:
            self.load_fusion_data()

    def reset_sorting(self):
        """
        reset tool sorting to initial state, do not select all
        """
        self.proxy_model.sort(-1)
        self._tv.clearSelection()

    def clear_search(self):
        self.search_line.clear()

    def changeAlwaysOnTop(self):
        if self.always_on_top.checkState():
            self.setWindowFlags(
                self.windowFlags() | (Qt.CustomizeWindowHint | Qt.WindowStaysOnTopHint)
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
            self.progress_bar.setValue(value)
        if isinstance(value, str):
            self.status_bar.showMessage(value)
        self.progress_bar.setVisible(True)
        if self.progress_bar.value() in [0, 100]:
            self.progress_bar.setVisible(False)

    def load_fusion_data(self):
        self._tm.load_fusion_data()
        self.proxy_model.setSourceModel(self._tm)
        self._tv.setSortingEnabled(True)
        self._tv.updateColumns()

    def reload_fusion_data(self):
        self.proxy_model.setSourceModel(None)
        self._tm.load_fusion_data()
        self.proxy_model.setSourceModel(self._tm)
        self._tv.setSortingEnabled(True)
        self._tv.updateColumns()

    def filterRegExpChanged(self):
        """
        This makes sure that the ItemDelegates for the TableView columns get updated, we have to do this as for some
        reason Qt has TableView column delegates decoupled from the underlying ProxyModel and indices get out of sync
        during sorting and filtering.
        """

        regExp = self.search_line.text()
        self.proxy_model.filteredKeys = []
        self.proxy_model.setFilterRegularExpression(regExp)


# increase font size for Retina Display on Mac
font_size = 12 if platform.system() == "Darwin" else 9

css = """
*, QTableCornerButton::section {{
    font: {}pt 'tahoma';
    color: rgb(192, 192, 192);
    background-color: rgb(52, 52, 52);
    }}

QLineEdit {{
    background-color: rgb(40,40,40);
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

QPushButton:pressed {{
    background-color: rgb(70, 86, 134);
    }}

QTableWidget::item {{
    text-align: top center;
    border-style: outset;
    border-width: 4px;
    background-color: rgb(30,30,30);
    }}
""".format(
    font_size
)

# We define fu and comp as globals so we can basically run the same script from console as well from within Fusion
# If both Resolve and Fusion are running, Fusion data may load improperly. So we check for scriptapp,
# and the script would not load if there's a confusion about which instance of Fusion to use.

if __name__ == "__main__":

    if not compatible_python():
        print(f"current python version is {sys.version}")
        msg = "Python >= 3.8 is required!"
        sys.stderr.write(f"{msg}\n")
        print(
            "Python 3.6 and later is required to run this script\n"
            "Set Python interpreter in Fusion Preferences -> Global Settings -> Script -> Default Script Version"
        )
        dialog = {
            1: {
                1: "",
                2: "Text",
                "ReadOnly": True,
                "Lines": 3,
                "Default": msg + "\nOpen Preferences?",
            }
        }
        dlg = comp.AskUser("Warning", dialog)
        if dlg:
            fu.ShowPrefs("PrefsScript")
        sys.exit()

    try:
        comp = fu.GetCurrentComp()  # this works in most cases
    except Exception as e:
        print("Could not find Fusion comp. Attempt to connect in standalone mode...")
        REMOTE_FUSION_ACCESS = True
        LOAD_SELECTED_TOOLS_LIMIT = 3
        fusion_host = DEFAULT_HOST
        if len(sys.argv) == 2:
            fusion_host = sys.argv[1]
        fusion = get_fusion(fusion_host)
        comp = get_fusion_comp(fusion)
        if not comp:
            raise ModuleNotFoundError("Comp not found")
    finally:
        current_comp_name = comp.GetAttrs()["COMPS_Name"]

    main_app = QApplication.instance()  # checks if QApplication already exists.
    if not main_app:  # create QApplication if it doesnt exist
        main_app = QApplication([])
    main_app.setStyleSheet(css)
    main = MainWindow()
    win_title = f"Attribute Spreadsheet 0.{__VERSION__}"
    if __beta__:
        win_title += "b"
    main.setWindowTitle(win_title)
    main.setMinimumSize(QSize(740, 200))
    main.show()
    main_app.exec()
    print("Done")
