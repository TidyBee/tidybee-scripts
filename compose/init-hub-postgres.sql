CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE TABLE IF NOT EXISTS files (
                                     id SERIAL PRIMARY KEY UNIQUE,
                                     name TEXT NOT NULL UNIQUE,
                                     size int NOT NULL,
                                     file_hash TEXT NOT NULL,
                                     last_modified TIMESTAMP NOT NULL,
                                     misnamed_score CHAR(1) NOT NULL,
                                     perished_score CHAR(1) NOT NULL,
                                     duplicated_score CHAR(1) NOT NULL,
                                     global_score CHAR(1) NOT NULL,
                                     provenance TEXT NOT NULL DEFAULT 'agent'
);

CREATE TABLE IF NOT EXISTS duplicate_associative_table (
                                                           id SERIAL PRIMARY KEY,
                                                           original_file_id INTEGER NOT NULL,
                                                           duplicate_file_id INTEGER NOT NULL,
                                                           CONSTRAINT fk_original_file
                                                               FOREIGN KEY (original_file_id)
                                                                   REFERENCES files (id),
                                                           CONSTRAINT fk_duplicate_file
                                                               FOREIGN KEY (duplicate_file_id)
                                                                   REFERENCES files (id)
);

CREATE TABLE rules (
                       id SERIAL PRIMARY KEY,
                       name TEXT NOT NULL,
                       description TEXT,
                       weight FLOAT NOT NULL,
                       rules_config JSON NOT NULL
);

CREATE TABLE IF NOT EXISTS backup_files (
                                            id SERIAL PRIMARY KEY UNIQUE,
                                            name TEXT NOT NULL UNIQUE,
                                            size int NOT NULL,
                                            file_hash TEXT NOT NULL,
                                            last_modified TIMESTAMP NOT NULL,
                                            misnamed_score CHAR(1) NOT NULL,
                                            perished_score CHAR(1) NOT NULL,
                                            duplicated_score CHAR(1) NOT NULL,
                                            global_score CHAR(1) NOT NULL,
                                            backup_date TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS backup_duplicate_associative_table (
                                                                  id SERIAL PRIMARY KEY,
                                                                  original_file_id INTEGER NOT NULL,
                                                                  duplicate_file_id INTEGER NOT NULL,
                                                                  backup_date TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS backup_average_scores (
                                                     id SERIAL PRIMARY KEY,
                                                     backup_date TIMESTAMP NOT NULL,
                                                     avg_misnamed_score FLOAT NOT NULL,
                                                     avg_perished_score FLOAT NOT NULL,
                                                     avg_duplicated_score FLOAT NOT NULL,
                                                     avg_global_score FLOAT NOT NULL,
                                                     total_files INT NOT NULL
);

INSERT INTO rules (name, description, weight, rules_config)
VALUES
    (
        'misnamed',
        'Le nommage des fichiers est une étape essentielle pour garantir une gestion efficace et une collaboration fluide dans les entreprises. Des fichiers bien nommés facilitent leur identification, leur classement, et leur partage. Voici pourquoi les règles ci-dessous sont cruciales',
        3.0,
        '{
          "type": "misnamed",
          "regex_rules": [
            {
              "name": "Date",
              "description": "Le nom fichier doit obligatoirement contenir une date avec le format ..._aaaa, ex facture_bill_robert_2024.pdf.\\n Ajouter une date permet de suivre facilement l’évolution des documents et d’identifier rapidement la version la plus récente",
              "regex": "_[0-9]{4}\\.",
              "weight": 3
            },
            {
              "name": "Séparateur",
              "description": "Le nom de fichier doit contenir au moins trois séparateurs underscore entre chaque mot, ex : facture_bill_robert_2024.pdf.\n Les espaces ou séparateurs variés (comme _, -, etc.) peuvent entraîner des confusions ou des incompatibilités dans certains systèmes. Optez pour un seul type de séparateur et appliquez-le systématiquement.",
              "regex": "^[^_]*(_[^_]*){2}$",
              "weight": 1.8
            },
            {
              "name": "Deux mots",
              "description": "Le nom de fichier doit contenir au moins deux mots explicites pour définir au mieux le fichier, ex: facture_robert_2024.pdf.\n Un nom de fichier trop court manque souvent de clarté, alors q''un fichier trop long peut très rapidement alourdir l''espace de stockage. Ajouter des mots descriptifs facilite la compréhension de son contenu sans devoir l''ouvrir.",
              "regex": "^\\w+_\\w+_.+$",
              "weight": 3
            },
            {
              "name": "Extension",
              "description": "Le nom de fichier doit obligatoirement contenir une extension comme par exemple .pdf. \n Les extensions (.pdf, .docx, etc.) sont indispensables pour associer un fichier à son logiciel de lecture. Cela garantit également une compatibilité entre systèmes et utilisateurs.",
              "regex": "\\.\\w+$",
              "weight": 2.5
            },
            {
              "name": "Caractères invisibles",
              "description": "Les espaces et autres caractères invisibles sont prohibés. \n Les caractères invisibles (tabulations, espaces multiples) peuvent provoquer des erreurs lors du traitement automatique des fichiers ou créer des doublons difficiles à identifier.",
              "regex": "^\\S+$",
              "weight": 2
            },
            {
              "name": "Caractères spéciaux",
              "description": "Les caractères spéciaux sont prohibés. \n Les caractères spéciaux (@, #, &, etc.) peuvent entraîner des problèmes de compatibilité, notamment lors de transferts de fichiers sur des systèmes différents ou lors d’une intégration dans des bases de données.",
              "regex": "^[A-Za-z0-9._]*$",
              "weight": 2
            }
          ]
        }'
    );


INSERT INTO rules (name, description, weight, rules_config)
VALUES
    ('perished',
     'Un fichier non modifié depuis un temps donné est considéré comme périmé',
     2.0,
     '{
       "type": "perished",
       "expiration_days": 300
     }'
    );

