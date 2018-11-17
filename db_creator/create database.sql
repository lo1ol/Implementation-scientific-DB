ROLLBACK;

BEGIN TRANSACTION;

DROP LANGUAGE IF EXISTS plpythonu CASCADE;
CREATE LANGUAGE plpythonu;


--todo

DROP SCHEMA IF EXISTS public;


DROP SCHEMA IF EXISTS main_data CASCADE;
CREATE SCHEMA main_data
  AUTHORIZATION "postgres";


GRANT USAGE ON SCHEMA main_data TO "Server";
GRANT USAGE ON SCHEMA main_data TO "ordinary_viewer";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "Server";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "ordinary_viewer";


DROP SCHEMA IF EXISTS employees CASCADE;
CREATE SCHEMA employees
  AUTHORIZATION "postgres";


GRANT USAGE ON SCHEMA employees TO "Server";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA employees TO "Server";


DROP SCHEMA IF EXISTS users CASCADE;
CREATE SCHEMA users
  AUTHORIZATION "postgres";

GRANT USAGE ON SCHEMA main_data TO "Server";
GRANT USAGE ON SCHEMA main_data TO "ordinary_viewer";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "Server";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "ordinary_viewer";


DROP SCHEMA IF EXISTS service_info CASCADE;
CREATE SCHEMA service_info
  AUTHORIZATION "postgres";

GRANT USAGE ON SCHEMA main_data TO "Server";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "Server";


DROP EXTENSION IF EXISTS pg_trgm;
CREATE EXTENSION pg_trgm WITH SCHEMA main_data;

DROP TABLE IF EXISTS main_data.record;
CREATE TABLE main_data.record(
	id SERIAL,
	abstract_number VARCHAR(25) NOT NULL,
	udc VARCHAR(128),
	language_id INT NOT NULL,
	country_id INT NOT NULL,
	title TEXT NOT NULL,
	abstract TEXT NOT NULL,
	ID_real VARCHAR(256),
	content TEXT,
	comment TEXT,
	info_id INTEGER,
	source_id INTEGER NOT NULL,
	generation_date DATE NOT NULL,
	publication_year INT,
	type INT CHECK (type>0  AND type < 15),
	verified BOOLEAN DEFAULT FALSE,
	create_time TIMESTAMP DEFAULT NOW(),
	verification_time timestamp DEFAULT NULL,


	deponire_number VARCHAR(64) CHECK ((type != 3 and type !=8 and deponire_number is NULL) or ((type = 3 or type = 8) and deponire_number IS NOT NULL)),
	deponire_date DATE	    CHECK ((type != 3 and type !=8 and deponire_date is NULL) or ((type = 3 or type = 8) and deponire_date IS NOT NULL)),
	deponire_place_id INT	    CHECK ((type != 3 and type !=8 and deponire_place_id is NULL) or ((type = 3 or type = 8) and deponire_place_id IS NOT NULL)),


	patent_number VARCHAR(64) UNIQUE CHECK ((type != 9 and patent_number is NULL) or (type = 9 and patent_number IS NOT NULL)),
	appeletion_date DATE 		 CHECK ((type != 9 and appeletion_date is NULL) or (type = 9 and appeletion_date IS NOT NULL)),
	priore_date DATE 		 CHECK ((type != 9 and priore_date is NULL) or (type =9)),
	publication_date DATE		 CHECK ((type != 9 and publication_date is NULL) or (type =9)),
	patent_place_id INT		 CHECK ((type != 9 and patent_place_id is NULL) or (type =9)),
	IPC VARCHAR(64)			 CHECK ((type != 9 and IPC is NULL) or (type = 9 and IPC IS NOT NULL)),


	ISSN CHAR(9)	 		 CHECK ((type != 1 and type !=2 and ISSN is NULL) or ((type = 1 or type = 2) and ISSN IS NOT NULL)),


	ISBN VARCHAR(20)		 CHECK ((type != 4 and type !=6 and ISBN is NULL) or ((type = 4 or type = 6) and ISBN IS NOT NULL)),
	
	
	CONSTRAINT pk_records PRIMARY KEY (id)
);


DROP INDEX IF EXISTS NA_idx;
CREATE INDEX NA_idx ON main_data.record(abstract_number); 

