//
//  ChromeCastController.swift
//  flutter_cast_video
//
//  Created by Alessio Valentini on 07/08/2020.
//

import Flutter
import GoogleCast

class ChromeCastController: NSObject, FlutterPlatformView {

    // MARK: - Internal properties

    private let channel: FlutterMethodChannel
    private let chromeCastButton: GCKUICastButton
    private let sessionManager = GCKCastContext.sharedInstance().sessionManager
    private var remoteMediaClient : GCKRemoteMediaClient? {
            get {return sessionManager.currentCastSession?.remoteMediaClient}
        }


    // MARK: - Init

    init(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        registrar: FlutterPluginRegistrar
    ) {
        self.channel = FlutterMethodChannel(name: "flutter_cast_video/chromeCast_\(viewId)", binaryMessenger: registrar.messenger())
        self.chromeCastButton = GCKUICastButton(frame: frame)
        super.init()
        self.configure(arguments: args)
    }

    func view() -> UIView {
        return chromeCastButton
    }

    private func configure(arguments args: Any?) {
        setTint(arguments: args)
        setMethodCallHandler()
    }

    // MARK: - Styling

    private func setTint(arguments args: Any?) {
        guard
            let args = args as? [String: Any],
            let red = args["red"] as? CGFloat,
            let green = args["green"] as? CGFloat,
            let blue = args["blue"] as? CGFloat,
            let alpha = args["alpha"] as? Int else {
                print("Invalid color")
                return
        }
        chromeCastButton.tintColor = UIColor(
            red: red / 255,
            green: green / 255,
            blue: blue / 255,
            alpha: CGFloat(alpha) / 255
        )
    }

    // MARK: - Flutter methods handling

    private func setMethodCallHandler() {
        channel.setMethodCallHandler { call, result in
            self.onMethodCall(call: call, result: result)
        }
    }

    private func setVolume(args: Any?) {
            guard
                 let args = args as? [String: Any],
                 let volume = args["volume"] as? Float,
                 let client = sessionManager.currentCastSession?.remoteMediaClient else {
                   return
                 }
        client.setStreamVolume(volume);

    }

    private func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
        case "chromeCast#wait":
            result(nil)
            break
        case "chromeCast#loadMedia":
            loadMedia(args: call.arguments)
            result(nil)
            break
        case "chromeCast#loadQueueMedia":
            loadQueueMedia(args: call.arguments)
            result(nil)
            break
        case "chromeCast#play":
            play()
            result(nil)
            break
        case "chromeCast#pause":
            pause()
            result(nil)
            break
        case "chromeCast#seek":
            seek(args: call.arguments)
            result(nil)
            break
        case "chromeCast#setVolume":
           setVolume(args: call.arguments)
           result(nil)
           break
        case "chromeCast#stop":
            stop()
            result(nil)
            break
        case "chromeCast#isConnected":
            result(isConnected())
            break
        case "chromeCast#duration":
            result(duration())
            break
        case "chromeCast#isPlaying":
            result(isPlaying())
            break
        case "chromeCast#getMediaInfo":
            result(getMediaInfo())
            break
        case "chromeCast#addSessionListener":
            addSessionListener()
            result(nil)
        case "chromeCast#removeSessionListener":
            removeSessionListener()
            result(nil)
        case "chromeCast#position":
            result(position())
        case "chromeCast#isBuffering":
            result(isBuffering())
            break
        case "chromeCast#getMediaInfo":
            result(getMediaInfo())
            break
        case "chromeCast#position":
            result(position())
        case "chromeCast#disconnect":
            disconnect()
            result(nil)


