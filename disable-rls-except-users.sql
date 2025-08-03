-- Users ve user_progress hariç tüm tablolarda RLS'yi disable et
-- Bu SQL'i Supabase SQL Editor'da çalıştır

-- 1. Mevcut RLS durumunu kontrol et
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled,
    forcerowsecurity as force_rls
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. Custom scenarios ile ilgili tabloların RLS'sini disable et
ALTER TABLE custom_scenarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_steps DISABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_questions DISABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_test_answers DISABLE ROW LEVEL SECURITY;

-- 3. Diğer tabloların RLS'sini de disable et (users ve user_progress hariç)
-- Eğer başka tablolar varsa buraya ekle
-- ALTER TABLE diğer_tablo DISABLE ROW LEVEL SECURITY;

-- 4. Mevcut policy'leri kaldır (users ve user_progress hariç)
DROP POLICY IF EXISTS "Enable all operations for custom_scenarios" ON custom_scenarios;
DROP POLICY IF EXISTS "Enable all operations for custom_scenario_steps" ON custom_scenario_steps;
DROP POLICY IF EXISTS "Enable all operations for custom_scenario_questions" ON custom_scenario_questions;
DROP POLICY IF EXISTS "Enable all operations for custom_scenario_test_answers" ON custom_scenario_test_answers;

-- 5. Tüm izinleri ver (RLS olmadığı için gerekli)
GRANT ALL ON custom_scenarios TO postgres, anon, authenticated;
GRANT ALL ON custom_scenario_steps TO postgres, anon, authenticated;
GRANT ALL ON custom_scenario_questions TO postgres, anon, authenticated;  
GRANT ALL ON custom_scenario_test_answers TO postgres, anon, authenticated;

-- 6. Sequence izinlerini ver
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated;

-- 7. Son durumu kontrol et
SELECT 
    'Final RLS Status:' as info,
    tablename,
    CASE 
        WHEN rowsecurity = true THEN 'ENABLED'
        ELSE 'DISABLED'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('users', 'user_progress', 'custom_scenarios', 'custom_scenario_steps', 'custom_scenario_questions', 'custom_scenario_test_answers')
ORDER BY tablename;

-- 8. Test query - artık çalışmalı
SELECT 'Test Query Results:' as info;
SELECT COUNT(*) as total_custom_scenarios FROM custom_scenarios;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_user_progress FROM user_progress;