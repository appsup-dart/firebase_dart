import 'dart:async';

import 'package:flutter/material.dart';

class ActionDialog<T> extends StatefulWidget {
  final List<Widget> children;

  final Widget? title;

  final FutureOr<T> Function() onContinue;

  const ActionDialog(
      {Key? key, required this.children, this.title, required this.onContinue})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ActionDialogState();
}

class _ActionDialogState<T> extends State<ActionDialog<T>> {
  bool _inProgress = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: SingleChildScrollView(
        child: ListBody(children: widget.children),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _inProgress
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: _inProgress
              ? null
              : () async {
                  setState(() => _inProgress = true);
                  try {
                    var v = await widget.onContinue();
                    if (mounted) Navigator.pop(context, v);
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('$e')));
                    setState(() => _inProgress = false);
                    rethrow;
                  }
                },
          child: Row(children: [
            SizedBox(
                width: 16,
                height: 16,
                child: _inProgress ? const CircularProgressIndicator() : null),
            Text(MaterialLocalizations.of(context).okButtonLabel),
          ]),
        ),
      ],
    );
  }
}

Future<T?> showConfirmDialog<T>(
    {required BuildContext context,
    required String title,
    String? bodyText,
    required FutureOr<T> Function() onContinue}) {
  return showDialog(
      context: context,
      builder: (context) {
        return ActionDialog(
          title: Text(title),
          children: [
            if (bodyText != null) Text(bodyText),
          ],
          onContinue: () async {
            return await onContinue();
          },
        );
      });
}

Future<T?> showEditFieldDialog<T>(
    {required BuildContext context,
    required String labelText,
    required String title,
    String? bodyText,
    String? initialValue,
    bool obscureText = false,
    required FutureOr<T> Function(String) onContinue}) {
  var controller = TextEditingController(text: initialValue);
  return showDialog(
      context: context,
      builder: (context) {
        return ActionDialog(
          title: Text(title),
          children: [
            if (bodyText != null) Text(bodyText),
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: labelText),
              obscureText: obscureText,
            )
          ],
          onContinue: () async {
            return await onContinue(controller.text);
          },
        );
      });
}
