package com.livewallpaper.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer

/**
 * Renders the user's chosen video as a live home screen wallpaper.
 *
 * Instead of pre-processing the video file to match every possible device
 * aspect ratio, this engine uses ExoPlayer's built-in
 * VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING against the wallpaper
 * Surface. That mode scales+crops the video to fully cover the surface
 * (like CSS `background-size: cover`), so a single processed clip always
 * fills the screen sharply regardless of the device's screen ratio.
 */
@UnstableApi
class VideoWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = VideoEngine()

    inner class VideoEngine : Engine() {
        private var player: ExoPlayer? = null
        private var currentPath: String? = null
        private var reloadReceiver: BroadcastReceiver? = null

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
            registerReloadReceiver()
        }

        override fun onSurfaceCreated(holder: SurfaceHolder) {
            super.onSurfaceCreated(holder)
            startOrReloadPlayer(holder)
        }

        override fun onSurfaceChanged(
            holder: SurfaceHolder,
            format: Int,
            width: Int,
            height: Int
        ) {
            super.onSurfaceChanged(holder, format, width, height)
            player?.setVideoSurfaceHolder(holder)
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            super.onSurfaceDestroyed(holder)
            releasePlayer()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            super.onVisibilityChanged(visible)
            if (visible) {
                player?.play()
            } else {
                player?.pause()
            }
        }

        override fun onDestroy() {
            super.onDestroy()
            releasePlayer()
            reloadReceiver?.let {
                try {
                    unregisterReceiver(it)
                } catch (_: IllegalArgumentException) {
                    // already unregistered — safe to ignore
                }
            }
            reloadReceiver = null
        }

        private fun startOrReloadPlayer(holder: SurfaceHolder) {
            val path = WallpaperPrefs.getActiveVideoPath(this@VideoWallpaperService)
            if (path.isNullOrEmpty()) {
                releasePlayer()
                return
            }
            if (player != null && path == currentPath) {
                player?.setVideoSurfaceHolder(holder)
                return
            }

            releasePlayer()
            currentPath = path

            val exoPlayer = ExoPlayer.Builder(this@VideoWallpaperService).build().apply {
                setVideoSurfaceHolder(holder)
                videoScalingMode = androidx.media3.common.C.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING
                repeatMode = androidx.media3.common.Player.REPEAT_MODE_ALL
                volume = 0f
                setMediaItem(MediaItem.fromUri(Uri.fromFile(java.io.File(path))))
                prepare()
                playWhenReady = isVisible
            }
            player = exoPlayer
        }

        private fun releasePlayer() {
            player?.release()
            player = null
            currentPath = null
        }

        /** Reloads immediately if the user changes the active video while
         * this wallpaper is already running (e.g. picks a different clip
         * without leaving the home screen). */
        private fun registerReloadReceiver() {
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    surfaceHolder?.let { startOrReloadPlayer(it) }
                }
            }
            registerReceiver(
                receiver,
                IntentFilter(ACTION_RELOAD_WALLPAPER),
                Context.RECEIVER_NOT_EXPORTED
            )
            reloadReceiver = receiver
        }
    }

    companion object {
        const val ACTION_RELOAD_WALLPAPER = "com.livewallpaper.app.ACTION_RELOAD_WALLPAPER"
    }
}
