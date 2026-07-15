package com.livewallpaper.app

import android.content.Context
import android.content.SharedPreferences

/**
 * Native-side storage for the active wallpaper's video path. Deliberately
 * separate from Flutter's `shared_preferences` plugin storage so the
 * wallpaper engine (which runs outside the Flutter engine's lifecycle) can
 * read it directly and reliably, without depending on Flutter plugin
 * internals staying stable.
 */
object WallpaperPrefs {
    private const val PREFS_NAME = "live_wallpaper_native_prefs"
    private const val KEY_ACTIVE_VIDEO_PATH = "active_video_path"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun setActiveVideoPath(context: Context, path: String?) {
        prefs(context).edit().putString(KEY_ACTIVE_VIDEO_PATH, path).apply()
    }

    fun getActiveVideoPath(context: Context): String? =
        prefs(context).getString(KEY_ACTIVE_VIDEO_PATH, null)

    fun clear(context: Context) {
        prefs(context).edit().remove(KEY_ACTIVE_VIDEO_PATH).apply()
    }
}
