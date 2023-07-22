from PySide6 import QtWidgets, QtGui, QtCore

class CheckableComboBox(QtWidgets.QComboBox):
    def __init__(self):
        super(CheckableComboBox, self).__init__()
        self.view().pressed.connect(self.handleItemPressed)
        self.setModel(QtGui.QStandardItemModel(self))

    def handleItemPressed(self, index):
        item = self.model().itemFromIndex(index)
        if item.checkState() == QtCore.Qt.Checked:
            item.setCheckState(QtCore.Qt.Unchecked)
        else:
            item.setCheckState(QtCore.Qt.Checked)

class Dialog_01(QtWidgets.QMainWindow):
    def __init__(self):
        super().__init__()
        myQWidget = QtWidgets.QWidget()
        myBoxLayout = QtWidgets.QHBoxLayout()
        myQWidget.setLayout(myBoxLayout)
        self.setCentralWidget(myQWidget)
        self.ComboBox = CheckableComboBox()
        self.toolbutton = QtWidgets.QToolButton(self)
        self.toolbutton.setText('Categories ')
        self.toolmenu = QtWidgets.QMenu(self)
        for i in range(3):
            self.ComboBox.addItem('Category %s' % i)
            item = self.ComboBox.model().item(i, 0)
            item.setCheckState(QtCore.Qt.Unchecked)
            action = self.toolmenu.addAction('Category %s' % i)
            action.setCheckable(True)
        self.toolbutton.setMenu(self.toolmenu)
        self.toolbutton.setPopupMode(QtWidgets.QToolButton.InstantPopup)
        myBoxLayout.addWidget(self.toolbutton)
        myBoxLayout.addWidget(self.ComboBox)

if __name__ == '__main__':

    app = QtWidgets.QApplication(['Test'])
    dialog_1 = Dialog_01()
    dialog_1.show()
    app.exec_()
    
