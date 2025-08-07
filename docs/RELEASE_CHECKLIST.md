# 📋 SNS Rooster Release Checklist

## 🚀 Pre-Release Checklist

### Code Quality
- [ ] All tests pass
- [ ] Code review completed
- [ ] No critical bugs in current version
- [ ] Performance testing completed
- [ ] Security audit passed

### Version Management
- [ ] Update version in `pubspec.yaml`
- [ ] Update build number
- [ ] Update version in backend routes
- [ ] Check version consistency across all files

### Documentation
- [ ] Update changelog
- [ ] Update API documentation (if needed)
- [ ] Update user documentation (if needed)
- [ ] Prepare release notes

### Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] UI tests pass
- [ ] Manual testing on multiple devices
- [ ] Test update notification system
- [ ] Test download functionality

## 🔨 Build Process

### APK Build
- [ ] Clean previous builds
- [ ] Update dependencies
- [ ] Build release APK
- [ ] Verify APK size is reasonable (<100MB for GitHub)
- [ ] Test APK installation
- [ ] Verify APK signature
- [ ] **MANUAL STEP:** Upload APK to GitHub Releases

### Release Files
- [ ] Create release directory
- [ ] **NOTE:** APK files are excluded from Git (LFS budget protection)
- [ ] Generate SHA256 hash (optional)
- [ ] Create release notes
- [ ] Create release summary

## 🏷️ Git Operations

### Version Control
- [ ] Commit all changes
- [ ] Create release tag
- [ ] Push changes to main branch
- [ ] Push tags to remote
- [ ] Verify tag creation

### Branch Management
- [ ] Merge feature branches (if any)
- [ ] Update develop branch
- [ ] Clean up feature branches
- [ ] Update release notes in main branch

## 🌐 Server Updates

### Backend Configuration
- [ ] Update version info via API
- [ ] Verify version check endpoint
- [ ] Test download endpoint
- [ ] Update alternative download URLs

### Monitoring
- [ ] Check server logs
- [ ] Verify API endpoints are working
- [ ] Test notification system
- [ ] Monitor error rates

## 📱 Distribution

### GitHub Releases (Manual Upload)
- [ ] Create new release on GitHub
- [ ] **MANUAL STEP:** Upload APK file to GitHub Releases
- [ ] Add release notes
- [ ] Mark as latest release
- [ ] Verify download links work
- [ ] Test APK download from GitHub

### Alternative Sources
- [ ] Update website download links
- [ ] Update Play Store listing (if applicable)
- [ ] Update documentation links
- [ ] Test all download sources

## 📊 Post-Release

### Monitoring
- [ ] Monitor download statistics
- [ ] Track update adoption rate
- [ ] Monitor error reports
- [ ] Check user feedback
- [ ] Monitor server performance

### Support
- [ ] Prepare support team
- [ ] Update FAQ if needed
- [ ] Monitor support channels
- [ ] Address reported issues

### Analytics
- [ ] Check analytics dashboard
- [ ] Monitor crash reports
- [ ] Track user engagement
- [ ] Analyze update success rate

## 🔄 Rollback Plan

### Emergency Rollback
- [ ] Identify rollback trigger conditions
- [ ] Prepare rollback script
- [ ] Test rollback process
- [ ] Document rollback procedures

### Communication
- [ ] Prepare rollback announcement
- [ ] Update status page
- [ ] Notify stakeholders
- [ ] Communicate with users

## 📞 Emergency Contacts

### Technical Team
- **Lead Developer:** [Contact Info]
- **DevOps:** [Contact Info]
- **QA Lead:** [Contact Info]

### Support Team
- **Support Email:** support@snstechservices.com.au
- **Emergency Hotline:** [Phone Number]

## 🎯 Success Metrics

### Release Success Criteria
- [ ] 95%+ successful downloads
- [ ] <1% crash rate
- [ ] <5% rollback rate
- [ ] Positive user feedback
- [ ] No critical security issues

### Timeline
- **Release Day:** [Date]
- **Monitoring Period:** [Duration]
- **Success Review:** [Date]

---

**Last Updated:** [Date]  
**Version:** 1.0 