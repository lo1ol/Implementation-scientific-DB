import postgresql
from Viniti_parser import VinitiRecordParser
from pprint import pprint

if __name__== "__main__":
	connection = postgresql.open('pq://Petr:@localhost:5432/viniti_db')
	db = VinitiRecordParser("./Data")
	for rec in db.get_records():
		for key in rec:
			if key == "RD":
				rec[key] += "-01"
			if key == "AU":
				rec[key] = [name[:-1] if name.endswith('*') else name for name in rec[key]]
			if not rec[key]:
				rec[key] = "NULL"
			elif isinstance(rec[key], list):
				rec[key] = 'ARRAY %s' % rec[key]
			elif isinstance(rec[key], str):
				rec[key] = "'%s'" % rec[key]
		pprint(rec)

		ps = connection.prepare("""SELECT make_record(
			abstruct := {AB},
			authors := {AU},
			BIC := {BIC},
			country := {CC},
			rubrics := {CL},
			appeletion_date:= {DAP},
			publication_date := {DP},
			prior_date := {DPP},
			type := {DT},
			ID := {ID},
			ILC := {ILC},
			IPC := {IPC},
			issues := {IS},
			ISBN := {ISB},
			ISSN := {ISN},
			key_words := {KW},
			language := {LN},
			MAC := {MAC},
			abstruct_number := {NA},
			deponire_date := {DD},
			deponire_number := {ND},
			patent_number := {NP},
			pages := {PGS},
			deponire_place := {PUN},
			publication_year := {PY},
			generation_date := {RD},
			resume_language := {RL},
			source := {SO},
			subject := {SS},
			TBC := {TBC},
			title := {TI},
			udc := {UC},
			volume := {VOL},
			patent_place := {WP}
			)""".format(**rec))
		print(ps())
		break
