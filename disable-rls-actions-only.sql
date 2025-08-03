-- Users ve user_progress hariç tüm tablolarda RLS'yi disable et
-- SADECE AKSIYON KOMUTLARI

-- RLS disable komutları
ALTER TABLE custom_scenarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_steps DISABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_questions DISABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_test_answers DISABLE ROW LEVEL SECURITY;

-- Policy'leri kaldır
DROP POLICY IF EXISTS "Enable all operations for custom_scenarios" ON custom_scenarios;
DROP POLICY IF EXISTS "Enable all operations for custom_scenario_steps" ON custom_scenario_steps;
DROP POLICY IF EXISTS "Enable all operations for custom_scenario_questions" ON custom_scenario_questions;
DROP POLICY IF EXISTS "Enable all operations for custom_scenario_test_answers" ON custom_scenario_test_answers;

-- İzinleri ver
GRANT ALL ON custom_scenarios TO postgres, anon, authenticated;
GRANT ALL ON custom_scenario_steps TO postgres, anon, authenticated;
GRANT ALL ON custom_scenario_questions TO postgres, anon, authenticated;  
GRANT ALL ON custom_scenario_test_answers TO postgres, anon, authenticated;

-- Sequence izinleri
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated;