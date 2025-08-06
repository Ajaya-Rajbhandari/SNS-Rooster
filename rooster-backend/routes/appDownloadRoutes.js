const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');

// APK file configuration
const APK_CONFIG = {
  android: {
    latest_version: '1.0.13',
    latest_build_number: '13',
    download_url: 'https://sns-rooster.onrender.com/api/app/download/android/file',
    file_path: path.join(__dirname, '../uploads/apk/sns-rooster-v1.0.13.apk'), // Local APK file path with version
    file_size: 0, // Will be calculated dynamically
    checksum: '', // Will be calculated dynamically
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
      download_url: apkInfo.download_url,
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
 * @desc    Download Android APK file directly
 * @access  Public
 */
router.get('/android/file', async (req, res) => {
  try {
    const apkPath = APK_CONFIG.android.file_path;
    
    // Check if APK file exists
    if (!fs.existsSync(apkPath)) {
      return res.status(404).json({
        error: 'APK file not found',
        message: 'The requested APK file is not available'
      });
    }
    
    // Get file stats
    const stats = fs.statSync(apkPath);
    
    // Set headers for file download
    res.setHeader('Content-Type', 'application/vnd.android.package-archive');
    res.setHeader('Content-Disposition', `attachment; filename="sns-rooster-v${APK_CONFIG.android.latest_version}.apk"`);
    res.setHeader('Content-Length', stats.size);
    res.setHeader('Cache-Control', 'no-cache');
    
    // Stream the file
    const fileStream = fs.createReadStream(apkPath);
    fileStream.pipe(res);
    
    console.log(`📱 APK download started: ${stats.size} bytes`);
    
  } catch (error) {
    console.error('❌ Error downloading APK:', error);
    res.status(500).json({
      error: 'Failed to download APK',
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
