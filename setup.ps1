# Quick Setup Script
# Run this after cloning the repository

Write-Host "Setting up Ridooo project..." -ForegroundColor Green

# Check if .env exists
if (-Not (Test-Path ".env")) {
    Write-Host "Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "✓ .env created. Please edit it with your actual API keys." -ForegroundColor Cyan
} else {
    Write-Host "✓ .env already exists" -ForegroundColor Green
}

# Check if android/local.properties exists
if (-Not (Test-Path "android/local.properties")) {
    Write-Host "Creating android/local.properties from template..." -ForegroundColor Yellow
    Copy-Item "android/local.properties.example" "android/local.properties"
    Write-Host "✓ android/local.properties created. Please edit it with your paths and API keys." -ForegroundColor Cyan
} else {
    Write-Host "✓ android/local.properties already exists" -ForegroundColor Green
}

# Check if ios/Runner/GeneratedConfig.plist exists
if (-Not (Test-Path "ios/Runner/GeneratedConfig.plist")) {
    Write-Host "Creating ios/Runner/GeneratedConfig.plist from template..." -ForegroundColor Yellow
    Copy-Item "ios/Runner/GeneratedConfig.plist.example" "ios/Runner/GeneratedConfig.plist"
    Write-Host "✓ ios/Runner/GeneratedConfig.plist created. Please edit it with your API key." -ForegroundColor Cyan
} else {
    Write-Host "✓ ios/Runner/GeneratedConfig.plist already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installing dependencies..." -ForegroundColor Green
flutter pub get

Write-Host ""
Write-Host "Setup complete! 🎉" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit .env with your Supabase and Google Maps API keys"
Write-Host "2. Edit android/local.properties with your SDK paths and API key"
Write-Host "3. Edit ios/Runner/GeneratedConfig.plist with your API key"
Write-Host "4. Run: flutter run"
Write-Host ""
Write-Host "See ENV_SETUP.md for detailed instructions." -ForegroundColor Cyan
