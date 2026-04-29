class YoutubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;
  final String topic;
  final String thumbnailUrl;
  final bool isBookmarked;

  const YoutubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.topic,
    required this.thumbnailUrl,
    this.isBookmarked = false,
  });

  YoutubeVideo copyWith({bool? isBookmarked}) => YoutubeVideo(
        videoId: videoId,
        title: title,
        channelTitle: channelTitle,
        topic: topic,
        thumbnailUrl: thumbnailUrl,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );
}
