Platform platform = Platform(isOnline: true); // TODO

class Platform {
  final bool isOnline;
  final bool isMobile;

  Platform({this.isOnline = true, this.isMobile = false});
}