DROP INDEX IF EXISTS lang_idx;
CREATE INDEX lang_idx ON main_data.record(language_id);

DROP INDEX IF EXISTS udc_idx;
CREATE INDEX udc_idx ON main_data.record(udc);

DROP INDEX IF EXISTS contant_and_abstruct_idx;
CREATE INDEX content_and_abstruct_idx ON main_data.record using 
					GIST(to_tsvector('english', abstract),
					to_tsvector('russian', abstract),
					to_tsvector('english', content),
					to_tsvector('russian',content),
					to_tsvector('english', title),
					to_tsvector('russian',title));


DROP INDEX IF EXISTS create_time_idx;
CREATE INDEX create_time_idx ON main_data.record(create_time);

DROP INDEX IF EXISTS verification_time_idx;
CREATE INDEX verification_time_idx ON main_data.record(verification_time);

DROP INDEX IF EXISTS publication__year_idx;
CREATE INDEX publication_year_idx ON main_data.record(publication_year);

DROP INDEX IF EXISTS record_type_idx;
CREATE INDEX record_type_idx ON main_data.record(type);

DROP INDEX IF EXISTS record_source_idx;
CREATE INDEX record_source_idx ON main_data.record(source_id);


DROP INDEX IF EXISTS ipc_idx;
CREATE INDEX ipc_idx ON main_data.record(IPC);

DROP INDEX IF EXISTS deponire_number_idx;
CREATE INDEX deponire_number_idx ON main_data.record(deponire_number);

DROP INDEX IF EXISTS ISSN_idx;
CREATE INDEX ISSN_idx ON main_data.record(ISSN);

DROP INDEX IF EXISTS ISBN_idx;
CREATE INDEX ISBN_idx ON main_data.record(ISBN);




DROP TABLE IF EXISTS main_data.deponire_place;
CREATE TABLE main_data.deponire_place(
	id SERIAL,
	name TEXT UNIQUE NOT NULL,

	CONSTRAINT pk_deponire_place PRIMARY KEY (id)
);


DROP TABLE IF EXISTS main_data.patent_place;
CREATE TABLE main_data.patent_place(
	id SERIAL,
	name VARCHAR(128) UNIQUE NOT NULL,

	CONSTRAINT pk_patent_place PRIMARY KEY (id)
);



DROP TABLE IF EXISTS main_data.country;
CREATE TABLE main_data.country(
	id SERIAL,
	name VARCHAR(256) UNIQUE NOT NULL,
	code VARCHAR(2) UNIQUE NOT NULL,
	CONSTRAINT pk_country PRIMARY KEY (id)
);



DROP TABLE IF EXISTS main_data.record_has_referend;
CREATE TABLE main_data.record_has_referend(
	record_id integer NOT NULL,
	referend_id integer NOT NULL,
	responsibilities TEXT,
	CONSTRAINT pk_record_has_referend PRIMARY KEY (record_id, referend_id)
);

DROP INDEX IF EXISTS record_has_referend_referend_idx;
CREATE INDEX record_has_referend_referend_idx ON main_data.record_has_referend(referend_id);

DROP TABLE IF EXISTS main_data.record_has_resume_language;
CREATE TABLE main_data.record_has_resume_language(
	record_id integer NOT NULL,
	language_id integer NOT NULL,
	CONSTRAINT pk_record_has_resume PRIMARY KEY (record_id, language_id)
);

DROP INDEX IF EXISTS record_has_resume_language_language_idx;
CREATE INDEX record_has_resume_language_language_idx ON main_data.record_has_resume_language(language_id);

DROP TABLE IF EXISTS main_data.language;
CREATE TABLE main_data.language(
	id SERIAL,
	name VARCHAR(64)UNIQUE NOT NULL,
	CONSTRAINT pk_language PRIMARY KEY (id)
);

DROP TABLE IF EXISTS main_data.record_has_key_word;
CREATE TABLE main_data.record_has_key_word(
	record_id integer NOT NULL,
	key_word_id integer NOT NULL, 
	CONSTRAINT pk_record_has_key_word PRIMARY KEY (record_id, key_word_id)
);

DROP INDEX IF EXISTS record_has_key_word_key_word_idx;
CREATE INDEX record_has_key_word_key_word_idx ON main_data.record_has_key_word(key_word_id);

