# Barter Gang App

A Flutter mobile application that analyzes product images and provides secondhand price estimates using AI-powered image recognition and market research.

## Features

- 📸 **Image Analysis**: Upload product images for AI-powered identification
- 🔍 **Market Research**: Automatic search for similar products and pricing
- 💰 **Price Estimation**: AI-generated secondhand price recommendations
- 📱 **Cross-Platform**: Runs on Android, iOS, Web, and Desktop
- 🌐 **Real-time API**: Node.js backend with Express server
- 🔄 **Retry Logic**: Automatic retry for failed API requests
- 🛡️ **Error Handling**: Comprehensive error handling and user feedback

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Node.js with Express
- **AI Services**: BytePlus ARK API for image analysis
- **Search API**: SerpAPI for market research
- **Platform**: Cross-platform mobile and web application

## Prerequisites

### Required Software

1. **Node.js** (v20.17.0 or later)
   - Download from: https://nodejs.org/
   - Verify: `node --version` and `npm --version`

2. **Flutter SDK** (Latest stable version)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your system PATH
   - Verify: `flutter --version`

3. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio
   - Install Android SDK and create an Android Virtual Device (AVD)
   - Configure Android SDK path in Flutter: `flutter config --android-sdk <path>`

4. **Git** (for version control)
   - Download from: https://git-scm.com/

### API Keys Required

You'll need to obtain API keys from these services:

1. **BytePlus ARK API**
   - Sign up at: https://console.volcengine.com/ark
   - Create a model endpoint and get your API key

2. **SerpAPI**
   - Sign up at: https://serpapi.com/
   - Get your API key from the dashboard

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd smart_price_checker_app
```

### 2. Install Dependencies

#### Node.js Dependencies
```bash
npm install
```

#### Flutter Dependencies
```bash
flutter pub get
```

### 3. Configure API Keys

Update the API keys in both `server.js` and `smart_price_checker.js`:

```javascript
// In server.js and smart_price_checker.js
const model = "your-ark-model-endpoint-id"; // Replace with your ARK model ID
const ARK_API_KEY = "your-ark-api-key-here"; // Replace with your ARK API key
const SERPAPI_API_KEY = "your-serpapi-key-here"; // Replace with your SerpAPI key
const ARK_BASE_URL = "https://ark.ap-southeast.bytepluses.com/api/v3"; // ARK API base URL
```

### 4. Setup Development Environment

#### Flutter Doctor Check
```bash
flutter doctor
```
Resolve any issues reported by Flutter doctor.

#### Android Emulator Setup
```bash
# List available devices
flutter devices

# If no devices available, create one in Android Studio:
# Tools > AVD Manager > Create Virtual Device
```

### 5. Network Configuration (Windows)

For Android emulator connectivity, add Windows Firewall exception:

```cmd
# Run as Administrator
netsh advfirewall firewall add rule name="Node.js Port 3000" dir=in action=allow protocol=TCP localport=3000
```

## Running the Application

### Method 1: Using npm Scripts (Recommended)

```bash
# Terminal 1: Start the backend server
npm run server

# Terminal 2: Start the Flutter app
flutter run
```

### Method 2: Manual Startup

```bash
# Terminal 1: Start server manually
node server.js

# Terminal 2: Start Flutter app
flutter run
```

### Expected Output

**Server Terminal:**
```
Barter Gang API server running on port 3000
Health check: http://localhost:3000/health
Main endpoint: POST http://localhost:3000/analyze-price
```

**Flutter Terminal:**
```
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h Repeat this help message.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

## Usage

1. **Launch the App**: The app will start on your connected device/emulator
2. **Check Server Status**: Look for the green server status indicator
3. **Enter Image URL**: Paste a valid image URL in the input field
4. **Analyze Price**: Tap "วิเคราะห์ราคา" (Analyze Price) button
5. **View Results**: See the AI analysis and price recommendations

## API Endpoints

### Health Check
```http
GET /health
```
Returns server status and uptime.

### Price Analysis
```http
POST /analyze-price
Content-Type: application/json

{
  "imageUrl": "https://example.com/product-image.jpg"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "imageUrl": "https://example.com/product-image.jpg",
    "identifiedItem": "iPhone 13 Pro Max 256GB",
    "searchQuery": "iPhone 13 Pro Max 256GB ราคา มือสอง",
    "searchResults": [
      {
        "title": "iPhone 13 Pro Max มือสอง ราคาดี",
        "link": "https://example.com/listing",
        "snippet": "ขาย iPhone 13 Pro Max 256GB สภาพดี ราคา 35,000 บาท"
      }
    ],
    "analysis": "คุณภาพของอุปกรณ์: ดีมาก\nราคาแนะนำ: 32,000 - 38,000 บาท",
    "tokenUsage": {
      "keyword": { "prompt_tokens": 150, "completion_tokens": 25, "total_tokens": 175 },
      "analysis": { "prompt_tokens": 800, "completion_tokens": 200, "total_tokens": 1000 }
    }
  }
}
```

