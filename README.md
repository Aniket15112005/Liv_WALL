# Live Wallpapers — Video Wallpaper App

Turn any video from your phone into an animated live wallpaper for your
Android home screen. Pick a video, trim the part you want, and set it —
the app automatically fits and smooths it for your screen.

## What this app does

- **Add a video** — pick any video from your phone's storage.
- **Trim & tune it** — drag a range slider to pick up to 30 seconds, choose
  a quality level (Data saver / Balanced / Best). The app compresses and
  smooths the clip (30fps, no audio) so it plays back lightly on battery
  and storage.
- **Automatic screen fit** — you don't need to crop or resize anything
  yourself. The wallpaper engine scales and crops the video to fully cover
  your screen's exact size and aspect ratio when it plays — the same way a
  CSS "cover" background works — so it looks sharp on any phone.
- **Set as live wallpaper** — opens Android's own "Set wallpaper"
  confirmation screen. (Android requires this system confirmation for any
  live wallpaper — no app is allowed to change your home screen silently.)
- **Manage your wallpapers** — your Library tab keeps every processed
  wallpaper so you can switch between them anytime, rename them, or delete
  them permanently. A History tab shows a timeline of everything you've
  applied.
- **Remove anytime** — a one-tap "Remove" button reverts your home screen
  back to the normal (non-live) wallpaper.

## What changed from the original project

The original repo generated animated wallpapers from code (particles,
waves, galaxy effects, etc.) with no way to use your own videos. This
version replaces that entirely with the video-import flow described above.
Favorites/categories from the old version were removed since they were
specific to the old generated-wallpaper concept — the whole app is now
organized around your own saved videos (Library + History) instead.

## Project structure

```
lib/
  models/            SavedWallpaper, HistoryEntry — data saved on-device
  services/          VideoWallpaperService — trims/compresses/saves/applies
  screens/           HomeScreen (Library/History), AddVideoScreen (pick+trim),
                     VideoDetailScreen (preview/apply/delete)
  widgets/           VideoWallpaperCard — library grid tile

android/app/src/main/kotlin/com/livewallpaper/app/
  MainActivity.kt          Flutter <-> Android bridge (MethodChannel)
  VideoWallpaperService.kt The actual live wallpaper engine (ExoPlayer)
  WallpaperPrefs.kt        Stores which video is currently active
```

Everything the video needs to loop smoothly and fill the screen happens in
`VideoWallpaperService.kt` using Android's ExoPlayer library — this is
what actually draws to your home screen, independent of the Flutter UI.

## Important: this must be built and tested on your own machine

This app was written and edited inside Replit, but Replit's workspace does
not have the Android/Flutter build toolchain (Android SDK, Gradle, an
emulator or device) needed to compile or run it, and there's no way to
preview a real Android live wallpaper in a browser — it's a native OS
feature tied to your actual home screen. You'll need to build and test it
yourself using the steps below.

## How to build and run it

1. **Install Flutter** (if you don't have it): https://docs.flutter.dev/get-started/install
   Run `flutter doctor` afterwards and make sure Android toolchain items
   are checked off.

2. **Install Android Studio**: https://developer.android.com/studio
   During setup, make sure the Android SDK and an emulator (or set up a
   real device with USB debugging enabled) are installed.

3. **Open the project**
   - Unzip this project.
   - Open the folder in Android Studio (`File > Open`), or from a
     terminal inside the project folder.

4. **Get dependencies**
   ```
   flutter pub get
   ```

5. **Run it**
   ```
   flutter run
   ```
   Pick your emulator or connected device when prompted. A real device is
   recommended for the smoothest live wallpaper preview, since some
   emulators render video wallpapers slowly.

6. **Test the live wallpaper**
   - In the app, tap **+** to add a video, trim it, and save it.
   - Open it and tap **Set as Live Wallpaper**.
   - Android will show its own confirmation screen — tap **Set wallpaper**
     there to finish. This system step can't be skipped; it's an Android
     security requirement, not something the app can bypass.
   - Go to your home screen to see it playing.
   - Back in the app, tap **Remove** on the active wallpaper to revert to
     your normal wallpaper anytime, or delete it from your Library.

## Before publishing to the Play Store

- `android/app/build.gradle.kts` still has a placeholder application ID
  (`com.example.live_wallpaper_project`). Change this to your own unique
  ID before release — see the `applicationId` line and the TODO comment
  above it.
- The release build currently signs with the debug key so `flutter run
  --release` works out of the box. Set up your own signing config before
  publishing (see the `signingConfig` TODO in the same file).

## Permissions used

- `SET_WALLPAPER` / `BIND_WALLPAPER` — required by Android for any live
  wallpaper.
- `READ_MEDIA_VIDEO` (Android 13+) and `READ_EXTERNAL_STORAGE` (older
  versions) — needed so the video picker can read the file you choose.

## Troubleshooting

- **Build fails with `Could not find method jcenter()` while building
  `video_thumbnail`** — this app no longer uses the `video_thumbnail`
  package at all (it shows a live paused video frame instead of a
  generated thumbnail image), so this error should not appear if you're
  using the current version of these files. If you still see it, run
  `flutter clean && flutter pub get` to make sure the old dependency is
  fully removed, then rebuild.
- **"Failed to open the wallpaper chooser"** — make sure you granted
  storage/media permission when picking a video, and that the file wasn't
  moved or deleted after you picked it.
- **Wallpaper looks stretched oddly** — this shouldn't happen since the
  engine always crops to cover the screen, but if you notice it, check
  that the saved `.mp4` file actually contains video (not just audio) by
  opening it from the Library preview screen first.
- **Video wallpaper doesn't loop smoothly** — try a shorter clip (10–15s)
  and a lower quality setting; longer/higher-quality clips use more
  memory and can stutter on older devices.
