ROLLBACK;

SET enable_seqscan = off;

SELECT r.id, r.abstract_number, r.udc, lang.name, country.name, r.abstract,
r.id_real, r,content, r.comment, 
info.*, so.*, 
array_agg(DISTINCT kw.phrase), array_agg(DISTINCT au.full_name),
generation_date, publication_date, 
type, verified, create_time, verification_time, deponire_number, deponire_date, dep_place.*, r.patent_number, r.appeletion_date, r.priore_date,
r.publication_date, r.patent_place_id, r.ipc, r.issn, r.isbn, array_agg(DISTINCT rub.name), array_agg(DISTINCT sub.name)

		FROM main_data.record as r 
		
		LEFT OUTER JOIN main_data.record_has_rubric as rrub ON rrub.record_id = r.id
		LEFT OUTER JOIN main_data.rubric as rub ON rrub.rubric_id = rub.id

		LEFT OUTER JOIN main_data.rubric_has_subject as rubs ON rubs.rubric_id = rub.id
		LEFT OUTER JOIN main_data.subject as sub ON rubs.subject_id = sub.id

		LEFT OUTER JOIN main_data.record_has_key_word as rkw ON rkw.record_id = r.id
		LEFT OUTER JOIN main_data.key_word as kw ON  rkw.key_word_id = kw.id

		LEFT OUTER JOIN main_data.record_has_author as rau ON rau.record_id = r.id 
		LEFT OUTER JOIN main_data.author as au ON rau.author_id = au.id
		
		LEFT OUTER JOIN main_data.language as lang ON r.language_id = lang.id
		LEFT OUTER JOIN main_data.country as country ON r.country_id = country.id
		LEFT OUTER JOIN main_data.info as info ON r.info_id = info.id
		LEFT OUTER JOIN main_data.source as so ON r.source_id = so.id
		LEFT OUTER JOIN main_data.deponire_place as dep_place ON r.deponire_place_id = dep_place.id
		LEFT OUTER JOIN main_data.patent_place as pat_place ON r.patent_place_id = pat_place.id
		
		WHERE to_tsvector('russian', r.abstract) @@ plainto_tsquery('russian','модель')
		GROUP BY r.id, lang.name, country.name, info.id, so.id, dep_place.id, pat_place.id
		ORDER BY r.publication_date;
		--ORDER BY ts_rank(to_tsvector('russian', au.full_name), plainto_tsquery('russian','иванов'))

--COPY (SELECT abstract_number, udc, language_id, country_id, title, abstract, ID_real, content, comment, info_id, source_id, generation_date, publication_year, type, verified, create_time,
-- verification_time, deponire_number, deponire_date, deponire_place_id, patent_number, appeletion_date, priore_date, publication_date, patent_place_id, IPC, ISSN
-- FROM main_data.record LIMIT 10) TO 'C:/Users/mkh19/Desktop/kek.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';
 
--COPY main_data.record(abstract_number, udc, language_id, country_id, title, abstract, ID_real, content, comment, info_id, source_id, generation_date, publication_year, type, verified, create_time,
-- verification_time, deponire_number, deponire_date, deponire_place_id, patent_number, appeletion_date, priore_date, publication_date, patent_place_id, IPC, ISSN)
--  FROM 'C:/Users/mkh19/Desktop/kek.csv' DELIMITER ',' CSV HEADER;
  
--select * from to_tsvector('simple', 'вирус гепатита');
--select plainto_tsquery('russian', 'вирусы гепатита');
--select phrase, to_tsvector('english', kw.phrase), to_tsvector('russian', kw.phrase), to_tsvector('russian', kw.phrase) || to_tsvector('english', kw.phrase) from main_data.key_word as kw;
