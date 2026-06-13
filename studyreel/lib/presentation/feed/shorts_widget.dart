import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme.dart';
import '../../core/youtube_launcher.dart';
import '../../data/models/youtube_video.dart';

class ShortsWidget extends StatefulWidget {
  final YoutubeVideo video;
  final bool isActive;

  /// 화면이 실제로 보이는지(다른 탭/화면에 가려지면 false). false면 재생을
  /// 멈춰 배경 재생음을 방지한다.
  final bool screenVisible;
  final VoidCallback onBookmark;

  /// 인앱 재생이 불가한 영상(임베드 차단·삭제·검색 불가)으로 판명되면 1회 호출.
  /// 부모가 피드/캐시에서 제거해 다음 영상으로 자동으로 넘긴다.
  final VoidCallback? onUnplayable;

  /// 영상이 실제 재생(playing)에 도달하면 1회 호출 → 시청 기록에 저장.
  final VoidCallback? onWatched;

  const ShortsWidget({
    super.key,
    required this.video,
    required this.isActive,
    required this.onBookmark,
    this.screenVisible = true,
    this.onUnplayable,
    this.onWatched,
  });

  @override
  State<ShortsWidget> createState() => _ShortsWidgetState();
}

class _ShortsWidgetState extends State<ShortsWidget>
    with SingleTickerProviderStateMixin {
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubePlayerValue>? _sub;

  /// 더블탭 저장 시 중앙에 잠깐 띄우는 북마크 버스트 애니메이션
  late final AnimationController _burst;

  /// 인앱 임베드가 실패하면 true → 썸네일 + 외부 실행 폴백으로 전환
  bool _embedFailed = false;

  /// 사용자가 탭으로 일시정지한 상태 → 중앙에 재생 아이콘 표시
  bool _paused = false;

  /// onUnplayable을 영상당 한 번만 호출하기 위한 가드
  bool _reportedUnplayable = false;

  /// 실제 재생(playing)에 도달했는지. 도달 전 워치독이 만료되면 재생 불가로 본다.
  bool _started = false;

  /// onWatched를 영상당 한 번만 호출하기 위한 가드
  bool _reportedWatched = false;

  /// 활성 영상이 제한시간 내 재생되지 않으면 스킵을 트리거하는 워치독.
  Timer? _watchdog;

  /// 활성화 후 이 시간 안에 재생이 시작되지 않으면 재생 불가로 간주(에러 미발생
  /// 무한 버퍼링/큐 상태까지 포함). 짧을수록 스킵이 빠르지만 느린 네트워크에서
  /// 정상 영상을 오스킵할 위험이 커진다.
  static const _playStartTimeout = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.videoId,
      autoPlay: widget.isActive && widget.screenVisible,
      params: const YoutubePlayerParams(
        // 풀화면 몰입을 위해 네이티브 컨트롤은 숨기고 탭으로 재생/정지.
        showControls: false,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        // 소리 켠 자동재생. youtube-nocookie 호스트 + 패키지가 설정하는
        // mediaPlaybackRequiresUserGesture(false) 조합으로 실기기에서
        // 무음 없이 소리까지 정상 재생됨(Z Fold7 검증).
        mute: false,
        loop: true,
        // error 152-4 회피: youtube-nocookie는 유효한 임베드 호스트라
        // 플레이어가 정상 로드되면서 youtube.com과 다른 도메인이라 152를
        // 우회한다. (이 패키지는 origin을 host로도 써서 유효 호스트 필수)
        origin: 'https://www.youtube-nocookie.com',
        userAgent:
            'Mozilla/5.0 (Linux; Android 14; SM-F966N) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
      ),
    );
    _sub = _controller.listen((value) {
      // 실제 재생에 도달하면 워치독 해제(정상 영상) + 시청 기록 1회 보고.
      if (value.playerState == PlayerState.playing) {
        _watchdog?.cancel();
        // 첫 재생 도달 시 썸네일 커버를 페이드아웃(검은 로딩 프레임 제거).
        if (!_started) {
          _started = true;
          if (mounted) setState(() {});
        }
        if (!_reportedWatched) {
          _reportedWatched = true;
          widget.onWatched?.call();
        }
      }
      // 인앱 재생이 불가한 확정적 에러(임베드 차단 101/150, 영상 없음 100,
      // 검색 불가 105)면 폴백으로 전환하고, 활성 영상이면 부모에 통보해
      // 피드/캐시에서 제거한다. html5Error(5)·unknown 등 일시 오류로는
      // 전환하지 않는다(전체 피드 캐스케이드 방지).
      const unplayable = {
        YoutubeError.notEmbeddable,
        YoutubeError.sameAsNotEmbeddable,
        YoutubeError.videoNotFound,
        YoutubeError.cannotFindVideo,
      };
      if (unplayable.contains(value.error) && mounted) {
        if (!_embedFailed) setState(() => _embedFailed = true);
        _maybeReportUnplayable();
      }
      // 활성 페이지의 영상이 cue(준비·정지) 상태가 되면 즉시 자동재생.
      // 스와이프해 넘어온 다음 영상이 바로 재생됨(진짜 쇼츠처럼).
      if (widget.isActive &&
          widget.screenVisible &&
          !_embedFailed &&
          value.playerState == PlayerState.cued) {
        _controller.playVideo();
      }
      // 중앙 재생 아이콘 표시용(명시적 일시정지 상태만 반영).
      final paused = value.playerState == PlayerState.paused;
      if (paused != _paused && mounted) {
        setState(() => _paused = paused);
      }
    });
    if (widget.isActive && widget.screenVisible) _armWatchdog();
  }

  /// 활성 영상이 제한시간 내 재생되지 않으면 재생 불가로 보고 스킵을 트리거한다.
  void _armWatchdog() {
    _watchdog?.cancel();
    if (!widget.isActive || _started || _reportedUnplayable) return;
    _watchdog = Timer(_playStartTimeout, () {
      if (!mounted || !widget.isActive || _started || _reportedUnplayable) {
        return;
      }
      if (!_embedFailed) setState(() => _embedFailed = true);
      _reportedUnplayable = true;
      widget.onUnplayable?.call();
    });
  }

  @override
  void didUpdateWidget(covariant ShortsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 활성 + 화면 보임일 때만 재생. 둘 중 하나라도 바뀌면 재생/정지 갱신.
    final wasPlaying = oldWidget.isActive && oldWidget.screenVisible;
    final nowPlaying = widget.isActive && widget.screenVisible;
    if (wasPlaying != nowPlaying) {
      if (nowPlaying) {
        // 비활성 상태에서 이미 재생 불가로 판명됐다면, 활성이 되는 순간 통보.
        if (_embedFailed) {
          _maybeReportUnplayable();
        } else {
          _controller.playVideo();
          _armWatchdog(); // 보이는데 재생 안 되면 스킵
        }
      } else {
        _watchdog?.cancel(); // 안 보이는 영상엔 워치독 불필요
        if (!_embedFailed) _controller.pauseVideo();
      }
    }
  }

  /// 활성 + 재생 불가 + 미통보일 때만 부모에 1회 통보한다.
  void _maybeReportUnplayable() {
    if (widget.isActive && _embedFailed && !_reportedUnplayable) {
      _reportedUnplayable = true;
      widget.onUnplayable?.call();
    }
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _sub?.cancel();
    _burst.dispose();
    _controller.close();
    super.dispose();
  }

  void _togglePlay() {
    if (_paused) {
      _controller.playVideo();
    } else {
      _controller.pauseVideo();
    }
  }

  /// 더블탭으로 저장(틱톡식). 이미 저장된 영상은 유지하고 버스트만 표시한다.
  void _onDoubleTapBookmark() {
    HapticFeedback.mediumImpact();
    if (!widget.video.isBookmarked) widget.onBookmark();
    _burst.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 플레이어를 화면 비율로 강제해 풀블리드(9:16)로 채운다.
    // (YoutubePlayer는 내부적으로 AspectRatio로 감싸므로 화면 비율을 넘김)
    final screenAspect = size.width / size.height;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1) 영상 (전체 화면) 또는 폴백
          if (_embedFailed)
            _buildFallback()
          else
            Center(
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: screenAspect,
                backgroundColor: Colors.black,
                enableFullScreenOnVerticalDrag: false, // PageView 스와이프 보존
              ),
            ),

          // 1.5) 재생 도달 전 썸네일 커버 — 스와이프 직후 검은 로딩 프레임을
          //      가려 '끊김 없는 쇼츠' 느낌을 준다. playing 도달 시 페이드아웃.
          if (!_embedFailed)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _started ? 0 : 1,
                  duration: const Duration(milliseconds: 350),
                  child: Image.network(
                    widget.video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: Colors.black),
                  ),
                ),
              ),
            ),

          // 2) 탭으로 재생/정지, 더블탭으로 저장 (세로 스와이프는 PageView로 통과)
          if (!_embedFailed)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
              onDoubleTap: _onDoubleTapBookmark,
            ),

          // 3) 일시정지 시 중앙 재생 아이콘
          if (_paused && !_embedFailed)
            const IgnorePointer(
              child: Center(
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white70, size: 84),
              ),
            ),

          // 3.5) 더블탭 저장 버스트 — 중앙 북마크가 커졌다 사라진다.
          IgnorePointer(
            child: Center(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (_, _) {
                  final t = _burst.value;
                  if (t == 0) return const SizedBox.shrink();
                  final scale = 0.6 + t * 0.7;
                  final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: const Icon(Icons.bookmark_rounded,
                          color: Colors.white, size: 116),
                    ),
                  );
                },
              ),
            ),
          ),

          // 4) 상단 스크림 — 윗부분은 불투명 블랙으로 YouTube 플레이어가 영상
          //    위에 띄우는 제목 바를 가린다(상태바·AppBar와 겹쳐 잘려 보이던 문제).
          //    아래로 갈수록 투명해져 영상이 자연스럽게 드러난다.
          const IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF000000),
                        Color(0xFF000000),
                        Color(0x00000000),
                      ],
                      stops: [0.0, 0.58, 1.0],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),

          // 5) 하단 스크림 (정보/액션 가독성)
          const IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 340,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xB3000000), Color(0x00000000)],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),

          // 6) 하단 정보(좌) + 액션(우)
          Positioned(
            left: 16,
            right: 12,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _buildInfo()),
                    const SizedBox(width: 12),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Semantics(
      container: true,
      label: '${widget.video.topic} 주제 학습 영상. '
          '${widget.video.title}. 채널 ${widget.video.channelTitle}.',
      child: ExcludeSemantics(child: _buildInfoColumn()),
    );
  }

  Widget _buildInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(widget.video.topic,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        Text(
          widget.video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.3,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.video.channelTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(
          icon: widget.video.isBookmarked
              ? Icons.bookmark
              : Icons.bookmark_border,
          label: widget.video.isBookmarked ? '저장됨' : '저장',
          color: widget.video.isBookmarked ? kPrimaryColor : Colors.white,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onBookmark();
          },
        ),
        const SizedBox(height: 22),
        _actionButton(
          icon: Icons.open_in_new_rounded,
          label: 'YouTube',
          color: Colors.white,
          onTap: () => launchYoutube(widget.video.videoId),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 34),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// 인앱 재생이 막힌 영상: 썸네일 + 안내 + 외부 실행
  Widget _buildFallback() {
    return GestureDetector(
      onTap: () => launchYoutube(widget.video.videoId),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.video.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: Colors.black),
          ),
          const ColoredBox(color: Color(0x59000000)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 14),
                const Text('인앱 재생이 제한된 영상이에요',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('탭하면 YouTube에서 볼 수 있어요',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
