-- Fix Supabase custom_scenarios table access issues
-- Bu SQL'leri Supabase SQL Editor'da çalıştır

-- 1. Önce mevcut policy'leri temizle
DROP POLICY IF EXISTS "Enable all operations for custom_scenarios" ON custom_scenarios;
DROP POLICY IF EXISTS "Enable all operations for custom_scenario_steps" ON custom_scenario_steps;
DROP POLICY IF EXISTS "Enable all operations for custom_scenario_questions" ON custom_scenario_questions;
DROP POLICY IF EXISTS "Enable all operations for custom_scenario_test_answers" ON custom_scenario_test_answers;

-- 2. RLS'yi disable et (geçici olarak, debug için)
ALTER TABLE custom_scenarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_steps DISABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_questions DISABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_test_answers DISABLE ROW LEVEL SECURITY;

-- 3. Tabloları kontrol et ve gerekli kolonları ekle
DO $$ 
BEGIN
    -- custom_scenarios tablosu için eksik kolonları kontrol et
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_scenarios' AND column_name = 'raw_content') THEN
        ALTER TABLE custom_scenarios ADD COLUMN raw_content TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_scenarios' AND column_name = 'file_name') THEN
        ALTER TABLE custom_scenarios ADD COLUMN file_name VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_scenarios' AND column_name = 'file_size') THEN
        ALTER TABLE custom_scenarios ADD COLUMN file_size INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_scenarios' AND column_name = 'test_status') THEN
        ALTER TABLE custom_scenarios ADD COLUMN test_status VARCHAR(20) DEFAULT 'draft';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_scenarios' AND column_name = 'test_score') THEN
        ALTER TABLE custom_scenarios ADD COLUMN test_score INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'custom_scenarios' AND column_name = 'test_completed_at') THEN
        ALTER TABLE custom_scenarios ADD COLUMN test_completed_at TIMESTAMPTZ;
    END IF;
END $$;

-- 4. Temel indexleri oluştur
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_user_id ON custom_scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_created_at ON custom_scenarios(created_at);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_steps_scenario_id ON custom_scenario_steps(scenario_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_questions_scenario_id ON custom_scenario_questions(scenario_id);

-- 5. Test verisi ekle (eğer tablo boşsa)
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
    'test-user-123',
    'Test Scenario',
    'Test scenario for debugging',
    'security-incident',
    2,
    '{"test": "data"}',
    'test.json',
    100,
    'draft'
WHERE NOT EXISTS (SELECT 1 FROM custom_scenarios WHERE title = 'Test Scenario');

-- 6. Yetkileri kontrol et
GRANT ALL ON custom_scenarios TO postgres, anon, authenticated;
GRANT ALL ON custom_scenario_steps TO postgres, anon, authenticated;
GRANT ALL ON custom_scenario_questions TO postgres, anon, authenticated;
GRANT ALL ON custom_scenario_test_answers TO postgres, anon, authenticated;

-- 7. Sequence'lerin sahipliğini düzelt
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated;

-- 8. Tablo durumunu kontrol et
SELECT 
    t.table_name,
    t.row_security,
    COUNT(p.policyname) as policy_count,
    pg_total_relation_size(t.table_name::regclass) as table_size
FROM information_schema.tables ist
LEFT JOIN pg_tables t ON ist.table_name = t.tablename
LEFT JOIN pg_policies p ON t.tablename = p.tablename
WHERE ist.table_name LIKE 'custom_scenario%'
AND ist.table_schema = 'public'
GROUP BY t.table_name, t.row_security, ist.table_name;

-- 9. Test query - bu çalışmalı
SELECT COUNT(*) as total_scenarios FROM custom_scenarios;

-- 10. Debug bilgisi
SELECT 
    'custom_scenarios table info' as info,
    COUNT(*) as row_count,
    string_agg(DISTINCT user_id::text, ', ') as user_ids
FROM custom_scenarios
UNION ALL
SELECT 
    'current_user() result' as info,
    0 as row_count,
    current_user as user_ids;