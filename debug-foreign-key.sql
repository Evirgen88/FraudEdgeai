-- Foreign key yapısını kontrol et ve düzelt
-- Bu SQL'i Supabase SQL Editor'da çalıştır

-- 1. Users tablosu yapısını kontrol et
SELECT 
    'Users tablo yapısı:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 2. MEHMET YILMAZ kullanıcısının bilgilerini kontrol et
SELECT 
    'MEHMET YILMAZ kullanıcı bilgileri:' as info,
    id,
    uuid,
    first_name,
    last_name
FROM users 
WHERE first_name = 'MEHMET' AND last_name = 'YILMAZ';

-- 3. Foreign key constraint'ini kontrol et
SELECT 
    'Foreign key constraints:' as info,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'custom_scenarios';

-- 4. Eğer foreign key users.id'ye bağlıysa, id kullanarak insert yap
WITH test_user AS (
    SELECT id, uuid FROM users 
    WHERE first_name = 'MEHMET' AND last_name = 'YILMAZ'
    LIMIT 1
)
INSERT INTO custom_scenarios (
    user_id, 
    title, 
    description, 
    category, 
    difficulty, 
    raw_content, 
    file_name, 
    file_size, 
    test_status
) 
SELECT 
    test_user.id::text::uuid, -- id'yi UUID'ye çevir
    'Test Scenario v2',
    'Test scenario for debugging - using ID',
    'security-incident',
    2,
    '{"test": "data"}',
    'test.json',
    100,
    'draft'
FROM test_user
WHERE NOT EXISTS (SELECT 1 FROM custom_scenarios WHERE title = 'Test Scenario v2');

-- 5. Alternatif: UUID kullanarak deneme
WITH test_user AS (
    SELECT uuid FROM users 
    WHERE first_name = 'MEHMET' AND last_name = 'YILMAZ'
    LIMIT 1
)
INSERT INTO custom_scenarios (
    user_id, 
    title, 
    description, 
    category, 
    difficulty, 
    raw_content, 
    file_name, 
    file_size, 
    test_status
) 
SELECT 
    test_user.uuid,
    'Test Scenario v3',
    'Test scenario for debugging - using UUID',
    'security-incident',
    2,
    '{"test": "data"}',
    'test.json',
    100,
    'draft'
FROM test_user
WHERE NOT EXISTS (SELECT 1 FROM custom_scenarios WHERE title = 'Test Scenario v3');

-- 6. Sonuçları kontrol et
SELECT 
    'Insert sonuçları:' as info,
    COUNT(*) as total_test_scenarios
FROM custom_scenarios 
WHERE title LIKE 'Test Scenario%';