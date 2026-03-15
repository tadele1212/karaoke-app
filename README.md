# Karaoke Flutter App

This is a simple Flutter karaoke app that plays two versions of the same video:

- **Singer**: video with vocals
- **Karaoke**: instrumental version

The app:

- Uses the `video_player` plugin to render video.
- Loads **two local MP4 files** and keeps them synchronized.
- Allows **instant switching** between Singer and Karaoke without restarting the video.
- Relies on the underlying platform (Android) to route audio to a paired Bluetooth speaker automatically.

## Video file locations

By default, the app expects the following files on an Android device:

- `/storage/emulated/0/Download/videoA.mp4` (with singer)
- `/storage/emulated/0/Download/videoB.mp4` (karaoke)

You can change these paths in `lib/main.dart` to match your actual file locations.

## Getting started

1. Make sure you have Flutter installed.
2. In this folder, run:

   ```bash
   flutter pub get
   flutter run
   ```

3. Ensure your `videoA.mp4` and `videoB.mp4` exist at the configured paths.

Android will automatically route the audio to a connected Bluetooth speaker.

