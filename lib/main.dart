import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:android_intent/android_intent.dart';
import 'package:app_uninstaller/app_uninstaller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:device_apps/device_apps.dart';

import 'package:notification_shade/notification_shade.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_panel_android/settings_panel_android.dart';
import 'package:share/share.dart';
import 'package:shortcuts/shortcuts.dart';
import 'package:skylauncher/app.dart';
import 'package:skylauncher/app_theme.dart';
import 'package:skylauncher/interfaces/homeassistant.dart';
import 'package:skylauncher/util/theme_data.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:skylauncher/widget_grid.dart';
import 'package:tuple/tuple.dart';
import 'package:unicons/unicons.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  await Hive.initFlutter();
  appLaunchCountBox = await Hive.openBox('appLaunchCount');
  dataBox = await Hive.openBox('data');
/*   flutterViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
  flutterViewController.isViewOpaque = false */

  // TODO Add HomeAssistant Init

  runApp(MyApp());
  // SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AppTheme(
      data: (theme) => buildThemeData(theme == 'dark'),
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          title: 'SkyLauncher',
          theme: theme,
          home: HomePage(),
        );
      },
    );

/*     return MaterialApp(
      title: 'SkyDroid Launcher',
      theme: 
      home: HomePage(),
    ); */
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

enum ResultType {
  app,
  search,
  shortcut,
}

class ListedApp {
  final ResultType type;
  final String customLabel;
  Application app;
  double priority;
  List<TextSpan> textSpans;

  String packageName;
  String shortcutId;

  ListedApp({
    this.app,
    this.priority = 0,
    this.textSpans,
    this.type = ResultType.app,
    this.customLabel,
    this.packageName,
    this.shortcutId,
  });
}

class _HomePageState extends State<HomePage> {
  Set<String> hiddenApps;
  @override
  void initState() {
    lastAppLaunches = List.from(dataBox.get('lastAppLaunches') ?? []);
    hiddenApps = Set<String>.from(dataBox.get('hiddenApps') ?? <String>[]);

    _loadApplications();

    SystemChannels.lifecycle.setMessageHandler((msg) async {
      // print('SystemChannels> $msg');

      switch (msg) {
        /*     case "AppLifecycleState.paused":
          break;
        case "AppLifecycleState.inactive":
          break; */
        case "AppLifecycleState.resumed":
          if (streamSub != null) await streamSub.cancel();
          startListening();

          break;
        /*  case "AppLifecycleState.suspending":
          break; */
        default:
      }
    });

    // apps = [];
    // topApps = [];

    // _loadWallpaper();
    super.initState();
  }

  final searchCtrl = TextEditingController();

  List<Application> collection;

  List<ListedApp> apps;

  bool _showWidgetGrid = true;

  //ThemeData themeData = buildThemeData(true);

/*   void _loadWallpaper() async {
    //print('_loadWallpaper start');
    var status = await Permission.storage.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      final result = await Permission.storage.request();

      if (!result.isGranted) {
        // TODO Show error

        return;
      }
    }

    final _wallpaperBytes = await LauncherHelper.getWallpaper;

    final brightness =
        await LauncherHelper.calculateBrightness(_wallpaperBytes);

    if (brightness < 128) {
      themeData = buildThemeData(true);
    } else {
      themeData = buildThemeData(false);
    }

    setState(() {});
  } */

  StreamSubscription streamSub;

  void startListening() {
    streamSub = DeviceApps.listenToAppsChanges().listen((event) async {
      if (event.event == ApplicationEventType.uninstalled) {
        collection.removeWhere((app) => app.packageName == event.packageName);
        appLaunchCountBox.delete(event.packageName);
        shortcutsMap.remove(event.packageName);
        _filterApplications();
        _calculateTopApplications();
      } else if (event.event == ApplicationEventType.installed) {
        collection.add(await DeviceApps.getApp(event.packageName, false));
        addToLastAppLaunches(event.packageName);
        await _loadOneAppShortcuts(event.packageName);

        _filterApplications();
        _calculateTopApplications();
      }
      print('EVENT ${event.event} ${event.packageName} ${event.time}');
    });
  }

