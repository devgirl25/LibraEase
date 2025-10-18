// lib/constants.dart

import 'package:flutter/material.dart';

const Color kPrimaryBrown = Color(0xFF5D4037);
const Color kLightCream = Color(0xFFFFF8E1);
const Color kScaffoldBackground = Color(0xFFD7CCC8);

// Optional: HTTP endpoint for server-side import function.
// Set this to your deployed Cloud Function URL if you want the app to
// call an HTTP import endpoint instead of using the cloud_functions package.
// Example (production): const String kImportFunctionUrl = 'https://us-central1-<proj>.cloudfunctions.net/importEbookHttp';
// For local testing with the Firebase Functions emulator run locally, use the emulator URL below.
// If you're running the Android AVD, replace 127.0.0.1 with 10.0.2.2 (AVD host loopback).
// Example emulator URL: http://127.0.0.1:5001/<PROJECT_ID>/us-central1/importEbookHttp
// Optional: Google Books API key. If you have one, set it here. Leave empty to use
// unauthenticated requests (rate-limited).
const String kGoogleBooksApiKey = '';
