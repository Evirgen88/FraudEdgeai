-- custom_scenarios tablosu için RLS ve policies ekle
-- Bu SQL'leri Supabase SQL Editor'da çalıştır

-- 1. RLS'yi enable et
ALTER TABLE custom_scenarios ENABLE ROW LEVEL SECURITY;

-- 2. Basic policy - tüm işlemlere izin ver (test amaçlı)
CREATE POLICY "Enable all operations for custom_scenarios" 
ON custom_scenarios FOR ALL 
USING (true) 
WITH CHECK (true);

-- 3. Diğer tablolar için de RLS enable et
ALTER TABLE custom_scenario_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_test_answers ENABLE ROW LEVEL SECURITY;

-- 4. Diğer tablolar için de basic policies
CREATE POLICY "Enable all operations for custom_scenario_steps" 
ON custom_scenario_steps FOR ALL 
USING (true) 
WITH CHECK (true);

CREATE POLICY "Enable all operations for custom_scenario_questions" 
ON custom_scenario_questions FOR ALL 
USING (true) 
WITH CHECK (true);

CREATE POLICY "Enable all operations for custom_scenario_test_answers" 
ON custom_scenario_test_answers FOR ALL 
USING (true) 
WITH CHECK (true);

-- 5. Index'leri oluştur
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_user_id ON custom_scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_test_status ON custom_scenarios(test_status);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_steps_scenario_id ON custom_scenario_steps(scenario_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_questions_scenario_id ON custom_scenario_questions(scenario_id);

-- 6. Updated_at trigger ekle
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER update_custom_scenarios_updated_at
    BEFORE UPDATE ON custom_scenarios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 7. Kontrol et - RLS status
SELECT schemaname, tablename, rowsecurity, forcerowsecurity 
FROM pg_tables 
WHERE tablename LIKE 'custom_scenario%' 
AND schemaname = 'public';