  void _loadApplications() async {
    await Future.delayed(Duration(milliseconds: 500));

    collection = await DeviceApps.getInstalledApplications(
      includeAppIcons: false,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
    );

    startListening();

    await _loadAllShortcuts();

    /* for (final pack in await IconPacks.iconPacks) {
      print(pack);
    } */

    //compute(LauncherHelper.getApplications, null);

/*     print(collection.totalApps);
    for (final Application app in collection) {
      print(app.label);
    } */

    _filterApplications();
    _calculateTopApplications();

    // setState(() {});
  }

  List<Application> topApps;

  void _calculateTopApplications() {
    final order = appLaunchCountBox.keys.toList();

    order.removeWhere((element) => hiddenApps.contains(element));

    order.sort(
        (a, b) => appLaunchCountBox.get(b).compareTo(appLaunchCountBox.get(a)));

    topApps = order
        .take(min(32, order.length))
        .map<Application>(
          (e) => collection.firstWhere(
            (element) => element.packageName == e,
            orElse: () => null,
          ),
        )
        .where((element) => element != null)
        .toList();

    setState(() {});

    /* for(final app in collection){
      if()
    } */
  }

  Future<void> _loadAllShortcuts() async {
    for (final app in collection) {
      //print('${app.appName} (${app.packageName})');
      await _loadOneAppShortcuts(app.packageName);
    }

    // TODO Remove
    print(
        'totalShortcutsLength ${shortcutsMap.values.fold(0, (previousValue, element) => previousValue + element.length)}');
  }

  final Map<String, Map<String, String>> shortcutsMap = {};

  Future<void> _loadOneAppShortcuts(String packageName) async {
    final shortcuts = await ShortcutsAPI.getShortcuts(packageName);
    shortcutsMap[packageName] = shortcuts.cast<String, String>();
  }

  Tuple2<double, List<TextSpan>> getPriorityAndSelection(
      String label, String searchTerm,
      {String key}) {
    double priority = 0.0;

    final lowerCaseLabel = label.toLowerCase();
    if (RegExp(r'^' + searchTerm).hasMatch(lowerCaseLabel)) {
      priority = 2.0;
    } else if (RegExp(r' ' + searchTerm).hasMatch(lowerCaseLabel)) {
      priority = 1.0;
    }
    if (key != null) {
      priority += lastAppLaunches.indexOf(key) * 0.0001;
    }

    final match = RegExp(searchTerm).firstMatch(lowerCaseLabel);

    return Tuple2(
      priority,
      [
        if (match.start != 0) TextSpan(text: label.substring(0, match.start)),
        TextSpan(
          text: label.substring(match.start, match.end),
          style: TextStyle(
            color: Theme.of(context).accentColor,
          ),
        ),
        TextSpan(text: label.substring(match.end)),
      ],
    );
  }

