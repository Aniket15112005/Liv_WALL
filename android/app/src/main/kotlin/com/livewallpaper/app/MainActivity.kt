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
                "applyWallpaper" -> {
                    val wallpaperId = call.argument<String>("wallpaperId") ?: ""
                    val wallpaperType = call.argument<Int>("wallpaperType") ?: 0
                    val colors = call.argument<List<Int>>("colors") ?: emptyList()

                    // Store wallpaper settings for the service to read
                    WallpaperSettings.wallpaperId = wallpaperId
                    WallpaperSettings.wallpaperType = wallpaperType
                    WallpaperSettings.colors = colors

                    try {
                        val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                            putExtra(
                                WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                ComponentName(
                                    this@MainActivity,
                                    LiveWallpaperService::class.java
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

                "isWallpaperServiceEnabled" -> {
                    try {
                        val wallpaperManager = WallpaperManager.getInstance(this)
                        val isLiveWallpaper = wallpaperManager.wallpaperInfo != null
                        result.success(isLiveWallpaper)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "openWallpaperPicker" -> {
                    try {
                        val intent = Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        // Fallback to live wallpaper list
                        try {
                            val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                                putExtra(
                                    WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                    ComponentName(
                                        this@MainActivity,
                                        LiveWallpaperService::class.java
                                    )
                                )
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(null)
                        } catch (ex: Exception) {
                            result.error("PICKER_ERROR", ex.message, null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}

// Singleton to pass settings from Flutter to the WallpaperService
object WallpaperSettings {
    var wallpaperId: String = "particles_blue"
    var wallpaperType: Int = 0
    var colors: List<Int> = listOf(0xFF0D47A1.toInt(), 0xFF1565C0.toInt(), 0xFF42A5F5.toInt())
}
