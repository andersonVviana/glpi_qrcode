class InventoryItem {
  final String type; // "Computer" | "Phone" | "Printer"
  final int id;
  final String hostname;
  final String status;
  final String manufacturer;
  final String model;
  final String serial;
  final String userName;
  final String location;

  InventoryItem({
    required this.type,
    required this.id,
    required this.hostname,
    required this.status,
    required this.manufacturer,
    required this.model,
    required this.serial,
    required this.userName,
    required this.location,
  });
}
