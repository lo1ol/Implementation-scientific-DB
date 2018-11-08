import postgresql
from Viniti_parser import VinitiRecordParser
from pprint import pprint

if __name__== "__main__":
	connection = postgresql.open('pq://Server:@localhost:5432/viniti_db')
	db = VinitiRecordParser("./Data")
	i = 0 #test
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
			elif key == "DD":
				rec[key] = "to_date('%s', 'DD.MM.YYYY')" % rec[key]
			elif isinstance(rec[key], str):
				rec[key] = "$text$%s$text$" % rec[key]

		ps = connection.prepare("""SELECT main_data.make_record(
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
			)""".format(**rec))

		print(ps())

		i += 1
		if (i == 100):
			break
