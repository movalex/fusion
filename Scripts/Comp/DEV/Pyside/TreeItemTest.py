#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
from PySide6.QtWidgets import QApplication, QWidget, QGroupBox, QHBoxLayout, QVBoxLayout, QTreeView
from PySide6.QtCore import Qt, QAbstractItemModel, QModelIndex


class GUIWindow(QWidget):
    def __init__(self, parent=None):
        super(GUIWindow, self).__init__(parent)
        """ Setup UI """

        self.setWindowTitle("QTreeView from Dictionary")

        groupbox_model = QGroupBox('TreeView')  # Create a Group Box for the Model

        hbox_model = QHBoxLayout()  # Create a Horizontal layout for the Model
        vbox = QVBoxLayout()  # Create a Vertical layout for the Model Horizontal layout

        tree_view = QTreeView()  # Instantiate the View

        headers = ["Dictionary Keys", "Dictionary Values"]

        tree = {'Root': {"Level_1": {"Item_1": 1.10, "Item_2": 1.20, "Item_3": 1.30},
                         "Level_2": {"SubLevel_1":
                                         {"SubLevel_1_item1": 2.11, "SubLevel_1_Item2": 2.12, "SubLevel_1_Item3": 2.13},
                                     "SubLevel_2":
                                         {"SubLevel_2_Item1": 2.21, "SubLevel_2_Item2": 2.22,
                                          "SubLevel_2_Item3": 2.23}},
                         "Level_3": {"Item_1": 3.10, "Item_2": 3.20, "Item_3": 3.30}}}

        # Set the models
        model = TreeModel(headers, tree)
        tree_view.setModel(model)
        tree_view.expandAll()
        tree_view.resizeColumnToContents(0)

        hbox_model.addWidget(tree_view)  # Add the Widget to the Model Horizontal layout
        groupbox_model.setLayout(hbox_model)  # Add the hbox_model to layout of group box
        vbox.addWidget(groupbox_model)  # Add groupbox elements to vbox
        self.setLayout(vbox)


class TreeModel(QAbstractItemModel):
    def __init__(self, headers, data, parent=None):
        super(TreeModel, self).__init__(parent)
        """ subclassing the standard interface item models must use and 
                implementing index(), parent(), rowCount(), columnCount(), and data()."""

        rootData = [header for header in headers]
        self.rootItem = TreeNode(rootData)
        indent = -1
        self.parents = [self.rootItem]
        self.indentations = [0]
        self.createData(data, indent)

    def createData(self, data, indent):
        if type(data) == dict:
            indent += 1
            position = 4 * indent
            for dict_keys, dict_values in data.items():
                if position > self.indentations[-1]:
                    if self.parents[-1].childCount() > 0:
                        self.parents.append(self.parents[-1].child(self.parents[-1].childCount() - 1))
                        self.indentations.append(position)
                else:
                    while position < self.indentations[-1] and len(self.parents) > 0:
                        self.parents.pop()
                        self.indentations.pop()
                parent = self.parents[-1]
                parent.insertChildren(parent.childCount(), 1, parent.columnCount())
                parent.child(parent.childCount() - 1).setData(0, dict_keys)
                if type(dict_values) != dict:
                    parent.child(parent.childCount() - 1).setData(1, str(dict_values))
                self.createData(dict_values, indent)

    def index(self, row, column, index=QModelIndex()):
        """ Returns the index of the item in the model specified by the given row, column and parent index """

        if not self.hasIndex(row, column, index):
            return QModelIndex()
        if not index.isValid():
            item = self.rootItem
        else:
            item = index.internalPointer()

        child = item.child(row)
        if child:
            return self.createIndex(row, column, child)
        return QModelIndex()

    def parent(self, index):
        """ Returns the parent of the model item with the given index
                If the item has no parent, an invalid QModelIndex is returned """

        if not index.isValid():
            return QModelIndex()
        item = index.internalPointer()
        if not item:
            return QModelIndex()

        parent = item.parentItem
        if parent == self.rootItem:
            return QModelIndex()
        else:
            return self.createIndex(parent.childNumber(), 0, parent)

    def rowCount(self, index=QModelIndex()):
        """ Returns the number of rows under the given parent
                When the parent is valid it means that rowCount is returning the number of children of parent """

        if index.isValid():
            parent = index.internalPointer()
        else:
            parent = self.rootItem
        return parent.childCount()

    def columnCount(self, index=QModelIndex()):
        """ Returns the number of columns for the children of the given parent """

        return self.rootItem.columnCount()

    def data(self, index, role=Qt.DisplayRole):
        """ Returns the data stored under the given role for the item referred to by the index """

        if index.isValid() and role == Qt.DisplayRole:
            return index.internalPointer().data(index.column())
        elif not index.isValid():
            return self.rootItem.data(index.column())

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        """ Returns the data for the given role and section in the header with the specified orientation """

        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self.rootItem.data(section)


class TreeNode(object):
    def __init__(self, data, parent=None):
        self.parentItem = parent
        self.itemData = data
        self.children = []

    def child(self, row):
        return self.children[row]

    def childCount(self):
        return len(self.children)

    def childNumber(self):
        if self.parentItem is not None:
            return self.parentItem.children.index(self)

    def columnCount(self):
        return len(self.itemData)

    def data(self, column):
        return self.itemData[column]

    def insertChildren(self, position, count, columns):
        if position < 0 or position > len(self.children):
            return False
        for row in range(count):
            data = [v for v in range(columns)]
            item = TreeNode(data, self)
            self.children.insert(position, item)

    def parent(self):
        return self.parentItem

    def setData(self, column, value):
        if column < 0 or column >= len(self.itemData):
            return False
        self.itemData[column] = value


if __name__ == '__main__':
    app = QApplication(sys.argv)
    app.setStyle("plastique")  # ("cleanlooks")
    form = GUIWindow()
    form.show()
    sys.exit(app.exec())