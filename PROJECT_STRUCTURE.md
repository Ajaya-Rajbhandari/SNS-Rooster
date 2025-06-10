# SNS Rooster Project Structure

## Frontend (Flutter)
```
sns_rooster/
├── lib/                    # Main Flutter application code
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
├── images/            # Documentation images
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