package uz.pizzastrada.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.yandex.mapkit.MapKitFactory

class MainActivity : FlutterActivity() {
    private val CHANNEL = "uz.pizzastrada.app/yandex_map"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "initMap") {
                val apiKey = call.argument<String>("apiKey")
                if (apiKey != null) {
                    try {
                        MapKitFactory.setApiKey(apiKey)
                        MapKitFactory.initialize(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INIT_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "API key is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
