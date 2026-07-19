// lib/screens/emulator_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../jjy_time_service.dart';
import '../services/jjy_audio_engine.dart';
import '../widgets/jjy_visualizer.dart';
import '../widgets/telemetry_card.dart';

class EmulatorScreen extends StatefulWidget {
  const EmulatorScreen({super.key});

  @override
  State<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends State<EmulatorScreen> {
  final JJYTimeService _timeService = JJYTimeService();
  late final WebViewController _webViewController;
  
  int _selectedServerIndex = 0;
  bool _isSyncingNetwork = false;
  String _syncStatusText = "NTP 서버를 선택하고 동기화하세요.";
  bool _isTransmitting = false;
  int _selectedFrequency = 60; 
  int _currentSecond = 0;
  String _currentPulseType = "-";
  List<dynamic> _currentFrameData = List.filled(60, "0");
  String _digitalClockDisplay = "00:00:00";
  Timer? _localClockTimer;

  @override
  void initState() {
    super.initState();
    _startDisplayClock();
    _initWebViewController();
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'JJYChannel',
        onMessageReceived: (message) {
          try {
            final parsed = jsonDecode(message.message);
            setState(() {
              _currentSecond = parsed['second'];
              _currentPulseType = parsed['pulseType'];
              _currentFrameData = parsed['fullFrame'];
            });
          } catch (_) {}
        },
      )
      ..loadHtmlString(JJYAudioEngine.htmlSource);
  }

  void _startDisplayClock() {
    _localClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _digitalClockDisplay = _timeService.getFormattedTrueTime();
      });
    });
  }

  Future<void> _triggerNtpSync() async {
    setState(() {
      _isSyncingNetwork = true;
      _syncStatusText = "표준시 RTC 서버 동기화 중...";
    });

    bool success = await _timeService.synchronizeWithSpecificServer(_selectedServerIndex);

    setState(() {
      _isSyncingNetwork = false;
      _syncStatusText = success 
          ? "동기화 성공! [${_timeService.activeServerName}]" 
          : "동기화 실패. 네트워크를 확인하세요.";
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
      appBar: AppBar(title: const Text('JJY Protocol Sync Emulator'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: JJYSignalVisualizer(isTransmitting: _isTransmitting)),
            const SizedBox(height: 16),
            Text(_digitalClockDisplay, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, fontFamily: 'Courier', letterSpacing: 2)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TelemetryCard(label: "STREAM SECOND", value: "#$_currentSecond"),
                TelemetryCard(
                  label: "PULSE TYPE", 
                  value: _currentPulseType, 
                  valueColor: _currentPulseType == "M" ? Colors.orangeAccent : (_currentPulseType == "1" ? Colors.greenAccent : Colors.blueAccent)
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFrameMatrix(),
            const SizedBox(height: 24),
            _buildServerSelector(),
            const SizedBox(height: 24),
            _buildFrequencySelector(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameMatrix() {
    return Column(
      children: [
        const Text("60-SEC TIME DATA FRAME MATRIX", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10, crossAxisSpacing: 5, mainAxisSpacing: 5),
          itemCount: 60,
          itemBuilder: (context, index) {
            bool isCurrent = _currentSecond == index && _isTransmitting;
            var bitVal = _currentFrameData[index];
            Color cellColor = _isTransmitting 
                ? (isCurrent ? Colors.white : (bitVal == 'M' || bitVal.toString().startsWith('P') ? Colors.orange.withAlpha(140) : (bitVal == 1 ? Colors.green.withAlpha(140) : Colors.blue.withAlpha(90))))
                : Colors.white.withAlpha(15);
            return Container(
              decoration: BoxDecoration(color: cellColor, borderRadius: BorderRadius.circular(6), border: isCurrent ? Border.all(color: Colors.greenAccent, width: 2) : null),
              alignment: Alignment.center,
              child: Text(bitVal.toString(), style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? Colors.black : Colors.white70)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServerSelector() {
    return Column(
      children: [
        const Text('RTC TIME SERVER SELECTION:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedServerIndex,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              items: List.generate(_timeService.ntpServers.length, (i) => DropdownMenuItem(value: i, child: Text(_timeService.ntpServers[i]['name']!))),
              onChanged: _isTransmitting ? null : (val) { if (val != null) { setState(() => _selectedServerIndex = val); _triggerNtpSync(); } },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(_syncStatusText, style: TextStyle(fontSize: 12, color: _timeService.isSynced ? Colors.greenAccent : Colors.orangeAccent, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      children: [
        const Text('TRANSMITTER FREQUENCY:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(label: const Text('40 kHz'), selected: _selectedFrequency == 40, onSelected: _isTransmitting ? null : (s) => setState(() => _selectedFrequency = 40)),
            const SizedBox(width: 16),
            ChoiceChip(label: const Text('60 kHz'), selected: _selectedFrequency == 60, onSelected: _isTransmitting ? null : (s) => setState(() => _selectedFrequency = 60)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return ElevatedButton(
      onPressed: _toggleTransmission,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isTransmitting ? Colors.redAccent : Colors.blueAccent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(_isTransmitting ? 'STOP EMULATOR' : 'START EMULATOR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}