# SNS Rooster Project Structure

## Frontend (Flutter)
```
sns_rooster/
├── lib/                    # Main Flutter application code
│   ├── services/           # Business logic services
│   │   └── app_update_service.dart  # App update system
│   ├── screens/            # UI screens
│   │   └── login/          # Login screen with version display
│   └── utils/              # Utility classes
│       └── global_navigator.dart    # Global navigation support
├── scripts/                # Automation scripts
│   ├── deploy-app-update.ps1        # Automated deployment
│   ├── test-login-version-display.ps1 # Testing scripts
│   └── debug-update-button.ps1      # Debugging scripts
├── test/                   # Flutter tests
├── web/                    # Web-specific code
├── android/               # Android-specific code
├── ios/                   # iOS-specific code
├── windows/               # Windows-specific code
├── macos/                 # macOS-specific code
├── linux/                 # Linux-specific code
├── assets/               # Static assets (images, fonts, etc.)
└── pubspec.yaml          # Flutter dependencies
```

## Backend (Node.js)
```
rooster-backend/
├── routes/               # API route handlers
│   ├── appVersionRoutes.js    # App version management
│   └── appDownloadRoutes.js   # APK download endpoints
├── downloads/            # APK file storage
│   └── sns-rooster.apk   # Latest APK file
├── models/              # Data models
├── middleware/          # Express middleware
├── scripts/            # Utility scripts
└── server.js           # Main server file
```

## Documentation
```
docs/
├── api/                # API documentation
│   └── API_CONTRACT.md # API and data model specifications
├── architecture/       # System architecture docs
│   └── PROJECT_STRUCTURE.md
├── images/            # Documentation images
├── APP_UPDATE_WORKFLOW.md      # Complete app update workflow
├── QUICK_UPDATE_GUIDE.md       # Quick reference for updates
├── UPDATE_SYSTEM_SUMMARY.md    # App update system overview
└── README.md         # Project documentation
```

## Development Tools
- `.vscode/`           # VS Code settings
- `.dart_tool/`        # Dart tooling
- `.git/`              # Git repository
- `.gitignore`         # Git ignore rules
- `analysis_options.yaml` # Dart analysis options
- `devtools_options.yaml` # Flutter DevTools options

## Build and Dependencies
- `pubspec.yaml`       # Flutter dependencies
- `pubspec.lock`       # Flutter dependency lock file
- `package.json`       # Node.js dependencies
- `package-lock.json`  # Node.js dependency lock file

## Notes
- All configuration files should be in the root directory
- Platform-specific code should be in their respective directories
- Documentation should be kept up to date in the `docs/` directory
- Build artifacts and logs should be ignored in `.gitignore`

## 🚨 Critical Workflows

### App Update System
- **Automated Script**: `sns_rooster/scripts/deploy-app-update.ps1`
- **Complete Workflow**: `docs/APP_UPDATE_WORKFLOW.md`
- **Quick Reference**: `docs/QUICK_UPDATE_GUIDE.md`
- **Reminder**: `APP_UPDATE_REMINDER.md` (root level)

**IMPORTANT**: Every time new features are added to the Flutter app, the app update workflow MUST be followed to ensure the update system works correctly. 