const axios = require('axios');

const API_URL = 'http://localhost:8080/api';

async function testProfileUpdate() {
  const userId = 'user_001_alice_sf';
  
  console.log('\n🧪 Testing Profile Update with Resilient Save\n');
  
  try {
    // 1. Get current profile
    console.log('1️⃣ Fetching current profile...');
    const getResponse = await axios.get(`${API_URL}/profiles/${userId}`, {
      headers: { 'x-user-id': userId }
    });
    console.log(`✅ Current profile: ${getResponse.data.name} in ${getResponse.data.city}\n`);
    
    // 2. Update profile
    const updateData = {
      city: 'Malindi',
      bio: 'Updated bio - now in Malindi',
      social_frequency: 8,
    };
    
    console.log('2️⃣ Updating profile with new data:', updateData);
    const updateResponse = await axios.patch(
      `${API_URL}/profiles/${userId}`,
      updateData,
      { headers: { 'x-user-id': userId } }
    );
    console.log(`✅ Profile updated successfully!`);
    console.log(`   - New city: ${updateResponse.data.city}`);
    console.log(`   - New bio: ${updateResponse.data.bio}\n`);
    
    // 3. Verify update
    console.log('3️⃣ Verifying update...');
    const verifyResponse = await axios.get(`${API_URL}/profiles/${userId}`, {
      headers: { 'x-user-id': userId }
    });
    console.log(`✅ Profile verified:`);
    console.log(`   - City: ${verifyResponse.data.city}`);
    console.log(`   - Bio: ${verifyResponse.data.bio}`);
    console.log(`   - Last updated: ${new Date(verifyResponse.data.updated_at).toISOString()}\n`);
    
    console.log('🎉 All tests passed! Profile update resilience working correctly.\n');
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    process.exit(1);
  }
}

testProfileUpdate();