DROP TABLE IF EXISTS main_data.key_word;
CREATE TABLE main_data.key_word(
	id SERIAL,
	phrase TEXT UNIQUE NOT NULL,
	CONSTRAINT pk_key_word PRIMARY KEY (id)
);

DROP INDEX IF EXISTS key_word_idx;
CREATE INDEX key_word_idx ON main_data.key_word USING GIST(to_tsvector('english', phrase), to_tsvector('russian', phrase));


DROP TABLE IF EXISTS main_data.record_has_author;
CREATE  TABLE main_data.record_has_author(
	record_id integer NOT NULL,
	author_id integer NOT NULL,
	CONSTRAINT pk_record_has_author PRIMARY KEY (record_id, author_id)
);

DROP INDEX IF EXISTS record_has_author_author_idx;
CREATE INDEX record_has_author_author_idx ON main_data.record_has_author(author_id);

DROP TABLE IF EXISTS main_data.author;
CREATE TABLE main_data.author(
	id SERIAL,
	last_name VARCHAR(128) NOT NULL,
	first_name VARCHAR(128) DEFAULT '',
	otchestvo VARCHAR(128) DEFAULT '',
	full_name VARCHAR(256) NOT NULL,
	CONSTRAINT pk_author PRIMARY KEY (id),
	CONSTRAINT uk_author UNIQUE (first_name, last_name, otchestvo)
);

DROP INDEX IF EXISTS author_full_gin_idx;
CREATE INDEX author_full_gin_idx ON main_data.author USING GIN (full_name main_data.gin_trgm_ops);

DROP INDEX IF EXISTS author_full_gist_idx;
CREATE INDEX author_full_gist_idx ON main_data.author USING GIST (to_tsvector('russian', full_name), to_tsvector('english', full_name));


DROP TABLE IF EXISTS main_data.source;
CREATE TABLE main_data.source(
	id SERIAL,
	name TEXT NOT NULL,
	volume VARCHAR(255),
	issue VARCHAR(45),
	CONSTRAINT pk_source PRIMARY KEY (id),
	CONSTRAINT uk_source UNIQUE (name, volume, issue)
);

DROP INDEX IF EXISTS source_idx;
CREATE INDEX source_idx ON main_data.source USING GIST(to_tsvector('english', name), to_tsvector('russian', name));



DROP TABLE IF EXISTS main_data.info;
CREATE TABLE main_data.info(
	id SERIAL,
	pages VARCHAR(45),
	bic integer,
	mac integer,
	ilc integer,
	tbc integer,
	CONSTRAINT pk_info PRIMARY KEY(id)
);


DROP TABLE IF EXISTS main_data.record_has_rubric;
CREATE TABLE main_data.record_has_rubric(
	record_id integer,
	rubric_id integer,
	CONSTRAINT pk_record_har_rubric PRIMARY KEY (record_id, rubric_id)
);


DROP TABLE IF EXISTS main_data.rubric;
CREATE TABLE main_data.rubric(
	id SERIAL,
	name TEXT UNIQUE NOT NULL,
	CONSTRAINT pk_rubric PRIMARY KEY (id)
);

DROP INDEX IF EXISTS rubric_name_idx;
CREATE INDEX rubric_name_idx ON main_data.rubric USING GIN (name main_data.gin_trgm_ops);

DROP TABLE IF EXISTS main_data.rubric_has_subject;
CREATE TABLE main_data.rubric_has_subject(
	rubric_id integer,
	subject_id integer,
	CONSTRAINT pk_rubric_has_subject PRIMARY KEY (rubric_id, subject_id)
);

DROP INDEX IF EXISTS rubric_has_subject_subject_idx;
CREATE INDEX rubric_has_subject_subject_idx ON main_data.rubric_has_subject(subject_id);


DROP TABLE IF EXISTS main_data.subject;
CREATE TABLE main_data.subject(
	id SERIAL,
	code CHAR(2) UNIQUE NOT NULL,
	name VARCHAR(256) UNIQUE NOT NULL,
	CONSTRAINT pk_subject PRIMARY KEY (id)
);


