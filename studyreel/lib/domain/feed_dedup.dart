import '../data/models/youtube_video.dart';

/// [existing] 뒤에 [incoming] 중 새 영상만 이어붙인 새 리스트를 반환한다.
/// - 이미 [existing]에 있는 videoId는 제외
/// - [incoming] 내부 중복도 제거
/// - [excludedIds](예: 시청한 영상)도 제외
/// [existing]은 변경하지 않는다(불변).
List<YoutubeVideo> dedupeAppend(
  List<YoutubeVideo> existing,
  List<YoutubeVideo> incoming, {
  Set<String> excludedIds = const {},
}) {
  final seen = {...existing.map((v) => v.videoId), ...excludedIds};
  final result = [...existing];
  for (final v in incoming) {
    if (seen.add(v.videoId)) result.add(v);
  }
  return result;
}
