// lib/services/jjy_audio_engine.dart
class JJYAudioEngine {
  static String get htmlSource => """
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

          frame[0] = 'M'; frame[9] = 'P1'; frame[19] = 'P2'; frame[29] = 'P3';
          frame[39] = 'P4'; frame[49] = 'P5'; frame[59] = 'P0';

          frame[1] = (min10 & 4) ? 1 : 0; frame[2] = (min10 & 2) ? 1 : 0; frame[3] = (min10 & 1) ? 1 : 0;
          frame[4] = 0;
          frame[5] = (min1 & 8) ? 1 : 0; frame[6] = (min1 & 4) ? 1 : 0; frame[7] = (min1 & 2) ? 1 : 0; frame[8] = (min1 & 1) ? 1 : 0;
          frame[12] = (hour10 & 2) ? 1 : 0; frame[13] = (hour10 & 1) ? 1 : 0;
          frame[14] = 0;
          frame[15] = (hour1 & 8) ? 1 : 0; frame[16] = (hour1 & 4) ? 1 : 0; frame[17] = (hour1 & 2) ? 1 : 0; frame[18] = (hour1 & 1) ? 1 : 0;
          frame[22] = (doy100 & 2) ? 1 : 0; frame[23] = (doy100 & 1) ? 1 : 0;
          frame[24] = 0;
          frame[25] = (doy10 & 8) ? 1 : 0; frame[26] = (doy10 & 4) ? 1 : 0; frame[27] = (doy10 & 2) ? 1 : 0; frame[28] = (doy10 & 1) ? 1 : 0;
          frame[30] = (doy1 & 8) ? 1 : 0; frame[31] = (doy1 & 4) ? 1 : 0; frame[32] = (doy1 & 2) ? 1 : 0; frame[33] = (doy1 & 1) ? 1 : 0;
          frame[36] = p1; frame[37] = p2;
          frame[41] = (year10 & 8) ? 1 : 0; frame[42] = (year10 & 4) ? 1 : 0; frame[43] = (year10 & 2) ? 1 : 0; frame[44] = (year10 & 1) ? 1 : 0;
          frame[45] = (year1 & 8) ? 1 : 0; frame[46] = (year1 & 4) ? 1 : 0; frame[47] = (year1 & 2) ? 1 : 0; frame[48] = (year1 & 1) ? 1 : 0;
          frame[50] = (wday & 4) ? 1 : 0; frame[51] = (wday & 2) ? 1 : 0; frame[52] = (wday & 1) ? 1 : 0;

          return frame;
        }

        function startJJY(targetFreq) {
          if (audioCtx) return;
          audioCtx = new (window.AudioContext || window.webkitAudioContext)();
          oscillator = audioCtx.createOscillator();
          gainNode = audioCtx.createGain();
          oscillator.type = 'square';
          oscillator.frequency.setValueAtTime(targetFreq === 40 ? 13333.33 : 20000.00, audioCtx.currentTime);
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

            if (currentBit === 1) { highDuration = 500; pulseType = "1"; }
            else if (typeof currentBit === 'string') { highDuration = 200; pulseType = "M"; }

            if (window.JJYChannel) {
              window.JJYChannel.postMessage(JSON.stringify({
                "second": sec,
                "pulseType": pulseType,
                "fullFrame": frame
              }));
            }

            gainNode.gain.setValueAtTime(1.0, audioCtx.currentTime);
            setTimeout(() => { gainNode.gain.setValueAtTime(0.0, audioCtx.currentTime); }, highDuration);
            mainLoop = setTimeout(tick, 1000 - new Date().getMilliseconds());
          }
          tick();
        }

        function stopJJY() {
          if (mainLoop) clearTimeout(mainLoop);
          if (oscillator) { oscillator.stop(); oscillator.disconnect(); }
          if (audioCtx) audioCtx.close();
          audioCtx = null; oscillator = null; gainNode = null;
        }
      </script>
    </body>
    </html>
  """;
}