DROP TABLE IF EXISTS users.user;
CREATE TABLE users.user(
	id SERIAL,
	name VARCHAR(256) NOT NULL,
	login VARCHAR(64) UNIQUE NOT NULL,
	password_hash VARCHAR(60) NOT NULL,
	email VARCHAR(256),
	comment TEXT,
	download_count INT DEFAULT 0,
	select_count INT DEFAULT 0,
	plan_id INT,
	
	CONSTRAINT pk_user PRIMARY KEY (id)
);

DROP INDEX IF EXISTS user_name_idx;
CREATE INDEX user_name_idx ON users.user(name);


DROP TABLE IF EXISTS users.bookmarks;
CREATE TABLE users.bookmarks(
	user_id INT,
	record_id INT,

	CONSTRAINT pk_bookmarks PRIMARY KEY (user_id, record_id)
);


DROP TABLE IF EXISTS users.user_has_history;
CREATE TABLE users.user_has_history(
	user_id INT,
	history_id INT,

	CONSTRAINT pk_user_has_hstory PRIMARY KEY (user_id, history_id)
);

DROP INDEX IF EXISTS user_has_history_history_idx;
CREATE INDEX user_has_history_history_idx ON users.user_has_history(history_id);

DROP TABLE IF EXISTS users.history;
CREATE TABLE users.history(
	id SERIAL,
	request TEXT,

	CONSTRAINT pk_usr_history PRIMARY KEY (id)
);

DROP TABLE IF EXISTS employees.referend;
CREATE TABLE employees.referend(
	privileges BIT(3) NOT NULL, -- 1 - UPDATE 2 - CREATE 4 - VERIFY
	
	CONSTRAINT pk_referend PRIMARY KEY (id),
	CONSTRAINT uk_login UNIQUE (login)
) INHERITS(users.user);

DROP INDEX IF EXISTS referend_name_idx;
CREATE INDEX referend_name_idx ON employees.referend(name);


DROP TABLE IF EXISTS employees.referend_has_history;
CREATE TABLE employees.referend_has_history(
	referend_id INT,
	history_id INT,

	CONSTRAINT pk_referend_has_history PRIMARY KEY (referend_id, history_id)
);

DROP INDEX IF EXISTS referend_has_history_history_idx;
CREATE INDEX referend_has_history_history_idx ON employees.referend_has_history(history_id);

DROP TABLE IF EXISTS employees.history;
CREATE TABLE employees.history(
	id SERIAL,
	descripion TEXT,
	occur_time TIMESTAMP DEFAULT NOW(),

	CONSTRAINT pk_ref_history PRIMARY KEY (id)
);


DROP TYPE IF EXISTS main_data.ACTION_TYPE;
CREATE TYPE main_data.ACTION_TYPE AS ENUM('UPDATE', 'SELECT', 'DELETE', 'LOGIN', 'NEW USER', 'DOWNLOAD');

DROP TABLE IF EXISTS service_info.log;
CREATE TABLE service_info.log(
	id SERIAL,
	kind main_data.ACTION_TYPE NOT NULL,
	occur_time TIMESTAMP DEFAULT NOW(),
	description TEXT,
	user_id INT,

	CONSTRAINT pk_log PRIMARY KEY (id)
);



ALTER TABLE main_data.record ADD CONSTRAINT fk_rec_info FOREIGN KEY (info_id) REFERENCES main_data.info(id);
ALTER TABLE main_data.record ADD CONSTRAINT fk_rec_lang FOREIGN KEY (language_id) REFERENCES main_data.language(id);
ALTER TABLE main_data.record ADD CONSTRAINT fk_rec_country FOREIGN KEY (country_id) REFERENCES main_data.country(id);
ALTER TABLE main_data.record ADD CONSTRAINT fk_rec_so FOREIGN KEY (source_id) REFERENCES main_data.source(id);

ALTER TABLE main_data.record ADD CONSTRAINT fk_patent_patent_place FOREIGN KEY (patent_place_id) REFERENCES main_data.patent_place(id);
ALTER TABLE main_data.record ADD CONSTRAINT fk_dep_work_dep_place FOREIGN KEY (deponire_place_id) REFERENCES main_data.deponire_place(id);

