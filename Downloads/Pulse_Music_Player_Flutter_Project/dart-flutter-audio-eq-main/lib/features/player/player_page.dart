import '../../theme/app_colors.dart';
import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../equalizer/three_band_equalizer.dart';

class _Track {
  const _Track({required this.title, this.path, this.asset});
  final String title;
  final String? path;
  final String? asset;
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final SoLoud _audio = SoLoud.instance;
  late final ThreeBandEqualizer _eq = ThreeBandEqualizer(_audio);
  final List<_Track> _tracks = [
    const _Track(title: 'Demo Track', asset: 'assets/samples/demo.wav'),
  ];
  AudioSource? _source;
  SoundHandle? _handle;
  int _trackIndex = 0;
  bool _initialized = false;
  bool _loading = false;
  bool _playing = false;
  bool _draggingSeek = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _ticker;
  List<double> _gains = [0, 0, 0];
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _audio.init();
      _eq.initialize();
      _initialized = true;
      await _loadTrack(0, autoplay: false);
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        _refreshPosition();
      });
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = 'Audio engine could not start: $e');
    }
  }

  Future<void> _loadTrack(int index, {bool autoplay = true}) async {
    if (!_initialized || _tracks.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final oldSource = _source;
      final track = _tracks[index];
      final nextSource = track.asset != null
          ? await _audio.loadAsset(track.asset!)
          : await _audio.loadFile(track.path!);
      if (_handle != null && _audio.getIsValidVoiceHandle(_handle!)) {
        await _audio.stop(_handle!);
      }
      if (oldSource != null) await _audio.disposeSource(oldSource);
      _source = nextSource;
      _trackIndex = index;
      _duration = _audio.getLength(nextSource);
      _position = Duration.zero;
      _playing = false;
      _handle = _audio.play(nextSource, paused: !autoplay);
      _playing = autoplay;
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Could not open this audio file: $e';
      });
    }
  }

  Future<void> _pickAudio() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.audio);
      if (files.isEmpty) return;
      final additions = files
          .where((f) => f.path != null)
          .map((f) => _Track(title: f.name, path: f.path))
          .toList();
      if (additions.isEmpty) {
        if (mounted) setState(() => _error = 'The selected files could not be accessed from local storage.');
        return;
      }
      setState(() => _tracks.addAll(additions));
      await _loadTrack(_tracks.length - additions.length);
    } catch (e) {
      if (mounted) setState(() => _error = 'File picker failed: $e');
    }
  }

  void _togglePlayback() {
    final handle = _handle;
    if (handle == null || !_audio.getIsValidVoiceHandle(handle)) {
      final source = _source;
      if (source == null) return;
      _handle = _audio.play(source);
      setState(() {
        _position = Duration.zero;
        _playing = true;
      });
      return;
    }
    _audio.pauseSwitch(handle);
    setState(() => _playing = !_playing);
  }

  void _refreshPosition() {
    final handle = _handle;
    if (!_initialized || handle == null) return;
    if (!_audio.getIsValidVoiceHandle(handle)) {
      if (_playing && mounted) setState(() => _playing = false);
      return;
    }
    final next = _audio.getPosition(handle);
    if (!_draggingSeek && mounted) {
      setState(() {
        _position = next;
        if (_duration > Duration.zero && next >= _duration) _playing = false;
      });
    }
  }

  void _seek(double milliseconds) {
    final handle = _handle;
    if (handle == null || !_audio.getIsValidVoiceHandle(handle)) return;
    final value = Duration(milliseconds: milliseconds.round());
    _audio.seek(handle, value);
    setState(() => _position = value);
  }

  void _changeEq(int band, double value) {
    _eq.setGain(band, value);
    setState(() => _gains = _eq.gainsDb);
  }

  Future<void> _next() async {
    if (_tracks.isEmpty) return;
    await _loadTrack((_trackIndex + 1) % _tracks.length);
  }

  Future<void> _previous() async {
    if (_tracks.isEmpty) return;
    await _loadTrack((_trackIndex - 1 + _tracks.length) % _tracks.length);
  }

  String _time(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _eq.dispose();
    final source = _source;
    if (source != null) unawaited(_audio.disposeSource(source));
    if (_initialized) unawaited(_audio.deinitAsync());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = _tracks.isEmpty ? 'No track selected' : _tracks[_trackIndex].title;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
              children: [
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: AppColors.burgundy, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.graphic_eq_rounded, color: AppColors.cream),
                  ),
                  const SizedBox(width: 12),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PULSE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2.2)),
                    Text('MUSIC PLAYER', style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 1.8)),
                  ]),
                  const Spacer(),
                  IconButton.filledTonal(onPressed: _pickAudio, icon: const Icon(Icons.library_add_rounded), tooltip: 'Add audio files'),
                ]),
                const SizedBox(height: 28),
                _buildArtwork(track),
                const SizedBox(height: 24),
                Text(track, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(_tracks.length == 1 ? 'YOUR MUSIC' : 'TRACK ${_trackIndex + 1} OF ${_tracks.length}',
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 1.8)),
                const SizedBox(height: 20),
                _buildTransport(),
                const SizedBox(height: 26),
                _buildEqualizer(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: AppColors.burgundy)),
                ],
                const SizedBox(height: 18),
                Text('SUPPORTED: WINDOWS  •  ANDROID', textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 1.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(String track) => Container(
    height: 210,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          AppColors.plum,
          AppColors.burgundy,
          AppColors.dustyRose,
        ]),
    ),
    child: Stack(alignment: Alignment.center, children: [
      Positioned(top: 22, left: 26, child: Text('NOW PLAYING', style: TextStyle(color: AppColors.muted.withValues(alpha: .8), fontSize: 10, letterSpacing: 2))),
      const Icon(
        Icons.album_rounded,
        size: 146,
        color: AppColors.peach,
      ),
      Positioned(bottom: 18, right: 22, child: Icon(Icons.graphic_eq, size: 34, color: AppColors.peach)),
    ]),
  );

  Widget _buildTransport() => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(children: [
        Slider(
          min: 0,
          max: (_duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1).toDouble(),
          value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1).toDouble(),
          onChangeStart: (_) => setState(() => _draggingSeek = true),
          onChanged: _duration == Duration.zero ? null : (v) => setState(() => _position = Duration(milliseconds: v.round())),
          onChangeEnd: (v) { _seek(v); setState(() => _draggingSeek = false); },
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_time(_position), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontFeatures: [FontFeature.tabularFigures()])),
          Text(_time(_duration), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontFeatures: [FontFeature.tabularFigures()])),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: _loading ? null : _previous, iconSize: 28, icon: const Icon(Icons.skip_previous_rounded)),
          const SizedBox(width: 16),
          SizedBox(width: 62, height: 62, child: FilledButton(
            onPressed: _loading || !_initialized ? null : _togglePlayback,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.burgundy,
              foregroundColor: AppColors.cream,
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 34),
          )),
          const SizedBox(width: 16),
          IconButton(onPressed: _loading ? null : _next, iconSize: 28, icon: const Icon(Icons.skip_next_rounded)),
        ]),
      ]),
    ),
  );

  Widget _buildEqualizer() => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('EQUALIZER', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.7, fontSize: 13))),
          TextButton.icon(onPressed: () {
            _eq.reset();
            setState(() => _gains = _eq.gainsDb);
          }, icon: const Icon(Icons.restart_alt_rounded, size: 17), label: const Text('Reset')),
        ]),
        const SizedBox(height: 4),
        const Text('Shape your sound with three live frequency bands', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 18),
        _bandSlider(0, 'LOW', '100 Hz', Icons.graphic_eq_rounded),
        _bandSlider(1, 'MID', '1 kHz', Icons.multitrack_audio_rounded),
        _bandSlider(2, 'HIGH', '8 kHz', Icons.equalizer_rounded),
        const SizedBox(height: 4),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('−12 dB', style: TextStyle(color: AppColors.muted, fontSize: 10)),
          Text('FLAT', style: TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 1.5)),
          Text('+12 dB', style: TextStyle(color: AppColors.muted, fontSize: 10)),
        ]),
      ]),
    ),
  );

  Widget _bandSlider(int index, String name, String frequency, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.softRose, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.dustyRose, size: 19)),
      const SizedBox(width: 12),
      SizedBox(width: 48, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        Text(frequency, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ])),
      Expanded(child: Slider(value: _gains[index], min: -12, max: 12, divisions: 48, onChanged: (v) => _changeEq(index, v))),
      SizedBox(width: 48, child: Text('${_gains[index] > 0 ? '+' : ''}${_gains[index].toStringAsFixed(1)}', textAlign: TextAlign.end,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]))),
    ]),
  );
}
