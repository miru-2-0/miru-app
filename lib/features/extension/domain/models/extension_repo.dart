class ExtensionRepo {
  final String id;
  final String name;
  final String url;
  final bool isBuiltIn;

  const ExtensionRepo({
    required this.id,
    required this.name,
    required this.url,
    this.isBuiltIn = false,
  });
}
