String normalizeSymbolName(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

const Map<String, String> symbolAssetByNormalizedName = {
  'rising sun': 'assets/symbols/Rising sun.png',
  'two leaves': 'assets/symbols/Two leaves.png',
  'farmer carrying plough': 'assets/symbols/Farmer Carrying Plough.png',
  'camera': 'assets/symbols/Camera.png',
  'whistle': 'assets/symbols/Whistle.png',
  'elephant': 'assets/symbols/Elephant.png',
};

String? resolveSymbolAssetPath(String? symbolName) {
  if (symbolName == null || symbolName.trim().isEmpty) {
    return null;
  }

  final normalized = normalizeSymbolName(symbolName);
  return symbolAssetByNormalizedName[normalized];
}


