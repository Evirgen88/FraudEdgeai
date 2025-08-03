-- Doğru foreign key ile custom scenario oluştur
-- custom_scenarios.user_id → users.id kullan

-- 1. MEHMET YILMAZ'ın ID ve UUID bilgilerini kontrol et
SELECT 
    'MEHMET YILMAZ bilgileri:' as info,
    id as users_id,
    uuid as users_uuid,
    first_name,
    last_name
FROM users 
WHERE first_name = 'MEHMET' AND last_name = 'YILMAZ';

-- 2. Doğru foreign key (users.id) ile test scenario oluştur
WITH test_user AS (
    SELECT id FROM users 
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
    test_user.id, -- users.id kullan (SERIAL)
    'Test Scenario - Correct FK',
    'Test scenario using correct foreign key',
    'security-incident',
    2,
    '{"test": "data"}',
    'test.json',
    100,
    'draft'
FROM test_user
WHERE NOT EXISTS (SELECT 1 FROM custom_scenarios WHERE title = 'Test Scenario - Correct FK');

-- 3. Başarıyla eklendiğini kontrol et
SELECT 
    cs.id,
    cs.user_id,
    cs.title,
    cs.created_at,
    u.first_name,
    u.last_name,
    u.uuid
FROM custom_scenarios cs
JOIN users u ON cs.user_id = u.id  -- users.id ile JOIN
WHERE cs.title = 'Test Scenario - Correct FK';

-- 4. Tablo durumunu kontrol et
SELECT 
    'Custom scenarios tablosu:' as info,
    COUNT(*) as total_scenarios
FROM custom_scenarios;