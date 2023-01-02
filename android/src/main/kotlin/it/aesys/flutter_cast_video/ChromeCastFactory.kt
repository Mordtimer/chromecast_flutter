package it.aesys.flutter_cast_video

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView

class ChromeCastFactory(private val binaryMessenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    var activity: Context? = null

    override fun create(
            context: Context?,
            viewId: Int,
            args: Any?
    ): PlatformView = ChromeCastController(
            messenger = binaryMessenger,
            viewId = viewId,
            context = activity
    )
}
