// Script to fix all users' avatar/profilePicture paths in the database
// Usage: node fix_avatar_paths.js

const mongoose = require('mongoose');
const User = require('./models/User');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

async function fixAvatarPaths() {
  await mongoose.connect(MONGODB_URI);
  const users = await User.find({
    $or: [
      { avatar: { $regex: '^/api/uploads/' } },
      { profilePicture: { $regex: '^/api/uploads/' } }
    ]
  });
  console.log(`Found ${users.length} users to fix.`);
  for (const user of users) {
    let changed = false;
    if (user.avatar && user.avatar.startsWith('/api/uploads/')) {
      user.avatar = user.avatar.replace('/api/uploads/', '/uploads/');
      changed = true;
    }
    if (user.profilePicture && user.profilePicture.startsWith('/api/uploads/')) {
      user.profilePicture = user.profilePicture.replace('/api/uploads/', '/uploads/');
      changed = true;
    }
    if (changed) {
      await user.save();
      console.log(`Fixed user ${user.email}`);
    }
  }
  await mongoose.disconnect();
  console.log('All done!');
}

fixAvatarPaths().catch(err => {
  console.error('Error fixing avatar paths:', err);
  process.exit(1);
});