INSERT INTO rules (name, description, weight, rules_config)
VALUES
    ('duplicated',
     'Le fichier est considéré comme dupliqué si il apparait trop de fois sur le système',
     1.5,
     '{
       "type": "duplicated",
       "max_occurrences": 3
     }'
    );

ALTER TABLE duplicate_associative_table
    ADD CONSTRAINT unique_file_pair UNIQUE (original_file_id, duplicate_file_id);

ALTER TABLE duplicate_associative_table
    ADD CONSTRAINT no_self_duplicate CHECK (original_file_id != duplicate_file_id);

CREATE OR REPLACE PROCEDURE detect_and_store_duplicates()
    LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO duplicate_associative_table (original_file_id, duplicate_file_id)
    SELECT f1.id, f2.id
    FROM files f1
             JOIN files f2 ON f1.file_hash = f2.file_hash AND f1.id < f2.id
    ON CONFLICT DO NOTHING;
END;
$$;


CREATE OR REPLACE PROCEDURE calculate_perished_score(file_id INT)
    LANGUAGE plpgsql AS $$
DECLARE
    calculated_score CHAR(1);
    res INTERVAL;
    day_duration_limit INT;
    file_path TEXT;
    rule_config JSONB;
    file_name TEXT;
BEGIN
    SELECT name INTO file_name FROM files WHERE id = file_id;
    SELECT rules_config INTO rule_config
    FROM rules
    WHERE name = 'perished';

    BEGIN
        day_duration_limit := (rule_config->>'expiration_days')::INT;
    EXCEPTION WHEN others THEN
        RAISE WARNING 'Impossible to load day_duration_limit, default to 300 days (10 months)';
        day_duration_limit := 300;
    END;

    SELECT NOW() - last_modified, name INTO res, file_path
    FROM files
    WHERE id = file_id;

    IF res < INTERVAL '1 day' * day_duration_limit THEN
        calculated_score := 'A';
    ELSIF res <= INTERVAL '1 day' * (day_duration_limit + day_duration_limit / 4) THEN
        calculated_score := 'B';
    ELSIF res <= INTERVAL '1 day' * (day_duration_limit + day_duration_limit / 3) THEN
        calculated_score := 'C';
    ELSIF res <= INTERVAL '1 day' * (day_duration_limit + day_duration_limit / 2) THEN
        calculated_score := 'D';
    ELSIF res <= INTERVAL '1 day' * (day_duration_limit * 2) THEN
        calculated_score := 'E';
    ELSE
        calculated_score := 'F';
    END IF;

    RAISE NOTICE 'File "%" with id [%] has perished score: %', file_name, file_id, calculated_score;

    UPDATE files
    SET perished_score = calculated_score
    WHERE id = file_id;
END;
$$;


CREATE OR REPLACE FUNCTION assign_duplicated_score(occurrences INT)
    RETURNS CHAR(1) AS $$
BEGIN
    RETURN CASE
               WHEN occurrences < 1 THEN 'A'
               WHEN occurrences <= 1 THEN 'B'
               WHEN occurrences <= 3 THEN 'C'
               WHEN occurrences <= 5 THEN 'D'
               WHEN occurrences <= 8 THEN 'E'
               ELSE 'F'
        END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE calculate_duplicated_score(file_id INT)
    LANGUAGE plpgsql AS $$
DECLARE
    occurrence_count INT;
    new_score CHAR(1);
    max_occurrences INT;
    rule_config JSONB;
    file_name TEXT;
