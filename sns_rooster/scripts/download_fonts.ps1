# Create fonts directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "assets/fonts"

# Download OpenSans fonts
$openSansUrls = @{
    "OpenSans-Italic.ttf" = "https://github.com/google/fonts/raw/main/apache/opensans/OpenSans-Italic.ttf"
    "OpenSans-BoldItalic.ttf" = "https://github.com/google/fonts/raw/main/apache/opensans/OpenSans-BoldItalic.ttf"
}

foreach ($font in $openSansUrls.GetEnumerator()) {
    Write-Host "Downloading $($font.Key)..."
    Invoke-WebRequest -Uri $font.Value -OutFile "assets/fonts/$($font.Key)"
}

# Download ProductSans fonts
$productSansUrls = @{
    "ProductSans-BoldItalic.ttf" = "https://github.com/google/fonts/raw/main/ofl/productsans/ProductSans-BoldItalic.ttf"
}

foreach ($font in $productSansUrls.GetEnumerator()) {
    Write-Host "Downloading $($font.Key)..."
    Invoke-WebRequest -Uri $font.Value -OutFile "assets/fonts/$($font.Key)"
}

Write-Host "Font download complete!" 