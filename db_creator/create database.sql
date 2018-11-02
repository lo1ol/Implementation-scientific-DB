ROLLBACK;
BEGIN TRANSACTION;

DROP LANGUAGE IF EXISTS plpythonu CASCADE;
CREATE LANGUAGE plpythonu;

DROP SCHEMA IF EXISTS public;

DROP SCHEMA IF EXISTS main_data CASCADE;
CREATE SCHEMA main_data
  AUTHORIZATION "Redactor";

GRANT USAGE ON SCHEMA main_data TO "Server";
GRANT USAGE ON SCHEMA main_data TO "ordinary_viewer";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "Server";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "ordinary_viewer";


DROP SCHEMA IF EXISTS employees CASCADE;
CREATE SCHEMA employees
  AUTHORIZATION "Redactor";

GRANT USAGE ON SCHEMA employees TO "Server";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA employees TO "Server";


DROP SCHEMA IF EXISTS users CASCADE;
CREATE SCHEMA users
  AUTHORIZATION "Redactor";

GRANT USAGE ON SCHEMA main_data TO "Server";
GRANT USAGE ON SCHEMA main_data TO "ordinary_viewer";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "Server";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "ordinary_viewer";


DROP SCHEMA IF EXISTS service_info CASCADE;
CREATE SCHEMA service_info
  AUTHORIZATION "Redactor";

GRANT USAGE ON SCHEMA main_data TO "Server";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA main_data TO "Server";

DROP TABLE IF EXISTS main_data.record;
CREATE TABLE main_data.record(
	id SERIAL ,
	abstruct_number VARCHAR[25] NOT NULL,
	udc VARCHAR[128],
	language_id INT NOT NULL,
	country_id INT NOT NULL,
	document_id CHAR[32] NOT NULL,
	title TEXT NOT NULL,
	annotation TEXT NOT NULL,
	ID_real VARCHAR(256),
	content TEXT,
	comment TEXT,
	info_id INTEGER,
	source_id INTEGER NOT NULL,
	generate_date DATE NOT NULL,
	publication_year DATE,
	type INT CHECK (type>0  AND type < 15),
	verified BOOLEAN DEFAULT FALSE,
	create_time TIMESTAMP DEFAULT NOW(),
	verification_time timestamp DEFAULT NULL,
	
	CONSTRAINT pk_records PRIMARY KEY (id)
);


DROP INDEX IF EXISTS NA_idx;
CREATE INDEX NA_idx ON main_data.record(abstruct_number); 

DROP INDEX IF EXISTS lang_idx;
CREATE INDEX lang_idx ON main_data.record(language_id);

DROP INDEX IF EXISTS udc_idx;
CREATE INDEX udc_idx ON main_data.record(udc);

DROP INDEX IF EXISTS contant_and_annotation_idx;
CREATE INDEX content_and_annotation_idx ON main_data.record using 
					GIST((to_tsvector('english', annotation)||
					to_tsvector('russian', annotation)||
					to_tsvector('english', content)||
					to_tsvector('russian',content)||
					to_tsvector('english', title)||
					to_tsvector('russian',title)));

DROP INDEX IF EXISTS doc_id_idx;
CREATE INDEX doc_id_idx ON main_data.record(document_id);

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


DROP TABLE IF EXISTS main_data.deponire_work;
CREATE TABLE main_data.deponire_work(
	deponire_number VARCHAR(64) UNIQUE NOT NULL,
	deponire_date DATE NOT NULL,
	deponire_place_id INT NOT NULL
) INHERITS (main_data.record);

DROP TABLE IF EXISTS main_data.deponire_place;
CREATE TABLE main_data.deponire_place(
	id SERIAL,
	name TEXT UNIQUE NOT NULL,

	CONSTRAINT pk_deponire_place PRIMARY KEY (id)
);



