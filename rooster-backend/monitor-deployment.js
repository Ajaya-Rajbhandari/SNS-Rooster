const https = require('https');

const RENDER_URL = 'https://sns-rooster.onrender.com';

const testHealthEndpoint = async () => {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'sns-rooster.onrender.com',
      port: 443,
      path: '/api/monitoring/health',
      method: 'GET',
      timeout: 10000
    };

    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          resolve({
            status: res.statusCode,
            data: response,
            headers: res.headers
          });
        } catch (error) {
          resolve({
            status: res.statusCode,
            data: data,
            error: error.message
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.end();
  });
};

const monitorDeployment = async () => {
  console.log('🔍 Monitoring deployment status...');
  console.log('📡 Testing health endpoint at:', `${RENDER_URL}/api/monitoring/health`);
  
  try {
    const result = await testHealthEndpoint();
    
    console.log('✅ Health endpoint response:');
    console.log('Status Code:', result.status);
    console.log('Response:', JSON.stringify(result.data, null, 2));
    
    if (result.status === 200) {
      console.log('🎉 DEPLOYMENT SUCCESSFUL! Health endpoint is responding.');
      console.log('📊 Server uptime:', result.data.uptime, 'seconds');
      console.log('🗄️ Database status:', result.data.database);
      console.log('🌍 Environment:', result.data.environment);
    } else {
      console.log('⚠️ Health endpoint returned status:', result.status);
    }
    
  } catch (error) {
    console.error('❌ Health endpoint failed:', error.message);
    console.log('⏳ Deployment might still be in progress...');
    console.log('💡 Try again in a few minutes.');
  }
};

// Run the monitoring
monitorDeployment(); 