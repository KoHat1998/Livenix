class LiveRoom {
  final String id;
  final String title;
  final String hostName;
  final int viewersCount;
  final bool isLive;

  const LiveRoom({
    required this.id,
    required this.title,
    required this.hostName,
    this.viewersCount = 0,
    this.isLive = false,
  });

  LiveRoom copyWith({
    String? id,
    String? title,
    String? hostName,
    int? viewersCount,
    bool? isLive,
  }) {
    return LiveRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      hostName: hostName ?? this.hostName,
      viewersCount: viewersCount ?? this.viewersCount,
      isLive: isLive ?? this.isLive,
    );
  }
}
