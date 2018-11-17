ROLLBACK;
SELECT r.id, r.abstract_number, r.udc, lang.name, country.name, r.abstract,
r.id_real, r,content, r.comment, 
info.*, --so.*, 
array_agg(kw.phrase), array_agg(au.full_name),
generation_date, publication_date, 
type, verified, create_time, verification_time, deponire_number, deponire_date, dep_place.*, r.patent_number, r.appeletion_date, r.priore_date,
r.publication_date, r.patent_place_id, r.ipc, r.issn, r.isbn, array_agg(rub.name), array_agg(DISTINCT sub.name)

		FROM main_data.record as r 
		LEFT JOIN main_data.rubric as rub ON TRUE
		INNER JOIN main_data.record_has_rubric as rrub ON rrub.record_id = r.id AND rrub.rubric_id = rub.id
		LEFT OUTER JOIN main_data.language as lang ON r.language_id = lang.id
		LEFT OUTER JOIN main_data.country as country ON r.country_id = country.id
		LEFT OUTER JOIN main_data.info as info ON r.info_id = info.id
		LEFT OUTER JOIN main_data.source as so ON r.source_id = so.id
		LEFT OUTER JOIN main_data.deponire_place as dep_place ON r.deponire_place_id = dep_place.id
		LEFT OUTER JOIN main_data.patent_place as pat_place ON r.patent_place_id = pat_place.id
		LEFT JOIN main_data.key_word as kw ON TRUE
		INNER JOIN main_data.record_has_key_word as rkw ON rkw.record_id = r.id AND rkw.key_word_id = kw.id
		LEFT JOIN main_data.author as au ON TRUE
		INNER JOIN main_data.record_has_author as rau ON rau.record_id = r.id AND rau.author_id = au.id
		LEFT JOIN main_data.subject as sub ON TRUE
		INNER JOIN main_data.rubric_has_subject as rubs ON rubs.rubric_id = rub.id AND rubs.subject_id = sub.id
		
		WHERE au.full_name ~~* '%Ali%'
		GROUP BY r.id, lang.name, country.name, info.id, so.id, dep_place.id, pat_place.id;

--SELECT * FROM main_data.record;
--select * from to_tsvector('simple', 'вирус гепатита');
--select plainto_tsquery('russian', 'вирусы гепатита');
--select phrase, to_tsvector('english', kw.phrase), to_tsvector('russian', kw.phrase), to_tsvector('russian', kw.phrase) || to_tsvector('english', kw.phrase) from main_data.key_word as kw;