## Project Structure

```
smart_price_checker_app/
├── lib/                          # Flutter app source code
│   ├── main.dart                # App entry point
│   ├── screens/                 # UI screens
│   │   ├── home_screen.dart     # Main screen with image input
│   │   └── results_screen.dart  # Results display screen
│   └── services/                # API services
│       └── price_checker_service.dart # HTTP client for API calls
├── android/                     # Android-specific configuration
│   ├── app/
│   │   └── src/main/
│   │       ├── AndroidManifest.xml # Android permissions and config
│   │       └── res/xml/
│   │           └── network_security_config.xml # Network security
├── ios/                         # iOS-specific configuration
├── web/                         # Web-specific configuration
├── windows/                     # Windows-specific configuration
├── server.js                    # Node.js Express server
├── smart_price_checker.js       # Core analysis logic
├── package.json                 # Node.js dependencies
├── pubspec.yaml                # Flutter dependencies
└── README.md                   # This file
```

## Configuration Details

### Android Network Security

The app is configured to allow HTTP connections for development:

- `android:usesCleartextTraffic="true"` in AndroidManifest.xml
- Network security config allows localhost connections
- Platform-specific URL routing (10.0.2.2:3000 for Android emulator)

### Flutter Service Configuration

The `PriceCheckerService` automatically detects the platform and uses appropriate URLs:

- **Android Emulator**: `http://10.0.2.2:3000`
- **Web/Desktop/iOS**: `http://localhost:3000`

## Troubleshooting

### Common Issues

#### 1. Connection Refused Error

**Symptoms**: App shows "Connection refused" or "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้"

**Solutions**:
- Ensure Node.js server is running on port 3000
- Check Windows Firewall allows port 3000
- Verify Android emulator can reach 10.0.2.2:3000
- Try restarting both server and Flutter app

#### 2. ARK API 400 Error

**Symptoms**: "Exception: Ark API request failed: Request failed with status code 400"

**Solutions**:
- Verify ARK API key is valid and active
- Check image URL is accessible and valid
- Ensure model endpoint ID is correct
- Check internet connection
- Wait a moment and retry (rate limiting)

#### 3. Flutter Build Issues

**Solutions**:
```bash
flutter clean
flutter pub get
flutter run
```

#### 4. Dependencies Issues

**Solutions**:
```bash
# Node.js dependencies
rm -rf node_modules
npm install

# Flutter dependencies
flutter clean
flutter pub get
```

#### 5. Android SDK Issues

**Solutions**:
```bash
flutter doctor --android-licenses
flutter config --android-sdk <path-to-android-sdk>
```

### Debug Information

The app displays debug information at the bottom of the home screen:
- Platform detection (android, web, etc.)
- Base URL being used
- Server connection status

### Logs and Monitoring

**Server Logs**: Check the terminal running `npm run server` for API request logs

**Flutter Logs**: Use `flutter logs` in a separate terminal for detailed app logs

**Network Debugging**: Use browser dev tools or Flutter DevTools for network request inspection

## Development Tips

### Hot Reload
- Press `r` in Flutter terminal for hot reload
- Press `R` for hot restart
- Use `flutter hot reload` command

### API Testing

Test the API directly using curl:

```bash
# Health check
curl http://localhost:3000/health

# Price analysis
curl -X POST http://localhost:3000/analyze-price \
  -H "Content-Type: application/json" \
  -d '{"imageUrl":"https://example.com/image.jpg"}'
```

### Performance Optimization

- The app includes retry logic with exponential backoff
- Search results are limited to 3 items to prevent oversized requests
- Timeouts are configured for both client (120s) and server (60s)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test thoroughly
4. Commit your changes: `git commit -m 'Add feature'`
5. Push to the branch: `git push origin feature-name`
6. Submit a pull request

## License

[Add your license information here]

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review server and Flutter logs
3. Create an issue in the repository
4. Include relevant error messages and system information

---

**Note**: This app requires active API keys for ARK and SerpAPI services. Ensure you have valid subscriptions and sufficient API credits for production use.