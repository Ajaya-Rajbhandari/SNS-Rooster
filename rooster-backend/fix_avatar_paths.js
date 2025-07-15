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
  
  // Find users with various malformed avatar paths
  const users = await User.find({
    $or: [
      { avatar: { $regex: '^/api/uploads/' } },
      { profilePicture: { $regex: '^/api/uploads/' } },
      { avatar: { $regex: '/opt/render/project/src/rooster-backend/uploads/avatars/' } },
      { profilePicture: { $regex: '/opt/render/project/src/rooster-backend/uploads/avatars/' } }
    ]
  });
  
  console.log(`Found ${users.length} users to fix.`);
  
  for (const user of users) {
    let changed = false;
    
    // Fix /api/uploads/ paths
    if (user.avatar && user.avatar.startsWith('/api/uploads/')) {
      user.avatar = user.avatar.replace('/api/uploads/', '/uploads/');
      changed = true;
      console.log(`Fixed avatar path for ${user.email}: ${user.avatar}`);
    }
    
    if (user.profilePicture && user.profilePicture.startsWith('/api/uploads/')) {
      user.profilePicture = user.profilePicture.replace('/api/uploads/', '/uploads/');
      changed = true;
      console.log(`Fixed profilePicture path for ${user.email}: ${user.profilePicture}`);
    }
    
    // Fix production server paths
    if (user.avatar && user.avatar.includes('/opt/render/project/src/rooster-backend/uploads/avatars/')) {
      user.avatar = user.avatar.replace('/opt/render/project/src/rooster-backend/uploads/avatars/', '/uploads/avatars/');
      changed = true;
      console.log(`Fixed production avatar path for ${user.email}: ${user.avatar}`);
    }
    
    if (user.profilePicture && user.profilePicture.includes('/opt/render/project/src/rooster-backend/uploads/avatars/')) {
      user.profilePicture = user.profilePicture.replace('/opt/render/project/src/rooster-backend/uploads/avatars/', '/uploads/avatars/');
      changed = true;
      console.log(`Fixed production profilePicture path for ${user.email}: ${user.profilePicture}`);
    }
    
    if (changed) {
      await user.save();
      console.log(`✅ Saved changes for user ${user.email}`);
    }
  }
  
  await mongoose.disconnect();
  console.log('🎉 All avatar paths fixed!');
}

fixAvatarPaths().catch(err => {
  console.error('Error fixing avatar paths:', err);
  process.exit(1);
});
