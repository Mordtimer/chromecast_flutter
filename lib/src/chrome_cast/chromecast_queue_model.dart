import 'package:flutter_cast_video/src/chrome_cast/chromecast_media_item_model.dart';

class ChromecastQueueModel {
  final List<ChromecastMediaItemModel> queue;
  final int index;
  final int position;

  ChromecastQueueModel(
    this.queue, {
    this.index = 0,
    this.position = 0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'queue': queue.map((e) => e.toJson()).toList(),
        'position': position,
        'queueIndex': index,
      };
}
