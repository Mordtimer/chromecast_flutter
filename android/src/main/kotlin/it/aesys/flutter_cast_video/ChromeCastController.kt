package it.aesys.flutter_cast_video

import android.content.Context
import android.net.Uri
import android.view.ContextThemeWrapper
import androidx.mediarouter.app.MediaRouteButton
import com.google.android.gms.cast.*
import com.google.android.gms.cast.framework.*
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.common.api.PendingResult
import com.google.android.gms.common.api.Status
import com.google.android.gms.common.images.WebImage
import io.flutter.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.json.JSONObject


class ChromeCastController(
    messenger: BinaryMessenger,
    viewId: Int,
    context: Context?
) : PlatformView, MethodChannel.MethodCallHandler, SessionManagerListener<Session>,
    PendingResult.StatusListener {
    private val channel = MethodChannel(messenger, "flutter_cast_video/chromeCast_$viewId")
    private val chromeCastButton =
        MediaRouteButton(ContextThemeWrapper(context, R.style.ChromecastCustomStyle))
    private val sessionManager = CastContext.getSharedInstance()?.sessionManager

    init {
        CastButtonFactory.setUpMediaRouteButton(context as Context, chromeCastButton)
        channel.setMethodCallHandler(this)
    }

    private fun loadMedia(args: Any?) {
        if (args is Map<*, *>) {
            val url = args["url"] as? String ?: ""
            val title = args["title"] as? String ?: ""
            val subtitle = args["subtitle"] as? String ?: ""
            val imageUrl = args["image"] as? String ?: ""
            val contentType = args["contentType"] as? String ?: "audio/mpeg"
            val liveStream = args["live"] as? Boolean ?: false

            val movieMetadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE)

            val streamType =
                if (liveStream) MediaInfo.STREAM_TYPE_LIVE else MediaInfo.STREAM_TYPE_BUFFERED

            movieMetadata.putString(MediaMetadata.KEY_TITLE, title)
            movieMetadata.putString(MediaMetadata.KEY_SUBTITLE, subtitle)
            movieMetadata.addImage(WebImage(Uri.parse(imageUrl)))

            val media = MediaInfo
                .Builder(url)
                .setStreamType(streamType)
                .setContentType(contentType)
                .setMetadata(movieMetadata)
                .build()
            val options = MediaLoadOptions.Builder().build()
            val request =
                sessionManager?.currentCastSession?.remoteMediaClient?.load(media, options)

            request?.addStatusListener(this)
        }
    }

    private fun play() {
        val request = sessionManager?.currentCastSession?.remoteMediaClient?.play()
        request?.addStatusListener(this)
    }

    private fun pause() {
        val request = sessionManager?.currentCastSession?.remoteMediaClient?.pause()
        request?.addStatusListener(this)
    }

    private fun loadMediaQueue(args: Any?) {
        val items: MutableList<MediaQueueItem> = mutableListOf()
        Log.d("LOADMEDIAQUEUE", "BEEEKA")
        var position: Int = 0
        var queueIndex: Int = 0


        if (args is Map<*, *>) {
            val jsonList = args["queue"] as? List<*>
            // Make sure that list have an proper type if null - just return end do nothing
            val queue =
                jsonList?.filterIsInstance<Map<*, *>>().takeIf { it?.size == jsonList?.size }
                    ?: return

            position = args["position"] as? Int ?: 0
            queueIndex = args["queueIndex"] as? Int ?: 0

            for (item in queue) {
                val url = item["url"] as? String ?: ""
                val title = item["title"] as? String ?: ""
                val subtitle = item["subtitle"] as? String ?: ""
                val imageUrl = item["image"] as? String ?: ""
                val contentType = item["contentType"] as? String ?: "audio/mpeg"
                val liveStream = item["live"] as? Boolean ?: false

                val movieMetadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE)

                val streamType =
                    if (liveStream) MediaInfo.STREAM_TYPE_LIVE else MediaInfo.STREAM_TYPE_BUFFERED

                movieMetadata.putString(MediaMetadata.KEY_TITLE, title)
                movieMetadata.putString(MediaMetadata.KEY_SUBTITLE, subtitle)
                movieMetadata.addImage(WebImage(Uri.parse(imageUrl)))

                val mediaInfo = MediaInfo
                    .Builder(url)
                    .setStreamType(streamType)
                    .setContentType(contentType)
                    .setMetadata(movieMetadata)
                    .build()
                val queueItem: MediaQueueItem = MediaQueueItem.Builder(mediaInfo)
                    .setAutoplay(true)
                    .setPreloadTime(20.0)


                    .build()

                items.add(queueItem)
            }
        }
        Log.d("LOADMEDIAQUEUE", args.toString())
        Log.d("LOADMEDIAQUEUE", items.toString())
        Log.d("LOADMEDIAQUEUE POSITION", position.toString())
        Log.d("LOADMEDIAQUEUE QUEUE INDEX", queueIndex.toString())
        Log.d("LOADMEDIAQUEUE ARGS", args.toString())


        val options = MediaLoadOptions.Builder().build()
        val request =
            sessionManager?.currentCastSession?.remoteMediaClient?.queueLoad(
                items.toTypedArray(),
                queueIndex,
                MediaStatus.REPEAT_MODE_REPEAT_OFF,
                position.toLong(),
                options.customData ?: JSONObject()
            )
        request?.addStatusListener(this)

    }


    private fun seek(args: Any?) {
        if (args is Map<*, *>) {
            val relative = (args["relative"] as? Boolean) ?: false
            var interval = args["interval"] as? Double
            interval = interval?.times(1000)
            if (relative) {
                interval = interval?.plus(
                    sessionManager?.currentCastSession?.remoteMediaClient?.mediaStatus?.streamPosition
                        ?: 0
                )
            }
            val request =
                sessionManager?.currentCastSession?.remoteMediaClient?.seek(interval?.toLong() ?: 0)
            request?.addStatusListener(this)
        }
    }

    private fun mediaInfoToMap(mediaInfo: MediaInfo?): HashMap<String, String>? {
        var info = HashMap<String, String>()
        mediaInfo?.let {
            var id = mediaInfo.getContentId() ?: ""
            info["id"] = id
            info["url"] = mediaInfo.getContentUrl() ?: id
            info["contentType"] = mediaInfo.getContentType() ?: ""
            // info["customData"] = mediaInfo.getCustomData().toString() ?: ""
            var meta = mediaInfo.getMetadata()
            meta?.let {
                info["title"] = meta.getString(MediaMetadata.KEY_TITLE) ?: ""
                info["subtitle"] = meta.getString(MediaMetadata.KEY_SUBTITLE) ?: ""
                val imgs = meta.getImages()
                if (imgs.size > 0) {
                    info["image"] = imgs[0].getUrl().toString();
                }
            }
        }
        return info;
    }

    private fun getMediaInfo(): HashMap<String, String>? =
        mediaInfoToMap(sessionManager?.currentCastSession?.remoteMediaClient?.getMediaInfo())


    private fun setVolume(args: Any?) {
        if (args is Map<*, *>) {
            val volume = args["volume"] as? Double
            val request = sessionManager?.currentCastSession?.remoteMediaClient?.setStreamVolume(
                volume ?: 0.0
            )
            request?.addStatusListener(this)
        }
    }

    private fun getVolume() = sessionManager?.currentCastSession?.volume ?: 0.0

    private fun stop() {
        val request = sessionManager?.currentCastSession?.remoteMediaClient?.stop()
        request?.addStatusListener(this)
    }

    private fun isPlaying() =
        sessionManager?.currentCastSession?.remoteMediaClient?.isPlaying ?: false

    private fun isConnected() = sessionManager?.currentCastSession?.isConnected ?: false

    private fun endSession() = sessionManager?.endCurrentSession(true)

    private fun position() =
        sessionManager?.currentCastSession?.remoteMediaClient?.approximateStreamPosition ?: 0

    private fun duration() =
        sessionManager?.currentCastSession?.remoteMediaClient?.mediaInfo?.streamDuration ?: 0

    private fun addSessionListener() {
        sessionManager?.addSessionManagerListener(this)
    }

    private fun removeSessionListener() {
        sessionManager?.removeSessionManagerListener(this)
    }

    private val mRemoteMediaClientListener: RemoteMediaClient.Callback =
        object : RemoteMediaClient.Callback() {
            override fun onStatusUpdated() {
                val mediaStatus: MediaStatus? =
                    sessionManager?.currentCastSession?.remoteMediaClient?.mediaStatus
                val playerStatus: Int = mediaStatus?.playerState ?: MediaStatus.PLAYER_STATE_UNKNOWN
                var retCode: Int = playerStatus
                if (playerStatus == MediaStatus.PLAYER_STATE_PLAYING) {
                    retCode = 1
                } else if (playerStatus == MediaStatus.PLAYER_STATE_BUFFERING) {
                    retCode = 0
                } else if (playerStatus == MediaStatus.PLAYER_STATE_IDLE && mediaStatus?.getIdleReason() === MediaStatus.IDLE_REASON_FINISHED) {
                    retCode = 2
                } else if (playerStatus == MediaStatus.PLAYER_STATE_PAUSED) {
                    retCode = 3
                } else {
                    retCode = 4 //error or unkonwn
                }
                channel.invokeMethod("chromeCast#didPlayerStatusUpdated", retCode)
            }

            override fun onMediaError(mediaError: MediaError) {
                var errorCode: Int = mediaError.getDetailedErrorCode() ?: 100
                channel.invokeMethod("chromeCast#didPlayerStatusUpdated", errorCode)
            }
        }

    override fun getView() = chromeCastButton

    override fun dispose() {

    }

    // Flutter methods handling

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "chromeCast#wait" -> result.success(null)
            "chromeCast#loadMedia" -> {
                loadMedia(call.arguments)
                result.success(null)
            }
            "chromeCast#loadQueueMedia" -> {
                loadMediaQueue(call.arguments)
                result.success(null)
            }
            "chromeCast#play" -> {
                play()
                result.success(null)
            }
            "chromeCast#pause" -> {
                pause()
                result.success(null)
            }
            "chromeCast#seek" -> {
                seek(call.arguments)
                result.success(null)
            }
            "chromeCast#setVolume" -> {
                setVolume(call.arguments)
                result.success(null)
            }
            "chromeCast#getMediaInfo" -> result.success(getMediaInfo())
            "chromeCast#getVolume" -> result.success(getVolume())
            "chromeCast#stop" -> {
                stop()
                result.success(null)
            }
            "chromeCast#isPlaying" -> result.success(isPlaying())
            "chromeCast#isConnected" -> result.success(isConnected())
            "chromeCast#endSession" -> {
                endSession()
                result.success(null)
            }
            "chromeCast#position" -> result.success(position())
            "chromeCast#duration" -> result.success(duration())
            "chromeCast#addSessionListener" -> {
                addSessionListener()
                result.success(null)
            }
            "chromeCast#removeSessionListener" -> {
                removeSessionListener()
                result.success(null)
            }
        }
    }

    // SessionManagerListener

    override fun onSessionStarted(p0: Session, p1: String) {
        if (p0 is CastSession) {
            p0.remoteMediaClient?.registerCallback(mRemoteMediaClientListener);
        }
        channel.invokeMethod("chromeCast#didStartSession", null)
    }

    override fun onSessionEnded(p0: Session, p1: Int) {
        channel.invokeMethod("chromeCast#didEndSession", null)
    }

    override fun onSessionResuming(p0: Session, p1: String) {

    }

    override fun onSessionResumed(p0: Session, p1: Boolean) {

    }

    override fun onSessionResumeFailed(p0: Session, p1: Int) {

    }

    override fun onSessionSuspended(p0: Session, p1: Int) {

    }

    override fun onSessionStarting(p0: Session) {

    }

    override fun onSessionEnding(p0: Session) {

    }

    override fun onSessionStartFailed(p0: Session, p1: Int) {

    }

    // PendingResult.StatusListener

    override fun onComplete(status: Status) {
        if (status.isSuccess) {
            channel.invokeMethod("chromeCast#requestDidComplete", null)
        }
    }
}
