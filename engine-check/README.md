# Android engine compatibility check

This folder is a minimal technical check of jMonkeyEngine 3.9.0-stable on Android, not the game, a prototype for release, or a replacement for the existing projects. The GitHub Actions workflow builds the test app and checks that a simple 3D scene initializes on an Android emulator. It does not validate frame rate, real-device compatibility, realistic graphics, gameplay, or asset import. No APK is uploaded for distribution.

The engine libraries are downloaded as Gradle dependencies in the workflow; they are not bundled into this repository. A successful check does not imply that the requested game is complete, nor that its Godot scripts can run in jMonkeyEngine without being rewritten.