ALTER TABLE main_data.record_has_referend ADD CONSTRAINT fk_rec_has_ref_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_referend ADD CONSTRAINT fk_rec_has_ref_ref FOREIGN KEY (referend_id) REFERENCES employees.referend(id);

ALTER TABLE main_data.record_has_resume_language ADD CONSTRAINT fk_rec_has_res_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_resume_language ADD CONSTRAINT fk_rec_has_res_res FOREIGN KEY (language_id) REFERENCES main_data.language(id);

ALTER TABLE main_data.record_has_key_word ADD CONSTRAINT fk_rec_has_kw_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_key_word ADD CONSTRAINT fk_rec_has_kw_kw FOREIGN KEY (key_word_id) REFERENCES main_data.key_word(id);

ALTER TABLE main_data.record_has_author ADD CONSTRAINT fk_rec_has_au_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_author ADD CONSTRAINT fk_rec_has_au_au FOREIGN KEY (author_id) REFERENCES main_data.author(id);



ALTER TABLE main_data.record_has_rubric ADD CONSTRAINT fk_rec_has_rub_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_rubric ADD CONSTRAINT fk_rec_has_rub_rub FOREIGN KEY (rubric_id) REFERENCES main_data.rubric(id);

ALTER TABLE main_data.rubric_has_subject ADD CONSTRAINT fk_rub_has_sub_rub FOREIGN KEY (rubric_id) REFERENCES main_data.rubric(id);
ALTER TABLE main_data.rubric_has_subject ADD CONSTRAINT fk_rub_has_sub_sub FOREIGN KEY (subject_id) REFERENCES main_data.subject(id);


ALTER TABLE users.bookmarks ADD CONSTRAINT fk_bookmarks_usr FOREIGN KEY (user_id) REFERENCES users.user(id);
ALTER TABLE users.bookmarks ADD CONSTRAINT fk_bookmarks_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);

ALTER TABLE users.user_has_history ADD CONSTRAINT fk_usr_has_hist_usr FOREIGN KEY (user_id) REFERENCES users.user(id);
ALTER TABLE users.user_has_history ADD CONSTRAINT fk_usr_has_hist_hist FOREIGN KEY (history_id) REFERENCES users.history(id);

ALTER TABLE employees.referend_has_history ADD CONSTRAINT fk_ref_has_hist_ref FOREIGN KEY(referend_id) REFERENCES employees.referend(id);
ALTER TABLE employees.referend_has_history ADD CONSTRAINT fk_ref_has_hist_hist FOREIGN KEY(history_id) REFERENCES employees.history(id);


--todo
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA main_data TO "Server";



DROP TYPE IF EXISTS main_data.author_t;
CREATE TYPE main_data.author_t AS(
	first_name VARCHAR(256),
	last_name VARCHAR(256),
	otchestvo VARCHAR(256),
	full_name VARCHAR(256)
);


DROP TYPE IF EXISTS main_data.referend_t  CASCADE;
CREATE TYPE main_data.referend_t AS(
	login VARCHAR(256),
	responsibilities TEXT
);


CREATE OR REPLACE FUNCTION main_data.parse_author(sname TEXT)
RETURNS main_data.author_t
AS $$ 
	name = sname.decode('utf-8')
	parts = name.split();
	first_name = None
	last_name = ''
	otchestvo = ''
	full_name = None
	for i, part in enumerate(parts):
		if part.endswith('.'):
			part = part[:-1]
		if len(part) == 0:
			continue
		if i == 0:
			full_name = part
			last_name = part
		elif i == 1:
			first_name = part
			full_name += ' ' + part
		elif i==2:
			otchestvo = part
			full_name += ' ' + part
		else:
			full_name += ' ' + part
			otchestvo += ' ' + part
	#file = open(r"C:\Users\mkh19\Desktop\log.txt", 'w')
	#file.write(first_name + '\n' + last_name + '\n' + otchestvo + '\n' + full_name)
	#file.close()
	return (first_name, last_name, otchestvo, full_name)
$$ LANGUAGE plpythonu;


DROP FUNCTION IF EXISTS main_data.add_authors_for_record;
CREATE OR REPLACE FUNCTION main_data.add_authors_for_record(authors TEXT[], record_id INT) --todo
RETURNS VOID
AS $$
DECLARE
	author TEXT;
	au_id INT;
	au main_data.author_t;
