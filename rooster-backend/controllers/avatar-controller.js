const { Storage } = require('@google-cloud/storage');
const User = require('../models/User');

const storage = new Storage();
const bucket = storage.bucket('sns-rooster-8cca5.appspot.com');

// GET /api/avatar/:userId/signed-url
async function getAvatarSignedUrl(req, res) {
  try {
    const userId = req.params.userId;
    const requester = req.user; // set by auth middleware

    // Fetch user from DB
    const user = await User.findById(userId);
    if (!user || !user.avatar) {
      return res.status(404).json({ error: 'Avatar not found' });
    }

    // Only allow owner or admin
    if (requester.role !== 'admin' && String(requester.userId) !== String(userId)) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    // Extract filename from GCS URL
    let filename = user.avatar;
    // If avatar is a full GCS URL, extract the path after the bucket
    if (filename.startsWith('http')) {
      // Use URL to get the full path after the bucket
      const url = new URL(filename);
      filename = url.pathname.startsWith('/') ? url.pathname.slice(1) : url.pathname;
    }

    // Generate signed URL
    const [url] = await bucket.file(filename).getSignedUrl({
      version: 'v4',
      action: 'read',
      expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    });
    return res.json({ url });
  } catch (err) {
    console.error('Error generating signed avatar URL:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

module.exports = { getAvatarSignedUrl };