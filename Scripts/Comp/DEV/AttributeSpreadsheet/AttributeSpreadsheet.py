"""
    Attribute Spreadsheet script

    About:
        A spreadsheet script to edit the input parameters of multiple Fusion tools at once.

    Requires:
        Python >= 3.6
        Fusion 9/16, Davinci Resolve 16
        PySide 6.4+
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
        2023/07
        v 0.3.1
            -- disable table update during search
            -- cleanup
            -- refactoring pip_install script
            -- fix pyside6 compatibility for table models
        v 0.3.2
            -- use logging module
            -- refine pip installation script
            -- fix edit filtered entries
            -- fix always on top option
            -- fix QT deprecation warnings
        v0.3.3 - 2024/04 
            -- Logging info to stdout
        v0.4 - 2024/09
            -- refactoring
            -- use AI to add docstrings 
            -- use UI utils instead of tkinter

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
import re
import sys
from pprint import pprint

from ui_utils import ConfirmationDialog
from log_utils import set_logging

__VERSION__ = "0.4.1"
__license__ = "MIT"
__copyright__ = """2011-2013, Sven Neve <sven[AT]houseofsecrets[DOT]nl>
2019-2024, Alexey Bogomolov <mail[AT]abogomolov.com>"""

try:
    comp = fu.GetCurrentComp()
except NameError:
    from bmd_utils import get_app

    print("Fusion is not defined, trying to import it...")
    fu = get_app("Fusion")
    comp = fu.GetCurrentComp()

PKG_REQUIRED = "PySide6"
REMOTE_FUSION_ACCESS = False
DEFAULT_HOST = "localhost"
LOG_LEVEL = "debug"  # info, warning, debug
SCRIPT_NAME = "Attribute Spreadsheet"

# Do not auto-load the spreadsheet on startup
# if more than given number of tools selected
LOAD_SELECTED_TOOLS_LIMIT = 10


def compatible_python():
    """Only Python 3.6 or higher is supported"""

    return sys.version_info >= (3, 6)


def check_python_version():
    """Check the Python version and alert the user if it's incompatible."""
    if not compatible_python():
        log.info(f"Current Python version is {sys.version}")
        msg = "Python version >= 3.6 is required!"
        sys.stderr.write(f"{msg}\n")

        log.info(
            "Python 3.6 or later is required to run this script.\n"
            "Set the Python interpreter in Fusion Preferences -> Global Settings -> Script -> Default Script Version."
        )

        confirm_message = (f"{msg}\nOpen Preferences?",)
        dlg = ConfirmationDialog("Open Preferences", confirm_message)
        if dlg:
            fu.ShowPrefs("PrefsScript")
        sys.exit(1)  # Explicitly indicate the script exited due to an error.


check_python_version()

print(f"_____________________\n{SCRIPT_NAME} version {__VERSION__}\n")


log = set_logging(LOG_LEVEL, SCRIPT_NAME)


def get_fusion_module():
    """Get current Fusion instance"""
    fusion = getattr(sys.modules["__main__"], "fusion", None)
    return fusion


def get_bmd_library():
    """Get bmd library"""
    bmd = getattr(sys.modules["__main__"], "bmd", None)
    return bmd


def get_current_comp():
    """Get current comp in this session"""
    fusion = get_fusion_module()
    if fusion is not None:
        comp = fusion.CurrentComp
        return comp



