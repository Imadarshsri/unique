import 'package:flutter/material.dart';
import 'package:unique/modules/video_call/screens/classroom_channel.dart';

class VideoConf extends StatefulWidget {
  const VideoConf({Key? key}) : super(key: key);

  @override
  _VideoConfState createState() => _VideoConfState();
}

class _VideoConfState extends State<VideoConf> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        child: Text("Join Now"),
        onPressed: () {
          print("Joining Channel");
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => Channel()));
        },
      ),
    );
  }
}
