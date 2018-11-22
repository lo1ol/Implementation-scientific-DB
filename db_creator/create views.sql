ROLLBACK;
BEGIN TRANSACTION;

DROP VIEW IF EXISTS main_data.expert_view;
CREATE VIEW main_data.expert_view AS 
	SELECT r.id as id,
		r.abstract_number as abstract_number, 
		r.udc as udc, 
		lang.name as language, 
		country.name as country, 
		r.abstract as abstract,
		r.id_real as real_id, 
		r.content as content, 
		r.comment as comment, 
		info.pages as pages,
		info.bic as bic,
		info.mac as mac,
		info.ilc as ilc,
		info.tbc as tbc, 
		so.name as source_name,
		so.volume as volume,
		so.issue as issue,
		kw.phrase as key_word, 
		au.name as author,
		r.generation_date as generation_date, 
		r.publication_year as publication_year, 
		r.type as type, 
		r.verified as verified, 
		r.create_time as create_time, 
		r.verification_time as verification_time, 
		r.deponire_number as deponire_number, 
		r.deponire_date as deponire_date, 
		dep_place.name as deponire_place, 
		r.patent_number as patent_number, 
		r.appeletion_date as appeletion_date, 
		r.priore_date as priore_date,
		r.publication_date as patent_publication_date, 
		pat_place.name as patent_place, 
		r.ipc as ipc, 
		r.issn as issn, 
		r.isbn as isbn, 
		rub.name as rubric, 
		sub.name as subject,
		rl.name as resume_language,
		rf.name as referend_name,
		rf.login as referend_login,
		rrf.responsibilities as referend_responsobilities

	FROM main_data.record as r 
	
	LEFT OUTER JOIN main_data.record_has_rubric as rrub ON rrub.record_id = r.id
	LEFT OUTER JOIN main_data.rubric as rub ON rrub.rubric_id = rub.id

	LEFT OUTER JOIN main_data.rubric_has_subject as rubs ON rubs.rubric_id = rub.id
	LEFT OUTER JOIN main_data.subject as sub ON rubs.subject_id = sub.id

	INNER JOIN main_data.record_has_key_word as rkw ON rkw.record_id = r.id
	INNER JOIN main_data.key_word as kw ON  rkw.key_word_id = kw.id

	INNER JOIN main_data.record_has_author as rau ON rau.record_id = r.id 
	INNER JOIN main_data.author as au ON rau.author_id = au.id

	LEFT OUTER JOIN main_data.record_has_resume_language as rrl ON rrl.record_id = r.id
	LEFT OUTER JOIN main_data.language as rl ON rl.id = rrl.language_id

	INNER JOIN main_data.record_has_referend as rrf ON rrf.record_id = r.id
	INNER JOIN employees.referend as rf ON rf.id = rrf.referend_id
		
	INNER JOIN main_data.language as lang ON r.language_id = lang.id
	INNER JOIN main_data.country as country ON r.country_id = country.id
	LEFT OUTER JOIN main_data.info as info ON r.info_id = info.id
	LEFT OUTER JOIN main_data.source as so ON r.source_id = so.id
	LEFT OUTER JOIN main_data.deponire_place as dep_place ON r.deponire_place_id = dep_place.id
	LEFT OUTER JOIN main_data.patent_place as pat_place ON r.patent_place_id = pat_place.id;


DROP VIEW IF EXISTS main_data.simple_view;
CREATE VIEW main_data.simple_view AS 
	SELECT 	r.id as id,
		r.abstract_number as abstract_number, 
		r.udc as udc, 
		lang.name as language, 
		country.name as country, 
		r.abstract as abstract,
		r.id_real as real_id, 
		r.content as content, 
		info.pages as pages,
		info.bic as bic,
		info.mac as mac,
		info.ilc as ilc,
		info.tbc as tbc, 
		so.name as source_name,
		so.volume as volume,
		so.issue as issue,
		kw.phrase as key_word, 
		au.name as author,
		r.generation_date as generation_date, 
		r.publication_year as publication_year, 
		r.type as type, 
		r.deponire_number as deponire_number, 
		r.deponire_date as deponire_date, 
		dep_place.name as deponire_place, 
		r.patent_number as patent_number, 
		r.appeletion_date as appeletion_date, 
		r.priore_date as priore_date,
		r.publication_date as patent_publication_date, 
		pat_place.name as patent_place, 
		r.ipc as ipc, 
		r.issn as issn, 
		r.isbn as isbn, 
		rub.name as rubric, 
		sub.name as subject,
		rl.name as resume_language

	FROM main_data.record as r 
	
	LEFT OUTER JOIN main_data.record_has_rubric as rrub ON rrub.record_id = r.id
	LEFT OUTER JOIN main_data.rubric as rub ON rrub.rubric_id = rub.id

	LEFT OUTER JOIN main_data.rubric_has_subject as rubs ON rubs.rubric_id = rub.id
	LEFT OUTER JOIN main_data.subject as sub ON rubs.subject_id = sub.id

	INNER JOIN main_data.record_has_key_word as rkw ON rkw.record_id = r.id
	INNER JOIN main_data.key_word as kw ON  rkw.key_word_id = kw.id

	INNER JOIN main_data.record_has_author as rau ON rau.record_id = r.id 
	INNER JOIN main_data.author as au ON rau.author_id = au.id

	LEFT OUTER JOIN main_data.record_has_resume_language as rrl ON rrl.record_id = r.id
	LEFT OUTER JOIN main_data.language as rl ON rl.id = rrl.language_id
		
	INNER JOIN main_data.language as lang ON r.language_id = lang.id
	INNER JOIN main_data.country as country ON r.country_id = country.id
	LEFT OUTER JOIN main_data.info as info ON r.info_id = info.id
	LEFT OUTER JOIN main_data.source as so ON r.source_id = so.id
	LEFT OUTER JOIN main_data.deponire_place as dep_place ON r.deponire_place_id = dep_place.id
	LEFT OUTER JOIN main_data.patent_place as pat_place ON r.patent_place_id = pat_place.id;

