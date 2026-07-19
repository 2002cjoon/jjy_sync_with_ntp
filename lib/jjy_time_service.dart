import 'dart:async';
import 'package:ntp/ntp.dart';

class JJYTimeService {
  static final JJYTimeService _instance = JJYTimeService._internal();
  factory JJYTimeService() => _instance;
  JJYTimeService._internal();

  int _deviceTimeOffset = 0;
  bool _isSynced = false;
  String _activeServerName = "미동기화 (로컬 시계)";

  bool get isSynced => _isSynced;
  String get activeServerName => _activeServerName;

  // UI에서 드롭다운 메뉴로 뿌려줄 서버 리스트 리얼 타임 노출
  final List<Map<String, String>> ntpServers = [
    {'name': '일본 국립정보통신연 (NICT)', 'address': 'ntp.nict.jp'},
    {'name': '한국 표준시 서버 (KR Pool)', 'address': 'kr.pool.ntp.org'},
    {'name': '구글 공용 (Google Time)', 'address': '://google.com'},
    {'name': '클라우드플레어 (Cloudflare)', 'address': '://cloudflare.com'},
  ];

  /// 사용자가 선택한 특정 서버 번호(index)로 NTP 동기화를 시도합니다.
  Future<bool> synchronizeWithSpecificServer(int index) async {
    if (index < 0 || index >= ntpServers.length) return false;
    
    final target = ntpServers[index];
    try {
      DateTime ntpTime = await NTP.now(
        lookUpAddress: target['address']!,
        timeout: const Duration(seconds: 4),
      );

      DateTime localTime = DateTime.now();
      _deviceTimeOffset = ntpTime.difference(localTime).inMilliseconds;
      
      _isSynced = true;
      _activeServerName = target['name']!;
      return true;
    } catch (e) {
      _isSynced = false;
      _deviceTimeOffset = 0;
      _activeServerName = "연결 실패 (로컬 시계 사용)";
      return false;
    }
  }

  DateTime get now {
    if (!_isSynced) return DateTime.now(); 
    return DateTime.now().add(Duration(milliseconds: _deviceTimeOffset));
  }

  String getFormattedTrueTime() {
    final trueTime = now;
    final hour = trueTime.hour.toString().padLeft(2, '0');
    final minute = trueTime.minute.toString().padLeft(2, '0');
    final second = trueTime.second.toString().padLeft(2, '0');
    return "$hour:$minute:$second";
  }
}
