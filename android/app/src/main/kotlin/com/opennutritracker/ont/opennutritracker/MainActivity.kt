package com.opennutritracker.ont.opennutritracker

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (rather than FlutterActivity) is required by the
// health plugin: Health Connect permission requests go through
// registerForActivityResult, which needs a ComponentActivity host.
class MainActivity: FlutterFragmentActivity() {
}
