import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:notification_toolbox_private/notification_toolbox_private.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/app_info.dart';
import '/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  runApp(App(sharedPreferences: sharedPreferences));
}

class App extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const App({
    Key? key,
    required this.sharedPreferences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      home: AppListPage(sharedPreferences: sharedPreferences),
    );
  }
}

class AppListPage extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const AppListPage({
    Key? key,
    required this.sharedPreferences,
  }) : super(key: key);

  @override
  State<AppListPage> createState() => _AppListPageState();
}

class _AppListPageState extends State<AppListPage> {
  static const _excludedSystemKey = 'excludeSystem';

  late final SearchBar _searchBar;

  Iterable<AppInfo> Function(List<AppInfo> input)? _filter;

  @override
  void initState() {
    super.initState();
    _searchBar = SearchBar(
      setState: setState,
      buildDefaultAppBar: _buildAppBar,
      clearOnSubmit: false,
      closeOnSubmit: false,
      inBar: false,
      onChanged: (value) {
        final lowercaseValue = value.toLowerCase();
        setState(() {
          _filter = value.isEmpty
              ? null
              : (input) => input.where((appInfo) =>
                  appInfo.name.toLowerCase().contains(lowercaseValue));
        });
      },
      onCleared: () => setState(() => _filter = null),
      onClosed: () => setState(() => _filter = null),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final excludeSystem =
        widget.sharedPreferences.getBool(_excludedSystemKey) ?? true;
    return AppBar(
      title: const Text('Notification Toolbox'),
      actions: [
        _searchBar.getSearchAction(context),
        PopupMenuButton<bool>(
          onSelected: (shouldShowAboutDialog) {
            if (shouldShowAboutDialog) {
              showAboutDialog(
                context: context,
                applicationName: appName,
                applicationVersion: appBuildName,
                applicationIcon: const Icon(appIconData),
                applicationLegalese: appLegalese,
              );
            }
          },
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                value: false,
                child: excludeSystem
                    ? const Text('Include system apps')
                    : const Text('Exclude system apps'),
                onTap: () => setState(() {
                  widget.sharedPreferences
                      .setBool(_excludedSystemKey, !excludeSystem);
                }),
              ),
              const PopupMenuItem(
                value: true,
                child: Text('About'),
              ),
            ];
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final excludeSystem =
        widget.sharedPreferences.getBool(_excludedSystemKey) ?? true;
    return Scaffold(
      appBar: _searchBar.build(context),
      body: AppListWidget(
        excludeSystem: excludeSystem,
        filter: _filter,
      ),
    );
  }
}

class AppListWidget extends StatefulWidget {
  final bool excludeSystem;
  final Iterable<AppInfo> Function(List<AppInfo> input)? filter;

  const AppListWidget({
    Key? key,
    this.excludeSystem = false,
    this.filter,
  }) : super(key: key);

  @override
  _AppListWidgetState createState() => _AppListWidgetState();
}

class _AppListWidgetState extends State<AppListWidget> {
  late Future<List<AppInfo>> _appInfo;
  late Future<Map<AppInfo, Uint8List?>> _appIcons;

  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _startLoadingAppData();
    initializeNotificationChannelManager().then((successful) {
      if (!successful) {
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return WillPopScope(
                onWillPop: () async => false,
                child: const AlertDialog(
                  title: Text('Cannot change notification settings'),
                  content: Text(
                      'Your ROM protects the notification channel settings, and they cannot be read or modified by this app.\n'
                      '\n'
                      'Read the requirements section of the README or app description for suggestions.'),
                ),
              );
            },
          );
        });
      }
    });
  }

  @override
  void didUpdateWidget(AppListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.excludeSystem != widget.excludeSystem) {
      _appInfo = Future.value(const []);
      _appIcons = Future.value(const {});
      _refreshIndicatorKey.currentState!.show();
    }
  }

  void _startLoadingAppData() {
    _appInfo = getInstalledApps(excludeSystemApps: widget.excludeSystem)
        .then((appInfo) => appInfo..sort((a, b) => a.name.compareTo(b.name)));
    _appIcons = _appInfo.then(
      (appInfo) async {
        final appIcons = await getAppIconsPng(
          appInfo
              .map((singleAppInfo) => singleAppInfo.packageName)
              .toList(growable: false),
        );
        return {
          for (var i = 0; i < appIcons.length; ++i) appInfo[i]: appIcons[i]
        };
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () {
        setState(_startLoadingAppData);
        return _appInfo;
      },
      child: FutureBuilder<List<AppInfo>>(
        future: _appInfo,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appInfo = widget.filter
                  ?.call(snapshot.requireData)
                  .toList(growable: false) ??
              snapshot.requireData;
          return IgnorePointer(
            ignoring: snapshot.connectionState == ConnectionState.waiting,
            child: ListView.builder(
              itemCount: appInfo.length,
              itemBuilder: (context, index) {
                final singleAppInfo = appInfo[index];
                final appIconFuture =
                    _appIcons.then((appIcons) => appIcons[singleAppInfo]);
                return ListTile(
                  leading: AspectRatio(
                    aspectRatio: 1,
                    child: FutureBuilder<Uint8List?>(
                      future: appIconFuture,
                      builder: (context, snapshot) {
                        final iconPng = snapshot.data;
                        return iconPng == null
                            ? const SizedBox()
                            : Image.memory(iconPng);
                      },
                    ),
                  ),
                  title: Text(singleAppInfo.name),
                  subtitle: Text(singleAppInfo.versionInfo),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppInfoPage(
                          appInfo: singleAppInfo,
                          appIconFuture: appIconFuture,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AppInfoPage extends StatefulWidget {
  final AppInfo appInfo;
  final Future<Uint8List?> appIconFuture;

  const AppInfoPage({
    Key? key,
    required this.appInfo,
    required this.appIconFuture,
  }) : super(key: key);

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  late Future<List<NotificationChannelData>> _channelData;

  @override
  void initState() {
    super.initState();
    _startLoadingChannelData();
  }

  void _startLoadingChannelData() {
    _channelData = getNotificationChannelDataForPackage(
            widget.appInfo.packageName, widget.appInfo.uid)
        .then((notificationChannelData) =>
            notificationChannelData..sort((a, b) => a.id.compareTo(b.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appInfo.name),
      ),
      body: FutureBuilder<List<NotificationChannelData>>(
        future: _channelData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final notificationChannelData = snapshot.requireData;

          if (notificationChannelData.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No notification channels.\n'
                  '\n'
                  'Notification channels may not show up until they are used.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: notificationChannelData.length,
            itemBuilder: (context, index) {
              final singleNotificationChannelData =
                  notificationChannelData[index];
              return ListTile(
                leading: {
                      NotificationChannelData.importanceNone:
                          const Icon(Icons.notifications_off_outlined),
                      NotificationChannelData.importanceMin:
                          const Icon(Icons.visibility_off_outlined),
                      NotificationChannelData.importanceLow:
                          const Icon(Icons.volume_off_outlined),
                      NotificationChannelData.importanceDefault:
                          const Icon(Icons.notifications_outlined),
                      NotificationChannelData.importanceHigh:
                          const Icon(Icons.notifications_active_outlined),
                      NotificationChannelData.importanceMax:
                          const Icon(Icons.notification_important_outlined),
                    }[singleNotificationChannelData.importance] ??
                    const SizedBox(),
                title: Text(singleNotificationChannelData.name),
                subtitle: singleNotificationChannelData.description == null
                    ? null
                    : Text(singleNotificationChannelData.description!),
                onTap: () async {
                  final newImportance = await showDialog<int>(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        title: Text(singleNotificationChannelData.name),
                        children: [
                          RadioListTile(
                            value: NotificationChannelData.importanceNone,
                            groupValue:
                                singleNotificationChannelData.importance,
                            onChanged: Navigator.of(context).pop,
                            title: const Text('Disabled'),
                            subtitle: const Text('Do not show at all.'),
                          ),
                          RadioListTile(
                            value: NotificationChannelData.importanceMin,
                            groupValue:
                                singleNotificationChannelData.importance,
                            onChanged: Navigator.of(context).pop,
                            title: const Text('Minimal'),
                            subtitle: const Text(
                                'In the notification shade, collapse notifications to one line.'),
                          ),
                          RadioListTile(
                            value: NotificationChannelData.importanceLow,
                            groupValue:
                                singleNotificationChannelData.importance,
                            onChanged: Navigator.of(context).pop,
                            title: const Text('Low'),
                            subtitle: const Text(
                                'Show in the notification shade (and possible in the status bar), but with no sound or vibration.'),
                          ),
                          RadioListTile(
                            value: NotificationChannelData.importanceDefault,
                            groupValue:
                                singleNotificationChannelData.importance,
                            onChanged: Navigator.of(context).pop,
                            title: const Text('Default'),
                            subtitle: const Text(
                                'Show everywhere, with a sound and vibration, but do not visually intrude.'),
                          ),
                          RadioListTile(
                            value: NotificationChannelData.importanceHigh,
                            groupValue:
                                singleNotificationChannelData.importance,
                            onChanged: Navigator.of(context).pop,
                            title: const Text('Maximal'),
                            subtitle: const Text(
                                'Show notifications as banner across the top of the screen.'),
                          ),
                          if (singleNotificationChannelData.importance ==
                              NotificationChannelData.importanceMax)
                            RadioListTile(
                              value: NotificationChannelData.importanceMax,
                              groupValue:
                                  singleNotificationChannelData.importance,
                              onChanged: Navigator.of(context).pop,
                              title: const Text('Internal maximum'),
                              subtitle: const Text('Undocumented behaviour.'),
                            ),
                        ],
                      );
                    },
                  );
                  if (newImportance == null) return;
                  await updateNotificationChannelImportanceForPackage(
                    widget.appInfo.packageName,
                    widget.appInfo.uid,
                    singleNotificationChannelData,
                    newImportance,
                  );
                  setState(() {
                    _startLoadingChannelData();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
