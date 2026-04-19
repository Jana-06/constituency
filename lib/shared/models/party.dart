class Party {
  const Party({
    required this.id,
    required this.tamilName,
    required this.englishName,
    required this.shortName,
    required this.flagUrl,
    required this.ideology,
    required this.leadership,
  });

  final String id;
  final String tamilName;
  final String englishName;
  final String shortName;
  final String flagUrl;
  final String ideology;
  final String leadership;

  String get fullName => '$tamilName ($englishName)';
}

