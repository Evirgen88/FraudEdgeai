-- Foreign key constraint hatası düzeltmesi
-- Bu SQL'i Supabase SQL Editor'da çalıştır

-- 1. Önce users tablosunda mevcut kullanıcıları kontrol et
SELECT 
    'Mevcut kullanıcılar:' as info,
    id,
    uuid,
    first_name,
    last_name
FROM users 
LIMIT 5;

-- 2. Eğer hiç kullanıcı yoksa, test kullanıcısı oluştur
INSERT INTO users (
    first_name,
    last_name,
    referral_source,
    description,
    subscription_type
)
SELECT 
    'Test',
    'User',
    'debug',
    'Test user for debugging custom scenarios',
    'premium'
WHERE NOT EXISTS (
    SELECT 1 FROM users 
    WHERE first_name = 'Test' AND last_name = 'User'
);

-- 3. Test kullanıcısının UUID'sini al
WITH test_user AS (
    SELECT uuid FROM users 
    WHERE first_name = 'Test' AND last_name = 'User'
    LIMIT 1
)
-- 4. Test kullanıcısı ile custom scenario oluştur
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
    'Test Scenario',
    'Test scenario for debugging',
    'security-incident',
    2,
    '{"test": "data"}',
    'test.json',
    100,
    'draft'
FROM test_user
WHERE NOT EXISTS (SELECT 1 FROM custom_scenarios WHERE title = 'Test Scenario');

-- 5. Sonucu kontrol et
SELECT 
    cs.id,
    cs.user_id,
    cs.title,
    cs.created_at,
    u.first_name,
    u.last_name
FROM custom_scenarios cs
JOIN users u ON cs.user_id = u.uuid
WHERE cs.title = 'Test Scenario';

-- 6. Tablo yapısını kontrol et
SELECT 
    'custom_scenarios tablo bilgisi:' as info,
    COUNT(*) as total_scenarios,
    COUNT(DISTINCT user_id) as unique_users
FROM custom_scenarios;