BEGIN	
	
	FOREACH author IN ARRAY authors
	LOOP
		au := main_data.parse_author(author);
		INSERT INTO main_data.author(id, first_name, last_name, otchestvo, full_name)
		VALUES (DEFAULT, first_name(au), last_name(au), otchestvo(au), full_name(au))
		ON CONFLICT (first_name, last_name, otchestvo) DO UPDATE SET full_name = EXCLUDED.full_name
		RETURNING id INTO au_id;

		INSERT INTO main_data.record_has_author (author_id, record_id)
		VALUES (au_id, record_id);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS main_data.add_key_words_for_record;
CREATE OR REPLACE FUNCTION main_data.add_key_words_for_record(key_words TEXT[], record_id INT) --todo
RETURNS VOID
AS $$
DECLARE
	key_word TEXT;
	kw_id INT;
BEGIN
	FOREACH key_word IN ARRAY key_words
	LOOP
		INSERT INTO main_data.key_word(id, phrase)
		VALUES (DEFAULT, key_word)
		ON CONFLICT (phrase) DO UPDATE SET phrase = EXCLUDED.phrase
		RETURNING id INTO kw_id;

		INSERT INTO main_data.record_has_key_word (key_word_id, record_id)
		VALUES (kw_id, record_id);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS main_data.add_rubrics_for_record;
CREATE OR REPLACE FUNCTION main_data.add_rubrics_for_record(p_rubrics TEXT[], p_subject CHAR(2), p_record_id INT) --todo
RETURNS VOID
AS $$
DECLARE
	v_rubric TEXT;
	v_rub_id INT;
	v_sub_id INT;
BEGIN
	FOREACH v_rubric IN ARRAY p_rubrics
	LOOP
		INSERT INTO main_data.rubric(id, name)
		VALUES (DEFAULT, v_rubric)
		ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
		RETURNING id INTO v_rub_id;
		
		SELECT id INTO v_sub_id FROM main_data.subject WHERE code = p_subject;
		
		INSERT INTO main_data.rubric_has_subject(rubric_id, subject_id)
		VALUES (v_rub_id, v_sub_id)
		ON CONFLICT DO NOTHING;

		INSERT INTO main_data.record_has_rubric (rubric_id, record_id)
		VALUES (v_rub_id, p_record_id);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS main_data.add_resume_languages_for_record;
CREATE OR REPLACE FUNCTION main_data.add_resume_languages_for_record(languages TEXT[], record_id INT) --todo
RETURNS VOID
AS $$
DECLARE
	lang TEXT;
	lang_id INT;
BEGIN
	FOREACH lang IN ARRAY languages
	LOOP
		SELECT id INTO lang_id FROM main_data.language WHERE name=lang;
		INSERT INTO main_data.record_has_resume_language (language_id, record_id)
		VALUES (lang_id, record_id);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS main_data.add_referends_for_record;
CREATE OR REPLACE FUNCTION main_data.add_referends_for_record(referends main_data.referend_t[], record_id INT) --todo
RETURNS VOID
AS $$
DECLARE
	ref main_data.referend_t;
	ref_id INT;
BEGIN
	FOREACH ref IN ARRAY referends
	LOOP
		SELECT id INTO ref_id FROM employees.referend WHERE login=login(ref);
		INSERT INTO main_data.record_has_referend (referend_id, record_id, responsibilities)
		VALUES (ref_id, record_id, responsibilities(ref));
	END LOOP;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS main_data.make_record;