DROP VIEW IF EXISTS main_data.fast_search_view;
CREATE VIEW main_data.fast_search_view AS 
	SELECT 	r.id as id,
		r.abstract_number as abstract_number, 
		r.udc as udc, 
		lang.name as language, 
		country.name as country, 
		r.abstract as abstract,
		r.id_real as real_id, 
		r.content as content, 
		so.name as source_name,
		so.volume as volume,
		so.issue as issue,
		kw.phrase as key_word, 
		au.name as author,
		r.generation_date as generation_date, 
		r.publication_year as publication_year, 
		r.type as type, 
		r.deponire_number as deponire_number,
		r.patent_number as patent_number, 
		r.ipc as ipc, 
		r.issn as issn, 
		r.isbn as isbn, 
		rub.name as rubric, 
		sub.name as subject

	FROM main_data.record as r 
	
	LEFT OUTER JOIN main_data.record_has_rubric as rrub ON rrub.record_id = r.id
	LEFT OUTER JOIN main_data.rubric as rub ON rrub.rubric_id = rub.id

	LEFT OUTER JOIN main_data.rubric_has_subject as rubs ON rubs.rubric_id = rub.id
	LEFT OUTER JOIN main_data.subject as sub ON rubs.subject_id = sub.id

	INNER JOIN main_data.record_has_key_word as rkw ON rkw.record_id = r.id
	INNER JOIN main_data.key_word as kw ON  rkw.key_word_id = kw.id

	INNER JOIN main_data.record_has_author as rau ON rau.record_id = r.id 
	INNER JOIN main_data.author as au ON rau.author_id = au.id
		
	INNER JOIN main_data.language as lang ON r.language_id = lang.id
	INNER JOIN main_data.country as country ON r.country_id = country.id
	LEFT OUTER JOIN main_data.info as info ON r.info_id = info.id
	LEFT OUTER JOIN main_data.source as so ON r.source_id = so.id;

DROP VIEW IF EXISTS main_data.fast_show_view;
CREATE VIEW main_data.fast_show_view AS 
	SELECT 	r.id as id,
		r.abstract_number as abstract_number, 
		lang.name as language, 
		country.name as country, 
		r.abstract as abstract,
		r.content as content, 
		so.name as source_name,
		so.volume as volume,
		so.issue as issue,
		kw.phrase as key_word, 
		au.name as author,
		r.publication_year as publication_year, 
		r.type as type, 
		rub.name as rubric, 
		sub.name as subject

	FROM main_data.record as r 
	
	LEFT OUTER JOIN main_data.record_has_rubric as rrub ON rrub.record_id = r.id
	LEFT OUTER JOIN main_data.rubric as rub ON rrub.rubric_id = rub.id

	LEFT OUTER JOIN main_data.rubric_has_subject as rubs ON rubs.rubric_id = rub.id
	LEFT OUTER JOIN main_data.subject as sub ON rubs.subject_id = sub.id

	INNER JOIN main_data.record_has_key_word as rkw ON rkw.record_id = r.id
	INNER JOIN main_data.key_word as kw ON  rkw.key_word_id = kw.id

	INNER JOIN main_data.record_has_author as rau ON rau.record_id = r.id 
	INNER JOIN main_data.author as au ON rau.author_id = au.id
		
	INNER JOIN main_data.language as lang ON r.language_id = lang.id
	INNER JOIN main_data.country as country ON r.country_id = country.id
	LEFT OUTER JOIN main_data.source as so ON r.source_id = so.id;


END TRANSACTION;