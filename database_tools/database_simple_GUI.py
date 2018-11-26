import sys
from PyQt5.QtWidgets import *
from request_pen_const import VIEW_ATTRIBUTES
from request_pen import make_request
import postgresql as pgsql
from os import getpid

class Field(QWidget):
	def __init__(self, parent):
		QWidget.__init__(self, parent)
		self.initUI()
	def initUI(self):
		hbox = QHBoxLayout()
		self.setLayout(hbox)
		options = ["fulltext search", "regular expression", ">", "<", ">=", "<=", "=", "!=", "is"]
		cls_btn = QPushButton("Удалить поле \"ИЛИ\"")
		cls_btn.clicked.connect(self.deleteSelf)

		self.opt_combo = QComboBox()
		for opt in options:
			self.opt_combo.addItem(opt)

		self.text_line = QLineEdit()
		hbox.addWidget(self.opt_combo)
		hbox.addWidget(self.text_line)
		hbox.addWidget(cls_btn)

	def deleteSelf(self):
		self.text_line.setText("")
		self.close()

	def getRequest(self):
		opt = self.opt_combo.currentText()
		text = self.text_line.text()
		if opt == 'fulltext search':
			opt = 'fs'
		elif opt == 'regular expression':
			opt = 're'
		if not text:
			return None
		else:
			return opt, text

class RequestOrField(QWidget):
	def __init__(self, parent):
		QWidget.__init__(self, parent)
		self.initUI()

	def initUI(self):
		self.lay = QVBoxLayout()
		main_lay = QVBoxLayout()
		self.setLayout(main_lay)
		add_btn = QPushButton("Добавить поле \"ИЛИ\"")
		add_btn.clicked.connect(self.addField)

		self.lay.addWidget(Field(self))
		main_lay.addLayout(self.lay)
		main_lay.addWidget(add_btn)


	def addField(self):
		self.lay.addWidget(Field(self))

	def getRequest(self):
		fields = [self.lay.itemAt(i) for i in range(self.lay.count())]
		responses = []
		for field in fields:
			response = field.widget().getRequest()
			if response:
				responses.append(response)
		return responses

	def deleteSelf(self):
		fields = [self.lay.itemAt(i) for i in range(self.lay.count())]
		for field in fields:
			field.widget().text_line.setText("")
		self.close()

class RequestField(QWidget):
	def __init__(self, parent, view):
		self.view = view
		QWidget.__init__(self, parent)
		self.initUI()

	def initUI(self):
		hbox = QHBoxLayout()
		self.setLayout(hbox)
		attributs = VIEW_ATTRIBUTES[self.view][0]

		self.fields = RequestOrField(self)
		self.attrib_combo = QComboBox(self)
		for attrib in attributs:
			self.attrib_combo.addItem(attrib)

		dlt_btn = QPushButton("Удалить поле", self)
		dlt_btn.clicked.connect(self.deleteSelf)

		hbox.addWidget(self.attrib_combo)
		hbox.addWidget(self.fields)
		hbox.addWidget(dlt_btn)

	def getRequest(self):
		attrib = self.attrib_combo.currentText()
		requests = self.fields.getRequest()
		resp = ()
		for request in requests:
			if not resp:
				resp = (attrib, ) + request
			else:
				resp = ((attrib, ) + request, 'or', resp)
		return resp

	def deleteSelf(self):
		self.fields.deleteSelf()
		self.close()


class DataBaseInterface(QWidget):
	def __init__(self, view):
		QWidget.__init__(self)
		self.view = view
		self.initUI()
		self.show()

	def initUI(self):
		main_layout = QVBoxLayout()
		self.fields = QVBoxLayout()
		self.setLayout(main_layout)
		for i in range(2):
			self.fields.addWidget(RequestField(self, self.view))

		btn_box = QHBoxLayout()
		new_rec_btn = QPushButton("Добавить запрос")
		new_rec_btn.clicked.connect(self.addSearchField)

		send_rec_btn = QPushButton("Отправить запрос")
		send_rec_btn.clicked.connect(self.sendRequest)

		btn_box.addWidget(new_rec_btn)
		btn_box.addStretch(1)
		btn_box.addWidget(send_rec_btn)

		main_layout.addLayout(self.fields)
		main_layout.addStretch(1)
		main_layout.addLayout(btn_box)

	def addSearchField(self):
		self.fields.addWidget(RequestField(self, self.view))

	def sendRequest(self):
		requests = [self.fields.itemAt(i) for i in range(self.fields.count())]
		responses = []
		for req in requests:
			response = req.widget().getRequest()
			if response:
				responses.append(response)
		print(responses)
		if responses:
			sql_request = make_request('main_data.fast_search_view', [responses])
			conn = pgsql.open('pq://Server:@localhost:5432/viniti_db')
			cursor_id = "cursor_%d" % getpid()
			try:
				with conn.xact():
					conn.execute(f"DECLARE {cursor_id} CURSOR FOR ({sql_request} LIMIT 100);")
					cur = conn.cursor_from_id(cursor_id)
					self.printTable(cur)
			except Exception as ex:
				print(ex)


	def printTable(self, cur):
		self._wdgt = QWidget()
		hbox = QHBoxLayout()
		self._wdgt.setLayout(hbox)
		tbl = QTableWidget()
		hbox.addWidget(tbl)
		tbl.setColumnCount(len(cur.column_names))
		i = 0
		for row in cur:
			tbl.insertRow(i)
			for j, elem in enumerate(row):
				if isinstance(elem, pgsql.types.Array):
					elem = list(elem)
				tbl.setItem(i, j, QTableWidgetItem(str(elem)))
			i += 1
		tbl.setHorizontalHeaderLabels(cur.column_names)
		tbl.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeToContents)
		self._wdgt.show()


if __name__ == "__main__":
	app = QApplication(sys.argv)
	inter = DataBaseInterface('main_data.fast_search_view')
	inter.show()
	sys.exit(app.exec_())
