import 'package:url_launcher/url_launcher.dart';

/// videoId로 YouTube 앱(설치 시) 또는 브라우저를 외부 실행한다.
Future<void> launchYoutube(String videoId) async {
  final appUrl = Uri.parse('vnd.youtube://$videoId');
  final webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');
  if (await canLaunchUrl(appUrl)) {
    await launchUrl(appUrl);
  } else {
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }
}
