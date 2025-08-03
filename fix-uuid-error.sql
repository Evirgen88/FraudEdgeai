-- UUID hatası düzeltmesi
-- Bu SQL'i Supabase SQL Editor'da çalıştır

-- 1. Önce mevcut test verisini temizle (eğer varsa)
DELETE FROM custom_scenarios WHERE title = 'Test Scenario';

-- 2. Geçerli bir UUID kullanarak test verisi ekle
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
    gen_random_uuid(), -- Geçerli UUID oluştur
    'Test Scenario',
    'Test scenario for debugging',
    'security-incident',
    2,
    '{"test": "data"}',
    'test.json',
    100,
    'draft'
WHERE NOT EXISTS (SELECT 1 FROM custom_scenarios WHERE title = 'Test Scenario');

-- 3. Test et - bu çalışmalı
SELECT 
    id,
    user_id,
    title,
    created_at
FROM custom_scenarios 
WHERE title = 'Test Scenario';

-- 4. Users tablosundan gerçek bir UUID al (varsa)
SELECT 
    'Mevcut user UUID örnekleri:' as info,
    id,
    uuid,
    first_name
FROM users 
LIMIT 3;