        default:
            result(nil)
            break
        }
    }

    private func loadMedia(args: Any?) {
         guard
             let args = args as? [String: Any],
             let url = args["url"] as? String,
             let mediaUrl = URL(string: url) else {
                 print("Invalid URL")
                 return
         }
         
             let _title = args["title"] as? String
             let _subtitle = args["subtitle"] as? String
             let _image = args["image"] as? String
             let live = args["live"] as? Bool

         let movieMetadata = GCKMediaMetadata()

         if let title = _title { 
         movieMetadata.setString(title, forKey: kGCKMetadataKeyTitle)
         }
         if let subtitle = _subtitle {
           movieMetadata.setString(subtitle, forKey: kGCKMetadataKeySubtitle)
         }
         if let image = _image {
          if let imageUrl = URL(string: image){
           movieMetadata.addImage(GCKImage(url: imageUrl, width: 480, height: 360))
          }
         }

         let mediaInfoBuilder = GCKMediaInformationBuilder.init(contentURL: mediaUrl)
         mediaInfoBuilder.streamType = .buffered
         if let islive = live {
          if islive {
            mediaInfoBuilder.streamType = .live
          }
         }
         mediaInfoBuilder.contentType = "audio/mpeg"
         mediaInfoBuilder.metadata = movieMetadata;
         let mediaInformation = mediaInfoBuilder.build()
         if let request = sessionManager.currentCastSession?.remoteMediaClient?.loadMedia(mediaInformation) {
             request.delegate = self
         }
    }
    
    private func loadQueueMedia(args: Any?) {
        guard
            let args = args as? [String: Any],
            let list = args["queue"] as? Array<Any> else{
                print("Invalid queue list")
                return
        }
        var queueMediaItemsList: [GCKMediaQueueItem] = []
        for item in list {
            guard
                let item = item as? [String: Any],
                let url = item["url"] as? String,
                let mediaUrl = URL(string: url) else {
                    print("Invalid URL")
                    return
            }
            
                let _title = args["title"] as? String
                let _subtitle = args["subtitle"] as? String
                let _image = args["image"] as? String
                let live = false
            
            let movieMetadata = GCKMediaMetadata()

            if let title = _title {
                movieMetadata.setString(title, forKey: kGCKMetadataKeyTitle)
            }
            if let subtitle = _subtitle {
                movieMetadata.setString(subtitle, forKey: kGCKMetadataKeySubtitle)
            }
            if let image = _image {
                 if let imageUrl = URL(string: image){
                     movieMetadata.addImage(GCKImage(url: imageUrl, width: 480, height: 360))
                 }
            }
            
            let mediaInfoBuilder = GCKMediaInformationBuilder.init(contentURL: mediaUrl)
            mediaInfoBuilder.streamType = GCKMediaStreamType.buffered
            mediaInfoBuilder.contentType = "audio/mpeg"
            mediaInfoBuilder.metadata = movieMetadata;
            let mediaInformation = mediaInfoBuilder.build()
            let mediaQueueItem = GCKMediaQueueItem(
                mediaInformation: mediaInformation,
                autoplay: true,
                startTime: TimeInterval(0),
                preloadTime: TimeInterval(2),
                activeTrackIDs: nil,
                customData: nil)
            queueMediaItemsList.append(mediaQueueItem)
            
        }
        
        let queueLoadOptions = GCKMediaQueueLoadOptions.init()
        queueLoadOptions.startIndex = 0
        queueLoadOptions.playPosition = TimeInterval(0)
        //queueLoadOptions.repeatMode = GCKMediaRepeatMode.all
        
        
        if let request = remoteMediaClient?.queueLoad(queueMediaItemsList, with: queueLoadOptions){
            request.delegate = self
        }
    }
    
