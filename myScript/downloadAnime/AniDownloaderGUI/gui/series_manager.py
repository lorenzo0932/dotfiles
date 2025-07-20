import os
import re
import platform
from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QTableWidget, QTableWidgetItem,
    QHeaderView, QLabel, QLineEdit, QPushButton, QFormLayout,
    QCheckBox, QSpinBox, QMessageBox, QFileDialog
)
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QPixmap
from core.download_worker import DownloadWorker, save_series_data
from .series_editor import SeriesEditorDialog

class SeriesManagerDialog(QDialog):
    def __init__(self, json_file_path, log_file_path, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Gestisci Serie")
        self.setGeometry(200, 200, 800, 600)
        self.setMinimumSize(700, 500)
        self.json_file_path = json_file_path
        self.log_file_path = log_file_path
        self.series_data = []
        self.original_series_data = []
        self._init_ui()
        self._load_series_data()

    def _init_ui(self):
        main_layout = QVBoxLayout(self)

        series_display_layout = QHBoxLayout()
        self.table_widget = QTableWidget()
        self.table_widget.setColumnCount(5)
        self.table_widget.setHorizontalHeaderLabels(["Nome", "Percorso", "Pattern Link", "Continua", "Ep. Passati"])
        
        header = self.table_widget.horizontalHeader()
        # **LA SOLUZIONE È QUI (Parte 1):** Imposta la modalità base su Interattiva
        for i in range(self.table_widget.columnCount()):
            header.setSectionResizeMode(i, QHeaderView.ResizeMode.Interactive)
        
        self.table_widget.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.table_widget.setSelectionMode(QTableWidget.SelectionMode.SingleSelection)
        self.table_widget.setSortingEnabled(True)
        self.table_widget.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table_widget.itemSelectionChanged.connect(self._on_series_selected)
        self.table_widget.doubleClicked.connect(self._open_series_editor)
        series_display_layout.addWidget(self.table_widget)
        
        self.image_label = QLabel("Seleziona una serie per vedere la locandina")
        self.image_label.setFixedSize(200, 300)
        self.image_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.image_label.setStyleSheet("border: 1px solid #ccc; background-color: #f0f0f0;")
        series_display_layout.addWidget(self.image_label)
        main_layout.addLayout(series_display_layout)

        control_layout = QHBoxLayout()
        control_layout.addWidget(QLabel("Cerca:"))
        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Cerca per nome...")
        self.search_input.textChanged.connect(self._filter_series)
        control_layout.addWidget(self.search_input)
        control_layout.addStretch(1)
        
        self.reset_sort_button = QPushButton("Ripristina Ordine")
        self.reset_sort_button.clicked.connect(self._reset_table_sort)
        control_layout.addWidget(self.reset_sort_button)
        main_layout.addLayout(control_layout)

        button_layout = QHBoxLayout()
        self.add_button = QPushButton("Aggiungi Serie")
        self.add_button.setStyleSheet("background-color: #4CAF50; color: white; font-weight: bold;")
        self.add_button.clicked.connect(self._add_series)
        self.edit_button = QPushButton("Modifica Serie Selezionata")
        self.edit_button.clicked.connect(self._open_series_editor)
        self.remove_button = QPushButton("Rimuovi Selezionata")
        self.remove_button.setStyleSheet("background-color: #f44336; color: white; font-weight: bold;")
        self.remove_button.clicked.connect(self._remove_selected_series)
        self.save_button = QPushButton("Salva e Chiudi")
        self.save_button.setDefault(True)
        self.save_button.clicked.connect(self._save_changes_and_accept)
        self.cancel_button = QPushButton("Annulla")
        self.cancel_button.clicked.connect(self.reject)
        button_layout.addWidget(self.add_button); button_layout.addWidget(self.edit_button); button_layout.addWidget(self.remove_button)
        button_layout.addStretch(1); button_layout.addWidget(self.cancel_button); button_layout.addWidget(self.save_button)
        main_layout.addLayout(button_layout)

    def _reset_table_sort(self):
        self.table_widget.horizontalHeader().setSortIndicator(-1, Qt.SortOrder.AscendingOrder)
        self._filter_series()

    def _on_series_selected(self):
        selected_items = self.table_widget.selectedItems()
        if not selected_items: self.image_label.clear(); self.image_label.setText("Nessuna serie selezionata"); return
        row = selected_items[0].row(); item = self.table_widget.item(row, 0)
        if not item: self.image_label.clear(); return
        
        series_name = item.text()
        series = next((s for s in self.series_data if s.get("name") == series_name), None)

        if series and series.get("path"):
            series_path = series.get("path")
            image_path = os.path.join(os.path.dirname(series_path), "folder.jpg")
            if os.path.exists(image_path) and (pixmap := QPixmap(image_path)) and not pixmap.isNull():
                self.image_label.setPixmap(pixmap.scaled(self.image_label.size(), Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation))
            else: self.image_label.clear(); self.image_label.setText("folder.jpg non trovato")
        else: self.image_label.clear(); self.image_label.setText("Percorso non definito")

    def _load_series_data(self):
        try:
            worker = DownloadWorker(series_list=[], json_file_path=self.json_file_path)
            self.series_data = worker._load_series_data()
            self.original_series_data = [s.copy() for s in self.series_data]
            self._filter_series()
        except Exception as e:
            QMessageBox.critical(self, "Errore Caricamento", f"Impossibile caricare: {e}")

    def _filter_series(self):
        search_text = self.search_input.text().lower()
        filtered_data = [s for s in self.series_data if search_text in s.get("name", "").lower()]
        self._populate_table(filtered_data)

    def _populate_table(self, data):
        self.table_widget.blockSignals(True)
        self.table_widget.setRowCount(0)
        self.table_widget.setRowCount(len(data))
        for row, series in enumerate(data):
            self.table_widget.setItem(row, 0, QTableWidgetItem(series.get("name", "")))
            self.table_widget.setItem(row, 1, QTableWidgetItem(series.get("path", "")))
            self.table_widget.setItem(row, 2, QTableWidgetItem(series.get("link_pattern", "")))
            self.table_widget.setItem(row, 3, QTableWidgetItem("Sì" if series.get("continue", False) else "No"))
            self.table_widget.setItem(row, 4, QTableWidgetItem(str(series.get("passed_episodes", 0))))
        self.table_widget.blockSignals(False)
        if data: self.table_widget.selectRow(0)
        else: self._on_series_selected()
        
        # **LA SOLUZIONE È QUI (Parte 2):** Applica il layout intelligente dopo aver caricato i dati
        self.table_widget.resizeColumnsToContents()
        self.table_widget.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)
        self.table_widget.horizontalHeader().setSectionResizeMode(1, QHeaderView.ResizeMode.Stretch)
        self.table_widget.horizontalHeader().setSectionResizeMode(2, QHeaderView.ResizeMode.Stretch)

    def _add_series(self):
        editor = SeriesEditorDialog({}, is_new=True, parent=self)
        if editor.exec():
            is_deleted, new_data = editor.get_data()
            if not is_deleted and new_data:
                self.series_data.append(new_data)
                self._filter_series()

    def _open_series_editor(self):
        selected_rows = self.table_widget.selectionModel().selectedRows()
        if not selected_rows:
            QMessageBox.warning(self, "Nessuna Selezione", "Seleziona una serie da modificare."); return
        
        selected_name = self.table_widget.item(selected_rows[0].row(), 0).text()
        series_to_edit = next((s for s in self.series_data if s.get("name") == selected_name), None)
        
        if series_to_edit:
            editor = SeriesEditorDialog(series_to_edit, is_new=False, parent=self)
            if editor.exec():
                is_deleted, modified_data = editor.get_data()
                original_index = next((i for i, s in enumerate(self.series_data) if s["name"] == selected_name), -1)
                if original_index == -1: return

                if is_deleted: self.series_data.pop(original_index)
                elif modified_data: self.series_data[original_index] = modified_data
                self._filter_series()

    def _remove_selected_series(self):
        selected_rows = self.table_widget.selectionModel().selectedRows()
        if not selected_rows:
            QMessageBox.warning(self, "Nessuna Selezione", "Seleziona una serie da rimuovere."); return
        
        selected_name = self.table_widget.item(selected_rows[0].row(), 0).text()
        reply = QMessageBox.question(self, "Conferma Eliminazione", f"Sei sicuro di voler rimuovere '{selected_name}' dalla lista?\nQuesta operazione sarà permanente solo dopo aver salvato.",
                                     QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No, QMessageBox.StandardButton.No)
        if reply == QMessageBox.StandardButton.Yes:
            self.series_data = [s for s in self.series_data if s.get("name") != selected_name]
            self._filter_series()

    def _save_changes_and_accept(self):
        try:
            if self.series_data != self.original_series_data:
                save_series_data(self.json_file_path, self.series_data)
            self.accept()
        except Exception as e:
            QMessageBox.critical(self, "Errore Salvataggio", f"Impossibile salvare le modifiche su disco: {e}")