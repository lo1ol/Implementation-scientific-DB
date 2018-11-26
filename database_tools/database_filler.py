import postgresql
from Viniti_parser import VinitiRecordParser
from pprint import pprint

if __name__== "__main__":
	connection = postgresql.open('pq://Server:@localhost:5432/viniti_db')
	db = VinitiRecordParser("./Data")
	i = 0 #test
	ex_cnt = 0
	ex_cnt2 = 0
	for rec in db.get_records():


		for key in rec:
			if key == "IPC" and isinstance(rec[key], list):
				print("KEKIPC", rec[key])
				rec[key] = rec[key][0]
			if key == "RD":
				if int(rec[key][-2:]) > 12:
					print("KEK")
					rec[key] = "2010-12"
				rec[key] += "-01"
			if key == "AU":
				rec[key] = [name[:-1] if name.endswith('*') else name for name in rec[key]]
			if key == "AB" and not rec[key]:
				rec[key] = "''"
			if key == "PUN" and not rec[key] and rec["DT"] in ["03", "08"]:
				rec[key] = "UNKNOWN"
				print("KEK UNKNOWN PUN")
			if key == 'DD' and len(rec[key]) == 8:
				if rec[key][6:] < '20':
					rec[key] = rec[key][:6] + '20' + rec[key][6:]
				else:
					rec[key] = rec[key][:6] + '19' + rec[key][6:]

			if not rec[key]:
				rec[key] = "NULL"
			elif isinstance(rec[key], list):
				rec[key] = list({elem.strip() for elem in rec[key]})
				rec[key] = ["$text$%s$text$" % elem for elem in rec[key]]
				string = "ARRAY ["
				for elem in rec[key]:
					string += elem + ','
				if string[-1] == ',':
					string = string[:-1]
				string += ']'
				rec[key] = string
			elif key in ["DD", "DAP", "DP", "DPP"]:
				if "ВИНИТИ" == rec[key]:
					rec[key] = "08.07.1997"
					print("KEK DATE BAD")
				rec[key] = "to_date('%s', 'DD.MM.YYYY')" % rec[key]
			elif isinstance(rec[key], str):
				rec[key] = "$text$%s$text$" % rec[key]
		req = """SELECT main_data.make_record(
			p_abstract := {AB},
			p_authors := {AU},
			p_BIC := {BIC},
			p_country_code := {CC},
			p_rubrics := {CL},
			p_appeletion_date:= {DAP},
			p_publication_date := {DP},
			p_prior_date := {DPP},
			p_type := {DT},
			p_ID_real := {ID},
			p_ILC := {ILC},
			p_IPC := {IPC},
			p_issue := {IS},
			p_ISBN := {ISB},
			p_ISSN := {ISN},
			p_key_words := {KW},
			p_language := {LN},
			p_MAC := {MAC},
			p_abstract_number := {NA},
			p_deponire_date := {DD},
			p_deponire_number := {ND},
			p_patent_number := {NP},
			p_pages := {PGS},
			p_deponire_place := {PUN},
			p_publication_year := {PY},
			p_generation_date := {RD},
			p_resume_language := {RL},
			p_source := {SO},
			p_referends := ARRAY [('UNKNOWN', NULL)::main_data.referend_t],
			p_subject := {SS},
			p_TBC := {TBC},
			p_title := {TI},
			p_udc := {UC},
			p_volume := {VOL},
			p_patent_place := {WP}
			)""".format(**rec)
		ps = connection.prepare(req)
		try:
			res = ps()
			if res[0][0] == 2:
				ex_cnt2 += 1
			if res[0][0] % 100 == 0:
				print(res)
		except Exception as ex:
			if "Иванов" not in str(ex) and "record_check1" not in str(ex):
				ex_cnt += 1
				print(ex)
		i += 1
		if (i == 100000):
			break

	print(ex_cnt)
	print(ex_cnt2)
