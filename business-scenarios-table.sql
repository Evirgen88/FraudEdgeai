-- Business scenarios tablosu oluştur
CREATE TABLE IF NOT EXISTS business_scenarios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_topic TEXT NOT NULL,
    questions JSONB,
    answers JSONB,
    analysis_results JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- İndeksler ekle
CREATE INDEX IF NOT EXISTS idx_business_scenarios_user_id ON business_scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_business_scenarios_created_at ON business_scenarios(created_at);

-- RLS (Row Level Security) politikaları
ALTER TABLE business_scenarios ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar sadece kendi senaryolarını görebilir
CREATE POLICY "Users can view own business scenarios" ON business_scenarios
    FOR SELECT USING (auth.uid() = user_id);

-- Kullanıcılar kendi senaryolarını ekleyebilir  
CREATE POLICY "Users can insert own business scenarios" ON business_scenarios
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Kullanıcılar kendi senaryolarını güncelleyebilir
CREATE POLICY "Users can update own business scenarios" ON business_scenarios
    FOR UPDATE USING (auth.uid() = user_id);

-- Kullanıcılar kendi senaryolarını silebilir
CREATE POLICY "Users can delete own business scenarios" ON business_scenarios
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger fonksiyonu updated_at için
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger ekle
CREATE OR REPLACE TRIGGER update_business_scenarios_updated_at 
    BEFORE UPDATE ON business_scenarios 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();