  void _filterApplications() async {
    // TODO Add optional fuzzy search using "fuzzy" package
/*     final fuse = Fuzzy(['apple', 'banana', 'orange'],options: FuzzyOptions(

    ));
    final result = fuse.search('ran');
    result.map((r) => r.score).forEach(print); */

    final tmpApps = <ListedApp>[];

    final searchTerm = searchCtrl.text.toLowerCase();

    print('searchTerm $searchTerm');

    if (searchTerm.isEmpty) {
      tmpApps.addAll(
        collection.map<ListedApp>(
          (e) => ListedApp(
            app: e,
            priority: lastAppLaunches.indexOf(e.packageName) * 0.0001,
          ),
        ),
      );
    } else {
      final packageNameToAppNameMap = <String, String>{};
      for (final Application app in collection) {
        packageNameToAppNameMap[app.packageName] = app.appName;
        if (app.appName.toLowerCase().contains(searchTerm)) {
          final res = getPriorityAndSelection(
            app.appName,
            searchTerm,
            key: app.packageName,
          );

          tmpApps.add(
              ListedApp(app: app, priority: res.item1, textSpans: res.item2));
        }
      }

      for (final String packageName in shortcutsMap.keys) {
        final appName = packageNameToAppNameMap[packageName];
        for (final String shortcutID in shortcutsMap[packageName].keys) {
          final shortcutName = shortcutsMap[packageName][shortcutID];

          if ('$appName|||$shortcutName'.toLowerCase().contains(searchTerm)) {
            final label = '$shortcutName ($appName)';
            final res = getPriorityAndSelection(
              label,
              searchTerm,
            );

            tmpApps.add(
              ListedApp(
                packageName: packageName,
                shortcutId: shortcutID,
                customLabel: label,
                type: ResultType.shortcut,
                priority: res.item1,
                textSpans: res.item2,
              ),
            );
          }
        }
      }
    }
    tmpApps.removeWhere(
        (element) => hiddenApps.contains(element?.app?.packageName));

    tmpApps.sort((a, b) => b.priority.compareTo(a.priority));

    // TODO Be able to add Shortcuts or Apps as Widgets

    if (searchTerm.isNotEmpty) {
      tmpApps.add(ListedApp(
          type: ResultType.search,
          customLabel: 'Web Search: ${searchCtrl.text}'));
    }

    setState(() {
      apps = tmpApps;
    });
  }

