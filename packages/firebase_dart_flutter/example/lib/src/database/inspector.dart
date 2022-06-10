import 'dart:async';
import 'dart:convert';

import 'package:firebase_dart/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QueryInspectorPage extends StatelessWidget {
  const QueryInspectorPage({
    Key? key,
    required this.database,
  }) : super(key: key);

  final FirebaseDatabase database;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Query inspector')),
        body: QueryWidget(database: database));
  }
}

class QueryWidget extends StatefulWidget {
  final FirebaseDatabase database;

  const QueryWidget({
    Key? key,
    required this.database,
  }) : super(key: key);

  @override
  State<QueryWidget> createState() => _QueryWidgetState();
}

class _QueryWidgetState extends State<QueryWidget> {
  final TextEditingController _path = TextEditingController();
  final ValueNotifier<String> _orderBy = ValueNotifier('.priority');
  final TextEditingController _orderByChild = TextEditingController();
  final TextEditingController _limit = TextEditingController(text: '0');

  StreamSubscription? _subscription;

  DataSnapshot? _currentValue;

  String? _error;

  void _startListen() {
    assert(_subscription == null);
    Query query = widget.database.reference().child(_path.text);
    switch (_orderBy.value) {
      case '.priority':
        query = query.orderByPriority();
        break;
      case '.key':
        query = query.orderByKey();
        break;
      case '.value':
        query = query.orderByValue();
        break;
      case '.child':
        query = query.orderByChild(_orderByChild.text);
        break;
    }

    var l = int.tryParse(_limit.text);

    if (l != null) {
      query = query.limitToFirst(l);
    }

    var s = query.onValue.listen((event) {
      setState(() {
        _currentValue = event.snapshot;
      });
    }, onError: (e) {
      setState(() {
        _error = '$e';
      });
    });
    setState(() {
      _subscription = s;
    });
  }

  void _stopListen() {
    assert(_subscription != null);
    _subscription!.cancel();
    setState(() {
      _subscription = null;
      _currentValue = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: _path,
              enabled: _subscription == null,
              decoration: const InputDecoration(labelText: 'path'),
            )),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ValueListenableBuilder(
            valueListenable: _orderBy,
            builder: (BuildContext context, String value, Widget? child) {
              var callback = _subscription != null
                  ? null
                  : (String? value) {
                      _orderBy.value = value!;
                    };
              return Column(children: [
                RadioListTile<String>(
                  groupValue: value,
                  value: '.priority',
                  title: const Text('priority'),
                  onChanged: callback,
                ),
                RadioListTile(
                  groupValue: value,
                  value: '.key',
                  title: const Text('key'),
                  onChanged: callback,
                ),
                RadioListTile(
                  groupValue: value,
                  value: '.value',
                  title: const Text('value'),
                  onChanged: callback,
                ),
                RadioListTile(
                  groupValue: value,
                  value: '.child',
                  title: const Text('child'),
                  onChanged: callback,
                ),
                if (_orderBy.value == '.child')
                  Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: TextFormField(
                        controller: _orderByChild,
                        decoration:
                            const InputDecoration(labelText: 'child key'),
                      ))
              ]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextFormField(
            enabled: _subscription == null,
            controller: _limit,
            decoration: const InputDecoration(labelText: 'limit'),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ], // Only numbers can be entered
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
                onPressed: _subscription != null
                    ? null
                    : () {
                        _startListen();
                      },
                child: const Text('start listening')),
            ElevatedButton(
                onPressed: _subscription == null
                    ? null
                    : () {
                        _stopListen();
                      },
                child: const Text('stop listening'))
          ],
        ),
        if (_subscription != null && _currentValue == null && _error == null)
          const Text('waiting...'),
        if (_subscription != null && _currentValue != null)
          Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text(const JsonEncoder.withIndent(' ')
                      .convert(_currentValue!.value)))),
        if (_subscription != null && _error != null)
          Text(_error!,
              style: TextStyle(
                color: Theme.of(context).errorColor,
              ))
      ],
    );
  }
}
