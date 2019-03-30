import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(new App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'fletter',
      theme: new ThemeData(
          primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: new Fletter(),
    );
  }
}

class Fletter extends StatefulWidget {
  Fletter({Key key}) : super(key: key);

  @override
  _FletterState createState() => new _FletterState();
}

class _FletterState extends State<Fletter> {
  List<LinePoints> lines = <LinePoints>[];
  List<Offset> nowPoints = <Offset>[];
  ScreenshotController screenshotController = ScreenshotController();
  File _imageFile;
  Color nowColor = Colors.blueGrey;

  void moveGestureDetector(DragUpdateDetails detail) {
    Offset p = Offset(detail.globalPosition.dx, detail.globalPosition.dy);
    setState(() {
      nowPoints.add(p);
    });
  }

  void newGestureDetector(DragStartDetails detail) {
    if (nowPoints.length != 0) {
      LinePoints l = LinePoints(new List<Offset>.from(nowPoints), nowColor);
      lines.add(l);
      nowPoints.clear();
    }
    Offset p = Offset(detail.globalPosition.dx, detail.globalPosition.dy);
    setState(() {
      nowPoints.add(p);
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
      setState(() {
        _imageFile = image;
      });
      print('DEBUG: image:$image');
    }).catchError((onError) {
      print('DEBUG: error:$onError');
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Screenshot(
      controller: screenshotController,
      child: Scaffold(
        body: new Stack(children: [
          new Image.asset("assets/comp.png"),
          Container(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            child: new Flex(
              direction: Axis.vertical,
              children: <Widget>[
                Expanded(
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
                )
              ],
            ),
          ),
        ], fit: StackFit.expand),
        //buttons
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
      ),
    );
  }
}

class PaintCanvas extends CustomPainter {
  final List<LinePoints> lines;
  final List<Offset> nowPoints;
  final Color nowColor;

  PaintCanvas(this.lines, this.nowPoints, this.nowColor);

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = new Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;
    canvas.save();
    for (int i = 0; i < lines.length; i++) {
      LinePoints l = lines[i];
      for (int j = 1; j < l.points.length; j++) {
        Offset p1 = l.points[j - 1], p2 = l.points[j];
        p.color = l.lineColor;
        canvas.drawLine(p1, p2, p);
      }
    }
    for (int i = 1; i < nowPoints.length; i++) {
      Offset p1 = nowPoints[i - 1];
      Offset p2 = nowPoints[i];
      p.color = nowColor;
      canvas.drawLine(p1, p2, p);
    }
    canvas.restore();
  }

  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class LinePoints {
  final List<Offset> points;
  final Color lineColor;
  LinePoints(this.points, this.lineColor);
}
