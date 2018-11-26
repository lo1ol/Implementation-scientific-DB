import os
import re
import xml.etree.ElementTree as ET
from copy import copy
import sys


class VinitiRecordParser:
	def __init__(self, path_to_dir=None):
		if not path_to_dir:
			return
		if path_to_dir.endswith("/") or path_to_dir.endswith('\\'):
			path_to_dir = path_to_dir[:-1]
		self.dir = path_to_dir

	def set_dir(self, path_to_dir):
		if path_to_dir.endswith("/") or path_to_dir.endswith('\\'):
			path_to_dir = path_to_dir[:-1]
		self.dir = path_to_dir

	_languages = {"русский": {'рус'},
	              "итальянский": {'итал', 'ит'},
	              "башкирский":{'башк'},
	              "английский":{'англ', 'анг'},
	              "латышский":{'латыш'},
	              "словацкий":{'словац'},
	              "китайский":{'кит'},
	              "немецкий":{'нем'},
	              "французский":{'фр'},
	              "японский":{'яп'},
	              "испанский":{'исп'},
	              "азербайджанский":{'азерб'},
	              "армянский":{'арм'},
	              "арабский":{'араб'},
	              "алтайский":{'алт'},
	              "африканский":{'африк'},
	              "белорусский":{'белорус'},
	              "болгарский":{'болг'},
	              "алгарский":{"алг"},
	              "венгерский":{'венг'},
	              "вьетнамский":{'вьет'},
	              "греческий":{'греч'},
	              "грузинский":{'груз'},
	              "датский":{'дат'},
	              "каталанский":{'катал', 'каталон'},
	              "казахский":{'каз'},
	              "корейский":{'кор'},
	              "литовский":{'лит'},
	              "латинский":{'лат', 'латин'},
	              "лаосский":{'лаос'},
	              "македонский":{'макед'},
	              "молдавский":{'молд'},
	              "нидерландский":{'нидерл', 'нид'},
	              "норвежский":{'норв'},
	              "польский":{'пол'},
	              "португальский":{'португ', 'порт'},
	              "румынский":{'рум'},
	              "словенский":{'слов', 'словен'},
	              "сербскохорватский":{'серб-хорв'},
	              "сербский":{'серб'},
	              "турецкий":{'тур'},
	              "тибетский":{'тибет'},
	              "иврит":{'иврит'},
	              "исландский":{'исл'},
	              "украинский":{'укр'},
	              "узбекский":{'узб'},
	              "финский":{'фин'},
	              "фламандский":{'флам', 'фламанд'},
	              "хинди":{'хинди'},
	              "хорватский":{'хорв', 'хорват'},
	              "чешский":{'чеш'},
	              "шведский":{'швед'},
	              "эстонский":{'эст'}
	              }


	@staticmethod
	def make_normal(un_normallist):
		format_list = []
		num = 0
		while un_normallist:
			rec = ''
			while True:
				prerec = un_normallist.pop(0) + " "
				rec += prerec
				num += prerec.count('(') - prerec.count(')')
				if num == 0:
					format_list.append(rec.strip())
					break
		return format_list

	@staticmethod
	def det_lang(text):
		if '; рез.' in text:
			text = text.split('; рез.')[-2]
		lang = text.split()[-1].lower()
		if lang.endswith('.'):
			lang = lang.replace('.', '')
		for maybylang, templates in VinitiRecordParser._languages.items():
			if lang in templates:
				return maybylang
		if 'США' in text or 'ЕПВ' in text or 'Великобритания' in text or 'Австралия' in text or 'Автралия' in text or 'Европа' in text or 'Канада' in text or ' англ.' in text.lower() or ' аегл.' in text.lower() or 'Sheffield' in text:
			return 'английский'
		if 'Россия' in text or ' рус.' in text.lower():
			return 'русский'
		if 'Франция' in text or ' фр.' in text.lower():
			return 'французский'
		if 'Германия' in text or 'ФРГ' in text or 'Австрия' in text or 'Швейцария' in text or ' нем.' in text.lower() or ' berlin' in text.lower():
			return 'немецкий'
		if 'Польша' in text:
			return 'польский'
		if ' укр.' in text.lower():
			return 'украинский'
		if ' арм.' in text.lower():
			return 'армянский'
		if 'EPB' in text or 'ЕРВ' in text:
			return "английский"
		raise RuntimeError("UNKNOWN LANGUAGE in %s" % text)

	@staticmethod
	def det_resume_lang(text):
		try:
			languages = [VinitiRecordParser.det_lang(text)]
		except RuntimeError:
			languages = []
		if '; рез.' in text:
			text = text.split('; рез.')[-1]
		else:
			return languages
		text = text.strip()
		langs = text.split(' ')
		langs = list(map((lambda str: str.replace('.', '').replace(',', '').lower().strip()), langs))
		for lang in langs:
			for maybylang, templates in VinitiRecordParser._languages.items():
				if lang in templates:
					languages.append(maybylang)
					break
			else:
				print('UNKNOWN RESUME LANGUAGE %s' % lang, file=sys.stderr)
		return languages

	@staticmethod
	def formatIPC(IPC_list):
		if IPC_list[0].startswith('<sup>'):
			year = re.sub('<sup>(?P<num>.*)</sup> .*', '\g<num>', IPC_list[0].upper())
			IPC_list[0] = IPC_list[0][IPC_list[0].find('</sup>')+6:].strip()
			for i in range(len(IPC_list)):
				IPC_list[i] = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)', r'\1\3\5 \7 (200%s)' % year, IPC_list[i].upper())

		elif re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+( )?\([0-9]{4}\.[0-9]{2}\)', IPC_list[0].upper()):
			for i in range(len(IPC_list)):
				if re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+', IPC_list[i].upper()):
					IPC_list[i] = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)', r'\1\3\5 \7 (%s)' % year, IPC_list[i].upper())
				elif re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+( )?\([0-9]{4}\.[0-9]{2}\)', IPC_list[i].upper()):
					year = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)( )?\(([0-9]{4}\.[0-9]{2})\)', r'\9', IPC_list[i].upper())
					IPC_list[i] = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)( )?(\([0-9]{4}\.[0-9]{2}\))', r'\1\3\5 \7 \9', IPC_list[i].upper())
				else:
					raise RuntimeError("%s argument in %s has error format" % (i, IPC_list))

		elif re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+( )?\([0-9]{4}\)', IPC_list[0].upper()):
			for i in range(len(IPC_list)):
				if re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+', IPC_list[i].upper()):
					IPC_list[i] = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)', r'\1\3\5 \7 (%s)' % year, IPC_list[i].upper())
				elif re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+( )?\(([0-9]{4})\)', IPC_list[i].upper()):
					year = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)( )?\(([0-9]{4})\)', r'\9', IPC_list[i].upper())
					IPC_list[i] = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)( )?(\([0-9]{4}\))', r'\1\3\5 \7 \9', IPC_list[i].upper())
				else:
					raise RuntimeError("%s argument in %s has error format" % (i, IPC_list))

		elif re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+( )?\([0-9]{4}\)', IPC_list[-1].upper()):
			year = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)( )?\(([0-9]{4})\)', r'\9', IPC_list[-1].upper())
			for i in range(len(IPC_list)-1, -1, -1):
				if re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+', IPC_list[i].upper()):
					IPC_list[i] = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)', r'\1\3\5 \7 (%s)' % year, IPC_list[i].upper())
				elif re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+( )?\(([0-9]{4})\)', IPC_list[i].upper()):
					year = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)( )?\(([0-9]{4})\)', r'\9', IPC_list[i].upper())
					IPC_list[i] = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)( )?(\([0-9]{4}\))', r'\1\3\5 \7 \9', IPC_list[i].upper())
				else:
					raise RuntimeError("%s argument in %s has error format" % (i, IPC_list))

		elif re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+( )?\([0-9]{4}\.[0-9]{2}\)', IPC_list[-1].upper()):
			for i in range(len(IPC_list)-1, -1, -1):
				if re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+', IPC_list[i].upper()):
					IPC_list[i] = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)', r'\1\3\5 \7 (%s)' % year, IPC_list[i].upper())
				elif re.fullmatch('[A-Z]( )?[0-9]{2}( )?[A-Z]( )?[0-9]+/[0-9]+( )?\([0-9]{4}\.[0-9]{2}\)', IPC_list[i].upper()):
					year = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)( )?\(([0-9]{4}\.[0-9]{2})\)', r'\9', IPC_list[i].upper())
					IPC_list[i] = re.sub('([A-Z])( )?([0-9]{2})( )?([A-Z])( )?([0-9]+/[0-9]+)( )?(\([0-9]{4}\.[0-9]{2}\))', r'\1\3\5 \7 \9', IPC_list[i].upper())
				else:
					raise RuntimeError("%s argument in %s has error format" % (i, IPC_list))
		else:
			raise RuntimeError("%s has error format" % IPC_list)


	def get_records(self):
		for file in os.listdir(self.dir):
			if not os.path.isfile(self.dir + "/" + file): continue
			file = open(self.dir + "/" + file, encoding='utf8')
			for rec in self.parse_file(file):
				yield rec
			file.close()


	def parse_file(self, file):
		file = file.readline() + file.readline()
		file = re.sub('<font color="#0000FF">(?P<char>.)</font>', '\g<char>', file)
		collection = ET.fromstring(file)
		for publication in collection:
			record = {key: "" for key in {'AU', 'UC', 'ID', 'IPC', 'NA', 'ISN', 'DT', 'ISB', 'AB', 'KW', 'CC', 'CL', 'SO', 'TI', 'LN', 'RL', 'NP', 'WP', 'DP', 'DAP', "DPP", 'ND', 'DD', 'SS', 'RD', 'PY', 'PUN', 'BIC', "ILC", "TBC", "MAC", "PGS", "IS", "VOL"}}
			for field in publication:
				if field.tag == "AU":
					record['AU'] = field.text.split(',')
					record['AU'] = list(map((lambda str: str.strip()), record['AU']))
					try:
						record['AU'] = self.make_normal(record['AU'])
					except IndexError:
						print(publication.attrib, "has anomaly bracket structure", file = sys.stderr)
					continue
				if field.tag == "TI":
					record["TI"] = ET.tostring(field, encoding="unicode")[4:-5]
					continue
				if field.tag == "AB":
					record["AB"] = ET.tostring(field, encoding="unicode")[4:-5]
					continue
				if field.tag == "KW":
					record["KW"] = ET.tostring(field, encoding="unicode")[4:-5].split(",")
					record["KW"] = list(map((lambda str: str.strip()), record['KW']))
					try:
						if record["KW"]:
							record['KW'] = self.make_normal(copy(record['KW']))
					except IndexError:
						print(publication.attrib, "has anomaly bracket structure", file=sys.stderr)
					continue
				if field.tag == "SO":
					record["SO"] = ET.tostring(field, encoding="unicode")[4:-5]
					if record["SO"].startswith('Заявка') or record["SO"].startswith('Пат.'):
						record["NP"] = record["SO"].split()[1]
						if not record["NP"][0].isdigit():
							if record['NP'] == 'инф.':
								record["WP"] = record['NP'] = ''
							else:
								record["WP"] = record["NP"][:-1]
						if re.match(".*Опубл\. [0-9]{2}\.[0-9]{2}\.[0-9]{2}.*", record['SO']):
							record["DP"] = re.sub(".*Опубл\. ([0-9]{2}\.[0-9]{2}\.[0-9]{2}).*", r'\1', record['SO'])
							year = record['DP'].split('.')[-1]
							if year<'18':
								record['DP'] = record['DP'][:-2]+'20'+year
							else:
								record['DP'] = record['DP'][:-2]+'19'+year
						if re.match(".*Заявл\. [0-9]{2}\.[0-9]{2}\.[0-9]{2}.*", record['SO']):
							record["DAP"] = re.sub(".*Заявл\. ([0-9]{2}\.[0-9]{2}\.[0-9]{2}).*", r'\1', record['SO'])
							year = record['DAP'].split('.')[-1]
							if year < '18':
								record['DAP'] = record['DAP'][:-2]+'20'+year
							else:
								record['DAP'] = record['DAP'][:-2]+'19'+year
						if re.match(".*Приор\. [0-9]{2}\.[0-9]{2}\.[0-9]{2}.*", record['SO']):
							record["DPP"] = re.sub(".*Приор\. ([0-9]{2}\.[0-9]{2}\.[0-9]{2}).*", r'\1', record['SO'])
							year = record['DPP'].split('.')[-1]
							if year<'18':
								record['DPP'] = record['DPP'][:-2]+'20'+year
							else:
								record['DPP'] = record['DPP'][:-2]+'19'+year

						if re.match(".*Опубл\. ([0-9]{2}\.[0-9]{2}\.[0-9]{4}).*", record['SO']):
							record["DP"] = re.sub(".*Опубл\. ([0-9]{2}\.[0-9]{2}\.[0-9]{4}).*", r'\1', record['SO'])
						if re.match(".*Заявл\. [0-9]{2}\.[0-9]{2}\.[0-9]{4}.*", record['SO']):
							record["DAP"] = re.sub(".*Заявл\. ([0-9]{2}\.[0-9]{2}\.[0-9]{4}).*", r'\1', record['SO'])
						if re.match(".*Приор\. [0-9]{2}\.[0-9]{2}\.[0-9]{4}.*", record['SO']):
							record["DPP"] = re.sub(".*Приор\. ([0-9]{2}\.[0-9]{2}\.[0-9]{4}).*", r'\1', record['SO'])
						else:
							record["WP"] = record["SO"][record["SO"].find(record["NP"])+len(record["NP"])+1:record["SO"].find(',')]
					if publication.find("NA").text.endswith("ДЕП"):
						record["ND"] = record["SO"].split()[-1]
						record["DD"] = record["SO"].split()[-3][0:-1]
						record["WD"] = record["SO"][record["SO"].rfind(' в ')+3: record["SO"].rfind(record["DD"])-1]
					try:
						record['LN'] = self.det_lang(record['SO'])
					except RuntimeError as err:
						print(err, file=sys.stderr)
					record['RL'] = self.det_resume_lang(record['SO'])
					if re.match(".*\[(19[4-9][0-9]|20[01][0-9])\].*", record['SO']):
						record['PY'] = re.sub(".*\[(19[4-9][0-9]|20[01][0-9])\].*", r'\1', record['SO'])
					elif re.match(".*[,. ](19[4-9][0-9]|20[01][0-9])[ ,.:].*", record['SO']):
						record['PY'] = re.sub('.*[,. ](19[4-9][0-9]|20[01][0-9])[ ,.:].*', r'\1', record['SO'])
					elif record['DP']:
						record['PY'] = record['DP'].split('.')[-1]
					elif re.match(".*<sub>[12][8901][0-9][0-9]</sub>.*", record['SO']):
						record['PY'] = re.sub(".*<sub>([12][8901][0-9][0-9])</sub>.*", r'\1', record['SO'])
					elif re.match(".*(19[4-9][0-9]|20[01][0-9])-(19[4-9][0-9]|20[01][0-9]).*", record['SO']):
						record['PY'] = re.sub(".*(19[4-9][0-9]|20[01][0-9])-(19[4-9][0-9]|20[01][0-9]).*", r'\2', record['SO'])
					elif re.match(".*(19[4-9][0-9]|20[01][0-9])( )?\((19[4-9][0-9]|20[01][0-9])\).*", record['SO']):
						record['PY'] = re.sub(".*(19[4-9][0-9]|20[01][0-9])( )?\((19[4-9][0-9]|20[01][0-9])\).*", r'\3', record['SO'])
					else:
						print('publication %s has no correct year of publication format' % publication.attrib, file=sys.stderr)
					if re.match('.*ISSN [0-9]{4}-[0-9]{3}[0-9xX].*', record['SO']):
						record['ISN'] = re.sub('.*ISSN ([0-9]{4}-[0-9]{3}[0-9xX]).*', r'\1', record['SO'])

					if not record["SO"].startswith('Заявка') and not record["SO"].startswith('Пат.'):
						if publication.find('NA').text.endswith('ДЕП'):
							text = record['SO'][:record['SO'].rfind(' Деп. ')]
						else:
							text = record['SO']
						yearpos = -1
						if text.rfind(record['PY']+'.') != -1:
							yearpos = text.rfind(record['PY'] + '.')
						elif text.rfind(record['PY'] + ',') != -1:
							yearpos = text.rfind(record['PY'] + ',')
						elif text.rfind(record['PY'] + ']') != -1:
							yearpos = text.rfind(record['PY'] + ']')
						elif text.rfind(record['PY'] + ')') != -1:
							yearpos = text.rfind(record['PY'] + ')')
						elif text.rfind(record['PY']) != -1:
							yearpos = text.rfind(record['PY'])
						if yearpos == -1:
							print('Can\'t find info in %s' % record['SO'], file=sys.stderr)
							continue ##################################################################WARNING!!!!!
						part = text[yearpos:]
						record['PUN'] = re.sub('(.*)\. .*?%s' % record['PY'], r'\1', text[:yearpos+4])
						if re.match('%s\. ([0-9]*).*' % record['PY'], part):
							record['VOL'] = re.sub('%s\. ([0-9]*).*' % record['PY'], r'\1', part)
						if re.match('.* N [0-9]*.*', part):
							record['IS'] = re.sub('.* N ([0-9]*).*', r'\1', part)
						if re.match('.* с. [^\s]*.*', part):
							record['PGS'] = re.sub('.* с. ([^ .,]*).*', r'\1', part)
						elif re.match('.*? [^\s]* с..*', part):
							record['PGS'] = re.sub('.*? ([^\s]*) с..*', r'\1', part)
						if re.match('.*?[0-9]* ил\..*', part):
							record['ILC'] = re.sub('.*?([0-9]*) ил\..*', r'\1', part)
						if re.match('.*?[0-9]* табл\..*', part):
							record['TBC'] = re.sub('.*?([0-9]*) табл\..*', r'\1', part)
						if re.match('.*?[0-9]* карт.*', part):
							record['MAC'] = re.sub('.*?([0-9]*) карт.*', r'\1', part)
						if re.match('.*Библ. [0-9]*.*', part):
							record['BIC'] = re.sub('.*Библ. ([0-9]*).*', r'\1', part)
					continue
				if field.tag == 'ID':
					record["ID"] = field.text
					record["RD"] = field.text.split()[0]
					record["SS"] = field.text.split()[1][0:2]
					continue
				if field.tag == 'CL':
					record['CL'] = field.text.replace(';', ' ').replace(',', ' ').split()
					continue
				if field.tag == 'IPC':
					record['IPC'] = ET.tostring(field, encoding='unicode')[5:-6].split(',')
					record['IPC'] = list(map((lambda str: str.strip()), record['IPC']))
					try:
						self.formatIPC(record['IPC'])
					except RuntimeError as err:
						print(err, file=sys.stderr)
					continue
				record[field.tag] = field.text
			yield record

if __name__ == "__main__":
	db = VinitiRecordParser("./Data")
