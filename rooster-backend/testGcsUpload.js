const express = require('express');
const avatarUpload = require('./gcsUpload');

const app = express();

app.post('/test-upload', (req, res) => {
  avatarUpload.single('avatar')(req, res, (err) => {
    if (err) {
      console.error('Upload error:', err); // Log the full error
      return res.status(500).json({ error: err.message, details: err });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    res.json({
      message: 'File uploaded successfully!',
      fileUrl: req.file.path,
    });
  });
});

app.listen(4000, () => {
  console.log('Test upload server running on port 4000');
}); 