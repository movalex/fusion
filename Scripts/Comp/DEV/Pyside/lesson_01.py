import sys

from PySide2.QtWidgets import QApplication, QMainWindow, QPushButton
from PySide2.QtCore import Qt, QSize


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("App")
        button = QPushButton("PressMe!")
        self.setFixedSize(QSize(500, 100))
        self.setCentralWidget(button)

    
if __name__ == "__main__":
    app = QApplication.instance()
    if not app:
        app = QApplication(sys.argv)

    window = MainWindow()
    window.show()

    app.exec_()
