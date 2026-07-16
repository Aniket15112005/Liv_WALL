package com.livewallpaper.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Handler
import android.os.HandlerThread
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import java.io.File

/**
 * Renders the user's chosen video as a live home screen wallpaper.
 *
 * Instead of pre-processing the video file to match every possible device
 * aspect ratio, this engine uses ExoPlayer's built-in
 * VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING against the wallpaper
 * Surface. That mode scales+crops the video to fully cover the surface
 * (like CSS `background-size: cover`), so a single processed clip always
 * fills the screen sharply regardless of the device's screen ratio.
 *
 * ExoPlayer is intentionally created on a dedicated background thread
 * (playerThread) so that its initialisation — which sets up codec renderers,
 * audio sessions and internal handler threads — never blocks the app's main
 * thread and cannot trigger an ANR.
 */
@UnstableApi
class VideoWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = VideoEngine()

    inner class VideoEngine : Engine() {
        private var player: ExoPlayer? = null
        private var currentPath: String? = null
        private var reloadReceiver: BroadcastReceiver? = null

        // Dedicated background thread for all ExoPlayer operations.
        private val playerThread = HandlerThread("VideoWallpaperThread")
        private lateinit var playerHandler: Handler

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
            playerThread.start()
            playerHandler = Handler(playerThread.looper)
            registerReloadReceiver()
        }

        override fun onSurfaceCreated(holder: SurfaceHolder) {
            super.onSurfaceCreated(holder)
            // Post to background thread so ExoPlayer init never blocks the
            // main thread while Android is waiting for a UI response.
            playerHandler.post { startOrReloadPlayer(holder) }
        }

        override fun onSurfaceChanged(
            holder: SurfaceHolder,
            format: Int,
            width: Int,
            height: Int
        ) {
            super.onSurfaceChanged(holder, format, width, height)
            playerHandler.post { player?.setVideoSurfaceHolder(holder) }
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            super.onSurfaceDestroyed(holder)
            playerHandler.post { releasePlayer() }
        }

        override fun onVisibilityChanged(visible: Boolean) {
            super.onVisibilityChanged(visible)
            playerHandler.post {
                if (visible) player?.play() else player?.pause()
            }
        }

        override fun onDestroy() {
            super.onDestroy()
            // Release player on the player thread, then shut the thread down.
            playerHandler.post { releasePlayer() }
            playerThread.quitSafely()
            reloadReceiver?.let {
                try {
                    unregisterReceiver(it)
                } catch (_: IllegalArgumentException) {
                    // already unregistered — safe to ignore
                }
            }
            reloadReceiver = null
        }

        /**
         * Must only be called from [playerHandler] (i.e. on [playerThread]).
         */
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

            // Build ExoPlayer with the background looper so all its internal
            // callbacks stay off the main thread.
            val exoPlayer = ExoPlayer.Builder(this@VideoWallpaperService)
                .setLooper(playerThread.looper)
                .build().apply {
                    setVideoSurfaceHolder(holder)
                    videoScalingMode =
                        androidx.media3.common.C.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING
                    repeatMode = androidx.media3.common.Player.REPEAT_MODE_ALL
                    volume = 0f
                    setMediaItem(MediaItem.fromUri(Uri.fromFile(File(path))))
                    prepare()
                    playWhenReady = isVisible
                }
            player = exoPlayer
        }

        /**
         * Must only be called from [playerHandler].
         */
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
                    // onReceive runs on the main thread; post player work to
                    // the dedicated player thread.
                    val holder = surfaceHolder ?: return
                    playerHandler.post { startOrReloadPlayer(holder) }
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
