-- Custom Scenarios Schema Update
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- Custom scenarios table - kullanıcı tarafından oluşturulan senaryolar
CREATE TABLE IF NOT EXISTS custom_scenarios (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'custom',
  difficulty INTEGER DEFAULT 1 CHECK (difficulty IN (1, 2, 3)),
  raw_content TEXT, -- Original log file content
  file_name TEXT,
  file_size INTEGER,
  test_status TEXT DEFAULT 'draft' CHECK (test_status IN ('draft', 'tested')),
  test_score INTEGER, -- Average score from test (if tested)
  test_completed_at TIMESTAMP WITH TIME ZONE, -- When test was completed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Custom scenario steps table - scenario adımları
CREATE TABLE IF NOT EXISTS custom_scenario_steps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
  step_order INTEGER NOT NULL,
  timestamp TEXT,
  level TEXT DEFAULT 'info', -- info, warning, error, success
  message TEXT NOT NULL,
  is_critical BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Custom scenario questions table - sorular ve cevaplar
CREATE TABLE IF NOT EXISTS custom_scenario_questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
  question_order INTEGER NOT NULL,
  question_text TEXT NOT NULL,
  points INTEGER DEFAULT 10,
  keywords JSONB, -- Expected keywords for grading
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Test answers table - test cevapları (optional, for tracking test results)
CREATE TABLE IF NOT EXISTS custom_scenario_test_answers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
  question_id UUID REFERENCES custom_scenario_questions(id) ON DELETE CASCADE,
  user_answer TEXT NOT NULL,
  ai_feedback TEXT,
  score INTEGER DEFAULT 0,
  test_session_id UUID, -- To group answers from same test session
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_user_id ON custom_scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_test_status ON custom_scenarios(test_status);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_steps_scenario_id ON custom_scenario_steps(scenario_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_questions_scenario_id ON custom_scenario_questions(scenario_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_test_answers_scenario_id ON custom_scenario_test_answers(scenario_id);

-- RLS (Row Level Security) policies
ALTER TABLE custom_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_test_answers ENABLE ROW LEVEL SECURITY;

-- Allow users to manage their own custom scenarios
CREATE POLICY "Users can manage their own custom scenarios" ON custom_scenarios FOR ALL USING (true);
CREATE POLICY "Users can manage custom scenario steps" ON custom_scenario_steps FOR ALL USING (true);
CREATE POLICY "Users can manage custom scenario questions" ON custom_scenario_questions FOR ALL USING (true);
CREATE POLICY "Users can manage custom scenario test answers" ON custom_scenario_test_answers FOR ALL USING (true);

-- Updated_at trigger for custom_scenarios
CREATE TRIGGER update_custom_scenarios_updated_at
    BEFORE UPDATE ON custom_scenarios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();