DROP TABLE IF EXISTS main_data.patent;
CREATE TABLE main_data.patent(
	patent_number VARCHAR(64) UNIQUE NOT NULL,
	appilation_date DATE NOT NULL,
	priore_date DATE,
	publication_date DATE,
	patent_place_id INT,
	IPC VARCHAR(64)
) INHERITS (main_data.record);



DROP INDEX IF EXISTS ipc_idx;
CREATE INDEX ipc_idx ON main_data.patent(IPC);


DROP TABLE IF EXISTS main_data.patent_place;
CREATE TABLE main_data.patent_place(
	id SERIAL,
	name VARCHAR(128) UNIQUE NOT NULL,

	CONSTRAINT pk_patent_place PRIMARY KEY (id)
);

DROP TABLE IF EXISTS main_data.jornal;
CREATE TABLE main_data.jornal(
	ISSN CHAR(9) UNIQUE NOT NULL
) INHERITS (main_data.record);



DROP TABLE IF EXISTS main_data.book;
CREATE TABLE main_data.book(
	ISBN VARCHAR(20) UNIQUE NOT NULL
) INHERITS (main_data.record);



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
	resposibilities TEXT,
	CONSTRAINT pk_record_has_referend PRIMARY KEY (record_id, referend_id)
);

DROP TABLE IF EXISTS main_data.record_has_resume_language;
CREATE TABLE main_data.record_has_resume_language(
	record_id integer NOT NULL,
	language_id integer NOT NULL,
	CONSTRAINT pk_record_has_resume PRIMARY KEY (record_id, language_id)
);

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

DROP TABLE IF EXISTS main_data.key_word;
CREATE TABLE main_data.key_word(
	id SERIAL NOT NULL,
	phrase TEXT UNIQUE NOT NULL,
	CONSTRAINT pk_key_word PRIMARY KEY (id)
);

DROP INDEX IF EXISTS key_word_idx;
CREATE INDEX key_word_idx ON main_data.key_word USING GIST((to_tsvector('english', phrase) || to_tsvector('russian', phrase)));


DROP TABLE IF EXISTS main_data.record_has_author;
CREATE  TABLE main_data.record_has_author(
	record_id integer NOT NULL,
	author_id integer NOT NULL,
	CONSTRAINT pk_record_has_author PRIMARY KEY (record_id, author_id)
);


DROP TABLE IF EXISTS main_data.author;
CREATE TABLE main_data.author(
	id SERIAL,
	last_name VARCHAR(128) NOT NULL,
	first_name VARCHAR(128) NOT NULL,
	otchestvo VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
	short_name VARCHAR(256) NOT NULL, -- for Alexandr Pavlovich Marks is Marks A.P.
	CONSTRAINT pk_author PRIMARY KEY (id),
	CONSTRAINT uk_author UNIQUE (first_name, last_name, otchestvo)
);

DROP INDEX IF EXISTS author_idx;
CREATE INDEX author_idx ON main_data.author USING GIST((to_tsvector('english', first_name) || to_tsvector('russian', first_name) || 
							to_tsvector('english', last_name) || to_tsvector('russian', last_name) || 
							to_tsvector('english', otchestvo) || to_tsvector('russian', otchestvo) ));


DROP INDEX IF EXISTS author_short_idx;
CREATE INDEX author_short_idx ON main_data.author(short_name);


DROP TABLE IF EXISTS main_data.source;
CREATE TABLE main_data.source(
	id SERIAL NOT NULL,
	name TEXT NOT NULL,
	volume VARCHAR(255),
	issue VARCHAR(45),
	CONSTRAINT pk_source PRIMARY KEY (id),
	CONSTRAINT uk_source UNIQUE (name, volume, issue)
);

DROP INDEX IF EXISTS source_idx;
CREATE INDEX source_idx ON main_data.source USING GIST((to_tsvector('english', name) || to_tsvector('russian', name)));



