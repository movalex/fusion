import sys
from PySide2.QtCore import (
    QSize,
    Qt,
)
from PySide2.QtWidgets import (
    QApplication,
    QHBoxLayout,
    QMainWindow,
    QPushButton,
    QWidget,
)

try:
    import BlackmagicFusion as bmd

    fu = bmd.scriptapp("Fusion")
except ImportError:
    print("no Fusion app found")
    sys.exit()


class BlurClass(QMainWindow):
    def __init__(self, parent=None):
        QMainWindow.__init__(self, parent)
        self.setWindowTitle("Add Blur")
        self.resize(450, 50)
        self.setMaximumSize(QSize(700, 130))
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        horizontal_layout = QHBoxLayout(central_widget)
        self.blr_btn = QPushButton(central_widget)
        horizontal_layout.addWidget(self.blr_btn)
        self.setWindowFlags(Qt.WindowStaysOnTopHint)
        self.retranslate_ui()

    def retranslate_ui(self):
        self.blr_btn.setText("add one blur")
        self.blr_btn.font()
        self.blr_btn.clicked.connect(self.add_blur_node)

    @staticmethod
    def add_blur_node():
        comp = fu.GetCurrentComp()
        blur = comp.AddTool("Blur", -32768, -32768)
        print(f"Node {blur.Name} added from PySide2 window!")


if __name__ == "__main__":
    # create QApplication if it doesnt exist
    app = QApplication.instance()
    if not app:
        app = QApplication(sys.argv)
    w = BlurClass()
    app.setAttribute(Qt.AA_DisableHighDpiScaling)
    w.show()
    app.exec_()
