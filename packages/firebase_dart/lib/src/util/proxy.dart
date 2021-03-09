import 'package:http/http.dart' as http;

class ProxyClient extends http.BaseClient {
  final Map<Pattern, http.Client> clients;

  ProxyClient(this.clients);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    for (var p in clients.keys) {
      if (p.allMatches(request.url.replace(query: '').toString()).isNotEmpty) {
        return clients[p]!.send(request);
      }
    }
    throw ArgumentError('No client defined for url ${request.url}');
  }
}