DROP TABLE IF EXISTS main_data.info;
CREATE TABLE main_data.info(
	id SERIAL,
	pages VARCHAR(45),
	bibl_cnt integer,
	map_cnt integer,
	image_cnt integer,
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



DROP TABLE IF EXISTS main_data.rubric_has_subject;
CREATE TABLE main_data.rubric_has_subject(
	rubric_id integer,
	subject_id integer,
	CONSTRAINT pk_rubric_has_subject PRIMARY KEY (rubric_id, subject_id)
);


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



DROP TABLE IF EXISTS employees.history;
CREATE TABLE employees.history(
	id SERIAL,
	descripion TEXT,
	occur_time TIMESTAMP DEFAULT NOW(),

	CONSTRAINT pk_ref_history PRIMARY KEY (id)
);


DROP TYPE IF EXISTS ACTION_TYPE;
CREATE TYPE ACTION_TYPE AS ENUM('UPDATE', 'SELECT', 'DELETE', 'LOGIN', 'NEW USER', 'DOWNLOAD');

DROP TABLE IF EXISTS service_info.log;
CREATE TABLE service_info.log(
	id SERIAL,
	kind ACTION_TYPE NOT NULL,
	occur_time TIMESTAMP DEFAULT NOW(),
	description TEXT,
	user_id INT,

	CONSTRAINT pk_log PRIMARY KEY (id)
);



ALTER TABLE main_data.record ADD CONSTRAINT fk_rec_info FOREIGN KEY (info_id) REFERENCES main_data.info(id);
ALTER TABLE main_data.record ADD CONSTRAINT fk_rec_lang FOREIGN KEY (language_id) REFERENCES main_data.language(id);
ALTER TABLE main_data.record ADD CONSTRAINT fk_rec_country FOREIGN KEY (country_id) REFERENCES main_data.country(id);
ALTER TABLE main_data.record ADD CONSTRAINT fk_rec_so FOREIGN KEY (source_id) REFERENCES main_data.source(id);

ALTER TABLE main_data.patent ADD CONSTRAINT fk_patent_patent_place FOREIGN KEY (patent_place_id) REFERENCES main_data.patent_place(id);
ALTER TABLE main_data.deponire_work ADD CONSTRAINT fk_dep_work_dep_place FOREIGN KEY (deponire_place_id) REFERENCES main_data.deponire_place(id);

ALTER TABLE main_data.record_has_referend ADD CONSTRAINT fk_rec_has_ref_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_referend ADD CONSTRAINT fk_rec_has_ref_ref FOREIGN KEY (referend_id) REFERENCES employees.referend(id);

ALTER TABLE main_data.record_has_resume_language ADD CONSTRAINT fk_rec_has_res_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_resume_language ADD CONSTRAINT fk_rec_has_res_res FOREIGN KEY (language_id) REFERENCES main_data.language(id);

ALTER TABLE main_data.record_has_key_word ADD CONSTRAINT fk_rec_has_kw_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_key_word ADD CONSTRAINT fk_rec_has_kw_kw FOREIGN KEY (key_word_id) REFERENCES main_data.key_word(id);

ALTER TABLE main_data.record_has_author ADD CONSTRAINT fk_rec_has_au_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_author ADD CONSTRAINT fk_rec_has_au_kw FOREIGN KEY (author_id) REFERENCES main_data.author(id);



ALTER TABLE main_data.record_has_rubric ADD CONSTRAINT fk_rec_has_rub_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);
ALTER TABLE main_data.record_has_rubric ADD CONSTRAINT fk_rec_has_rub_kw FOREIGN KEY (rubric_id) REFERENCES main_data.rubric(id);

ALTER TABLE main_data.rubric_has_subject ADD CONSTRAINT fk_rub_has_sub_rub FOREIGN KEY (rubric_id) REFERENCES main_data.rubric(id);
ALTER TABLE main_data.rubric_has_subject ADD CONSTRAINT fk_rub_has_sub_sub FOREIGN KEY (subject_id) REFERENCES main_data.subject(id);


