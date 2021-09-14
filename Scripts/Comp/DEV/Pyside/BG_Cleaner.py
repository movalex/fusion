import sys

from PySide2.QtWidgets import QApplication, QWidget, QLabel, QPushButton, QVBoxLayout, QHBoxLayout, QGridLayout
from PySide2.QtCore import Qt


class BgCleaner(QWidget):
    def __init__(self):
        super(BgCleaner, self).__init__()
        self.init_ui()

    def init_ui(self):
        self.setGeometry(500, 500, 50, 50)
        self.setWindowTitle("BG Cleaner")
        self.setWindowFlags(self.windowFlags() | Qt.WindowStaysOnTopHint)

        self.display_ui()

        self.show()

    def display_ui(self):

        title = QLabel("Select all the BG nodes to clean then press the button.")
        clean_button = QPushButton('Clean', self)
        clean_button.clicked.connect(self.clean)

        title_version = QLabel("Version Up or Down the layering of the selected nodes.")
        version_up = QPushButton('Up', self)
        version_up.clicked.connect(self.v_up)
        version_down = QPushButton('Down', self)
        version_down.clicked.connect(self.v_down)

        # versions_section =
        menu = QGridLayout()
        menu.setContentsMargins(10, 10, 10, 10)
        menu.addWidget(title, 0, 0, 1, 2)
        menu.addWidget(clean_button, 1, 0, 1, 2)
        menu.addWidget(title_version, 2, 0, 1, 2)
        menu.addWidget(version_up, 3, 0)
        menu.addWidget(version_down, 3, 1)

        self.setLayout(menu)

    def clean(self):
        print("Cleaning")

    def v_up(self):
        print("Versioning up")

    def v_down(self):
        print("Versioning down")


if __name__ == '__main__':
    app = QApplication.instance()
    if not app:
        app = QApplication(sys.argv)

    window = BgCleaner()
    app.exec_()