//    private func loadMedia2(args: Any?) {
//        guard
//            let args = args as? [String: Any],
//            let url = args["url"] as? String
//            else {
//                print("Invalid URL")
//                return
//        }
//
//         if let imageUrl = URL(string: url){
//          let gckImage = GCKImage(url: imageUrl, width: 480, height: 360)
//          sessionManager.currentCastSession?.mediaMetadata?.addImage(gckImage)
//         }
//
//    }

    private func play() {
        if let request = remoteMediaClient?.play() {
            request.delegate = self
        }
    }

    private func pause() {
        if let request = remoteMediaClient?.pause() {
            request.delegate = self
        }
    }

    private func seek(args: Any?) {
        guard
            let args = args as? [String: Any],
            let relative = args["relative"] as? Bool,
            let interval = args["interval"] as? Double else {
                return
        }
        let seekOptions = GCKMediaSeekOptions()
        seekOptions.relative = relative
        seekOptions.interval = interval
        if let request = remoteMediaClient?.seek(with: seekOptions) {
            request.delegate = self
        }
    }

    private func stop() {
        if let request = remoteMediaClient?.stop() {
            request.delegate = self
        }
    }

    private func getMediaInfo() -> [String: String]? {
       return  mediaInfoToMap(_mediaInfo: remoteMediaClient?.mediaStatus?.mediaInformation)
    }

    private func mediaInfoToMap(_mediaInfo: GCKMediaInformation?) -> [String: String]? {
            var info = [String: String]()
            if let mediaInfo = _mediaInfo {
                info["id"] = mediaInfo.contentID
                if let u = mediaInfo.contentURL {
                  info["url"] = u.absoluteString
                }
                info["contentType"] = mediaInfo.contentType
                if let meta = mediaInfo.metadata {

                    info["title"] =  meta.string(forKey: kGCKMetadataKeyTitle)
                    info["subtitle"] =  meta.string(forKey: kGCKMetadataKeySubtitle)
                    let imgs = meta.images()
                               if (imgs.count > 0){
                                  if let img = imgs[0] as? GCKImage {
                                   info["image"] = img.url.absoluteString
                                  }

                               }



                }
            }
            return info;
        }

    private func isConnected() -> Bool {
        return remoteMediaClient?.connected ?? false
    }

    private func isPlaying() -> Bool {
        return remoteMediaClient?.mediaStatus?.playerState == GCKMediaPlayerState.playing
    }

    private func addSessionListener() {
        sessionManager.add(self)
    }

    private func removeSessionListener() {
        sessionManager.remove(self)
    }
    
    private func disconnect() {
        sessionManager.endSessionAndStopCasting(true)
    }

    private func position() -> Int {        
        return Int(remoteMediaClient?.approximateStreamPosition() ?? 1) * 1000
    }

    private func duration() -> Int {
            return Int(remoteMediaClient?.mediaStatus?.mediaInformation?.streamDuration ?? 1) * 1000
    }
    
    private func isBuffering() -> Bool {
            return remoteMediaClient?.mediaStatus?.playerState == GCKMediaPlayerState.buffering
        }
        
        private func isPaused() -> Bool {
            return remoteMediaClient?.mediaStatus?.playerState == GCKMediaPlayerState.paused
        }
        
        private func index() -> Int? {
            guard let itemId =  remoteMediaClient?.mediaStatus?.currentItemID
            else {
                return nil
            }
            
            let index = remoteMediaClient?.mediaQueue.indexOfItem(withID: itemId)
            return index
        }
        
        private func volume() -> Float? {
            return remoteMediaClient?.mediaStatus?.volume ?? 1.0
        }


}

// MARK: - GCKSessionManagerListener

extension ChromeCastController: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        session.remoteMediaClient?.add(self)
        channel.invokeMethod("chromeCast#didStartSession", arguments: nil)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        channel.invokeMethod("chromeCast#didEndSession", arguments: nil)
    }
}

// MARK: - GCKRequestDelegate

extension ChromeCastController: GCKRequestDelegate {
    func requestDidComplete(_ request: GCKRequest) {
        channel.invokeMethod("chromeCast#requestDidComplete", arguments: nil)
    }

    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        channel.invokeMethod("chromeCast#requestDidFail", arguments: ["error" : error.localizedDescription])
    }
}

// MARK: - GCKRemoteMediaClientListener
extension ChromeCastController : GCKRemoteMediaClientListener {
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        let returnValue = [
            "isPlaying" : isPlaying(),
            "isPaused" : isPaused(),
            "isBuffering" : isBuffering(),
            "index" : index(),
            "volume" : volume(),
            "position" : position(),
            "progress" : Double(position()) / Double(duration())
        ] as [String : Any?]
        channel.invokeMethod("chromeCast#mediaItemEvent", arguments: returnValue)
    }
}
