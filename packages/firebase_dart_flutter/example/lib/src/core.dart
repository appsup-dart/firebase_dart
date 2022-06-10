import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_dart/firebase_dart.dart';

import 'auth.dart';

class AppListPage extends StatelessWidget {
  final Stream<List<FirebaseOptions>> apps = (() async* {
    var box = await Hive.openBox('firebase_dart_flutter_example');
    List<FirebaseOptions> parseApps(List? v) =>
        (v ?? []).map((v) => FirebaseOptions.fromMap(v)).toList();

    yield parseApps(box.get('apps'));
    yield* box.watch(key: 'apps').map((e) => parseApps(e.value));
  })();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select a firebase app')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return NewAppDialog();
              });
        },
      ),
      body: StreamBuilder<List<FirebaseOptions>>(
        stream: apps,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              for (var v in snapshot.data!)
                ListTile(
                    title: Text(v.projectId),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return AppPage(
                          firebaseOptions: v,
                        );
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
  @override
  State<StatefulWidget> createState() => _NewAppDialogState();
}

class _NewAppDialogState extends State<NewAppDialog> {
  int _index = 0;

  final List<TextFormField> _fields = [
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: InputDecoration(labelText: 'project id'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty)
          return 'project id should not be empty';
        return null;
      },
    ),
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: InputDecoration(labelText: 'API key'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty)
          return 'API key should not be empty';
        return null;
      },
    ),
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: InputDecoration(labelText: 'auth domain'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty)
          return 'auth domain should not be empty';
        return null;
      },
    ),
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: InputDecoration(labelText: 'database url'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty)
          return 'database url should not be empty';
        return null;
      },
    ),
    TextFormField(
      key: GlobalKey<FormFieldState>(),
      controller: TextEditingController(),
      decoration: InputDecoration(labelText: 'storage bucket'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty)
          return 'storage bucket should not be empty';
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
    setState(() => null);
  }

  @override
  Widget build(BuildContext context) {
    var steps = [
      for (var f in _fields)
        Step(
            title: Text(''),
            isActive: _index == _fields.indexOf(f),
            content: f),
    ];

    var key = _fields[_index].key as GlobalKey<FormFieldState>;
    var canContinue = key.currentState?.isValid ?? false;
    return SimpleDialog(
      title: Text('New firebase app'),
      children: [
        Container(
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
      Navigator.pop(context);
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

class AppPage extends StatelessWidget {
  final FirebaseOptions firebaseOptions;

  final Future<FirebaseApp> app;

  AppPage({Key? key, required this.firebaseOptions})
      : app = _createApp(firebaseOptions),
        super(key: key);

  static Future<FirebaseApp> _createApp(FirebaseOptions firebaseOptions) async {
    try {
      return Firebase.app(firebaseOptions.projectId);
    } on FirebaseException {
      return Firebase.initializeApp(
          options: firebaseOptions, name: firebaseOptions.projectId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(future: app.then((app) async {
      await FirebaseAuth.instanceFor(app: app).trySignInWithEmailLink(
          askUserForEmail: () async {
        var email = TextEditingController();
        return showDialog<String>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Please provide your email'),
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
                      child: Text(
                          MaterialLocalizations.of(context).okButtonLabel)),
                ],
              );
            });
      });
      return app;
    }), builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Column(
          children: [CircularProgressIndicator()],
          mainAxisAlignment: MainAxisAlignment.center,
        );
      }
      return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(firebaseOptions.projectId),
              bottom: TabBar(
                tabs: [
                  Text('auth'),
                  Text('database'),
                  Text('storage'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                AuthTab(app: snapshot.data!),
                Text('database'),
                Text('storage'),
              ],
            ),
          ));
    });
  }
}
