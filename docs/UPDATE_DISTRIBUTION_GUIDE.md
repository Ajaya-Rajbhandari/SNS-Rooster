# 🔄 SNS Rooster Update Distribution Guide

## 📱 How Users Get Updates

### **Automatic Update Detection**
- App checks for updates on startup
- Version comparison between current and latest versions
- Users receive update notifications automatically

### **Update Flow**
1. **Notification**: User sees update alert in app
2. **Download**: User clicks "Update" button
3. **Installation**: User downloads and installs APK manually

## 🌐 **Multiple Download Sources**

### **Primary Sources**
1. **Direct Server Download**: `https://sns-rooster.onrender.com/api/app/download/android/file`
2. **GitHub Releases**: `https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/latest/download/sns-rooster.apk`
3. **Google Play Store**: `https://play.google.com/store/apps/details?id=com.snstech.sns_rooster`

### **Alternative Sources**
- **Website**: `https://sns-rooster.com/downloads/sns-rooster.apk`
- **Web App**: `https://sns-rooster-8ccz5.web.app`

## 🚀 **Update Distribution Methods**

### **1. GitHub Releases (Recommended)**
```bash
# Create a new release
git tag v1.0.14
git push origin v1.0.14

# Upload APK to GitHub release
# - Go to GitHub Releases page
# - Upload sns-rooster-v1.0.14.apk
# - Update release notes
```

### **2. Server Upload**
```bash
# Upload APK to server
scp sns-rooster-v1.0.14.apk user@server:/path/to/uploads/apk/

# Update version info via API
curl -X POST https://sns-rooster.onrender.com/api/app/version/update \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "android",
    "version": "1.0.14",
    "build_number": "14",
    "update_required": false,
    "message": "New version with bug fixes and improvements"
  }'
```

### **3. Google Play Store**
- Upload APK to Google Play Console
- Set up staged rollout
- Update store listing

## 📋 **Update Process Checklist**

### **Before Release**
- [ ] Test APK thoroughly
- [ ] Update version numbers in code
- [ ] Generate signed APK
- [ ] Prepare release notes

### **During Release**
- [ ] Upload APK to GitHub Releases
- [ ] Update server version info
- [ ] Test update flow
- [ ] Monitor download statistics

### **After Release**
- [ ] Monitor user feedback
- [ ] Track update adoption rate
- [ ] Address any issues
- [ ] Plan next release

## 🔧 **Technical Implementation**

### **Version Check API**
```javascript
GET /api/app/version/check?version=1.0.13&build=13

Response:
{
  "current_version": "1.0.13",
  "latest_version": "1.0.14",
  "update_available": true,
  "download_url": "https://sns-rooster.onrender.com/api/app/download/android/file",
  "alternative_downloads": [
    "https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/latest/download/sns-rooster.apk",
    "https://play.google.com/store/apps/details?id=com.snstech.sns_rooster"
  ]
}
```

### **Download API**
```javascript
GET /api/app/download/android/file
// Returns APK file for direct download
```

## 📊 **Monitoring & Analytics**

### **Update Metrics**
- Update adoption rate
- Download success rate
- User feedback
- Error reports

### **Tools**
- Google Analytics
- Firebase Analytics
- Custom logging
- User feedback system

## 🛠 **Troubleshooting**

### **Common Issues**
1. **Download fails**: Check server availability
2. **Installation fails**: Verify APK signature
3. **Update not showing**: Check version comparison logic

### **Fallback Options**
- Multiple download sources
- Manual download instructions
- Support contact information

## 📞 **Support**

For update-related issues:
- **Email**: support@snstechservices.com.au
- **GitHub**: Create issue on repository
- **Documentation**: Check this guide

---

**Last Updated**: August 6, 2024
**Version**: 1.0 