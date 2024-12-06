class AppSettings {
  AppSettings._();

  static final AppSettings _instance = AppSettings._();

  factory AppSettings() {
    return _instance;
  }




  double _facesMatchingScore  = 0.0; // Default theme
  double get facesMatchingScore => _facesMatchingScore;

  set facesMatchingScore(double value) {
    _facesMatchingScore = value;
  }

  double _realPersonScore = 0.0; // Default language
  double get realPersonScore => _realPersonScore;

  set realPersonScore(double value) {
    _realPersonScore = value;
  }

  bool _isIDPassport = false; // Default language
  bool get isIDPassport => _isIDPassport;

  set isIDPassport(bool value) {
    _isIDPassport = value;
  }

  bool _isIDExpired = false; // Default language
  bool get isIDExpired => _isIDExpired;

  set isIDExpired(bool value) {
    _isIDExpired = value;
  }
}