BEGIN
    SELECT name INTO file_name FROM files WHERE id = file_id;
    SELECT rules_config INTO rule_config
    FROM rules
    WHERE name = 'duplicated';

    BEGIN
        max_occurrences := (rule_config->>'max_occurrences')::INT;
    EXCEPTION WHEN others THEN
        RAISE WARNING 'Impossible to load max_occurrences, default to 3';
        max_occurrences := 3;
    END;

    SELECT COUNT(*) INTO occurrence_count
    FROM files
    WHERE file_hash = (SELECT file_hash FROM files WHERE id = file_id)
      AND id != file_id;

    new_score := assign_duplicated_score(occurrence_count);

    UPDATE files
    SET duplicated_score = new_score
    WHERE id = file_id;

    RAISE NOTICE 'File : "%" with id [%] has duplicated score: % with % occurrences', file_name, file_id, new_score, occurrence_count;
END;
$$;


CREATE OR REPLACE FUNCTION assign_misnamed_score(score FLOAT)
    RETURNS TEXT AS $$
BEGIN
    IF score >= 0.9 THEN
        RETURN 'A';
    ELSIF score >= 0.8 THEN
        RETURN 'B';
    ELSIF score >= 0.7 THEN
        RETURN 'C';
    ELSIF score >= 0.6 THEN
        RETURN 'D';
    ELSIF score >= 0.5 THEN
        RETURN 'E';
    ELSE
        RETURN 'F';
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE calculate_misnamed_score(file_id INT)
    LANGUAGE plpgsql AS $$
DECLARE
    res FLOAT := 0;
    total_rule_count INT;
    tidy_score_decimal FLOAT;
    computed_misnamed_score TEXT;
    rule_record JSONB;
    rule_weight FLOAT;
    rule_regex TEXT;
    rule_name TEXT;
    file_name TEXT;
    sigmoid_value FLOAT;
BEGIN
    SELECT regexp_replace(name, '.*/', '') INTO file_name FROM files WHERE id = file_id;

    SELECT rules_config INTO rule_record FROM rules WHERE name = 'misnamed';

    total_rule_count := jsonb_array_length(rule_record->'regex_rules');

    RAISE INFO 'Applying MISNAMED Rules...';

    FOR i IN 0..(total_rule_count - 1) LOOP
            rule_name := rule_record->'regex_rules'->i->>'name';
            rule_regex := rule_record->'regex_rules'->i->>'regex';
            rule_weight := (rule_record->'regex_rules'->i->>'weight')::FLOAT;

            IF (SELECT regexp_matches(file_name, rule_regex) IS NOT NULL) THEN
                RAISE INFO 'File : "%" with id [%] match the rule : %', file_name, file_id, rule_name;
                res := res + rule_weight;
            ELSE
                RAISE INFO 'File : "%" with id [%] doesn''t match the rule : %', file_name, file_id, rule_name;
            END IF;
        END LOOP;

    tidy_score_decimal := res / total_rule_count;
    sigmoid_value := 1 / (1 + exp(-tidy_score_decimal));
    computed_misnamed_score := assign_misnamed_score(sigmoid_value);

    UPDATE files SET misnamed_score = computed_misnamed_score WHERE id = file_id;

    RAISE INFO 'Misnamed score for file "%" with id [%]: %', file_name, file_id, computed_misnamed_score;
END;
$$;

CREATE OR REPLACE FUNCTION score_to_decimal(score CHAR(1)) RETURNS FLOAT AS $$
BEGIN
    CASE score
        WHEN 'A' THEN RETURN 0.9;
        WHEN 'B' THEN RETURN 0.7;
        WHEN 'C' THEN RETURN 0.5;
        WHEN 'D' THEN RETURN 0.3;
        WHEN 'E' THEN RETURN 0.1;
        ELSE RETURN 0.0;
        END CASE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION assign_global_score(
    misnamed_score CHAR(1),
    perished_score CHAR(1),
    duplicated_score CHAR(1)
) RETURNS CHAR(1) AS $$
DECLARE
    global_score CHAR(1);
    decimal_value FLOAT;
BEGIN
    IF misnamed_score NOT IN ('A', 'B', 'C', 'D', 'E', 'F') OR
       perished_score NOT IN ('A', 'B', 'C', 'D', 'E', 'F') OR
       duplicated_score NOT IN ('A', 'B', 'C', 'D', 'E', 'F') THEN
        RAISE INFO 'Undefined score U detected, result in U global score';
        RETURN 'U';
    END IF;

    decimal_value := (score_to_decimal(misnamed_score) + score_to_decimal(perished_score) + score_to_decimal(duplicated_score)) / 3;

    IF decimal_value >= 0.0 AND decimal_value < 0.2 THEN
        global_score := 'E';
    ELSIF decimal_value >= 0.2 AND decimal_value < 0.4 THEN
        global_score := 'D';
    ELSIF decimal_value >= 0.4 AND decimal_value < 0.6 THEN
        global_score := 'C';
    ELSIF decimal_value >= 0.6 AND decimal_value < 0.8 THEN
        global_score := 'B';
    ELSE
        global_score := 'A';
    END IF;

    RETURN global_score;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE calculate_global_score(file_id INT)
    LANGUAGE plpgsql AS $$
