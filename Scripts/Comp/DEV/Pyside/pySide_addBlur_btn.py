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


class BlurClass(QMainWindow):
    def __init__(self, parent=None):
        QMainWindow.__init__(self, parent)
        self.setWindowTitle("Add Blur")
        self.resize(250, 50)
        self.setMaximumSize(QSize(300, 130))
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
        blur = comp.AddTool("Blur")
        print(f"Node {blur.Name} added from PySide2 window!")


if __name__ == '__main__':
    app = QApplication([])
    w = BlurClass()
    w.show()
    app.exec_()