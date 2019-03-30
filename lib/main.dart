import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fletter',
      home: Fletter(),
    );
  }
}

class Fletter extends StatefulWidget {
  @override
  _FletterState createState() => _FletterState();
}

class _FletterState extends State<Fletter> {
  List<LinePoints> lines = <LinePoints>[];
  List<Offset> nowPoints = <Offset>[];
  ScreenshotController screenshotController = ScreenshotController();
  Color nowColor = Colors.greenAccent;
  var uuid = Uuid();

  final metaData = StorageMetadata(contentType: 'image/png');

  void moveGestureDetector(DragUpdateDetails detail) {
    final Offset p = Offset(detail.globalPosition.dx, detail.globalPosition.dy);
    setState(() {
      nowPoints.add(p);
    });
  }

  void newGestureDetector(DragStartDetails detail) {
    if (nowPoints.isNotEmpty) {
      lines.add(LinePoints(List<Offset>.from(nowPoints), nowColor));
      nowPoints.clear();
    }
    setState(() {
      nowPoints.add(Offset(detail.globalPosition.dx, detail.globalPosition.dy));
    });
  }

  void _tapClear() {
    setState(() {
      lines.clear();
      nowPoints.clear();
    });
  }

  void _takeScreenShot() {
    screenshotController.capture().then((File image) {
      final String fileName = Uuid().v1() + '.png';
      final StorageReference storageRef = FirebaseStorage.instance.ref().child(fileName);

      storageRef.putFile(image, metaData);
    }).catchError((error) {
      print('DEBUG: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Screenshot<File>(
        controller: screenshotController,
        child: Stack(children: [
          Image.asset('assets/comp.png'),
          Container(
            color: Color.fromRGBO(0, 0, 0, 0),
            child: Container(
              child: AspectRatio(
                aspectRatio: 2.0,
                child: GestureDetector(
                  child: CustomPaint(
                    painter: PaintCanvas(lines, nowPoints, nowColor),
                  ),
                  onHorizontalDragUpdate: moveGestureDetector,
                  onVerticalDragUpdate: moveGestureDetector,
                  onHorizontalDragStart: newGestureDetector,
                  onVerticalDragStart: newGestureDetector,
                ),
              ),
            ),
          ),
        ], fit: StackFit.expand),
      ),
      floatingActionButton: Column(
        verticalDirection: VerticalDirection.up,
        children: <Widget>[
          FloatingActionButton(
            onPressed: _tapClear,
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            child: Icon(Icons.delete),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton(
              onPressed: _takeScreenShot,
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              child: Icon(Icons.file_upload),
            ),
          ),
        ],
      ),
    );
  }
}

class PaintCanvas extends CustomPainter {
  PaintCanvas(this.lines, this.nowPoints, this.nowColor);

  final List<LinePoints> lines;
  final List<Offset> nowPoints;
  final Color nowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;
    canvas.save();
    for (int i = 0; i < lines.length; i++) {
      final LinePoints l = lines[i];
      for (int j = 1; j < l.points.length; j++) {
        final Offset p1 = l.points[j - 1], p2 = l.points[j];
        p.color = l.lineColor;
        canvas.drawLine(p1, p2, p);
      }
    }
    for (int i = 1; i < nowPoints.length; i++) {
      final Offset p1 = nowPoints[i - 1], p2 = nowPoints[i];
      p.color = nowColor;
      canvas.drawLine(p1, p2, p);
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class LinePoints {
  LinePoints(this.points, this.lineColor);
  final List<Offset> points;
  final Color lineColor;
}
