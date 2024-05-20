CREATE TABLE files (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    size int NOT NULL,
    file_hash TEXT NOT NULL,
    last_modified TIMESTAMP NOT NULL,
    misnamed_score CHAR(1) NOT NULL,
    perished_score CHAR(1) NOT NULL,
    duplicated_score CHAR(1) NOT NULL,
    global_score CHAR(1) NOT NULL
);

CREATE TABLE duplicate_associative_table (
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

-- TEST VALUES SHOULD BE DELETE
INSERT INTO files (name, size, file_hash, last_modified, misnamed_score, perished_score, duplicated_score, global_score)
VALUES
    ('correct_mot1_mot2_2022.txt', 2025, 'ab', NOW(), 'N', 'N', 'N', 'N'),
    ('only_2words_2023.txt', 2025, 'ab', '2023-02-05', 'N', 'N', 'N', 'N'),
    ('nounderscore3mot1mot22024.csv', 2025, 'alone', '2023-02-05', 'N', 'N', 'N', 'N'),
    ('onlyoneword.txt', 2025, 'abcd', '2023-02-05', 'N', 'N', 'N', 'N'),
    ('nodate_mot1_mot2.txt', 2025, 'abcd', '2023-02-05', 'N', 'N', 'N', 'N'),
    ('noextension_mot1_mot2_2010', 2025, 'abcd', '2023-02-05', 'N', 'N', 'N', 'N'),
    ('4words_mot1_mot2_mot3_2013.txt', 2025, 'acd', '2023-02-05', 'N', 'N', 'N', 'N'),
    ('correct_perished_mot2_2010.txt', 2025, 'acd', '2023-02-05', 'N', 'N', 'N', 'N'),
    ('bad! ', 2025, 'abcd', '2023-02-05', 'N', 'N', 'N', 'N'),
    ('special_aze_&ù\_2022.txt', 2025, 'abcd', '2023-02-05', 'N', 'N', 'N', 'N');

ALTER TABLE duplicate_associative_table
ADD CONSTRAINT unique_file_pair UNIQUE (original_file_id, duplicate_file_id);

ALTER TABLE duplicate_associative_table
ADD CONSTRAINT no_self_duplicate CHECK (original_file_id != duplicate_file_id);

CREATE OR REPLACE FUNCTION detect_and_store_duplicates() RETURNS VOID AS $$
BEGIN
    INSERT INTO duplicate_associative_table (original_file_id, duplicate_file_id)
    SELECT f1.id, f2.id
    FROM files f1
    JOIN files f2 ON f1.file_hash = f2.file_hash AND f1.id < f2.id
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_perished_score(file_id INT)
RETURNS VOID AS $$
DECLARE
    calculated_score CHAR(1);
    res INTERVAL;
    day_duration_limit INT := 300; -- Perished limit, ten months for the example
    file_path TEXT;
BEGIN
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

    RAISE NOTICE 'File % has perished score: %', file_path, calculated_score;

    UPDATE files
    SET perished_score = calculated_score
    WHERE id = file_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calculate_every_perished_scores()
RETURNS VOID AS $$
DECLARE
    file_record RECORD;
BEGIN
    FOR file_record IN SELECT id FROM files LOOP
        PERFORM calculate_perished_score(file_record.id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION assign_duplicated_grade(occurrences INT)
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

CREATE OR REPLACE FUNCTION calculate_duplicated_score(file_id INT)
RETURNS VOID AS $$
DECLARE
    occurrence_count INT;
    new_score CHAR(1); -- Nouveau score calculé
BEGIN
    -- Compter les occurrences du hash du fichier dans la table files
    SELECT COUNT(*) INTO occurrence_count
    FROM files
    WHERE file_hash = (SELECT file_hash FROM files WHERE id = file_id)
    AND id != file_id; -- Exclure le fichier actuel de la recherche de doublons

    -- Calculer le nouveau score
    new_score := assign_duplicated_grade(occurrence_count);

    -- Mettre à jour le score de duplication dans la table files
    UPDATE files
    SET duplicated_score = new_score
    WHERE id = file_id;

    RAISE NOTICE 'File ID: % has duplicated score: % with % occurrences', file_id, new_score, occurrence_count;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION calculate_every_duplicated_scores()
RETURNS VOID AS $$
DECLARE
    file_record RECORD;
BEGIN
    FOR file_record IN SELECT id FROM files LOOP
        PERFORM calculate_duplicated_score(file_record.id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;