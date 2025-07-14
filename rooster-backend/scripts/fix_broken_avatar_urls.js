const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../models/User');

const DEFAULT_AVATAR_URL = 'https://storage.googleapis.com/sns-rooster-8cca5.firebasestorage.app/avatars/default-avatar.png';

function isValidGcsImageUrl(url) {
  return (
    typeof url === 'string' &&
    url.startsWith('https://storage.googleapis.com/sns-rooster-8cca5.firebasestorage.app/avatars/')
  );
}

async function fixAllAvatars() {
  await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');
  const users = await User.find({});
  let fixed = 0;
  for (const user of users) {
    let updated = false;
    if (!isValidGcsImageUrl(user.avatar)) {
      user.avatar = DEFAULT_AVATAR_URL;
      updated = true;
    }
    if (!isValidGcsImageUrl(user.profilePicture)) {
      user.profilePicture = DEFAULT_AVATAR_URL;
      updated = true;
    }
    if (updated) {
      await user.save();
      fixed++;
      console.log(`Fixed avatar for user: ${user.email}`);
    }
  }
  console.log(`\nFixed ${fixed} users with broken avatar/profilePicture URLs.`);
  mongoose.connection.close();
}

fixAllAvatars(); 