CREATE OR REPLACE FUNCTION main_data.make_record
(
	p_abstract TEXT			DEFAULT NULL,
	p_authors TEXT[] 		DEFAULT NULL,
	p_BIC INT 			DEFAULT NULL,
	p_country_code VARCHAR(256) 	DEFAULT NULL, 
	p_rubrics VARCHAR(256)[] 	DEFAULT NULL, 
	p_appeletion_date DATE 		DEFAULT NULL, 
	p_publication_date DATE 	DEFAULT NULL,
	p_prior_date DATE 		DEFAULT NULL,
	p_type INT 			DEFAULT NULL,
	p_ID_real VARCHAR(256) 		DEFAULT NULL,
	p_ILC INT 			DEFAULT NULL,
	p_IPC VARCHAR(128) 		DEFAULT NULL,
	p_issue VARCHAR(128) 		DEFAULT NULL,
	p_ISBN VARCHAR(128) 		DEFAULT NULL,
	p_ISSN VARCHAR(128) 		DEFAULT NULL,
	p_key_words TEXT[] 		DEFAULT NULL,
	p_language VARCHAR(128) 	DEFAULT NULL,
	p_MAC INT 			DEFAULT NULL,
	p_abstract_number TEXT 		DEFAULT NULL,
	p_deponire_date DATE		DEFAULT NULL,
	p_deponire_number VARCHAR(128) 	DEFAULT NULL,
	p_patent_number VARCHAR(128) 	DEFAULT NULL,
	p_pages VARCHAR(128) 		DEFAULT NULL,
	p_deponire_place TEXT 		DEFAULT NULL,
	p_publication_year INT 		DEFAULT NULL,
	p_generation_date DATE 		DEFAULT NULL,
	p_resume_language VARCHAR(256)[]DEFAULT NULL,
	p_source TEXT 			DEFAULT NULL,
	p_referends main_data.referend_t[]DEFAULT NULL,
	p_subject CHAR(2) 		DEFAULT NULL,
	p_TBC INT 			DEFAULT NULL,
	p_title TEXT 			DEFAULT NULL,
	p_udc VARCHAR(256) 		DEFAULT NULL,
	p_volume VARCHAR(128) 		DEFAULT NULL,
	p_patent_place TEXT 		DEFAULT NULL
)
RETURNS INT
AS $$
DECLARE 
	v_record_id INT;
	v_source_id INT;
	v_info_id INT;
	v_language_id INT;
	v_country_id INT;
	v_place_id INT;
