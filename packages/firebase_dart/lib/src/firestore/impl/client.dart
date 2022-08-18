import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart';

import '../../firestore.dart';

class FirestoreClient {
  final FirestoreApi api = FirestoreApi(Client());

  Future<Document> getDocumentFromLocalCache(String? docKey) async {
    throw FirebaseFirestoreException(
      code: 'unavailable',
      message:
          'Failed to get document from cache. (However, this document may exist on the '
          'server. Run again without setting source to CACHE to attempt '
          'to retrieve the document from the server.)',
    );
  }
}
