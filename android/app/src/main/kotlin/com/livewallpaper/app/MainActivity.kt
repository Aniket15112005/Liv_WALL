package com.livewallpaper.app

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.livewallpaper.app/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // Stores the processed video's path, then hands off to the
                // system's "set live wallpaper" flow. Android requires the
                // user to confirm this themselves in a system dialog — no
                // app is allowed to silently set a live wallpaper.
                "setLiveWallpaper" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "Missing video path", null)
                        return@setMethodCallHandler
                    }

                    try {
                        WallpaperPrefs.setActiveVideoPath(this@MainActivity, path)

                        // Nudge an already-running instance of our wallpaper
                        // (if the user is switching clips without leaving
                        // the home screen) to reload immediately.
                        sendBroadcast(
                            Intent(VideoWallpaperService.ACTION_RELOAD_WALLPAPER).apply {
                                setPackage(packageName)
                            }
                        )

                        val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                            putExtra(
                                WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                ComponentName(
                                    this@MainActivity,
                                    VideoWallpaperService::class.java
                                )
                            )
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WALLPAPER_ERROR", e.message, null)
                    }
                }

                // Compares the currently active system wallpaper service
                // against ours, so the Flutter UI can tell if what's on the
                // home screen right now was actually set by this app.
                "isLiveWallpaperActive" -> {
                    try {
                        val wallpaperManager = WallpaperManager.getInstance(this)
                        val info = wallpaperManager.wallpaperInfo
                        val isOurs = info != null &&
                            info.serviceName == VideoWallpaperService::class.java.name
                        result.success(isOurs)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                // Clears our stored active video and reverts the home
                // screen to the system default wallpaper. This is the only
                // OS-sanctioned way to remove a live wallpaper — there is
                // no way to do this without going through WallpaperManager.
                "clearLiveWallpaper" -> {
                    try {
                        WallpaperPrefs.clear(this@MainActivity)
                        WallpaperManager.getInstance(this).clear()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CLEAR_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
