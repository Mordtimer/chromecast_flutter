library flutter_cast_video;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_cast_video/src/chrome_cast/chrome_cast_platform.dart';
import 'package:flutter_cast_video/src/air_play/air_play_platform.dart';
import 'package:flutter_cast_video/src/models/chromecast_queue_model.dart';

import 'src/models/cast_media_item_event.dart';

export 'package:flutter_cast_video/src/models/chromecast_queue_model.dart';
export 'package:flutter_cast_video/src/models/chromecast_media_item_model.dart';

part 'src/chrome_cast/chrome_cast_controller.dart';
part 'src/chrome_cast/chrome_cast_button.dart';
part 'src/air_play/air_play_button.dart';
