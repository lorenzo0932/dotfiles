from PyQt6.QtWidgets import (
    QTableWidgetItem, QDialog, QVBoxLayout, QLabel,
    QCheckBox, QHBoxLayout, QPushButton
)
from PyQt6.QtCore import QTimer, Qt

class StatusTableWidgetItem(QTableWidgetItem):
    def __init__(self, text, priority):
        super().__init__(text)
        self.priority = priority

    def __lt__(self, other):
        if isinstance(other, StatusTableWidgetItem):
            return self.priority < other.priority
        return super().__lt__(other)

class StopConfirmationDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Conferma Interruzione")
        self.setModal(True)
        self.setMinimumWidth(400)
        
        layout = QVBoxLayout(self)
        
        message_label = QLabel(
            "<b>ATTENZIONE: Stai per interrompere il processo.</b><br><br>"
            "Questa operazione terminerà forzatamente tutti i download e le conversioni in corso.<br>"
            "Tutti i file parziali e temporanei verranno eliminati.<br><br>"
            "Sei sicuro di voler procedere?"
        )
        message_label.setWordWrap(True)
        layout.addWidget(message_label)

        self.dont_show_again_checkbox = QCheckBox("Non mostrare più questo avviso")
        layout.addWidget(self.dont_show_again_checkbox)

        button_layout = QHBoxLayout()
        self.ok_button = QPushButton("Attendi 5s...")
        self.ok_button.setEnabled(False)
        self.ok_button.clicked.connect(self.accept)
        
        cancel_button = QPushButton("Annulla")
        cancel_button.clicked.connect(self.reject)
        
        button_layout.addStretch()
        button_layout.addWidget(cancel_button)
        button_layout.addWidget(self.ok_button)
        layout.addLayout(button_layout)
        
        self.timer_seconds = 5
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_timer)
        self.timer.start(1000)

    def update_timer(self):
        self.timer_seconds -= 1
        if self.timer_seconds > 0:
            self.ok_button.setText(f"Attendi {self.timer_seconds}s...")
        else:
            self.timer.stop()
            self.ok_button.setText("OK, Interrompi")
            self.ok_button.setEnabled(True)

    def dont_show_again(self):
        return self.dont_show_again_checkbox.isChecked()