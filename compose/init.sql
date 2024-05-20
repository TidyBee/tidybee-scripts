-- Create rules table
CREATE TABLE misnamed_rule (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    regular_expression TEXT NOT NULL,
    weight FLOAT NOT NULL
);

-- Add rules into db
INSERT INTO misnamed_rule (name, description, regular_expression, weight)
VALUES
    ('Date', 'Filename must contain a date with format ..._yyyy, ex: phone_bill_robert_2024.pdf', '_[0-9]{4}\.', 3),
    ('4 separator', 'Filename must have 4 separators which are underscore only, ex: phone_bill_robert_2024.pdf', '^[^_]*(_[^_]*){3}$', 1.8),
    ('3 words', 'Filename must contain 3 words separated by underscore, ex: phone_bill_robert_2024.pdf', '^\w+_\w+_\w+_.+$', 3),
    ('Extension', 'Filename must contain an extension, ex: phone_bill_robert_2024.pdf', '\\.\w+$', 2.5),
    ('White Space', 'Don''t accept white spaces', '^\S+$', 2),
    ('Unauthorized Char', 'Don''t accept special characters', '^[A-Za-z0-9._]*$', 2);

-- create files table
CREATE TABLE files (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT NOT NULL,
    size INT NOT NULL,
    hash TEXT NOT NULL,
    last_modified TIMESTAMP NOT NULL,
    last_accessed TIMESTAMP NOT NULL,
    tidy_score TEXT
);

-- Add files into files table
INSERT INTO files (name, path, size, hash, last_modified, last_accessed)
VALUES
    ('correct_mot1_mot2_2022.txt', 'C:/Documents/correct_mot1_mot2_2022.txt', 2025, 'ab', '2024-03-05', NOW()),
    ('only_2words_2023.txt', 'C:/Documents/only_2words_2023.txt', 2025, 'ab', '2024-02-05', '2023-02-05'),
    ('nounderscore3mot1mot22024.csv', 'C:/Documents/nounderscore3mot1mot22024.csv', 2025, 'abcd', '2023-12-05', '2023-02-05'),
    ('onlyoneword.txt', 'C:/Documents/onlyoneword.txt', 2025, 'abcd', '2023-10-05', '2023-02-05'),
    ('nodate_mot1_mot2.txt', 'C:/Documents/nodate_mot1_mot2.txt', 2025, 'abcd', '2023-08-05', '2023-02-05'),
    ('noextension_mot1_mot2_2010', 'C:/Documents/noextension_mot1_mot2_2010', 2025, 'abcd', '2023-06-05', '2023-02-05'),
    ('4words_mot1_mot2_mot3_2013.txt', 'C:/Documents/4words_mot1_mot2_mot3_2013.txt', 2025, 'acd', '2023-04-05', '2023-02-05'),
    ('correct_perished_mot2_2010.txt', 'C:/Documents/correct_perished_mot2_2010.txt', 2025, 'acd', '2023-02-05', '2023-02-05'),
    ('bad! ', 'C:/Documents/bad! ', 2025, 'abcd', '2023-02-05', '2023-02-05'),
    ('special_aze_&ù\_2022.txt', 'C:/Documents/special_aze_&ù\_2022.txt', 2025, 'abcd', '2022-12-05', '2023-02-05');

-- Intern function assign misnamed grade to grade a file
CREATE OR REPLACE FUNCTION assign_misnamed_grade(score FLOAT)
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

-- Declaration of apply_misnamed function
CREATE OR REPLACE FUNCTION apply_misnamed(file_id INT)
RETURNS VOID AS $$
DECLARE
    res FLOAT := 0;
    total_rule_count INT;
    tidy_score_decimal FLOAT;
    misnamed_grade TEXT;
    rule_record RECORD;
BEGIN
SELECT COUNT(*)INTO total_rule_count FROM misnamed_rule;

    RAISE INFO 'Applying MISNAMED Rules...';

    FOR rule_record IN
        SELECT name, regular_expression, weight FROM misnamed_rule
    LOOP
        IF (SELECT regexp_matches((SELECT name FROM files WHERE id = file_id), rule_record.regular_expression) IS NOT NULL) THEN
            RAISE INFO 'File : % match the rule : %', (SELECT name FROM files WHERE id = file_id), rule_record.name;
            res := res + rule_record.weight;
        ELSE
            RAISE INFO 'File : % doesn''t match the rule : %', (SELECT name FROM files WHERE id = file_id), rule_record.name;
        END IF;

    END LOOP;

    tidy_score_decimal := res / total_rule_count;
    misnamed_grade := assign_misnamed_grade(tidy_score_decimal);

    UPDATE files SET tidy_score = misnamed_grade WHERE id = file_id;

    RAISE INFO 'Misnamed grade for file %: %', file_id, misnamed_grade;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION assign_duplicated_grade(occurrences INT)
RETURNS VARCHAR(1) AS $$
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

-- Declaration of apply_duplicated function
CREATE OR REPLACE FUNCTION apply_duplicated(file_id INT)
RETURNS VOID AS $$
DECLARE
    hash_value VARCHAR(64);
    occurrence_count INT;
    file_path VARCHAR(255);
BEGIN
    SELECT hash, path INTO hash_value, file_path
    FROM files
    WHERE id = file_id;
    SELECT COUNT(*) INTO occurrence_count
    FROM files
    WHERE hash = hash_value;
    UPDATE files
    SET tidy_score = assign_duplicated_grade(occurrence_count)
    WHERE id = file_id;

    -- This is more debug than very useful
    RAISE NOTICE 'File : % has duplicated score : %', file_path, assign_duplicated_grade(occurrence_count);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION apply_perished(file_id INT)
RETURNS VOID AS $$
DECLARE
    res INTERVAL;
    perished_grade TEXT;
    day_duration_limit INT := 300; -- Perished limit, ten months for the example
    file_path VARCHAR(255);
BEGIN
    SELECT NOW() - last_modified, path INTO res, file_path
    FROM files
    WHERE id = file_id;

    IF res < INTERVAL '1 day' * day_duration_limit THEN
        perished_grade := 'A';
    ELSIF res <= INTERVAL '1 day' * (day_duration_limit + day_duration_limit / 4) THEN
        perished_grade := 'B';
    ELSIF res <= INTERVAL '1 day' * (day_duration_limit + day_duration_limit / 3) THEN
        perished_grade := 'C';
    ELSIF res <= INTERVAL '1 day' * (day_duration_limit + day_duration_limit / 2) THEN
        perished_grade := 'D';
    ELSIF res <= INTERVAL '1 day' * (day_duration_limit * 2) THEN
        perished_grade := 'E';
    ELSE
        perished_grade := 'F';
    END IF;

    UPDATE files
    SET tidy_score = perished_grade
    WHERE id = file_id;

    RAISE NOTICE 'File % has perished score: %', file_path, perished_grade;
END;
$$ LANGUAGE plpgsql;
