# SkyLauncher

An advanced Android Launcher, written in Flutter.

Currently in beta.

## Features

- App list sorted by last used apps
- Quick search for apps and shortcuts (for example contacts from a messenger app)
- Automatically generated vertical favorites bar with most used apps (starts empty)
- Menu to hide apps, open app info, uninstall the app and view the app in Google Play
- Web search
- Android widgets are supported
- Support for live wallpapers
- Button to pull down the notification bar with ease
- Light and dark mode
- Dimmable background
- Data export which saves a JSON file with all statistics as well as widget structure

## Permissions

- `android.permission.INTERNET`: Needed for some built-in widgets, not fully implemented yet
- `android.permission.READ_EXTERNAL_STORAGE` and `android.permission.WRITE_EXTERNAL_STORAGE`: Used for exporting the launcher data / creating a backup
- `net.dinglisch.android.tasker.PERMISSION_RUN_TASKS`: Used for Tasker integration, not fully implemented yet
- `android.permission.REQUEST_DELETE_PACKAGES`: Used when trying to uninstall an app
- `android.permission.BIND_APPWIDGET`: Used for embedding native Android Widgets
- `android.permission.EXPAND_STATUS_BAR`: Needed by the button to pull down the notification shade
- `android.permission.RECEIVE_BOOT_COMPLETED`: Used to start launcher on boot
