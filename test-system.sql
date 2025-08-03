-- Sistem Test Scripti
-- Supabase SQL Editor'da çalıştır

-- 1. Test kullanıcısının UUID'sini al
SELECT 'Test User UUID:', uuid FROM users WHERE first_name = 'Test' LIMIT 1;

-- 2. İlk limit kontrolü (sıfır scenario)
SELECT 'İlk Durum:' as test, * FROM check_user_limits(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

-- 3. 1. scenario'yu simulate et
SELECT 'Scenario 1 increment:' as test, increment_scenario_count(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

SELECT 'Scenario 1 sonrası:' as test, * FROM check_user_limits(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

-- 4. 2. scenario'yu simulate et
SELECT 'Scenario 2 increment:' as test, increment_scenario_count(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

SELECT 'Scenario 2 sonrası:' as test, * FROM check_user_limits(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

-- 5. 3. scenario'yu simulate et
SELECT 'Scenario 3 increment:' as test, increment_scenario_count(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

SELECT 'Scenario 3 sonrası:' as test, * FROM check_user_limits(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

-- 6. 4. scenario'yu dene (limit aşımı)
SELECT 'Scenario 4 increment (LIMIT AŞIMI):' as test, increment_scenario_count(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

SELECT 'Scenario 4 sonrası (LIMIT AŞILDI):' as test, * FROM check_user_limits(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

-- 7. Premium'a upgrade simülasyonu
UPDATE users 
SET subscription_type = 'premium_monthly',
    subscription_start = CURRENT_DATE,
    subscription_end = CURRENT_DATE + INTERVAL '1 month'
WHERE first_name = 'Test';

SELECT 'Premium sonrası:' as test, * FROM check_user_limits(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);

-- 8. Test'i sıfırla
UPDATE users 
SET subscription_type = 'free',
    subscription_start = NULL,
    subscription_end = NULL,
    daily_scenario_count = 0,
    monthly_scenario_count = 0
WHERE first_name = 'Test';

SELECT 'Test sıfırlandı:' as test, * FROM check_user_limits(
  (SELECT uuid FROM users WHERE first_name = 'Test' LIMIT 1)
);