  final _mainListScrollCtrl = ScrollController();
  final _favListScrollCtrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black
          .withOpacity(dataBox.get('theme_background_opacity') ?? 0.0),
      // color: Colors.transparent,
      body: apps == null
          ? Center(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        Colors.white,
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      'Loading apps...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  /*      SafeArea(
                          child: Material(
                            color: Colors.transparent,
                            child: */ /* Column(
                              children: [ */
                  // if (!kDebugMode)
                  if (_showWidgetGrid) WidgetGrid(),
                  /* ) */
                  /*  ], */
                  /*     ),
                          ),
                        ), */
                  Container(
                    height: 1,
                    color: Theme.of(context).accentColor,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            cacheExtent: 1000,
                            controller: _mainListScrollCtrl,
                            physics: BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                              top: 56,
                              bottom: 4,
                            ),
                            reverse: true,
                            itemCount: apps.length,
                            itemBuilder: (context, index) {
                              final ListedApp listedApp = apps[index];

                              if (listedApp.type == ResultType.shortcut) {
                                return ListTile(
                                  leading: AppIconWidget(
                                    packageName: listedApp.packageName,
                                    shortcutId: listedApp.shortcutId,
                                  ),
                                  onTap: () {
                                    launchResult(listedApp);
                                  },
                                  title: listedApp.textSpans == null
                                      ? Text(listedApp.customLabel)
                                      : Text.rich(
                                          TextSpan(
                                            children: listedApp.textSpans,
                                          ),
                                        ),
                                );
                              }

                              final app = listedApp.app;

                              // TODO app.enabled

                              final GlobalKey _menuKey = new GlobalKey();

                              // if (app == null) return SizedBox();
                              return ListTile(
                                onLongPress: listedApp.type != ResultType.app
                                    ? null
                                    : () {
                                        dynamic state = _menuKey.currentState;
                                        state.showButtonMenu();
                                      },
                                leading: listedApp.type == ResultType.search
                                    ? Icon(Icons.search)
                                    : PopupMenuButton(
                                        key: _menuKey,
                                        itemBuilder: (_) =>
                                            <PopupMenuItem<String>>[
                                          new PopupMenuItem<String>(
                                            child: const Text(
                                                'View in Play Store'),
                                            value: 'view_in_play_store',
                                          ),
                                          new PopupMenuItem<String>(
                                            child: const Text('Hide'),
                                            value: 'hide',
                                          ),
                                          new PopupMenuItem<String>(
                                            child:
                                                const Text('Launch App Info'),
                                            value:
                                                'launchApplicationDetailsSettings',
                                          ),
                                          new PopupMenuItem<String>(
                                            child: const Text('Uninstall'),
                                            value: 'uninstall',
                                          ),
                                        ],
                                        onSelected: (key) async {
                                          if (key == 'hide') {
                                            hiddenApps.add(app.packageName);

                                            dataBox.put('hiddenApps',
                                                hiddenApps.toList());

                                            _filterApplications();
                                            _calculateTopApplications();
                                          } else if (key ==
                                              'view_in_play_store') {
                                            AndroidIntent intent =
                                                AndroidIntent(
                                              action: 'action_view',
                                              data:
                                                  'https://play.google.com/store/apps/details?id=${app.packageName}',
                                            );
                                            await intent.launch();
                                          } else if (key == 'uninstall') {
                                            var isUninstalled =
                                                await AppUninstaller.Uninstall(
                                              app.packageName,
                                            );
                                          } else if (key ==
                                              'launchApplicationDetailsSettings') {
                                            DeviceApps.openAppSettings(
                                                app.packageName);

                                            /* final bool result =
                                                    await methodChannel
                                                        .invokeMethod(
                                                  'launchApplicationDetailsSettings',
                                                  app.packageName,
                                                ); */
                                          }
                                        },
                                        child: AppIconWidget(
                                            packageName: app.packageName),
                                      ),
                                onTap: () {
                                  launchResult(listedApp);
                                },
                                title: listedApp.textSpans == null
                                    ? Text(listedApp.customLabel ?? app.appName)
                                    : Text.rich(
                                        TextSpan(children: listedApp.textSpans),
                                      ),
                              );
                            },
                          ),
                        ),
                        if (topApps != null)
                          SizedBox(
                            width: 56, // 48
                            //height: 100,
                            child: ListView.builder(
                              cacheExtent: 1000,
                              controller: _favListScrollCtrl,
                              reverse: true,
                              physics: BouncingScrollPhysics(),
                              itemCount: topApps.length,
                              itemBuilder: (context, index) {
                                final app = topApps[index];
                                return InkWell(
                                  onTap: () {
                                    launchApp(app.packageName);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: AppIconWidget(
                                      packageName: app.packageName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      left: 0.0,
                      right: 0,
                      bottom: 8.0,
                    ),
                    child: Row(
                      children: [
                        PopupMenuButton(
                          itemBuilder: (_) => <PopupMenuItem<String>>[
                            new PopupMenuItem<String>(
                              child:
                                  const Text('Change background transparency'),
                              value: 'theme_background_opacity',
                            ),
                            new PopupMenuItem<String>(
                              child: Text(
                                  'Switch to ${AppTheme.of(context).loadTheme() == 'dark' ? 'light' : 'dark'} theme'),
                              value: 'switch_theme',
                            ),
                            new PopupMenuItem<String>(
                              child: const Text('View hidden apps'),
                              value: 'view_hidden_apps',
                            ),
                            new PopupMenuItem<String>(
                              child: const Text('Export all data'),
                              value: 'export',
                            ),
                            new PopupMenuItem<String>(
                              child: const Text('Manually refresh app list'),
                              value: 'refresh',
                            ),
                            new PopupMenuItem<String>(
                              child: const Text('Reload widget grid'),
                              value: 'reload_widget_grid',
                            ),
                          ],
                          onSelected: (key) async {
                            if (key == 'reload_widget_grid') {
                              await _reloadWidgetGrid();
                            } else if (key == 'theme_background_opacity') {
                              double val =
                                  dataBox.get('theme_background_opacity') ??
                                      0.0;
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Change background transparency'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 50,
                                        child: StatefulBuilder(
                                            builder: (context, sState) {
                                          return Slider(
                                              value: val,
                                              onChanged: (value) {
                                                sState(() {
                                                  val = value;
                                                });
                                              });
                                        }),
                                      ),
                                      Row(
                                        children: [
                                          Text('Transparent'),
                                          Spacer(),
                                          Text('Black'),
                                        ],
                                      )
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: context.nav.pop,
                                      child: Text('Apply'),
                                    ),
                                  ],
                                ),
                              );
                              dataBox.put('theme_background_opacity', val);
                              setState(() {});
                            } else if (key == 'switch_theme') {
                              final newTheme =
                                  AppTheme.of(context).loadTheme() == 'dark'
                                      ? 'light'
                                      : 'dark';

                              dataBox.put('theme', newTheme);
                              AppTheme.of(context).setTheme(
                                newTheme,
                              );
                            } else if (key == 'view_hidden_apps') {
                              bool didChange = false;
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Hidden apps'),
                                  content: SizedBox(
                                    height: 200,
                                    width: 100,
                                    child: StatefulBuilder(
                                        builder: (context, sState) {
                                      return ListView(
                                        children: [
                                          for (final hiddenApp in hiddenApps)
                                            ListTile(
                                              title: Text(hiddenApp),
                                              trailing: Icon(Icons.close),
                                              onTap: () {
                                                hiddenApps.remove(hiddenApp);
                                                sState(() {});
                                                dataBox.put(
                                                  'hiddenApps',
                                                  hiddenApps.toList(),
                                                );
                                                didChange = true;
                                              },
                                            )
                                        ],
                                      );
                                    }),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: context.nav.pop,
                                      child: Text('Close'),
                                    )
                                  ],
                                ),
                              );
                              if (didChange) {
                                _filterApplications();
                                _calculateTopApplications();
                              }
                            } else if (key == 'refresh') {
                              setState(() {
                                collection = null;
                                apps = null;
                              });
                              collection =
                                  await DeviceApps.getInstalledApplications(
                                includeAppIcons: false,
                                includeSystemApps: true,
                                onlyAppsWithLaunchIntent: true,
                              );
                              await _loadAllShortcuts();

                              _filterApplications();
                              _calculateTopApplications();
                            } else if (key == 'export') {
                              final dir = await path_provider
                                  .getExternalStorageDirectory();

                              final file = File(
                                  '${dir.path}/SkyDroid-Launcher-Export-${DateTime.now()}.json');

                              file.writeAsStringSync(json.encode({
                                'data': dataBox.toMap(),
                                'appLaunchCount': appLaunchCountBox.toMap(),
                              }));
                              Share.shareFiles(
                                [file.path],
                                text: 'SkyDroid Launcher Export',
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Icon(UniconsLine.setting),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                // width: 0.0 produces a thin "hairline" border
                                borderSide: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                              labelStyle: new TextStyle(color: Colors.green),
                              fillColor: Colors.red,
                              hintText: 'Search...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              contentPadding: const EdgeInsets.only(
                                left: 12,
                                right: 12,
                              ),
                            ),
                            controller: searchCtrl,
                            onChanged: (_) {
                              _filterApplications();
                            },
                            onSubmitted: (_) {
                              if (apps.isNotEmpty) {
                                launchResult(apps.first);
                              }
                            },
                          ),
                        ),
                        InkWell(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Icon(UniconsLine.arrow_from_top),
                          ),
                          onTap: () async {
                            NotificationShade.openNotificationShade;
                          },
                          onLongPress: () {
                            SettingsPanel.display(
                              SettingsPanelAction.internetConnectivity,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      /*    ), */
    );
  }

  List<String> lastAppLaunches;

  void launchResult(ListedApp listedApp) {
    if (listedApp.type == ResultType.shortcut) {
      ShortcutsAPI.launchShortcut(
        packageName: listedApp.packageName,
        shortcutID: listedApp.shortcutId,
      );
      clearSearch();
    } else if (listedApp.type == ResultType.search) {
      launchSearch(searchCtrl.text);
    } else {
      launchApp(listedApp.app.packageName);
    }

    /*                  final doesApplicationExist =
        await LauncherHelper.doesApplicationExist(
            app.packageName);
    print('doesApplicationExist $doesApplicationExist');
    final isEnabled =
        await LauncherHelper.isApplicationEnabled(
            app.packageName);
    print('isEnabled $isEnabled'); */
  }

  Future<void> _reloadWidgetGrid({bool delayed = false}) async {
    /*    if (delayed) {
      await Future.delayed(Duration(milliseconds: 800));
    }
 */
    setState(() {
      _showWidgetGrid = false;
    });

    await Future.delayed(Duration(milliseconds: 100));

    setState(() {
      _showWidgetGrid = true;
    });
  }

  void clearSearch() {
    _mainListScrollCtrl.jumpTo(0);
    _favListScrollCtrl.jumpTo(0);
    FocusScope.of(context).unfocus();
    if (searchCtrl.text.isNotEmpty) {
      searchCtrl.clear();
      _filterApplications();
    }
  }

  void launchSearch(String query) {
    // _reloadWidgetGrid(delayed: true);
    launch(
      Uri.https('www.google.com', '/search', {
        'q': query,
      }).toString(),
    );
    clearSearch();
  }

  void addToLastAppLaunches(String packageName) {
    lastAppLaunches.removeWhere((element) => element == packageName);
    lastAppLaunches.add(packageName);
    dataBox.put('lastAppLaunches', lastAppLaunches);
  }

  void launchApp(String packageName) {
    // _reloadWidgetGrid(delayed: true);
    print('launchApp $packageName');
    //return;
    DeviceApps.openApp(packageName);

    addToLastAppLaunches(packageName);

    // TODO Check if this makes sense
    clearSearch();

    final count = (appLaunchCountBox.get(packageName) ?? 0) + 1;
    appLaunchCountBox.put(packageName, count);

    _loadOneAppShortcuts(packageName);

    // TODO Only sometimes
    _calculateTopApplications();
  }
}

