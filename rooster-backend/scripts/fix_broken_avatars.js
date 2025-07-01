const mongoose = require('mongoose');
const path = require('path');
const fs = require('fs');
const User = require('../models/User');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const MONGODB_URI = process.env.MONGODB_URI || process.env.MONGO_URI;
const DEFAULT_AVATAR = '/uploads/avatars/default-avatar.png';

async function fixBrokenAvatars() {
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB');

  const users = await User.find({ avatar: { $exists: true, $ne: null } });
  let fixed = 0;
  for (const user of users) {
    if (user.avatar && user.avatar !== DEFAULT_AVATAR) {
      const avatarPath = path.join(__dirname, '..', user.avatar);
      if (!fs.existsSync(avatarPath)) {
        user.avatar = DEFAULT_AVATAR;
        await user.save();
        fixed++;
        console.log(`Fixed avatar for user: ${user.email}`);
      }
    }
  }
  console.log(`Done. Fixed ${fixed} users.`);
  await mongoose.disconnect();
}

fixBrokenAvatars().catch(err => {
  console.error('Error:', err);
  process.exit(1);
}); 