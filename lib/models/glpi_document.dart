class GlpiDocument {
  final int id;
  final String name;
  final String filename;
  final String mime;
  final String dateCreation;
  final String dateMod;
  final String heading; // título/observação

  GlpiDocument({
    required this.id,
    required this.name,
    required this.filename,
    required this.mime,
    required this.dateCreation,
    required this.dateMod,
    required this.heading,
  });

  factory GlpiDocument.fromJson(Map<String, dynamic> raw) {
    return GlpiDocument(
      id: (raw['id'] is int) ? raw['id'] : int.tryParse('${raw['id']}') ?? 0,
      name: (raw['name'] ?? '').toString(),
      filename: (raw['filename'] ?? raw['filepath'] ?? '').toString(),
      mime: (raw['mime'] ?? raw['mimetype'] ?? '').toString(),
      dateCreation: (raw['date_creation'] ?? '').toString(),
      dateMod: (raw['date_mod'] ?? '').toString(),
      heading: (raw['heading'] ?? '').toString(),
    );
  }
}
