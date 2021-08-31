import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/material.dart';

import '../../../common.dart';

class ClassroomController extends ChangeNotifier {
  final ClientRole role = ClientRole.Broadcaster;

  static late List<int> _users;
  static late List<String> _infoStrings;
  static late bool _muteAudio, _muteVideo;
  static late RtcEngine _engine;
  ClassroomController._privateConstructor();

  static final ClassroomController _instance =
      ClassroomController._privateConstructor();

  factory ClassroomController() {
    _users = [];
    _infoStrings = [];
    _muteAudio = false;
    _muteVideo = false;
    return _instance;
  }
  void disposeController() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      _infoStrings.add(
        'APP_ID missing, please provide your APP_ID in settings.dart',
      );
      _infoStrings.add('Agora Engine is not starting');
      notifyListeners();
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(width: 1920, height: 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(CHANNEL_TOKEN, CHANNEL_NAME, null, 0);
  }

  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(APP_ID);
    await _engine.enableVideo();
    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.Communication);
  }

  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      final info = 'onError: $code';
      _infoStrings.add(info);
      notifyListeners();
    }, joinChannelSuccess: (channel, uid, elapsed) {
      final info = 'onJoinChannel: $channel, uid: $uid';
      _infoStrings.add(info);
      notifyListeners();
    }, leaveChannel: (stats) {
      _infoStrings.add('onLeaveChannel');
      _users.clear();
      notifyListeners();
    }, userJoined: (uid, elapsed) {
      final info = 'userJoined: $uid';
      _infoStrings.add(info);
      _users.add(uid);
      notifyListeners();
    }, userOffline: (uid, elapsed) {
      final info = 'userOffline: $uid';
      _infoStrings.add(info);
      _users.remove(uid);
      notifyListeners();
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      final info = 'firstRemoteVideo: $uid ${width}x $height';
      _infoStrings.add(info);
      notifyListeners();
    }));
  }

  List<Widget> getRenderViews() {
    final List<StatefulWidget> list = [];
    if (role == ClientRole.Broadcaster) {
      list.add(RtcLocalView.SurfaceView());
    }
    _users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  Widget videoView(view) {
    return Expanded(child: Container(child: view));
  }

  Widget expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  Widget viewRows() {
    final views = getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            expandedVideoRow([views[0]]),
            expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            expandedVideoRow(views.sublist(0, 2)),
            expandedVideoRow(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            expandedVideoRow(views.sublist(0, 2)),
            expandedVideoRow(views.sublist(2, 4))
          ],
        ));
      default:
        return Container(
            child: Column(
          children: <Widget>[
            expandedVideoRow(views.sublist(0, 2)),
            expandedVideoRow(views.sublist(2, 4)),
            Text("more participants"),
          ],
        ));
    }
  }

  Widget panel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _infoStrings[index],
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget toolbar(BuildContext context) {
    if (role == ClientRole.Audience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMuteAudio,
            child: Icon(
              _muteAudio ? Icons.mic_off : Icons.mic,
              color: _muteAudio ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: _muteAudio ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: _onToggleMuteVideo,
            child: Icon(
              _muteVideo ? Icons.videocam_off : Icons.videocam,
              color: _muteVideo ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: _muteVideo ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child: Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
          )
        ],
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
    disposeController();
    Navigator.pop(context);
  }

  Future<void> _onToggleMuteAudio() async {
    _muteAudio = !_muteAudio;
    notifyListeners();
    await _engine.muteLocalAudioStream(_muteAudio);
  }

  Future<void> _onToggleMuteVideo() async {
    _muteVideo = !_muteVideo;
    notifyListeners();
    await _engine.muteLocalVideoStream(_muteVideo);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }
}
