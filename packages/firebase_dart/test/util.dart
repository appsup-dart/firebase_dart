import 'package:firebase_dart/core.dart';

FirebaseOptions getOptions(
    {String appId = 'my_app_id',
    String apiKey = 'apiKey',
    String projectId = 'my_project'}) {
  return FirebaseOptions(
      appId: appId,
      apiKey: apiKey,
      projectId: projectId,
      messagingSenderId: 'ignore',
      authDomain: '$projectId.firebaseapp.com');
}
