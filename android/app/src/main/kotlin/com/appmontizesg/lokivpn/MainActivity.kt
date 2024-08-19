package com.appmontizesg.lokivpn

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin

class MainActivity : FlutterFragmentActivity() {
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == 24 && resultCode == Activity.RESULT_OK) {
            OpenVPNFlutterPlugin.connectWhileGranted(true)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
