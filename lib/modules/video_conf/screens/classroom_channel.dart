import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'classroom_video_call.dart';
import 'package:universal_html/html.dart' as html;

class Channel extends StatefulWidget {
  const Channel({Key? key}) : super(key: key);

  @override
  _ChannelState createState() => _ChannelState();
}

class _ChannelState extends State<Channel> {
  late TextEditingController _channelController;
  late bool _validateError;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _channelController = TextEditingController(text: 'ch1');
    _validateError = false;
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  Future<void> onJoin() async {
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      if (Platform.isAndroid || Platform.isIOS) {
        await _handleCameraAndMic(Permission.camera);
        await _handleCameraAndMic(Permission.microphone);
      } else {
        final perm =
            await html.window.navigator.permissions!.query({"name": "camera"});
        if (perm.state == "denied") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Oops! Camera access denied!"),
              backgroundColor: Colors.orangeAccent,
            ),
          );
          return;
        }
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCall(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APIExample'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          height: 400,
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _channelController,
                      decoration: InputDecoration(
                        errorText:
                            _validateError ? 'Channel name is mandatory' : null,
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(width: 1),
                        ),
                        hintText: 'Classroom Id',
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onJoin,
                        child: Text('Join'),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
