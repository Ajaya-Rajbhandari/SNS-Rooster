const express = require('express');
const router = express.Router();

// App version configuration
const APP_VERSIONS = {
  android: {
    latest_version: '1.0.14',
    latest_build_number: '14',
    update_required: false,
    update_message: 'A new version of SNS Rooster is available with enhanced user experience and performance improvements!',
    download_url: 'https://sns-rooster.onrender.com/api/app/download/android/file',
    min_required_version: '1.0.0',
    min_required_build: '1',
  },
  web: {
    latest_version: '1.0.14',
    latest_build_number: '14',
    update_required: false,
    update_message: 'A new version of SNS Rooster is available with enhanced user experience and performance improvements. Please refresh your browser.',
    download_url: 'https://sns-rooster.onrender.com/api/app/download/android/file',
    min_required_version: '1.0.0',
    min_required_build: '1',
  },
  ios: {
    latest_version: '1.0.0',
    latest_build_number: '1',
    update_required: false,
    update_message: 'A new version of SNS Rooster is available on the App Store.',
    download_url: 'https://apps.apple.com/app/sns-rooster/id123456789',
    min_required_version: '1.0.0',
    min_required_build: '1',
  }
};



/**
 * @route   GET /api/app/version/check
 * @desc    Check for app updates
 * @access  Public
 */
router.get('/check', async (req, res) => {
  try {
    const userAgent = req.headers['user-agent'] || '';
    const platform = _detectPlatform(userAgent);
    const currentVersion = req.query.version || '1.0.0';
    const currentBuild = req.query.build || '1';
    
    console.log(`🔍 App version check - Platform: ${platform}, Version: ${currentVersion}, Build: ${currentBuild}`);
    
    const versionInfo = APP_VERSIONS[platform] || APP_VERSIONS.android;
    
    // Check if update is required (critical security updates)
    const isUpdateRequired = _isUpdateRequired(
      currentVersion,
      currentBuild,
      versionInfo.min_required_version,
      versionInfo.min_required_build
    );
    
    // Check if newer version is available
    // For web platform, never show update alerts since it's always the latest version
    const hasNewerVersion = platform === 'web' ? false : _compareVersions(
      currentVersion,
      currentBuild,
      versionInfo.latest_version,
      versionInfo.latest_build_number
    );
    
    const response = {
      current_version: currentVersion,
      current_build_number: currentBuild,
      latest_version: versionInfo.latest_version,
      latest_build_number: versionInfo.latest_build_number,
      update_available: hasNewerVersion,
      update_required: isUpdateRequired,
      update_message: versionInfo.update_message,
      download_url: versionInfo.download_url,
      platform: platform,
      timestamp: new Date().toISOString(),
    };
    
    console.log(`📱 Version check response:`, response);
    
    res.json(response);
  } catch (error) {
    console.error('❌ Error checking app version:', error);
    res.status(500).json({
      error: 'Failed to check app version',
      message: error.message
    });
  }
});

/**
 * @route   POST /api/app/version/update
 * @desc    Update app version information (admin only)
 * @access  Private (Admin)
 */
router.post('/update', async (req, res) => {
  try {
    // TODO: Add admin authentication middleware
    const { platform, version, build_number, update_required, message, download_url } = req.body;
    
    if (!platform || !version || !build_number) {
      return res.status(400).json({
        error: 'Missing required fields: platform, version, build_number'
      });
    }
    
    if (!APP_VERSIONS[platform]) {
      return res.status(400).json({
        error: `Invalid platform: ${platform}. Supported platforms: ${Object.keys(APP_VERSIONS).join(', ')}`
      });
    }
    
    // Update version information
    APP_VERSIONS[platform] = {
      ...APP_VERSIONS[platform],
      latest_version: version,
      latest_build_number: build_number,
      update_required: update_required || false,
      update_message: message || APP_VERSIONS[platform].update_message,
      download_url: download_url || APP_VERSIONS[platform].download_url,
    };
    
    console.log(`✅ Updated ${platform} version to ${version} (build ${build_number})`);
    
    res.json({
      success: true,
      message: `Updated ${platform} version to ${version}`,
      version_info: APP_VERSIONS[platform]
    });
  } catch (error) {
    console.error('❌ Error updating app version:', error);
    res.status(500).json({
      error: 'Failed to update app version',
      message: error.message
    });
  }
});

/**
 * @route   GET /api/app/version/info
 * @desc    Get current version information for all platforms
 * @access  Public
 */
router.get('/info', async (req, res) => {
  try {
    res.json({
      platforms: APP_VERSIONS,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('❌ Error getting version info:', error);
    res.status(500).json({
      error: 'Failed to get version information',
      message: error.message
    });
  }
});

/**
 * Detect platform from user agent string
 */
function _detectPlatform(userAgent) {
  const ua = userAgent.toLowerCase();
  
  // Check for SNS-Rooster app with platform info first
  if (ua.includes('sns-rooster') && ua.includes('(android)')) {
    return 'android';
  } else if (ua.includes('sns-rooster') && ua.includes('(ios)')) {
    return 'ios';
  } else if (ua.includes('sns-rooster') && ua.includes('(web)')) {
    return 'web';
  }
  
  // Fallback to general platform detection
  if (ua.includes('android')) {
    return 'android';
  } else if (ua.includes('iphone') || ua.includes('ipad') || ua.includes('ipod')) {
    return 'ios';
  } else if (ua.includes('flutter') && (ua.includes('android') || ua.includes('mobile'))) {
    // Flutter mobile app
    return 'android';
  } else if (ua.includes('flutter') && ua.includes('web')) {
    // Flutter web app
    return 'web';
  } else if (ua.includes('chrome') || ua.includes('firefox') || ua.includes('safari') || ua.includes('edge')) {
    // Browser-based apps
    return 'web';
  } else {
    // Default to web for browser-based apps
    return 'web';
  }
}

/**
 * Compare version numbers
 */
function _compareVersions(currentVersion, currentBuild, latestVersion, latestBuild) {
  try {
    const currentParts = currentVersion.split('.').map(Number);
    const latestParts = latestVersion.split('.').map(Number);
    
    // Compare major.minor.patch
    for (let i = 0; i < 3; i++) {
      const current = currentParts[i] || 0;
      const latest = latestParts[i] || 0;
      
      if (latest > current) return true;
      if (latest < current) return false;
    }
    
    // If versions are equal, compare build numbers
    const currentBuildNum = parseInt(currentBuild) || 0;
    const latestBuildNum = parseInt(latestBuild) || 0;
    
    return latestBuildNum > currentBuildNum;
  } catch (error) {
    console.error('❌ Error comparing versions:', error);
    return false;
  }
}

/**
 * Check if update is required (critical)
 */
function _isUpdateRequired(currentVersion, currentBuild, minRequiredVersion, minRequiredBuild) {
  try {
    const currentParts = currentVersion.split('.').map(Number);
    const minParts = minRequiredVersion.split('.').map(Number);
    
    // Compare major.minor.patch
    for (let i = 0; i < 3; i++) {
      const current = currentParts[i] || 0;
      const min = minParts[i] || 0;
      
      if (current < min) return true;
      if (current > min) return false;
    }
    
    // If versions are equal, compare build numbers
    const currentBuildNum = parseInt(currentBuild) || 0;
    const minBuildNum = parseInt(minRequiredBuild) || 0;
    
    return currentBuildNum < minBuildNum;
  } catch (error) {
    console.error('❌ Error checking if update is required:', error);
    return false;
  }
}

module.exports = router; 





