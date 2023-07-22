import sys

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QAbstractItemView,
    QApplication,
    QHeaderView,
    QLabel,
    QMainWindow,
    QTreeWidget,
    QTreeWidgetItem,
    QVBoxLayout,
    QWidget,
)


class MyTreeItem(QTreeWidgetItem):
    def __init__(self, title):
        super().__init__()
        self.title = title
        self.setText(0, self.title)
        self.setData(0, Qt.CheckStateRole, Qt.Unchecked)
    def setChecked(self, checked):
        """Set the check state of the item."""
        self.setData(
            0,
            Qt.CheckStateRole,
            Qt.Checked if checked else Qt.Unchecked,
        )


class MyTreeWidget(QTreeWidget):
    def __init__(self, contents, parent=None):
        super().__init__(parent)
        self.setAllColumnsShowFocus(True)
        self.setDragDropMode(QAbstractItemView.NoDragDrop)
        self.setSelectionMode(QAbstractItemView.MultiSelection)
        self.setStyleSheet("QTreeView::item{margin-top:1px;margin-bottom:1px;}")
        self.setColumnCount(1)
        self.setHeaderLabels(["Title"])

        # add item to the tree
        my_items = []
        for content in contents:
            my_items.append(MyTreeItem(content))
        self.addTopLevelItems(my_items)
    def selectionChanged(self, selected, deselected):
        """Selection changed."""
        super().selectionChanged(selected, deselected)
        self.blockSignals(True)
        for index in selected.indexes():
            item = self.itemFromIndex(index)
            # did not work at PySide6.3.1
            item.setChecked(True)
            # item.setData(0, Qt.CheckStateRole, Qt.Checked)
        for index in deselected.indexes():
            item = self.itemFromIndex(index)
            # did not work at PySide6.3.1
            item.setChecked(False)
            # item.setData(0, Qt.CheckStateRole, Qt.Unchecked)
        self.blockSignals(False)


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle('TREEWIDGET_DEMO')

        # self.setMinimumSize(400, 460)
        main_layout = QVBoxLayout()

        label = QLabel("Demo")
        label.setAlignment(Qt.AlignCenter)
        main_layout.addWidget(label)

        data = [
            "Demo 01",
            "Demo 02",
            "Demo 03",
            "Demo 04",
            "Demo 05",
            "Demo 06",
        ]
        self.my_list_tree = MyTreeWidget(data)
        self.my_list_tree.setFixedHeight(200)
        main_layout.addWidget(self.my_list_tree, 1)

        widget = QWidget()
        widget.setLayout(main_layout)
        self.setCentralWidget(widget)


app = QApplication(sys.argv)
window = MainWindow()
window.show()
app.exec()

