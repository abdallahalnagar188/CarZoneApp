class AppRes {
  AppRes._();

  /// Wash Up "W" ribbon mark (aspect [markAspect]) and its reversed version.
  static const String logo = 'assets/logo/mark.png';
  static const String logoWhite = 'assets/logo/mark_white.png';
  static const double markAspect = 673 / 302;

  /// "WASHUP" wordmark (aspect [wordmarkAspect]) and its reversed version.
  static const String wordmark = 'assets/logo/wordmark.png';
  static const String wordmarkWhite = 'assets/logo/wordmark_white.png';
  static const double wordmarkAspect = 810 / 111;

  static String photo(String id, {int width = 800, int? height}) =>
      'https://images.unsplash.com/$id?auto=format&fit=crop&q=70&w=$width${height != null ? '&h=$height' : ''}';

  static const String foamBay = 'photo-1605164598708-25701594473e';
  static const String mistMustang = 'photo-1575844611398-2a68400b437c';
  static const String foamBmw = 'photo-1633014041037-f5446fb4ce99';
  static const String interiorWipe = 'photo-1732357624591-f2137085659b';
  static const String foamHatch = 'photo-1762933855598-273a51b47649';
  static const String autoWash = 'photo-1762933868999-a7adb3f60287';
  static const String detailBrush = 'photo-1771491237218-cbd4a707497e';
  static const String station = 'photo-1762506168937-fb21f3fcad84';
  static const String handWash = 'photo-1607860108855-64acf2078ed9';
  static const String pressureBay = 'photo-1769641156615-5d561513b3fa';
  static const String rimSpray = 'photo-1608506375591-b90e1f955e4b';
  static const String rearFoam = 'photo-1520340356584-f9917d1eea6f';
  static const String twoCars = 'photo-1761312834165-c27d037b3a6b';
  static const String grilleFoam = 'photo-1761312834150-4beefff097a7';
  static const String sponge = 'photo-1694678505383-676d78ea3b96';
  static const String wheelBrush = 'photo-1565689876697-e467b6c54da2';
  static const String blueTail = 'photo-1704796141009-5ed5cc8ca5f3';
  static const String tireBrush = 'photo-1708805282683-50a060eba80f';

  static const String hero = mistMustang;

  static const List<String> onboarding = [station, handWash, pressureBay];

  static const List<String> offers = [twoCars, blueTail, grilleFoam];

  static const Map<String, String> category = {
    'exterior': foamBmw,
    'interior': interiorWipe,
    'full': foamHatch,
    'deep': detailBrush,
  };

  static const List<String> branchPool = [
    rimSpray,
    rearFoam,
    twoCars,
    tireBrush,
    grilleFoam,
    sponge,
    wheelBrush,
    pressureBay,
    foamBay,
    blueTail,
    handWash,
    foamHatch,
    mistMustang,
    foamBmw,
    station,
    autoWash,
  ];
}
