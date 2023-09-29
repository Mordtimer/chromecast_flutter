import '../chrome_cast/chrome_cast_event.dart';

class CastMediaItemEvent extends ChromeCastEvent {
  final bool isPlaying;
  final bool isPaused;
  final bool isBuffering;
  final int? index;
  final double volume;
  final int position;
  final double progress;

  CastMediaItemEvent({
    required int id,
    required this.isPlaying,
    required this.isPaused,
    required this.isBuffering,
    required this.index,
    required this.volume,
    required this.position,
    required this.progress,
  }) : super(id);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'isPlaying': isPlaying,
        'isPaused': isPaused,
        'isBuffering': isBuffering,
        'index': index,
        'volume': volume,
        'position': position,
        'progress': progress,
      };
}
