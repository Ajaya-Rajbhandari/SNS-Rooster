const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');

// APK file configuration - Updated for GitHub-first approach
const APK_CONFIG = {
  android: {
    latest_version: '1.0.14',
    latest_build_number: '14',
    // Primary download URL (GitHub Releases) - Updated with correct filename
    download_url: 'https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/latest/download/sns-rooster-v1.0.14.apk',
    // Alternative download URLs (fallback options)
    alternative_downloads: [
      'https://play.google.com/store/apps/details?id=com.snstech.sns_rooster',
      'https://sns-rooster.com/downloads/sns-rooster-v1.0.14.apk'
    ],
    // Server file path (for admin uploads only)
    file_path: path.join(__dirname, '../uploads/apk/sns-rooster-v1.0.14.apk'),
    file_size: 0,
    checksum: '',
  }
};

/**
 * @route   GET /api/app/download/android
 * @desc    Get Android APK download information
 * @access  Public
 */
router.get('/android', async (req, res) => {
  try {
    const apkInfo = APK_CONFIG.android;
    
    // Check if APK file exists
    const apkPath = apkInfo.file_path;
    if (fs.existsSync(apkPath)) {
      const stats = fs.statSync(apkPath);
      apkInfo.file_size = stats.size;
      apkInfo.checksum = await _calculateChecksum(apkPath);
    }
    
    res.json({
      version: apkInfo.latest_version,
      build_number: apkInfo.latest_build_number,
      download_url: apkInfo.download_url, // GitHub URL as primary
      alternative_downloads: apkInfo.alternative_downloads || [],
      file_size: apkInfo.file_size,
      checksum: apkInfo.checksum,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('❌ Error getting APK download info:', error);
    res.status(500).json({
      error: 'Failed to get APK download information',
      message: error.message
    });
  }
});

/**
 * @route   GET /api/app/download/android/file
 * @desc    Redirect to GitHub Releases for APK download
 * @access  Public
 */
router.get('/android/file', async (req, res) => {
  try {
    // Redirect to GitHub Releases (primary download source) - Updated with correct filename v1.0.14
    const githubUrl = 'https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/latest/download/sns-rooster-v1.0.14.apk';
    
    console.log(`📱 Redirecting APK download to GitHub: ${githubUrl}`);
    
    // Return redirect response
    res.status(302).json({
      redirect: true,
      download_url: githubUrl,
      message: 'Redirecting to GitHub Releases for download',
      alternative_downloads: APK_CONFIG.android.alternative_downloads,
      timestamp: new Date().toISOString(),
    });
    
  } catch (error) {
    console.error('❌ Error redirecting APK download:', error);
    res.status(500).json({
      error: 'Failed to redirect APK download',
      message: error.message
    });
  }
});

/**
 * @route   POST /api/app/download/upload
 * @desc    Upload new APK file (admin only)
 * @access  Private (Admin)
 */
router.post('/upload', async (req, res) => {
  try {
    // TODO: Add admin authentication middleware
    const { version, build_number, file_path } = req.body;
    
    if (!version || !build_number || !file_path) {
      return res.status(400).json({
        error: 'Missing required fields: version, build_number, file_path'
      });
    }
    
    // Update APK configuration
    APK_CONFIG.android.latest_version = version;
    APK_CONFIG.android.latest_build_number = build_number;
    APK_CONFIG.android.file_path = file_path;
    
    console.log(`✅ Updated APK to version ${version} (build ${build_number})`);
    
    res.json({
      success: true,
      message: `Updated APK to version ${version}`,
      apk_info: APK_CONFIG.android
    });
  } catch (error) {
    console.error('❌ Error uploading APK:', error);
    res.status(500).json({
      error: 'Failed to upload APK',
      message: error.message
    });
  }
});

/**
 * @route   GET /api/app/download/status
 * @desc    Get download status and statistics
 * @access  Public
 */
router.get('/status', async (req, res) => {
  try {
    const apkInfo = APK_CONFIG.android;
    const apkPath = apkInfo.file_path;
    
    let fileExists = false;
    let fileSize = 0;
    let lastModified = null;
    
    if (fs.existsSync(apkPath)) {
      const stats = fs.statSync(apkPath);
      fileExists = true;
      fileSize = stats.size;
      lastModified = stats.mtime;
    }
    
    res.json({
      platform: 'android',
      version: apkInfo.latest_version,
      build_number: apkInfo.latest_build_number,
      file_exists: fileExists,
      file_size: fileSize,
      last_modified: lastModified,
      download_url: apkInfo.download_url,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('❌ Error getting download status:', error);
    res.status(500).json({
      error: 'Failed to get download status',
      message: error.message
    });
  }
});

/**
 * Generate APK filename with version
 */
function _getApkFilename(version) {
  return `sns-rooster-v${version}.apk`;
}

/**
 * Calculate file checksum (MD5)
 */
async function _calculateChecksum(filePath) {
  try {
    const crypto = require('crypto');
    const hash = crypto.createHash('md5');
    const fileBuffer = fs.readFileSync(filePath);
    hash.update(fileBuffer);
    return hash.digest('hex');
  } catch (error) {
    console.error('❌ Error calculating checksum:', error);
    return '';
  }
}

module.exports = router; 
