class LiveRoom {
  final String id;
  final String title;
  final String hostName;
  final int viewersCount;       // non-nullable
  final bool isLive;
  final String? thumbnailUrl;   // optional

  const LiveRoom({
    required this.id,
    required this.title,
    required this.hostName,
    this.viewersCount = 0,
    this.isLive = false,
    this.thumbnailUrl,
  });

  LiveRoom copyWith({
    String? id,
    String? title,
    String? hostName,
    int? viewersCount,
    bool? isLive,
    String? thumbnailUrl,
  }) {
    return LiveRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      hostName: hostName ?? this.hostName,
      viewersCount: viewersCount ?? this.viewersCount,
      isLive: isLive ?? this.isLive,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}
