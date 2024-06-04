CREATE TABLE files (
    id SERIAL PRIMARY KEY UNIQUE,
    name TEXT NOT NULL UNIQUE,
    size int NOT NULL,
    file_hash TEXT NOT NULL,
    last_modified TIMESTAMP NOT NULL,
    misnamed_score CHAR(1) NOT NULL,
    perished_score CHAR(1) NOT NULL,
    duplicated_score CHAR(1) NOT NULL,
    global_score CHAR(1) NOT NULL
);

CREATE TABLE duplicate_associative_table (
    SERIAL PRIMARY KEY,
    INTEGER NOT NULL,
    INTEGER NOT NULL,
    fk_original_file
    KEY (original_file_id)
    files (id),
    fk_duplicate_file
    KEY (duplicate_file_id)
    files (id)
);

CREATE TABLE rules (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    weight FLOAT NOT NULL,
    rules_config JSON NOT NULL
);

INSERT INTO rules (name, description, weight, rules_config)
VALUES
    (
        'misnamed',
        'Filename must follow specific naming conventions',
        3.0,
        '{
          "type": "misnamed",
          "regex_rules": [
            {
              "name": "Date",
              "description": "Filename must contain a date with format ..._yyyy, ex: phone_bill_robert_2024.pdf",
              "regex": "_[0-9]{4}\\.",
              "weight": 3
            },
            {
              "name": "4 separator",
              "description": "Filename must have 4 separators which are underscore only, ex: phone_bill_robert_2024.pdf",
              "regex": "^[^_]*(_[^_]*){3}$",
              "weight": 1.8
            },
            {
              "name": "3 words",
              "description": "Filename must contain at least 3 words separated by underscore, ex: phone_bill_robert_2024.pdf",
              "regex": "^\\w+_\\w+_\\w+_.+$",
              "weight": 3
            },
            {
              "name": "Extension",
              "description": "Filename must contain an extension, ex: phone_bill_robert_2024.pdf",
              "regex": "\\.\\w+$",
              "weight": 2.5
            },
            {
              "name": "White Space",
              "description": "Don''t accept white spaces",
              "regex": "^\\S+$",
              "weight": 2
            },
            {
              "name": "Unauthorized Char",
              "description": "Don''t accept special characters",
              "regex": "^[A-Za-z0-9._]*$",
              "weight": 2
            }
          ]
        }'
    );


INSERT INTO rules (name, description, weight, rules_config)
VALUES
    ('perished',
     'File is considered perished if it has not been modified for a certain period',
     2.0,
     '{
       "type": "perished",
       "expiration_days": 300
     }'
    );

INSERT INTO rules (name, description, weight, rules_config)
VALUES
    ('duplicated',
     'File is considered duplicated if it appears too many times in the system',
     1.5,
     '{
       "type": "duplicated",
       "max_occurrences": 3
     }'
    );


-- TEST VALUES SHOULD BE DELETE
INSERT INTO files (name, size, file_hash, last_modified, misnamed_score, perished_score, duplicated_score, global_score)
VALUES
    ('correct_mot1_mot2_2022.txt', 2025, 'ab', NOW(), 'U', 'U', 'U', 'U'),
    ('only_2words_2023.txt', 2025, 'ab', '2024-02-05', 'U', 'U', 'U', 'U'),
    ('nounderscore3mot1mot22024.csv', 2025, 'alone', '2023-10-05', 'U', 'U', 'U', 'U'),
    ('onlyoneword.txt', 2025, 'abcd', '2023-12-05', 'U', 'U', 'U', 'U'),
    ('nodate_mot1_mot2.txt', 2025, 'abcd', '2024-01-25', 'U', 'U', 'U', 'U'),
    ('noextension_mot1_mot2_2010', 2025, 'abcd', '2024-05-05', 'U', 'U', 'U', 'U'),
    ('4words_mot1_mot2_mot3_2013.txt', 2025, 'acd', '2023-02-05', 'U', 'U', 'U', 'U'),
    ('correct_perished_mot2_2010.txt', 2025, 'acd', '2023-02-05', 'U', 'U', 'U', 'U'),
    ('bad! ', 2025, 'abcd', '2023-02-05', 'U', 'U', 'U', 'U'),
    ('special_aze_&ù\_2022.txt', 2025, 'abcd', '2023-02-05', 'U', 'U', 'U', 'U');
-------------------------------------------------

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
    SELECT name INTO file_name FROM files WHERE id = file_id;

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