ALTER TABLE users.bookmarks ADD CONSTRAINT fk_bookmarks_usr FOREIGN KEY (user_id) REFERENCES users.user(id);
ALTER TABLE users.bookmarks ADD CONSTRAINT fk_bookmarks_rec FOREIGN KEY (record_id) REFERENCES main_data.record(id);

ALTER TABLE users.user_has_history ADD CONSTRAINT fk_usr_has_hist_usr FOREIGN KEY (user_id) REFERENCES users.user(id);
ALTER TABLE users.user_has_history ADD CONSTRAINT fk_usr_has_hist FOREIGN KEY (history_id) REFERENCES users.history(id);

ALTER TABLE employees.referend_has_history ADD CONSTRAINT fk_ref_has_hist_ref FOREIGN KEY(referend_id) REFERENCES employees.referend(id);
ALTER TABLE employees.referend_has_history ADD CONSTRAINT fk_ref_has_hist_jist FOREIGN KEY(history_id) REFERENCES employees.history(id);

DROP TYPE IF EXISTS author_t;
CREATE TYPE author_t AS(
	first_name VARCHAR(256),
	last_name VARCHAR(256),
	otchestvo VARCHAR(256),
	short_name VARCHAR(256)
);


DROP TYPE IF EXISTS referend_t  CASCADE;
CREATE TYPE referend_t AS(
	login VARCHAR(256),
	responsibilities TEXT,
	priveleges BIT(3)
);




CREATE OR REPLACE FUNCTION parse_author(name VARCHAR(256))
RETURNS author_t
AS $$ 
	parts = name.split();
	first_name = None
	last_name = None
	otchestvo = 'UNKNOWN'
	short_name = None
	for i, part in enumerate(parts):
		if i == 0:
			short_name = part
			last_name = part
		elif i == 1:
			if part.endswith('.'):
				part = part[:-1]
			first_name = part
			short_name += ' ' + part[0] + '.'
		elif i==2:
			if part.endswith('.'):
				part = part[:-1]
			otchestvo = part
			short_name += ' ' + part[0] + '.'
		else:
			otchestvo += ' ' + part
	return (first_name, last_name, otchestvo, short_name)
$$ LANGUAGE plpythonu;


DROP FUNCTION IF EXISTS add_authors_for_record;
CREATE OR REPLACE FUNCTION add_authors_for_record(authors TEXT[], record_id INT) --todo
RETURNS VOID
AS $$
DECLARE
	author TEXT;
	au_id INT;
	au author_t;
BEGIN
	FOREACH author IN ARRAY authors
	LOOP
		au := parse_author(author);
		INSERT INTO main_data.author(id, first_name, last_name, otchestvo, short_name)
		VALUES (DEFAULT, first_name(au), last_name(au), otchestvo(au), short_name(au))
		ON CONFLICT DO NOTHING
		RETURNING id INTO au_id;

		INSERT INTO main_data.record_has_author (au_id, record_id)
		VALUES (au_id, record_id);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS add_key_words_for_record;
CREATE OR REPLACE FUNCTION add_key_words_for_record(key_words TEXT[], record_id INT) --todo
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
		ON CONFLICT DO NOTHING
		RETURNING id INTO kw_id;

		INSERT INTO main_data.record_has_key_word (key_word_id, record_id)
		VALUES (kw_id, record_id);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS add_rubrics_for_record;
CREATE OR REPLACE FUNCTION add_rubrics_for_record(rubrics TEXT[], subject CHAR(2), record_id INT) --todo
RETURNS VOID
AS $$
DECLARE
	rubric TEXT;
	rub_id INT;
	sub_id INT;
BEGIN
	FOREACH rubric IN ARRAY rubrics
	LOOP
		INSERT INTO main_data.rubrics(id, name)
		VALUES (DEFAULT, rubric)
		RETURNING id INTO rub_id;

		SELECT id INTO sub_id FROM main_data.subject WHERE name = subject;

		INSERT INTO rubric_has_subject(rubric_id, subject_id)
		VALUES (rub_id, sub_id)
		ON CONFLICT DO NOTHING;

		INSERT INTO main_data.record_has_rubric (rubric_id, record_id)
		VALUES (rub_id, record_id);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS add_resume_languages_for_record;
