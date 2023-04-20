import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isPub = false;

  RTCVideoRenderer _localRender = RTCVideoRenderer();
  RTCVideoRenderer _remoteRender = RTCVideoRenderer();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initRender();
    initSFU();
  }

  initRender() async {
    await _localRender.initialize();
    await _remoteRender.initialize();
  }

  getUrl() {
    // if (kIsWeb) {
    //   return ion.GRPCWebSignal('http://localhost:50051');
    // } else {
    //   setState(() {
    //     isPub = true;
    //   });
    //   return ion.GRPCWebSignal("http://192.168.0.103:500551");
    // }
    return ion.GRPCWebSignal("http://192.168.0.103:50051");
  }

  ion.Signal? _signal;
  ion.Client? _client;
  ion.LocalStream? _localStream;
  final String _uuid = Uuid().v4();

  initSFU() async {
    final _signal = await getUrl();
    _client = await ion.Client.create(sid: "test", uid: _uuid, signal: _signal);
    if (isPub == false) {
      _client?.ontrack = (track, ion.RemoteStream remoteStream) async {
        if (track.kind == "video") {
          print("ontrack ${remoteStream.id}");
          _remoteRender.srcObject = remoteStream.stream;
        }
      };
    }
  }

  _publish() async {
    _localStream = await ion.LocalStream.getUserMedia(
        constraints: ion.Constraints.defaults..simulcast = false);
    setState(() {
      _localRender.srcObject = _localStream?.stream;
    });
    await _client?.publish(_localStream!);
  }

  _getFab() {
    if (isPub == false) {
      return Container();
    } else {
      return FloatingActionButton(
        onPressed: _publish,
        child: Icon(Icons.video_call),
      );
    }
  }

  _getUserVideoView() {
    if (isPub == true) {
      return Expanded(child: RTCVideoView(_localRender));
    } else {
      return Expanded(child: RTCVideoView(_remoteRender));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[_getUserVideoView()],
        ),
      ),
      floatingActionButton:
          _getFab(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
