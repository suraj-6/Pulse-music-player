import 'dart:math' as math;
import 'package:flutter_soloud/flutter_soloud.dart';

/// Three-band parametric EQ applied to SoLoud's live output mixer.
/// UI values are dB; SoLoud's parametric EQ gain is a linear multiplier.
class ThreeBandEqualizer {
  ThreeBandEqualizer(this._audio);

  final SoLoud _audio;
  static const frequencies = [100.0, 1000.0, 8000.0];
  static const qValues = [0.8, 1.0, 0.8];
  static const flat = [0.0, 0.0, 0.0];
  final List<double> _gainsDb = [...flat];
  bool _ready = false;

  List<double> get gainsDb => List.unmodifiable(_gainsDb);

  void initialize() {
    final eq = _audio.filters.parametricEqFilter;
    eq.activate();
    eq
      ..stftWindowSize.value = 1024
      ..numBands.value = 3;
    for (var i = 0; i < 3; i++) {
      eq.bandFreq(i).value = frequencies[i];
      eq.bandQ(i).value = qValues[i];
      eq.bandGain(i).value = 1.0;
    }
    _ready = true;
  }

  void setGain(int band, double db) {
    if (!_ready || band < 0 || band > 2) return;
    final safeDb = db.clamp(-12.0, 12.0).toDouble();
    _gainsDb[band] = safeDb;
    // SoLoud parametric EQ: 1.0 = flat, 0.0..4.0 is the documented range.
    final linearGain = math.pow(10.0, safeDb / 20.0).toDouble().clamp(0.0, 4.0);
    _audio.filters.parametricEqFilter.bandGain(band).value = linearGain;
  }

  void reset() {
    for (var i = 0; i < 3; i++) {
      setGain(i, 0);
    }
  }

  void dispose() {
    if (_ready) {
      _audio.filters.parametricEqFilter.deactivate();
      _ready = false;
    }
  }
}
