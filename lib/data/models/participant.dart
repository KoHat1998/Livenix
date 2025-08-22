class Participant {
  final String id;
  final String name;
  final bool isHost;
  final bool micOn;
  final bool camOn;

  const Participant({
    required this.id,
    required this.name,
    this.isHost = false,
    this.micOn = true,
    this.camOn = true,
  });
}