CREATE OR REPLACE FUNCTION add_resume_languages_for_record(languages TEXT[], record INT) --todo
RETURNS VOID
AS $$
DECLARE
	lang TEXT;
	lang_id INT;
BEGIN
	FOREACH lang IN ARRAY languages
	LOOP
		SELECT id INTO lang_id FROM man_data.language WHERE language=lang;
		INSERT INTO main_data.record_has_resume_languege (lang_id, record_id)
		VALUES (lang_id, record_id);
	END LOOP;
END;
$$ LANGUAGE plpgsql;




DROP FUNCTION IF EXISTS make_record;
CREATE OR REPLACE FUNCTION make_record
(
	abstruct TEXT			DEFAULT NULL,
	authors TEXT[] 			DEFAULT NULL,
	BIC INT 			DEFAULT NULL,
	country_code VARCHAR(256) 	DEFAULT NULL, 
	rubrics VARCHAR(256)[] 		DEFAULT NULL, 
	appeletion_date DATE 		DEFAULT NULL, 
	publication_date DATE 		DEFAULT NULL,
	prior_date DATE 		DEFAULT NULL,
	type INT 			DEFAULT NULL,
	ID_real VARCHAR(256) 		DEFAULT NULL,
	ILC INT 			DEFAULT NULL,
	IPC VARCHAR(128) 		DEFAULT NULL,
	issue VARCHAR(128) 		DEFAULT NULL,
	ISBN VARCHAR(128) 		DEFAULT NULL,
	ISSN VARCHAR(128) 		DEFAULT NULL,
	key_words TEXT[] 		DEFAULT NULL,
	language VARCHAR(128) 		DEFAULT NULL,
	MAC INT 			DEFAULT NULL,
	abstruct_number TEXT 		DEFAULT NULL,
	deponire_date DATE		DEFAULT NULL,
	deponire_number VARCHAR(128) 	DEFAULT NULL,
	patent_number VARCHAR(128) 	DEFAULT NULL,
	pages VARCHAR(128) 		DEFAULT NULL,
	deponire_place TEXT 		DEFAULT NULL,
	publication_year INT 		DEFAULT NULL,
	generation_date DATE 		DEFAULT NULL,
	resume_language VARCHAR(256)[] 	DEFAULT NULL,
	source TEXT 			DEFAULT NULL,
	referends referend_t[]		DEFAULT NULL,
	subject CHAR(2) 		DEFAULT NULL,
	TBC INT 			DEFAULT NULL,
	title TEXT 			DEFAULT NULL,
	udc VARCHAR(256) 		DEFAULT NULL,
	volume VARCHAR(128) 		DEFAULT NULL,
	patent_place TEXT 		DEFAULT NULL
)
RETURNS INT
AS $$
DECLARE 
	record_id INT;
	source_id INT;
	info_id INT;
	language_id INT;
	country_id INT;
	place_id INT;
