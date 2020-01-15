from PySide2 import QtCore
from PySide2.QtGui import *
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


class Ui_blurWindow(object):
    def setupUi(self, blurWindow):
        blurWindow.setObjectName("blurWindow")
        blurWindow.resize(200, 50)
        blurWindow.setMaximumSize(QtCore.QSize(225, 130))
        self.centralwidget = QWidget(blurWindow)
        self.centralwidget.setObjectName("centralwidget")
        self.horizontalLayout = QHBoxLayout(self.centralwidget)
        self.horizontalLayout.setObjectName("horizontalLayout")
        self.blr_btn = QPushButton(self.centralwidget)
        self.blr_btn.setObjectName("blr_btn")
        self.horizontalLayout.addWidget(self.blr_btn)
        blurWindow.setCentralWidget(self.centralwidget)
        self.retranslateUi(blurWindow)
        QtCore.QMetaObject.connectSlotsByName(blurWindow)

    def retranslateUi(self, blurWindow):
        blurWindow.setWindowTitle(QApplication.translate("blurWindow", "add Blur", None))
        self.blr_btn.setText(QApplication.translate("blurWindow", "Blur", None))


class blurClass(QMainWindow, Ui_blurWindow):
    def __init__(self):
        super(blurClass, self).__init__()
        self.setupUi(self)
        self.setWindowFlags(QtCore.Qt.WindowStaysOnTopHint)
        self.blr_btn.clicked.connect(self.addBlurNode)

    def addBlurNode(self):
        blur = composition.AddTool("Blur")
        print("Node added from PySide2 window!")


if __name__ == '__main__':
    app = QApplication([])
    w = blurClass()
    w.show()
    app.exec_()
