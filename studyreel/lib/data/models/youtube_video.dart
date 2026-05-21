class YoutubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;
  final String topic;
  final String thumbnailUrl;
  final bool isBookmarked;

  /// 인앱 iframe 임베드 가능 여부. YouTube `videos.list status.embeddable` 결과.
  final bool embeddable;

  /// 영상 길이(초). 쇼츠 형태 유지를 위해 피드에는 60초 이하만 노출한다.
  final int durationSeconds;

  const YoutubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.topic,
    required this.thumbnailUrl,
    this.isBookmarked = false,
    this.embeddable = false,
    this.durationSeconds = 0,
  });

  YoutubeVideo copyWith({
    bool? isBookmarked,
    bool? embeddable,
    int? durationSeconds,
  }) =>
      YoutubeVideo(
        videoId: videoId,
        title: title,
        channelTitle: channelTitle,
        topic: topic,
        thumbnailUrl: thumbnailUrl,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        embeddable: embeddable ?? this.embeddable,
        durationSeconds: durationSeconds ?? this.durationSeconds,
      );
}