BEGIN
	IF (	p_authors IS NULL OR 
		p_country_code IS NULL OR 
		p_publication_year IS NULL OR
		p_type IS NULL OR 
		p_ID_real IS NULL OR
		p_key_words IS NULL OR
		p_language IS NULL OR
		p_abstract_number IS NULL OR
		p_generation_date IS NULL OR
		p_referends IS NULL OR
		p_source IS NULL OR
		p_subject IS NULL OR
		p_title IS NULL)
	THEN
		RETURN 1;
	END IF;

	INSERT INTO main_data.source(id, name, volume, issue)
	VALUES(DEFAULT, p_source, p_volume, p_issue)
	ON CONFLICT (name, volume, issue) DO UPDATE SET name = EXCLUDED.name
	RETURNING id INTO v_source_id;

	INSERT INTO main_data.info(id, pages, bic, mac, tbc, ilc)
	VALUES (DEFAULT, p_pages, p_BIC, p_MAC, p_TBC, p_ILC)
	RETURNING id INTO v_info_id;

	SELECT id INTO v_language_id FROM main_data.language WHERE name = p_language;
	SELECT id INTO v_country_id FROM main_data.country WHERE code = p_country_code;

	
	IF p_type = 1 OR p_type = 2 THEN
		INSERT INTO main_data.record(id,      abstract,   country_id,   type,   ID_real,   language_id,   abstract_number,   publication_year,   generation_date,   title,   udc,   info_id,   ISSN,   source_id)
		VALUES 			    (DEFAULT, p_abstract, v_country_id, p_type, p_ID_real, v_language_id, p_abstract_number, p_publication_year, p_generation_date, p_title, p_udc, v_info_id, p_ISSN, v_source_id)
		RETURNING id INTO v_record_id;
		
	ELSIF p_type = 4 OR p_type = 6 THEN
		INSERT INTO main_data.record(id, 	      abstract,   country_id,   type,   ID_real,   language_id,   abstract_number,   publication_year,   generation_date,   title,   udc,   info_id,   source_id,
																								ISBN)
		VALUES 			    (DEFAULT, p_abstract, v_country_id, p_type, p_ID_real, v_language_id, p_abstract_number, p_publication_year, p_generation_date, p_title, p_udc, v_info_id, v_source_id,
																								p_ISBN)
		RETURNING id INTO v_record_id;
		
	ELSIF p_type = 3 OR p_type = 8 THEN
		INSERT INTO main_data.deponire_place (id, name)
		VALUES (DEFAULT, p_deponire_place)
		ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
		RETURNING id INTO v_place_id;
		
		INSERT INTO main_data.record(id,      abstract,   country_id,   type,   ID_real,   language_id,   abstract_number,   publication_year,   generation_date,   title,   udc,   info_id,   source_id,
																					deponire_date,   deponire_number,   deponire_place_id)
		VALUES 			    	   (DEFAULT, p_abstract, v_country_id, p_type, p_ID_real, v_language_id, p_abstract_number, p_publication_year, p_generation_date, p_title, p_udc, v_info_id, v_source_id,
																					p_deponire_date, p_deponire_number, v_place_id)
		RETURNING id INTO v_record_id;

	ELSIF p_type = 9 THEN
		INSERT INTO main_data.patent_place (id, name)
		VALUES (DEFAULT, p_patent_place)
		ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
		RETURNING id INTO v_place_id;


		INSERT INTO main_data.record(id,      abstract,   country_id,   type,   ID_real,   language_id,   abstract_number,   publication_year,   generation_date,   title,   udc,   info_id,   source_id,
																appeletion_date,   publication_date, priore_date,   patent_number,   patent_place_id, ipc)
		VALUES 			    (DEFAULT, p_abstract, v_country_id, p_type, p_ID_real, v_language_id, p_abstract_number, p_publication_year, p_generation_date, p_title, p_udc, v_info_id, v_source_id,
																p_appeletion_date, p_publication_date, p_prior_date, p_patent_number, v_place_id, p_ipc)
		RETURNING id INTO v_record_id;
	
	ELSE
		INSERT INTO main_data.record(id,        abstract,   country_id,   type,   ID_real,   language_id,   abstract_number,   publication_year,   generation_date,   title,   udc,   info_id,   source_id)
		VALUES 			    (DEFAULT,   p_abstract, v_country_id, p_type, p_ID_real, v_language_id, p_abstract_number, p_publication_year, p_generation_date, p_title, p_udc, v_info_id, v_source_id)
		RETURNING id INTO v_record_id;
		
	END IF;
	
	PERFORM main_data.add_authors_for_record(p_authors, v_record_id);
	PERFORM main_data.add_key_words_for_record(p_key_words, v_record_id);
	PERFORM main_data.add_rubrics_for_record(p_rubrics, p_subject, v_record_id);
	PERFORM main_data.add_resume_languages_for_record(p_resume_language, v_record_id);
	PERFORM main_data.add_referends_for_record(p_referends, v_record_id);
	
	RETURN v_record_id;
	END;
$$ LANGUAGE plpgsql;


DROP EXTENSION IF EXISTS pgcrypto;
CREATE EXTENSION pgcrypto WITH SCHEMA main_data;


CREATE OR REPLACE FUNCTION users.add_user() --todo
RETURNS TRIGGER
AS $$
BEGIN
	IF NEW.password_hash is NULL THEN
		RAISE EXCEPTION 'Password must be not NULL !!!!!!!!!!';
	END IF;
	NEW.password_hash := main_data.crypt(NEW.password_hash, main_data.gen_salt('bf'));
	RETURN NEW;
END;
$$LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS add_user_trigger ON users.user;
CREATE TRIGGER add_user_trigger BEFORE INSERT OR UPDATE ON users.user
	FOR EACH ROW EXECUTE PROCEDURE users.add_user();

DROP TRIGGER IF EXISTS add_referend_trigger ON employees.referend;
CREATE TRIGGER add_referend_trigger BEFORE INSERT OR UPDATE ON employees.referend
	FOR EACH ROW EXECUTE PROCEDURE users.add_user();


DROP FUNCTION IF EXISTS users.verify_user;
CREATE OR REPLACE FUNCTION users.verify_user(login TEXT, password TEXT, kind TEXT)
RETURNS BOOL
AS $$
DECLARE
	psw_hash VARCHAR(60);
BEGIN
	EXECUTE format($comand$ SELECT password_hash FROM %s WHERE login = '%s' $comand$, kind, login) INTO psw_hash;
	IF psw_hash = main_data.crypt(password, psw_hash) THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
	
END;
$$LANGUAGE plpgsql;



END TRANSACTION;