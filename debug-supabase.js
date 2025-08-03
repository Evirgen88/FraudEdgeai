// Debug script for browser console
// Bu kodu browser console'da çalıştırarak Supabase bağlantısını test et

async function debugSupabaseConnection() {
    console.log('🔍 === SUPABASE DEBUG BAŞLADI ===');
    
    try {
        // 1. Import services
        const supabaseService = window.supabaseService || (await import('./src/services/supabaseService.js')).default;
        const scenarioBuilderService = window.scenarioBuilderService || (await import('./src/services/scenarioBuilderService.js')).default;
        
        console.log('✅ Services imported successfully');
        
        // 2. Test basic Supabase connection
        console.log('🔍 Testing basic Supabase connection...');
        const connectionTest = await supabaseService.manualTest();
        console.log('🔍 Connection test result:', connectionTest);
        
        // 3. Test custom_scenarios table directly
        console.log('🔍 Testing custom_scenarios table access...');
        const { supabase } = supabaseService;
        
        if (!supabase) {
            console.error('❌ Supabase client not available');
            return;
        }
        
        // Test simple select
        console.log('🔍 Testing SELECT query...');
        const { data: selectData, error: selectError } = await supabase
            .from('custom_scenarios')
            .select('id, title, user_id')
            .limit(5);
            
        console.log('🔍 SELECT result:', selectData);
        console.log('🔍 SELECT error:', selectError);
        
        // Test insert permissions
        console.log('🔍 Testing INSERT permissions...');
        const testData = {
            user_id: 'debug-test-' + Date.now(),
            title: 'Debug Test Scenario',
            description: 'Test scenario for debugging',
            category: 'test',
            difficulty: 1,
            raw_content: '{"test": "debug"}',
            file_name: 'debug.json',
            file_size: 50,
            test_status: 'draft'
        };
        
        const { data: insertData, error: insertError } = await supabase
            .from('custom_scenarios')
            .insert([testData])
            .select()
            .single();
            
        console.log('🔍 INSERT result:', insertData);
        console.log('🔍 INSERT error:', insertError);
        
        // Clean up test data
        if (insertData && insertData.id) {
            console.log('🔍 Cleaning up test data...');
            await supabase
                .from('custom_scenarios')
                .delete()
                .eq('id', insertData.id);
        }
        
        // 4. Test scenario builder service
        console.log('🔍 Testing ScenarioBuilderService...');
        const testUserId = 'debug-user-123';
        const testScenarioData = {
            title: 'Service Test Scenario',
            description: 'Testing scenario builder service',
            category: 'test',
            difficulty: 1,
            steps: [
                {
                    timestamp: '10:00:00',
                    level: 'info',
                    message: 'Test step',
                    critical: false
                }
            ],
            questions: [
                {
                    text: 'Test question?',
                    points: 10,
                    keywords: ['test']
                }
            ],
            testStatus: 'draft'
        };
        
        const saveResult = await scenarioBuilderService.saveCustomScenario(
            testUserId,
            testScenarioData,
            '{"test": "content"}',
            'test.json',
            100
        );
        
        console.log('🔍 ScenarioBuilder save result:', saveResult);
        
        console.log('✅ === SUPABASE DEBUG TAMAMLANDI ===');
        
    } catch (error) {
        console.error('❌ Debug script error:', error);
    }
}

// Run the debug function
console.log('🔍 Supabase debug script loaded. Run debugSupabaseConnection() to test.');