BEGIN
	IF (	authors IS NULL OR 
		country_code IS NULL OR 
		publication_year IS NULL OR
		type IS NULL OR 
		ID_real IS NULL OR
		key_words IS NULL OR
		language IS NULL OR
		abstruct_number IS NULL OR
		generation_date IS NULL OR
		referends IS NULL OR
		source IS NULL OR
		subject IS NULL OR
		title IS NULL)
	THEN
		RETURN 1;
	END IF;

	INSERT INTO main_data.source(id, name, volume, issue)
	VALUES(DEFAULT, source, volume, issue)
	ON CONFLICT DO NOTHING	--todo
	RETURNING id INTO source_id;

	INSERT INTO info(id, pages, BIC, MAC, TBC, ILC)
	VALUES (DEFAULT, pages, BIC, MAC, TBC, ILC)
	RETURNING id INTO info_id;

	SELECT id INTO language_id FROM main_data.language WHERE name = language;
	SELECT id INTO country_id FROM main_data.country WHERE code = country_code;

	
	IF type = 1 OR type = 2 THEN
		INSERT INTO main_data.jornal(id, 	abstruct, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc, ISSN)
		VALUES 			    (DEFAULT,   abstract, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc, ISSN)
		RETURNING id INTO record_id;
		
	ELSIF type = 4 OR type = 6 THEN
		INSERT INTO main_data.book(id, 		abstruct, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc, ISBN)
		VALUES 			    (DEFAULT,   abstract, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc, ISBN)
		RETURNING id INTO record_id;
		
	ELSIF type = 3 OR type = 8 THEN
		INSERT INTO main_data.deponire_place (id, name)
		VALUES (DEFAULT, deponire_place)
		ON CONFLICT DO NOTHING
		RETURNING id INTO place_id;
		
		INSERT INTO main_data.deponire_work(id, 	abstruct, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc, deponire_date, deponire_number, deponire_place_id)
		VALUES 			    	   (DEFAULT,   	abstract, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc, deponire_date, deponire_number, place_id)
		RETURNING id INTO record_id;

	ELSIF type = 9 THEN
		INSERT INTO main_data.patent_place (id, name)
		VALUES (DEFAULT, patent_lace)
		ON CONFLICT DO NOTHING
		RETURNING id INTO place_id;


		INSERT INTO main_data.patent(id, 	abstruct, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc, appeletion_date, publication_date, prioritet_date, patent_number, patent_place_id)
		VALUES 			    (DEFAULT,   abstract, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc, appeletion_date, publication_date, prioritet_date, patent_number, place_id)
		RETURNING id INTO record_id;
	
	ELSE
		INSERT INTO main_data.record(id, 	abstruct, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc) -- insert info in referend relation
		VALUES 			    (DEFAULT,   abstract, country_id, type, ID_real, language_id, abstruct_number, publication_year, generation_date, title, udc)
		RETURNING id INTO record_id;
		
	END IF;

	SELECT add_authtors_for_record(authors, record_id);
	SELECT add_key_words_for_record(key_words, record_id);
	SELECT add_rubrics_for_record(rubrics, subject, record_id);
	SELECT add_resume_languages_for_record(resume_language, record_id);

	
	RETURN 0;
	END;
$$ LANGUAGE plpgsql;


DROP EXTENSION IF EXISTS pgcrypto;
CREATE EXTENSION pgcrypto;

CREATE OR REPLACE FUNCTION add_user() --todo
RETURNS TRIGGER
AS $$
BEGIN
	IF NEW.password_hash is NULL THEN
		RAISE EXCEPTION 'Password must be not NULL !!!!!!!!!!';
	END IF;
	NEW.password_hash := crypt(NEW.password_hash, gen_salt('bf'));
	RETURN NEW;
END;
$$LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS add_user_trigger ON users.user;
CREATE TRIGGER add_user_trigger BEFORE INSERT OR UPDATE ON users.user
	FOR EACH ROW EXECUTE PROCEDURE add_user();

DROP TRIGGER IF EXISTS add_referend_trigger ON employees.referend;
CREATE TRIGGER add_referend_trigger BEFORE INSERT OR UPDATE ON employees.referend
	FOR EACH ROW EXECUTE PROCEDURE add_user();


DROP FUNCTION IF EXISTS verify_user;
CREATE OR REPLACE FUNCTION verify_user(login TEXT, password TEXT, kind TEXT)
RETURNS BOOL
AS $$
DECLARE
	psw_hash VARCHAR(60);
BEGIN
	EXECUTE format($comand$ SELECT password_hash FROM %s WHERE login = '%s' $comand$, kind, login) INTO psw_hash;
	IF psw_hash = crypt(password, psw_hash) THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
	
END;
$$LANGUAGE plpgsql;


END TRANSACTION;