import sys
from PyQt6.QtWidgets import QApplication
from gui.main_window import AniDownloaderGUI

if __name__ == '__main__':
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = AniDownloaderGUI()
    window.show()
    sys.exit(app.exec())