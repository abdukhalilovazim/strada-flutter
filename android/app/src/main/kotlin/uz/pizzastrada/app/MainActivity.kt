package uz.pizzastrada.app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.yandex.mapkit.MapKitFactory

class MainActivity : FlutterActivity() {
    private val CHANNEL = "uz.pizzastrada.app/yandex_map"
    private val TAG = "YandexMapNative"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "initMap") {
                // Key is already set in onCreate, but we success the call for Flutter side
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
