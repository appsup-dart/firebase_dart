/// The iframe URL builder used to build the iframe widget URL.
class IframeUrlBuilder {
  /// The application authDomain.
  final String authDomain;

  /// The API key.
  final String apiKey;

  /// The App name.
  final String appName;

  /// The client version.
  String? _version;

  /// The URI object used to build the iframe URL.
  final Uri uri;

  /// The endpoint ID.
  String? _endpointId;

  /// The list of framework IDs.
  final List<String> _frameworks = [];

  IframeUrlBuilder(this.authDomain, this.apiKey, this.appName)
      : uri = Uri(
            scheme: 'https',
            host: authDomain,
            path: '/__/auth/iframe',
            queryParameters: {
              'apiKey': apiKey,
              'appName': appName,
            });

  IframeUrlBuilder setVersion(String? value) {
    _version = value;
    return this;
  }

  IframeUrlBuilder setEndpointId(String? value) {
    _endpointId = value;
    return this;
  }

  IframeUrlBuilder setFrameworks(List<String>? value) {
    _frameworks
      ..clear()
      ..addAll(value ?? []);
    return this;
  }

  /// Modifes the URI with the relevant Auth provider parameters.
  @override
  String toString() {
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      // Pass the client version if available.
      if (_version != null) 'v': _version,
      // Pass the endpoint ID if available.
      if (_endpointId != null) 'eid': _endpointId,
      // Pass the list of frameworks if available.
      if (_frameworks.isNotEmpty) 'fw': _frameworks.join(',')
    }).toString();
  }
}
