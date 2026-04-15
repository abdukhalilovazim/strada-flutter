package uz.pizzastrada.app

import io.flutter.embedding.android.FlutterActivity
import com.yandex.mapkit.MapKitFactory

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        MapKitFactory.setApiKey("5a208825-198a-478f-bad4-2c686c374f08")
        super.onCreate(savedInstanceState)
    }
}