class IconCache {
  static final Map<String, ImageProvider> cache = {};

  static String toKey(String packageName, String shortcutId) {
    if (shortcutId == null) {
      return packageName;
    } else {
      return '$packageName|$shortcutId';
    }
  }

  static bool isIconInCache(String packageName, String shortcutId) {
    final key = toKey(packageName, shortcutId);
    return cache.containsKey(key);
  }

  static ImageProvider getIconFromCache(String packageName, String shortcutId) {
    final key = toKey(packageName, shortcutId);
    return cache[key];
  }

  static Future<void> loadIcon(String packageName, String shortcutId) async {
    final key = toKey(packageName, shortcutId);
    if (shortcutId == null) {
      final ApplicationWithIcon res =
          await DeviceApps.getApp(packageName, true);
      cache[key] = MemoryImage(res.icon);
    } else {
      final res = await ShortcutsAPI.getShortcutIcon(
        packageName: packageName,
        shortcutID: shortcutId,
        height: 48,
        width: 48,
      );

      cache[key] = res.image;
    }
  }
}

class AppIconWidget extends StatefulWidget {
  AppIconWidget({@required this.packageName, this.shortcutId})
      : super(key: ValueKey(packageName));

  final String packageName;
  final String shortcutId;

  @override
  _AppIconWidgetState createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  @override
  void initState() {
    if (!IconCache.isIconInCache(widget.packageName, widget.shortcutId)) {
      IconCache.loadIcon(widget.packageName, widget.shortcutId).then((_) {
        if (mounted) setState(() {});
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconCache.isIconInCache(widget.packageName, widget.shortcutId)
          ? Image(
              image: IconCache.getIconFromCache(
                  widget.packageName, widget.shortcutId),
              //(app as ApplicationWithIcon).icon,
              // key: ValueKey(app.packageName),
            )
          : null,
      /* (app.icon is RegularIcon)
          ? app.icon.foreground
          : Stack(
              children: [
                /* Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.green,
            ),
            borderRadius: BorderRadius.circular(8),
            color: (app.icon as AdaptableIcon)
                .background
                .color,
          ),
          child: SizedBox(),
        ), */
                (app.icon as AdaptableIcon).background,
                app.icon.foreground,
              ],
            ), */
    );
  }
}
