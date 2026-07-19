import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'jjy_time_service.dart';

void main() {
  runApp(const JJYEmulatorApp());
}

class JJYEmulatorApp extends StatelessWidget {
  const JJYEmulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JJY Atomic Sync Emulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.greenAccent,
        ),
      ),
      home: const EmulatorScreen(),
    );
  }
}

class EmulatorScreen extends StatefulWidget {
  const EmulatorScreen({super.key});

  @override
  State<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State<EmulatorScreen> {
  final JJYTimeService _timeService = JJYTimeService();
  int _selectedServerIndex = 0; // 기본 선택: 일본 NICT 서버
  bool _isSyncingNetwork = false;
  String _syncStatusText = "NTP 서버를 선택하고 동기화하세요.";

    Future<void> _triggerNtpSync() async {
    setState(() {
      _isSyncingNetwork = true;
      _syncStatusText = "표준시 RTC 서버 동기화 중...";
    });

    bool success = await _timeService.synchronizeWithSpecificServer(_selectedServerIndex);

    setState(() {
      _isSyncingNetwork = false;
      if (success) {
        _syncStatusText = "동기화 성공! [${_timeService.activeServerName}]";
      } else {
        _syncStatusText = "동기화 실패. 네트워크를 확인하세요.";
      }
    });
  }


  late final WebViewController _webViewController;
  bool _isTransmitting = false;
  int _selectedFrequency = 60; 
  
  int _currentSecond = 0;
  String _currentPulseType = "-";
  List<dynamic> _currentFrameData = List.filled(60, "0");
  String _digitalClockDisplay = "00:00:00";
  Timer? _localClockTimer;

  final String _htmlAudioSource = """
    <!DOCTYPE html>
    <html>
    <head><title>Full JJY Protocol Engine</title></head>
    <body>
      <script>
        let audioCtx = null;
        let oscillator = null;
        let gainNode = null;
        let mainLoop = null;

        function getDayOfYear(date) {
          const start = new Date(date.getFullYear(), 0, 0);
          const diff = date - start;
          const oneDay = 1000 * 60 * 60 * 24;
          return Math.floor(diff / oneDay);
        }

        function generateJJYFrame(date) {
          const frame = new Array(60).fill(0);
          
          const min = date.getMinutes();
          const min10 = Math.floor(min / 10);
          const min1 = min % 10;

          const hour = date.getHours();
          const hour10 = Math.floor(hour / 10);
          const hour1 = hour % 10;

          const doy = getDayOfYear(date);
          const doy100 = Math.floor(doy / 100);
          const doy10 = Math.floor((doy % 100) / 10);
          const doy1 = doy % 10;

          const year = date.getFullYear() % 100;
          const year10 = Math.floor(year / 10);
          const year1 = year % 10;

          const wday = date.getDay(); 

          let p1 = 0; 
          let hBits = (hour10 * 10) + hour1;
          while (hBits > 0) { p1 += hBits & 1; hBits >>= 1; }
          p1 = p1 % 2;

          let p2 = 0; 
          let mBits = (min10 * 10) + min1;
          while (mBits > 0) { p2 += mBits & 1; mBits >>= 1; }
          p2 = p2 % 2;

          frame[0] = 'M';
          frame[9] = 'P1';
          frame[19] = 'P2';
          frame[29] = 'P3';
          frame[39] = 'P4';
          frame[49] = 'P5';
          frame[59] = 'P0';

          frame[1] = (min10 & 4) ? 1 : 0;
          frame[2] = (min10 & 2) ? 1 : 0;
          frame[3] = (min10 & 1) ? 1 : 0;
          frame[4] = 0;
          frame[5] = (min1 & 8) ? 1 : 0;
          frame[6] = (min1 & 4) ? 1 : 0;
          frame[7] = (min1 & 2) ? 1 : 0;
          frame[8] = (min1 & 1) ? 1 : 0;

          frame[12] = (hour10 & 2) ? 1 : 0;
          frame[13] = (hour10 & 1) ? 1 : 0;
          frame[14] = 0;
          frame[15] = (hour1 & 8) ? 1 : 0;
          frame[16] = (hour1 & 4) ? 1 : 0;
          frame[17] = (hour1 & 2) ? 1 : 0;
          frame[18] = (hour1 & 1) ? 1 : 0;

          frame[22] = (doy100 & 2) ? 1 : 0;
          frame[23] = (doy100 & 1) ? 1 : 0;
          frame[24] = 0;
          frame[25] = (doy10 & 8) ? 1 : 0;
          frame[26] = (doy10 & 4) ? 1 : 0;
          frame[27] = (doy10 & 2) ? 1 : 0;
          frame[28] = (doy10 & 1) ? 1 : 0;

          frame[30] = (doy1 & 8) ? 1 : 0;
          frame[31] = (doy1 & 4) ? 1 : 0;
          frame[32] = (doy1 & 2) ? 1 : 0;
          frame[33] = (doy1 & 1) ? 1 : 0;

          frame[36] = p1;
          frame[37] = p2;

          frame[41] = (year10 & 8) ? 1 : 0;
          frame[42] = (year10 & 4) ? 1 : 0;
          frame[43] = (year10 & 2) ? 1 : 0;
          frame[44] = (year10 & 1) ? 1 : 0;
          frame[45] = (year1 & 8) ? 1 : 0;
          frame[46] = (year1 & 4) ? 1 : 0;
          frame[47] = (year1 & 2) ? 1 : 0;
          frame[48] = (year1 & 1) ? 1 : 0;

          frame[50] = (wday & 4) ? 1 : 0;
          frame[51] = (wday & 2) ? 1 : 0;
          frame[52] = (wday & 1) ? 1 : 0;

          return frame;
        }

        function startJJY(targetFreq) {
          if (audioCtx) return;
          audioCtx = new (window.AudioContext || window.webkitAudioContext)();
          oscillator = audioCtx.createOscillator();
          gainNode = audioCtx.createGain();

          oscillator.type = 'square';
          if (targetFreq === 40) {
            oscillator.frequency.setValueAtTime(13333.33, audioCtx.currentTime);
          } else {
            oscillator.frequency.setValueAtTime(20000.00, audioCtx.currentTime);
          }

          gainNode.gain.setValueAtTime(0, audioCtx.currentTime);
          oscillator.connect(gainNode);
          gainNode.connect(audioCtx.destination);
          oscillator.start();

          function tick() {
            const now = new Date();
            const sec = now.getSeconds();
            
            const frame = generateJJYFrame(now);
            const currentBit = frame[sec];

            let highDuration = 800; 
            let pulseType = "0";

            if (currentBit === 1) {
              highDuration = 500;   
              pulseType = "1";
            } else if (typeof currentBit === 'string') {
              highDuration = 200;   
              pulseType = "M";
            }

            if (window.JJYChannel) {
              window.JJYChannel.postMessage(JSON.stringify({
                "second": sec,
                "pulseType": pulseType,
                "fullFrame": frame
              }));
            }

            gainNode.gain.setValueAtTime(1.0, audioCtx.currentTime);
            setTimeout(() => {
              gainNode.gain.setValueAtTime(0.0, audioCtx.currentTime);
            }, highDuration);

            const nextTickDelay = 1000 - new Date().getMilliseconds();
            mainLoop = setTimeout(tick, nextTickDelay);
          }

          tick();
        }

        function stopJJY() {
          if (mainLoop) clearTimeout(mainLoop);
          if (oscillator) {
            oscillator.stop();
            oscillator.disconnect();
          }
          if (audioCtx) audioCtx.close();
          audioCtx = null;
          oscillator = null;
          gainNode = null;
        }
      </script>
    </body>
    </html>
  """;

  @override
  void initState() {
    super.initState();
    _startDisplayClock();
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'JJYChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final Map<String, dynamic> parsed = jsonDecode(message.message);
            setState(() {
              _currentSecond = parsed['second'];
              _currentPulseType = parsed['pulseType'];
              _currentFrameData = parsed['fullFrame'];
            });
          } catch (_) {}
        },
      )
      ..loadHtmlString(_htmlAudioSource);
  }

  void _startDisplayClock() {
    _localClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      setState(() {
        _digitalClockDisplay = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      });
    });
  }

  void _toggleTransmission() {
    setState(() {
      _isTransmitting = !_isTransmitting;
      if (!_isTransmitting) {
        _currentSecond = 0;
        _currentPulseType = "-";
        _currentFrameData = List.filled(60, "0");
      }
    });

    if (_isTransmitting) {
      _webViewController.runJavaScript("startJJY($_selectedFrequency);");
    } else {
      _webViewController.runJavaScript("stopJJY();");
    }
  }

  @override
  void dispose() {
    _localClockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JJY Protocol Sync Emulator'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: JJYSignalVisualizer(isTransmitting: _isTransmitting),
              ),
              const SizedBox(height: 16),
              
              Text(
                _digitalClockDisplay,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTelemetryCard("STREAM SECOND", "#$_currentSecond"),
                  _buildTelemetryCard(
                    "PULSE TYPE", 
                    _currentPulseType, 
                    valueColor: _currentPulseType == "M" ? Colors.orangeAccent : (_currentPulseType == "1" ? Colors.greenAccent : Colors.blueAccent)
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                "60-SEC TIME DATA FRAME MATRIX",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemCount: 60,
                itemBuilder: (context, index) {
                  bool isCurrent = _currentSecond == index && _isTransmitting;
                  var bitVal = _currentFrameData[index];
                  
                  Color cellColor = Colors.white.withAlpha(15);
                  if (_isTransmitting) {
                    if (isCurrent) {
                      cellColor = Colors.white;
                    } else if (bitVal == 'M' || bitVal.toString().startsWith('P')) {
                      cellColor = Colors.orange.withAlpha(140);
                    } else if (bitVal == 1) {
                      cellColor = Colors.green.withAlpha(140);
                    } else {
                      cellColor = Colors.blue.withAlpha(90);
                    }
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(6),
                      border: isCurrent ? Border.all(color: Colors.greenAccent, width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bitVal.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? Colors.black : Colors.white70,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
                            // --- 새 기능: RTC 표준시 서버 직접 선택 컨테이너 ---
              const Text(
                'RTC TIME SERVER SELECTION:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedServerIndex,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    items: List.generate(_timeService.ntpServers.length, (index) {
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(_timeService.ntpServers[index]['name']!),
                      );
                    }),
                    onChanged: _isTransmitting ? null : (int? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedServerIndex = newValue);
                        _triggerNtpSync(); // 서버 변경 시 자동으로 즉시 재동기화 시도
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _syncStatusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, 
                  color: _timeService.isSynced ? Colors.greenAccent : Colors.orangeAccent,
                  fontStyle: FontStyle.italic
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'TRANSMITTER FREQUENCY:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('40 kHz (Fukushima)'),
                    selected: _selectedFrequency == 40,
                    selectedColor: Colors.blueAccent.withAlpha(80),
                    onSelected: _isTransmitting ? null : (selected) {
                      if (selected) setState(() => _selectedFrequency = 40);
                    },
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('60 kHz (Kyushu)'),
                    selected: _selectedFrequency == 60,
                    selectedColor: Colors.blueAccent.withAlpha(80),
                    onSelected: _isTransmitting ? null : (selected) {
                      if (selected) setState(() => _selectedFrequency = 60);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _toggleTransmission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTransmitting ? Colors.redAccent : Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isTransmitting ? 'STOP EMULATOR' : 'START EMULATOR',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryCard(String label, String value, {Color valueColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor, fontFamily: 'Courier')),
        ],
      ),
    );
  }
}

class JJYSignalVisualizer extends StatefulWidget {
  final bool isTransmitting;
  const JJYSignalVisualizer({super.key, required this.isTransmitting});

  @override
  State<JJYSignalVisualizer> createState() => _JJYSignalVisualizerState();
}

class _JJYSignalVisualizerState extends State<JJYSignalVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (widget.isTransmitting) _controller.repeat();
  }

  @override
  void didUpdateWidget(JJYSignalVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTransmitting && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isTransmitting && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: 160,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildRippleRing(value: _controller.value, delay: 0.5),
              _buildRippleRing(value: _controller.value, delay: 0.0),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isTransmitting ? Colors.green.withAlpha(30) : Colors.blueAccent.withAlpha(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Icon(
                  Icons.settings_input_antenna,
                  size: 48,
                  color: widget.isTransmitting ? Colors.greenAccent : Colors.blueAccent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRippleRing({required double value, required double delay}) {
    if (!widget.isTransmitting) return const SizedBox.shrink();
    double progress = (value + delay) % 1.0;
    return Transform.scale(
      scale: 1.0 + (progress * 1.2),
      child: Opacity(
        opacity: (1.0 - progress).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 1.5),
          ),
          width: 80,
          height: 80,
         ),
       ),
    );
  }
}
