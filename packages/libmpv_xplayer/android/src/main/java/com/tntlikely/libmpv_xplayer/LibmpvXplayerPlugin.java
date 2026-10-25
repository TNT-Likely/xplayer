/**
 * This file is a part of media_kit (https://github.com/media-kit/media-kit).
 *
 * Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by MIT license that can be found in the LICENSE file.
 */
package com.tntlikely.libmpv_xplayer;

import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Objects;
import java.io.InputStream;
import java.io.BufferedReader;
import java.util.regex.Pattern;
import java.io.InputStreamReader;
import java.util.zip.GZIPInputStream;

import android.util.Log;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import android.content.res.AssetManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;

import com.alexmercerind.mediakitandroidhelper.MediaKitAndroidHelper;

/** LibmpvXplayerPlugin */
public class LibmpvXplayerPlugin implements FlutterPlugin {
    private MethodChannel compatibilityChannel;
    static {
        // DynamicLibrary.open on Dart side may not work on some ancient devices unless System.loadLibrary is called first.
        try {
            System.loadLibrary("mpv");
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        compatibilityChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(),
                "com.tntlikely.xplayer/decoder_capabilities");
        compatibilityChannel.setMethodCallHandler((call, result) -> {
            if (!call.method.equals("queryEglCapabilities")) {
                result.notImplemented();
                return;
            }
            if (Build.VERSION.SDK_INT < 17) {
                result.success(null);
                return;
            }
            new Thread(() -> {
                java.util.Map<String, Object> capabilities = EglCapabilities.query();
                new Handler(Looper.getMainLooper()).post(() -> result.success(capabilities));
            }, "xplayer-egl-probe").start();
        });
        Log.i("media_kit", "package:libmpv_xplayer attached.");
        try {
            // Save android.content.Context for access later within MediaKitAndroidHelpers e.g. loading bundled assets.
            MediaKitAndroidHelper.setApplicationContextJava(flutterPluginBinding.getApplicationContext());
            Log.i("media_kit", "Saved application context.");
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        compatibilityChannel.setMethodCallHandler(null);
        compatibilityChannel = null;
        Log.i("media_kit", "package:libmpv_xplayer detached.");
    }
}
