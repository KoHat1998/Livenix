class Message {
  final String id;
  final String from; // name
  final String text;
  final DateTime ts;
  final bool isHost;

  const Message({
    required this.id,
    required this.from,
    required this.text,
    required this.ts,
    this.isHost = false,
  });
}
