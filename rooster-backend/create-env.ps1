# Create .env file with real credentials
$envContent = @"
# =============================================================================
# DATABASE CONFIGURATION
MONGODB_URI=mongodb+srv://ajaya:Rx5IfjM5G32uws52@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0

# JWT CONFIGURATION
JWT_SECRET=5b990024ffc80d003af6e100d704f86372442f298db47ba03b3de14a94179578b0b5fbe0a97f69bf377d38ce19

# FIREBASE CONFIGURATION
FIREBASE_PROJECT_ID=sns-rooster-8cca5
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@sns-rooster-8cca5.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDNXEjLBbW00i6b
xmkX/3lzYlLSWnfgUhDYcIC4R5uY/Q4G4MvDHqfHZUxw33fhatnBPOAg/nZRwvzi
lcK7uKeQDuQtQOk1eYfVauPDqSkPwYzczR6ehfRaSEZeQodJ7/9F2TZJBzVbKAs9
JPNVPZVai6QC/CBKOouYujEeWMFX5lbNImYYw2xcyu8zCQve75wqK0RLBvLaFI+e
V+Av//nMBK13dm8PFL9DxVw97kkHhR/BLQuMfMNn2+3RFBj0iO77BC0slyO8b5zX
/sZ7zcf6qqhYjtkj9uIrXYUqRmv/fQJ6enc05Bnm4NbtVTaaAuYJcGDZEP/vseJZ
Iy2rdviPAgMBAAECggEAPHJmANBw8EUPsA2CYKxzuMlfvIghkfdF+xd+Y/+75pfR
+adQguHym8gO7IhylnjnmLAM/tk3xZBB9IYFeFD9jXM8qa9aFcHsgB7C5RRVQEyF
5HZCBYJDbxGoGNW3UcWhW5N4nZ1QEMFkMX6/Wz9Rx4Gj6LcC4CaEcZOYoqiYXIEq
O/n0Djsu3lnROGFFxhPEmqBZjAFCjK1HCINOOkUvQl+ZyF/him8JYHkab2+w+awE
GEMNE/zmkx64StB+abn1OgC/tWM4y/LG7cL5XJC5YNy/QgFYBwiTcmNKvx62+6k3
PCgqGJ+wNNUn/nyuvFQkHHtnFxfrEzWkUw8VmfaAiQKBgQD8tPXIAANZtdRhrsUz
nc81c/gJcyJ1r19fr3FQbztnL/OcQdVtCA0G9YWBOXT+WIVWKD0mqGGKgPTVP4Ey
b4a5JSD3KoXcAP8+Sri425/Rem74X+Z67J22rmOPWd/dzTpQd7K5OOs/QfTE/EW7
NWwn936kCZUXG+QWqc+S2sxpeQKBgQDQCV/36uIf1hXN9q3c68t+Cwwm2J//aes1
tXJpl4RNSfgF77CTXxt4KUVKiATLnG1ElKfDTVtwUgpbi7sboFW7BzjUzDxJ0fBG
VrtmAjJG0jfnU7huj5CArjHO+nFldOkPKrM43izngo16bxIiGa79LXshBKjxD2gf
ALetdb14RwKBgFSvJ7YwGu9TOarKcJdNiQS2qiYwiRm6/VEJcAWuYM/Bh/eTMDxr
eEIewPB/Gq+pZnVq4qMzxgwuDt3vfBI0wYcF5Dgv7c++Hcr4K1L3dmUyjEF7kbcb
1/ZCFmcRjS28+o/ArQnZAyydo7Lnf06vJmF2VOAPvgCSfisCGOdznxCxAoGBAIqp
VQAH3MRfi5UGkIgp2i6e6nCR/sLdNFtOH35l8VcasGg0hLsVr1d+GqM82gVktCf7
9X3ld8b7x8+Q6RvW2I2amLStlJmXhtE7ShkJ6bzurThQwyNeKXC7qpNMtnxrWlQz
n9WNsNx2Vhp/IdT8zXgO8nzlgD18iWfwsHy7d5hNAoGAfknW/hp+oUemQIJ0nwpX
JZpFB/A7w5OdxCkYzgGgvz/scZpzdghk+FwCRi0twKP3mdeRgaB43Y0cWNv3bKxo
ZpBs5pjszq1rp/p5D6cWLOXZ2N3fDYeypAAF11G0m722o6arQreFsa8FRyy9IgRY
0ucnRuhSBiydaNJ0GoUkF/k=
-----END PRIVATE KEY-----"

# EMAIL CONFIGURATION
EMAIL_PROVIDER=gmail
SMTP_HOST=smtp.gmail.com
SMTP_PASS=pfzo vbnj csif ykxq
SMTP_USER=your-email@gmail.com

# GOOGLE MAPS CONFIGURATION
GOOGLE_MAPS_API_KEY=AIzaSyCjFtMPrWvzlLcOZHhHAvNpVMwGVAFtcAo

# SERVER CONFIGURATION
PORT=5000
NODE_ENV=development

# CORS CONFIGURATION
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:8080,http://localhost:5000,https://sns-rooster.onrender.com,https://sns-rooster-8cca5.web.app

# TESTING CONFIGURATION
TEST_PASSWORD=test123
"@

# Write the content to .env file
$envContent | Out-File -FilePath ".env" -Encoding UTF8

Write-Host ".env file created successfully with real credentials!" -ForegroundColor Green
Write-Host "File location: $(Get-Location)\.env" -ForegroundColor Cyan 