DECLARE
    loaded_misnamed_score CHAR(1);
    loaded_perished_score CHAR(1);
    loaded_duplicated_score CHAR(1);
    misnamed_weight FLOAT;
    perished_weight FLOAT;
    duplicated_weight FLOAT;
    computed_global_score CHAR(1);
    file_name TEXT;
BEGIN
    SELECT name INTO file_name FROM files WHERE id = file_id;
    SELECT misnamed_score, perished_score, duplicated_score
    INTO loaded_misnamed_score, loaded_perished_score, loaded_duplicated_score
    FROM files
    WHERE id = file_id;

    SELECT (rules_config->>'weight')::FLOAT
    INTO misnamed_weight
    FROM rules
    WHERE name = 'misnamed';

    SELECT (rules_config->>'weight')::FLOAT
    INTO perished_weight
    FROM rules
    WHERE name = 'perished';

    SELECT (rules_config->>'weight')::FLOAT
    INTO duplicated_weight
    FROM rules
    WHERE name = 'duplicated';

    computed_global_score := assign_global_score(loaded_misnamed_score, loaded_perished_score, loaded_duplicated_score);

    UPDATE files
    SET global_score = computed_global_score
    WHERE id = file_id;

    RAISE INFO 'Global score for file "%" with id [%] : %', file_name, file_id, computed_global_score;
END;
$$;

CREATE OR REPLACE PROCEDURE calculate_every_global_scores()
    LANGUAGE plpgsql AS $$
DECLARE
    file_record RECORD;
BEGIN
    FOR file_record IN SELECT id FROM files LOOP
            CALL calculate_global_score(file_record.id);
        END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE calculate_every_duplicated_scores()
    LANGUAGE plpgsql AS $$
DECLARE
    file_record RECORD;
BEGIN
    FOR file_record IN SELECT id FROM files LOOP
            CALL calculate_duplicated_score(file_record.id);
        END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE calculate_every_perished_scores()
    LANGUAGE plpgsql AS $$
DECLARE
    file_record RECORD;
BEGIN
    FOR file_record IN SELECT id FROM files LOOP
            CALL calculate_perished_score(file_record.id);
        END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE calculate_every_misnamed_scores()
    LANGUAGE plpgsql AS $$
DECLARE
    file_record RECORD;
BEGIN
    FOR file_record IN SELECT id FROM files LOOP
            CALL calculate_misnamed_score(file_record.id);
        END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE calculate_every_scores()
    LANGUAGE plpgsql AS $$
BEGIN
    CALL calculate_every_perished_scores();
    CALL calculate_every_misnamed_scores();
    CALL calculate_every_duplicated_scores();
    CALL calculate_every_global_scores();
END;
$$;

CREATE OR REPLACE PROCEDURE backup_tables()
    LANGUAGE plpgsql AS $$
DECLARE
    current_timestamp TIMESTAMP := NOW();
    avg_misnamed FLOAT;
    avg_perished FLOAT;
    avg_duplicated FLOAT;
    avg_global FLOAT;
    file_count INT;
BEGIN
    INSERT INTO backup_files (name, size, file_hash, last_modified, misnamed_score, perished_score, duplicated_score, global_score, backup_date)
    SELECT name, size, file_hash, last_modified, misnamed_score, perished_score, duplicated_score, global_score, current_timestamp
    FROM files;

    INSERT INTO backup_duplicate_associative_table (original_file_id, duplicate_file_id, backup_date)
    SELECT original_file_id, duplicate_file_id, current_timestamp
    FROM duplicate_associative_table;

    SELECT
        COUNT(*),
        AVG(score_to_decimal(misnamed_score)),
        AVG(score_to_decimal(perished_score)),
        AVG(score_to_decimal(duplicated_score)),
        AVG(score_to_decimal(global_score))
    INTO
        file_count,
        avg_misnamed,
        avg_perished,
        avg_duplicated,
        avg_global
    FROM files
    WHERE
        misnamed_score != 'U' AND
        perished_score != 'U' AND
        duplicated_score != 'U' AND
        global_score != 'U';

    INSERT INTO backup_average_scores (
        backup_date,
        avg_misnamed_score,
        avg_perished_score,
        avg_duplicated_score,
        avg_global_score,
        total_files
    ) VALUES (
                         current_timestamp,
                         COALESCE(avg_misnamed, 0),
                         COALESCE(avg_perished, 0),
                         COALESCE(avg_duplicated, 0),
                         COALESCE(avg_global, 0),
                         file_count
             );
END;
$$;

SELECT cron.schedule('daily_files_backup', '0 0 * * *', 'CALL backup_tables();');