def pip_install_dialogue():
    """
    Display a dialogue for pip installation and install required packages.
    """
    try:
        script_path = comp.MapPath("Reactor:Deploy/Scripts/Utility")
        sys.path.append(script_path)

        from install_pip_package import pip_install

        pip_install(PKG_REQUIRED)

        sys.exit(0)  # Exit successfully after installation
    except Exception as e:
        log.error(f"Failed to install pip package: {e}")
        sys.exit(1)  # Exit with error if installation fails


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
        QSizePolicy,
        QTableView,
        QTableWidget,
        QTableWidgetItem,
        QVBoxLayout,
        QWidget,
    )
    from PySide6.QtCore import (
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
        super().__init__(parent)
        self.items = ["None"]  # Default list of combo box items

    def createEditor(self, parent, option, index):
        """Create a QComboBox editor for the table cell."""
        combo = QComboBox(parent)
        combo.addItems(self.items)
        combo.currentIndexChanged.connect(lambda: self.commitData)
        return combo

    def setEditorData(self, editor, index):
        """Set the current data in the combo box editor."""
        editor.blockSignals(True)
        try:
            value = str(index.model().data(index))
            log.debug(f"Setting ComboBox editor data: {value}")
            editor.setCurrentIndex(self.items.index(value))
        except (ValueError, IndexError):
            log.warning(f"Failed to set ComboBox editor data for index: {index}")
        finally:
            editor.blockSignals(False)

    def setModelData(self, editor, model, index):
        """Set the selected combo box data to the model."""
        model.setData(index, editor.currentIndex())

    def currentIndexChanged(self):
        """Emit commitData signal when the combo box value changes."""
        self.commitData.emit(self.sender())


class LineEditDelegate(QItemDelegate):
    """
    A delegate that places a fully functioning QLineEdit in every
    cell of the column to which it's applied
    """

    def __init__(self, parent):
        super().__init__(parent)

    def createEditor(self, parent, option, index):
        """Create a QLineEdit editor for the table cell."""
        line_edit = QLineEdit(parent)
        line_edit.textChanged.connect(lambda: self.commitData)
        return line_edit

    def setEditorData(self, editor, index):
        """Set the current data in the line edit editor."""
        editor.blockSignals(True)
        try:
            editor.setText(str(index.model().data(index)))
        except Exception as e:
            log.warning(f"Failed to set LineEdit editor data for index: {index}, error: {e}")
        finally:
            editor.blockSignals(False)

    def setModelData(self, editor, model, index):
        """Set the data from the line edit to the model."""
        model.sourceModel().stored_edit_role_data = editor.text()


class PointDelegate(QItemDelegate):
    """
    Create a Table Widget with Point(x, y) data.
    """

    def __init__(self, parent):
        QItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        """Create a small table editor for Point(x, y) data."""
        qtable_widget = QTableWidget(1, 2, parent)
        qtable_widget.verticalHeader().setVisible(False)
        qtable_widget.setMinimumHeight(40)
        qtable_widget.horizontalHeader().setVisible(False)
        qtable_widget.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        return qtable_widget

    def setEditorData(self, editor, index):
        """Set point data into the table editor."""
        point_data = str(index.model().data(index))
        try:
            # Parse point data like "{1:0.5, 2:0.5}" into x and y values
            substring = re.sub(r"[{} ]", "", point_data)
            dict_point = {
                int(k): v for k, v in (ss.split(":") for ss in substring.split(","))
            }

            x_value = QTableWidgetItem(dict_point.get(1, "0.5"))
            y_value = QTableWidgetItem(dict_point.get(2, "0.5"))

            editor.blockSignals(True)
            editor.setItem(0, 0, x_value)
            editor.setItem(0, 1, y_value)
            editor.blockSignals(False)
        except ValueError:
            log.warning(
                "error occurred while parsing the point data. Setting values to default"
            )
            for i in range(2):
                editor.setItem(0, i, QTableWidgetItem("0.5"))

    def setModelData(self, editor, model, index):
        """Extract point data from the table editor and store it."""
        try:
            x = editor.item(0, 0).text()
            y = editor.item(0, 1).text()
            model.sourceModel().stored_edit_role_data = [x, y]
        except AttributeError:
            log.warning("Point data extraction failed for the current editor.")


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
        Set the active tool when the vertical header is clicked.

        :param section: The section (row index) clicked in the vertical header.
        """
        try:
            comp = fu.GetCurrentComp()
            if not comp:
                log.warning("No Fusion composition found.")
                return

            tool_name = self.model().headerData(section, Qt.Vertical, Qt.DisplayRole)
            tool = comp.FindTool(tool_name)
            if not tool:
                log.warning(f"Tool '{tool_name}' not found.")
                return

            comp.SetActiveTool(tool)
            log.debug(f"Activated tool: {tool_name}")
        except Exception as e:
            log.error(f"Error activating tool in section {section}: {e}")

    def paintEvent(self, event):
        """Custom paint event to handle drawing on the table view."""
        super().paintEvent(event)  # Always call the base class paint event

        if self.mouseIsDown:
            painter = QPainter(self.viewport())
            painter.drawLine(self.center, self.startCenter)
            log.debug(f"Drawing line from {self.startCenter} to {self.center}")

    def mousePressEvent(self, event):
        """Handle mouse press events, including middle button for drawing and left button for selection."""
        if event.buttons() == Qt.MiddleButton:
            self.mouseIsDown = True
            pos = event.position().toPoint()
            self.center = self.startCenter = pos
            log.debug(f"Middle mouse button pressed at {self.center}")
        elif event.buttons() == Qt.LeftButton:
            self.mouseIsDown = False
            super().mousePressEvent(event)

    def create_value(self, source_model, index):
        """Create a value string from the selected tool and input, then commit it."""
        try:
            target_tool = source_model.tool_dict[index.row() + 1].Name
            target_input = source_model.tools_inputs[index.row()].get(
                source_model.attribute_name_keys[index.column()]
            )

            if target_input is None:
                log.warning("No input found for the given tool and column.")
                return

            value = f"={target_tool}.{target_input.ID}"
            self.commitDataDo(value)
            log.debug(f"Created value: {value}")
        except KeyError as e:
            log.error(f"Error creating value: {e}")

    def mouseReleaseEvent(self, event):
        """Handle mouse release events, including linking tools and clearing selections."""
        table_model = self.model()
        if self.mouseIsDown:
            self.mouseIsDown = False
            index_source = table_model.mapToSource(self.indexAt(self.center))
            source_model = table_model.sourceModel()

            if len(self.selectionModel().selection().indexes()) <= 1:
                index_target = table_model.mapToSource(self.indexAt(self.startCenter))

                if index_source == index_target:
                    log.warning("Cannot link input to itself.")
                    return

                if index_source.isValid() and index_target.isValid():
                    # Select the source index if not already selected
                    self.setSelection(
                        QRect(self.startCenter, self.startCenter),
                        QItemSelectionModel.SelectCurrent,
                    )

            self.create_value(source_model, index_source)
            self.viewport().repaint()

        super().mouseReleaseEvent(event)

    def mouseMoveEvent(self, event):
        """Track mouse movements for drawing when the middle button is held down."""
        if self.mouseIsDown:
            self.center = event.position().toPoint()
            self.viewport().repaint()
            log.debug(f"Mouse moved to {self.center}")
        super().mouseMoveEvent(event)

    def updateColumns(self):
        """
        Update the column item delegates based on the filtered data types.
        
        The columns are grouped by attribute/parameter names. Tools with attributes that
        have conflicting data types may encounter errors.
        """
        tm = self.model()

        # Adjust filteredKeys after filtering
        if tm.is_filtered:
            tm.filteredKeys = tm.filteredKeys[2:]  # Skip first two keys (hack)

        for k, v in enumerate(tm.filteredKeys):
            if v == "Point":
                self.setItemDelegateForColumn(k, PointDelegate(self))
            elif v in ["Number", "Float", "Int", "Clip", "Text", "FuID"]:
                self.setItemDelegateForColumn(k, LineEditDelegate(self))
            # Add other delegate conditions as needed
        
        # Resize rows and columns to fit the data
        self.resizeColumnsToContents()
        self.resizeRowsToContents()


    def commitData(self, editor):
        """
        Commit data to all multi-selected cells, ensuring they get the same value
        as the edited cell.
        """
        super().commitData(editor)
        tm = self.model().sourceModel()
        value = tm.stored_edit_role_data
        self.commitDataDo(value)


    def commitDataDo(self, value):
        table_model = self.model()
        source_model = table_model.sourceModel()
        comp.StartUndo(f"{SCRIPT_NAME}")
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
                        log.debug(
                            "setting {} [{}] to [{} : {}]".format(
                                tool_name, input_name, x, y
                            )
                        )
                    else:
                        log.debug(
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
        super().__init__(parent)
        self.filteredKeys = []
        self.is_filtered = False

    def filterAcceptsRow(self, source_row, source_parent):
        """Override this method if we need custom row filtering."""
        return True

    def filterAcceptsColumn(self, source_column, source_parent):
        """
        Filter columns based on the regular expression pattern.
        Update the filteredKeys list with the matching data types.
        """
        pattern = self.filterRegularExpression().pattern()

        if not pattern:
            self.filteredKeys = self.sourceModel().attribute_data_types
            return True

        self.is_filtered = True
        keys = pattern.split()

        index = self.sourceModel().createIndex(0, source_column)
        if index.isValid():
            attr_name = self.sourceModel().data(index, Qt.UserRole)
            data_type = self.sourceModel().data(index, Qt.UserRole + 1)

            for key in keys:
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
        """Set an expression for this input and refresh the data."""
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

        if value == "" and self.attributes["INPS_DataType"] in ["Text", "Clip"]:
            self.fusion_input[key] = value
            return

        # Handle expressions
        if self.get_expression():
            if value == "-x" or "-x" in value:
                log.debug("Expression cleared")
                self.set_expression(None)
            else:
                log.warning(
                    "This input is linked by expression. Use '-x' to clear expression"
                )
            return

        if isinstance(value, str) and value.startswith("="):
            self.set_expression(value.lstrip("="))
            return


        # Handle number inputs and compound assignments
        if self.attributes["INPS_DataType"] == "Number":
            value = self.process_number_input(key, value)

        # Handle point inputs
        if self.attributes["INPS_DataType"] == "Point":
            value = self.process_point_input(key, value)
       
        self.fusion_input[key] = value
        self.keyframes = self.fusion_input.GetKeyFrames()

    def process_number_input(self, key, value):
        """Process numerical input, including compound assignments."""
        if value[:2] in ["+=", "-=", "*=", "/=", "%="] and len(value) >= 3:
            operator = value[0]
            operand = float(value[2:])
            current_value = float(self.fusion_input[key])
            value = {
                "+": current_value + operand,
                "-": current_value - operand,
                "*": current_value * operand,
                "/": current_value / operand if operand != 0 else current_value,
                "%": current_value % operand,
            }.get(operator, current_value)

        # Handle MultiButtonIDControl inputs
        if self.attributes["INPID_InputControl"] == "MultiButtonIDControl":
            value = self.process_multibutton_input(value)

        if not self.is_number(value):
            log.warning("This field requires a numerical input.")
            value = self.fusion_input[key]

        return float(value)

    def process_multibutton_input(self, value):
        """Process MultiButtonIDControl inputs."""
        if value.lower() in ["0", "no", "off", "false"]:
            return 0
        elif value.lower() in ["1", "yes", "on", "true"]:
            return 1
        elif self.is_number(value):
            return round(min(1, max(0, float(value))))
        return value

    def process_point_input(self, key, value):
        """Process Point(x, y) input."""
        if value[0] == "p":
            pprint(self.attributes)
            return self.fusion_input[key]

        math_ops = ["+=", "-=", "*=", "/=", "%="]
        compute_values = []

        for i, v in enumerate(value):
            if any(op in v[:2] for op in math_ops) and len(v) >= 3:
                operator = v[0]
                operand = float(v[2:])
                current_value = float(self.fusion_input[key][float(i + 1)])
                v = {
                    "+": current_value + operand,
                    "-": current_value - operand,
                    "*": current_value * operand,
                    "/": current_value / operand if operand != 0 else current_value,
                    "%": current_value % operand,
                }.get(operator, current_value)
            compute_values.append(v)

        return [float(i) for i in compute_values]

    @staticmethod
    def is_number(s):
        try:
            float(s)
            return True
        except ValueError:
            return False


class Communicate(QObject):
    """
    A simple communication class that emits signals to broadcast messages.
    """
    broadcast = Signal(object)

    def __init__(self):
        super().__init__()

    def send(self, value):
        """Emit the broadcast signal with the given value."""
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
        self.tool_dict = dict()  # {row: tool}
        self.attribute_name_keys = []  # List of unique attribute name keys
        self.attribute_data_types = []  # this list is coupled to the key list
        self.tools_inputs = []  # Inputs for each tool (row)
        self.tools_attributes = []  # Attributes for each tool

        # Stores edit data temporarily for multi-edit (this way we get inline math to work)
        self.stored_edit_role_data = None

    def load_fusion_data(self):
        self.communicate.send("Loading tools and inputs")
        start_time = datetime.datetime.now()
        try:
            comp = fu.GetCurrentComp()
        except NameError:
            comp = get_current_comp()
        global current_comp_name
        comp_name = comp.GetAttrs()["COMPS_Name"]
        if comp_name and comp_name != current_comp_name:
            log.debug("Currently working with {}".format(comp_name))
            current_comp_name = comp_name
        if not comp:
            log.info("No comp data found. Probably both Resolve and Fusion are loaded?")
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
            current_tool_inputs = {}
            current_tool_inputs_attributes = {}
            for v in tool.GetInputList().values():
                QApplication.processEvents()
                f = FusionInput(v)
                if f.attributes["INPS_DataType"] not in self.data_types_to_skip:
                    key = f.Name
                    current_tool_inputs[key] = f
                    attribute_data_type = f.attributes["INPS_DataType"]
                    current_tool_inputs_attributes[key] = f.attributes
                    self.appendUnique(key, attribute_data_type)
            if current_tool_inputs:
                self.tools_inputs.append(current_tool_inputs)
                self.tools_attributes.append(current_tool_inputs_attributes)
            self.appendUnique("Tool ID")
            current_tool_inputs["Tool ID"] = tool.ID
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
        """Provide header data for table view."""
        if role == Qt.DisplayRole:
            if orientation == Qt.Horizontal:
                return self.split_header_name(self.attribute_name_keys[section])
            if orientation == Qt.Vertical:
                return self.tool_dict[section + 1].Name

    def setData(self, index, value, role=Qt.EditRole):
        """Update the data in the model."""
        if not index.isValid() or role != Qt.EditRole:
            return False

        fusion_input = self.tools_inputs[index.row()].get(self.attribute_name_keys[index.column()])
        if fusion_input:
            fusion_input[comp.CurrentTime] = value
            return True
        return False

    def flags(self, index):
        """
        Override flags to mark specific cells as editable or not.
        Strings like Tool ID should not be editable.
        """
        if not index.isValid():
            return Qt.ItemIsEnabled
        # If it's Tool ID or other non-editable columns, make it non-editable
        if self.attribute_name_keys[index.column()] in ["Tool ID"]:
            return Qt.ItemIsEnabled | Qt.ItemIsSelectable
        return Qt.ItemIsEditable | Qt.ItemIsEnabled | Qt.ItemIsSelectable

    def split_header_name(self, key, max_chars=8):
        """
        Helper method for QHeaderView labels.
        Splits horizontal headers into multiple lines based on a character limit per line.

        :param key: The original header string.
        :param max_chars: Maximum number of characters per line (default is 8).
        :return: Header string split into multiple lines.
        """
        words = key.split()
        header_name = []
        current_line = []

        char_count = 0
        for word in words:
            if char_count + len(word) + len(current_line) > max_chars:  # Check if adding this word exceeds the limit
                header_name.append(" ".join(current_line))  # Add the current line to the header
                current_line = [word]  # Start a new line
                char_count = len(word)  # Reset the character count for the new line
            else:
                current_line.append(word)  # Add word to the current line
                char_count += len(word)

        if current_line:  # Add the remaining words as the last line
            header_name.append(" ".join(current_line))

        return "\n".join(header_name)  # Join all lines with newlines


class MainWindow(QMainWindow):
    """
    Main window class that manages the table view, buttons, and the status bar.
    """

    def __init__(self, parent=None):
        super().__init__(parent)

        # Tools and attributes to skip
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

        # Set up model and table view
        self._tm = TableModel(self)
        self._tm.inputs_to_skip = self.inputs_to_skip
        self._tm.data_types_to_skip = self.data_types_to_skip
        self._tv = TableView(self)

        # Set up UI elements
        self.setup_ui()

        # Set up proxy model for sorting/filtering
        self.proxy_model = TableSortFilterProxyModel()
        self.proxy_model.setFilterCaseSensitivity(Qt.CaseInsensitive)
        self.proxy_model.setSortCaseSensitivity(Qt.CaseInsensitive)
        self.proxy_model.setDynamicSortFilter(True)
        self._tv.setModel(self.proxy_model)
        self._tv.setSortingEnabled(True)

        # Load initial tool list
        self.tool_list = comp.GetToolList(True)
        self.handle_initial_tool_list()

    def setup_ui(self):
        """Set up UI elements such as buttons, layout, and progress bar."""
        self.always_on_top = QCheckBox("Always on top")
        self.always_on_top.setChecked(True)

        self.clear_button = QPushButton("Clear")
        self.clear_button.setFixedSize(QSize(70, 30))

        self.refresh_button = QPushButton("Refresh")
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

        central_widget = QWidget()
        central_widget.setLayout(v_box)
        self.setCentralWidget(central_widget)

        # Status bar and progress bar
        self.status_bar = self.statusBar()
        self.progress_bar = QProgressBar()
        self.status_bar.addPermanentWidget(self.progress_bar)
        self.progress_bar.setValue(0)
        self.progress_bar.setVisible(False)

        # Corner button in the table
        self.corner = self._tv.findChild(QAbstractButton)

        # Connect signals
        self.setup_connections()

    def setup_connections(self):
        """Set up the signal connections for the UI elements."""
        self.always_on_top.stateChanged.connect(self.changeAlwaysOnTop)
        self.search_line.returnPressed.connect(self.reload_fusion_data)
        self.search_line.textChanged.connect(self.filterRegExpChanged)
        self.clear_button.pressed.connect(self.clear_search)
        self.clear_button.pressed.connect(self.reload_fusion_data)
        self.refresh_button.clicked.connect(self.reload_fusion_data)
        self._tm.communicate.broadcast.connect(self.communication)
        self.corner.clicked.connect(self.reset_sorting)

    def handle_initial_tool_list(self):
        """Handle the initial tool list after loading the composition."""
        if not self.tool_list:
            self.status_bar.showMessage("Select some tools and click Refresh button")
        elif len(self.tool_list.values()) >= LOAD_SELECTED_TOOLS_LIMIT:
            self.status_bar.showMessage("Click Refresh button to load selected tools")
        else:
            self.load_fusion_data()

    def reset_sorting(self):
        """Reset the sorting in the table and clear selection."""
        self.proxy_model.sort(-1)
        self._tv.clearSelection()

    def clear_search(self):
        """Clear the search bar."""
        self.search_line.clear()

    def changeAlwaysOnTop(self):
        """Toggle the 'Always on Top' window flag."""
        if self.always_on_top.isChecked():
            self.setWindowFlags(
                self.windowFlags() | Qt.CustomizeWindowHint | Qt.WindowStaysOnTopHint
            )
        else:
            self.setWindowFlags(
                self.windowFlags() ^ (Qt.CustomizeWindowHint | Qt.WindowStaysOnTopHint)
            )
        self.show()

    def communication(self, value):
        """Handle communication broadcasts from the TableModel."""
        if isinstance(value, float):
            self.progress_bar.setValue(value)
        elif isinstance(value, str):
            self.status_bar.showMessage(value)

        self.progress_bar.setVisible(self.progress_bar.value() not in [0, 100])

    def load_fusion_data(self):
        """Load Fusion data into the table view."""
        # Disable the refresh button during the reload process
        self.refresh_button.setEnabled(False)
        self.refresh_button.setStyleSheet("color: rgb(128,128,128);")

        # Load the Fusion data
        self._tm.load_fusion_data()
        self.proxy_model.setSourceModel(self._tm)
        self._tv.updateColumns()

        # Re-enable the refresh button after loading completes
        self.refresh_button.setEnabled(True)
        self.refresh_button.setStyleSheet("color: rgb(192,192,192);")

    def reload_fusion_data(self):
        """Reload the Fusion data, resetting any filters."""
        self.proxy_model.filteredKeys = []
        self.proxy_model.setSourceModel(None)
        self.load_fusion_data()

    def filterRegExpChanged(self):
        """Update the filter on the table view when the search text changes."""
        regExp = self.search_line.text()
        self.proxy_model.setFilterRegularExpression(regExp)
        self.proxy_model.filteredKeys = []


css = """
*, QTableCornerButton::section {
    color: rgb(192, 192, 192);
    background-color: rgb(52, 52, 52);
    }

QLineEdit {
    background-color: rgb(100,100,100);
    }

QMainWindow {
    border-top: 1px solid rgb(80,80,80);
    border-left: 1px solid rgb(80,80,80);
    border-right: 1px solid rgb(33,33,33);
    border-bottom: 1px solid rgb(33,33,33);
    }

QTableView {
    background-color: rgb(52, 52, 52);
    border-color: rgb(33, 33, 33);
    border-bottom-color: rgb(34, 34, 34);
    color: rgb(192, 192, 192);
    gridline-color: rgb(34, 34, 34);
    }

QHeaderView::section {
    background-color: rgb(100, 100, 100);
    color: rgb(0,0,0);
    padding: 0;
    }

QTableView::item {
    border: 0px;
    padding-left: 8px;
    }

QToolButton {
    background-color: rgb(52, 52, 52);
    }

QToolButton:checked {
    background-color: rgb(70, 86, 134);
    }

QPushButton:pressed {
    background-color: rgb(70, 86, 134);
    }

QTableWidget::item {
    text-align: top center;
    border-style: outset;
    border-width: 4px;
    background-color: rgb(30,30,30);
    }
"""


if __name__ == "__main__":
    try:
        comp = fu.GetCurrentComp()  # this works in most cases
    except Exception as e:
        log.warning(
            "Could not find Fusion comp. Attempt to connect in standalone mode..."
        )
        REMOTE_FUSION_ACCESS = True
        LOAD_SELECTED_TOOLS_LIMIT = 3
        fusion_host = DEFAULT_HOST
        if len(sys.argv) == 2:
            fusion_host = sys.argv[1]

    current_comp_name = comp.GetAttrs()["COMPS_Name"]

    main_app = QApplication.instance()  # checks if QApplication already exists.
    if not main_app:  # create QApplication if it doesnt exist
        main_app = QApplication(sys.argv)
    main_app.setStyleSheet(css)
    main = MainWindow()
    win_title = f"{SCRIPT_NAME} v{__VERSION__}"
    main.setWindowTitle(win_title)
    main.setMinimumSize(QSize(740, 200))
    main.show()
    main_app.exec()
    log.info("Done")
