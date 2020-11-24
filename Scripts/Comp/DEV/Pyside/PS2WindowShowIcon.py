from PySide2.QtWidgets import QApplication, QWidget
import sys
from PySide2.QtGui import QIcon


class Window(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Setting Icon")
        self.setGeometry(300, 300, 500, 400)

        self.setIcon()

    def setIcon(self):
        app_icon = QIcon("icon.png")
        self.setWindowIcon(app_icon)


myApp = QApplication(sys.argv)
window = Window()
window.show()

myApp.exec_()
sys.exit(0)
