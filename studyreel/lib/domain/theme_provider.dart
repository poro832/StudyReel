import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 현재 다크 모드 여부 (기본: 다크). 스플래시에서 저장값으로 시드하고,
/// 프로필 토글에서 변경·영속화한다.
final isDarkProvider = StateProvider<bool>((_) => true);
