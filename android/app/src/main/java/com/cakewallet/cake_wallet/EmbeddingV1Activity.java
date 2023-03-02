package com.cakewallet.cake_wallet;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.embedding.android.FlutterFragmentActivity;

import com.cakewallet.monero.CwMoneroPlugin;

public class EmbeddingV1Activity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        CwMoneroPlugin.registerWith(registrarFor("com.cakewallet.monero.CwMoneroPlugin"));
    }
}