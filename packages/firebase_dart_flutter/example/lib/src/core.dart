import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_dart/firebase_dart.dart';

import 'auth.dart';
import 'database.dart';

class AppListPage extends StatelessWidget {
  static Stream<List<FirebaseOptions>> apps() async* {
    var box = await Hive.openBox('firebase_dart_flutter_example');
    List<FirebaseOptions> parseApps(List? v) =>
        (v ?? []).map((v) => FirebaseOptions.fromMap(v)).toList();

    yield parseApps(box.get('apps'));
    yield* box.watch(key: 'apps').map((e) => parseApps(e.value));
  }

  const AppListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a firebase app')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return const NewAppDialog();
              });
        },
      ),
      body: StreamBuilder<List<FirebaseOptions>>(
        stream: apps(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          return ListView(
            children: [
              for (var v in snapshot.data!)
                ListTile(
                    title: Text(v.projectId),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return AppPage(projectId: v.projectId);
                      }));
                    })
            ],
          );
        },
      ),
    );
  }
}

class NewAppDialog extends StatefulWidget {
  const NewAppDialog({super.key});

  @override
  State<StatefulWidget> createState() => _NewAppDialogState();
}

class _NewAppDialogState extends State<NewAppDialog> {
  int _index = 0;

  final List<TextFormField> _fields = [
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: const InputDecoration(labelText: 'Project ID'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'project id should not be empty';
        }
        return null;
      },
    ),
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: const InputDecoration(labelText: 'API key'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'API key should not be empty';
        }
        return null;
      },
    ),
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: const InputDecoration(labelText: 'auth domain'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'auth domain should not be empty';
        }
        return null;
      },
    ),
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: const InputDecoration(labelText: 'database url'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'database url should not be empty';
        }
        return null;
      },
    ),
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: const InputDecoration(labelText: 'storage bucket'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'storage bucket should not be empty';
        }
        return null;
      },
    ),
  ];

  @override
  void initState() {
    for (var f in _fields) {
      f.controller!.addListener(_onFieldChanged);
    }
    super.initState();
  }

  @override
  void dispose() {
    for (var f in _fields) {
      f.controller!.removeListener(_onFieldChanged);
    }
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var steps = [
      for (var f in _fields)
        Step(
            title: const Text(''),
            isActive: _index == _fields.indexOf(f),
            content: f),
    ];

    var key = _fields[_index].key as GlobalKey<FormFieldState>;
    var canContinue = key.currentState?.isValid ?? false;
    return SimpleDialog(
      title: const Text('New firebase app'),
      children: [
        SizedBox(
            width: 300,
            height: 300,
            child: Form(
                child: Stepper(
              currentStep: _index,
              type: StepperType.horizontal,
              onStepContinue: canContinue ? () => _nextStep(context) : null,
              onStepCancel: () {
                if (_index == 0) {
                  Navigator.pop(context);
                }
                setState(() {
                  _index--;
                });
              },
              steps: steps,
            ))),
      ],
    );
  }

  String get projectId => _fields[0].controller!.text;
  String get apiKey => _fields[1].controller!.text;
  String get authDomain => _fields[2].controller!.text;
  String get databaseUrl => _fields[3].controller!.text;
  String get storageBucket => _fields[4].controller!.text;

  void _nextStep(BuildContext context) async {
    if (_index >= _fields.length - 1) {
      var box = await Hive.openBox('firebase_dart_flutter_example');
      var apps = box.get('apps') ?? [];
      apps = [
        ...apps,
        FirebaseOptions(
          projectId: projectId,
          apiKey: apiKey,
          authDomain: authDomain,
          databaseURL: databaseUrl,
          storageBucket: storageBucket,
          messagingSenderId: '',
          appId: '',
        ).asMap
      ];
      await box.put('apps', apps);
      if (context.mounted) Navigator.pop(context);
      return;
    }

    if (_index == 0) {
      _fields[2].controller!.text = '$projectId.firebaseapp.com';
      _fields[3].controller!.text = 'https://$projectId.firebaseio.com';
      _fields[4].controller!.text = '$projectId.appspot.com';
    }
    setState(() {
      _index++;
    });
  }
}

class AppPage extends StatefulWidget {
  final String projectId;

  const AppPage({super.key, required this.projectId});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  FirebaseApp? _app;

  StreamSubscription? _subscription;
  @override
  void initState() {
    _subscription = AppListPage.apps().listen((event) async {
      var o = event.firstWhere((v) => v.projectId == widget.projectId);

      try {
        _app ??= Firebase.app(o.projectId);
      } on FirebaseException {
        // ignore
      }

      if (_app != null && _app!.options == o) {
        return;
      }

      await _app?.delete();
      _app = await Firebase.initializeApp(options: o, name: o.projectId);

      if (_app != null) {
        await FirebaseAuth.instanceFor(app: _app!)
            .trySignInWithEmailLink(askUserForEmail: _askForEmail);
      }

      if (context.mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<String?> _askForEmail() {
    var email = TextEditingController();
    return showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Please provide your email'),
            content: Column(
              children: [
                TextFormField(
                  controller: email,
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel)),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(email.text);
                  },
                  child: Text(MaterialLocalizations.of(context).okButtonLabel)),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    var app = _app;

    if (app == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.projectId),
            bottom: const TabBar(
              tabs: [
                Text('settings'),
                Text('auth'),
                Text('database'),
                Text('storage'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              AppSettingsTab(app: app),
              AuthTab(app: app),
              DatabaseTab(app: app),
              const Text('storage'),
            ],
          ),
        ));
  }
}

class AppSettingsTab extends StatelessWidget {
  final FirebaseApp app;

  const AppSettingsTab({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    var options = app.options;
    return ListView(
      children: [
        ListTile(
            title: const Text('Project ID'), subtitle: Text(options.projectId)),
        _buildTile(context, 'API key', 'apiKey'),
        _buildTile(context, 'Database URL', 'databaseURL'),
        _buildTile(context, 'App ID', 'appId'),
        _buildTile(context, 'iOS client id', 'iosClientId'),
      ],
    );
  }

  Widget _buildTile(BuildContext context, String title, String property) {
    var o = app.options.asMap;
    return ListTile(
        title: Text(title),
        subtitle: Text(o[property] ?? ''),
        onTap: () {
          _showEditDialog(context, title: title, property: property);
        });
  }

  void _showEditDialog(BuildContext context,
      {required String title, required String property}) {
    var o = app.options.asMap;
    var c = TextEditingController(text: o[property]);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(controller: c),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel)),
              TextButton(
                  onPressed: () async {
                    var box =
                        await Hive.openBox('firebase_dart_flutter_example');
                    var apps = box.get('apps') as List? ?? [];
                    var index = apps.indexWhere(
                        (v) => v['projectId'] == app.options.projectId);
                    apps[index] = {
                      ...o,
                      property: c.text,
                    };
                    await box.put('apps', apps);

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child:
                      Text(MaterialLocalizations.of(context).saveButtonLabel)),
            ],
          );
        });
  }
}
