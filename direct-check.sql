-- Direct check - farklı yöntemlerle kontrol et
-- Bu sorguları tek tek çalıştır

-- 1. Tablonun var olup olmadığını kontrol et
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'custom_scenarios';

-- 2. Farklı bir yöntemle column'ları kontrol et
\d+ custom_scenarios;

-- 3. PostgreSQL native sorgusu
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM 
    information_schema.columns
WHERE 
    table_catalog = current_database()
    AND table_schema = 'public'
    AND table_name = 'custom_scenarios'
ORDER BY 
    ordinal_position;

-- 4. Manuel olarak tabloya veri eklemeyi dene
INSERT INTO custom_scenarios (title) VALUES ('Test Scenario');

-- 5. Tablodan veri çek
SELECT * FROM custom_scenarios;