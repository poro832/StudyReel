class YoutubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;
  final String topic;
  final String thumbnailUrl;
  final bool isBookmarked;

  /// 인앱 iframe 임베드 가능 여부. YouTube `videos.list status.embeddable` 결과.
  /// 피드에는 true만 포함되도록 fetch 시 필터링한다.
  final bool embeddable;

  const YoutubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.topic,
    required this.thumbnailUrl,
    this.isBookmarked = false,
    this.embeddable = false,
  });

  YoutubeVideo copyWith({bool? isBookmarked, bool? embeddable}) => YoutubeVideo(
        videoId: videoId,
        title: title,
        channelTitle: channelTitle,
        topic: topic,
        thumbnailUrl: thumbnailUrl,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        embeddable: embeddable ?? this.embeddable,
      );
}
