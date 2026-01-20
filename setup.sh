#!/bin/bash
# Quick Setup Script for Unix-based systems
# Run this after cloning the repository

echo "Setting up Ridooo project..."

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✓ .env created. Please edit it with your actual API keys."
else
    echo "✓ .env already exists"
fi

# Check if android/local.properties exists
if [ ! -f "android/local.properties" ]; then
    echo "Creating android/local.properties from template..."
    cp android/local.properties.example android/local.properties
    echo "✓ android/local.properties created. Please edit it with your paths and API keys."
else
    echo "✓ android/local.properties already exists"
fi

# Check if ios/Runner/GeneratedConfig.plist exists
if [ ! -f "ios/Runner/GeneratedConfig.plist" ]; then
    echo "Creating ios/Runner/GeneratedConfig.plist from template..."
    cp ios/Runner/GeneratedConfig.plist.example ios/Runner/GeneratedConfig.plist
    echo "✓ ios/Runner/GeneratedConfig.plist created. Please edit it with your API key."
else
    echo "✓ ios/Runner/GeneratedConfig.plist already exists"
fi

echo ""
echo "Installing dependencies..."
flutter pub get

echo ""
echo "Setup complete! 🎉"
echo ""
echo "Next steps:"
echo "1. Edit .env with your Supabase and Google Maps API keys"
echo "2. Edit android/local.properties with your SDK paths and API key"
echo "3. Edit ios/Runner/GeneratedConfig.plist with your API key"
echo "4. Run: flutter run"
echo ""
echo "See ENV_SETUP.md for detailed instructions."
