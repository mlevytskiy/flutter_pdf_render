import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb; // for checking whether running on Web or not
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:pdf_render/pdf_render_widgets.dart';

void main(List<String> args) => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = PdfViewerController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder<Matrix4>(
              // The controller is compatible with ValueListenable<Matrix4> and you can receive notifications on scrolling and zooming of the view.
              valueListenable: controller,
              builder: (context, _, child) =>
                  Text(controller.isReady ? 'Page #${controller.currentPageNumber}' : 'Page -')),
        ),
        backgroundColor: Colors.grey,
        body: GestureDetector(
          // Supporting double-tap gesture on the viewer.
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: () => controller.ready?.setZoomRatio(
            zoomRatio: controller.zoomRatio * 1.5,
            center: _doubleTapDetails!.localPosition,
          ),
          child: !kIsWeb && Platform.isMacOS
              // Networking sample using flutter_cache_manager
              ? PdfViewer.openFutureFile(
                  // Accepting function that returns Future<String> of PDF file path
                  () async => (await DefaultCacheManager().getSingleFile(
                          'https://github.com/espresso3389/flutter_pdf_render/raw/master/example/assets/hello.pdf'))
                      .path,
                  viewerController: controller,
                  onError: (err) => print(err),
                  params: const PdfViewerParams(
                    padding: 10,
                    minScale: 1.0,
                    scaleEnabled: false,
                    // scrollDirection: Axis.horizontal,
                  ),
                )
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.mouse}),
                  child: PdfViewer.openAsset(
                    'assets/hello.pdf',
                    viewerController: controller,
                    onError: (err) => print(err),
                    params: const PdfViewerParams(
                      padding: 10,
                      minScale: 1.0,
                      scaleEnabled: false,
                      // scrollDirection: Axis.horizontal,
                    ),
                  ),
                ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              child: const Icon(Icons.first_page),
              onPressed: () => controller.ready?.goToPage(pageNumber: 1),
            ),
            FloatingActionButton(
              child: const Icon(Icons.last_page),
              onPressed: () => controller.ready?.goToPage(pageNumber: controller.pageCount),
            ),
            FloatingActionButton(
              child: const Icon(Icons.bug_report),
              onPressed: () => rendererTest(),
            ),
          ],
        ),
      ),
    );
  }

  /// Just testing internal rendering logic
  Future<void> rendererTest() async {
    final PdfDocument doc;
    if (!kIsWeb && Platform.isMacOS) {
      final file = (await DefaultCacheManager()
              .getSingleFile('https://github.com/espresso3389/flutter_pdf_render/raw/master/example/assets/hello.pdf'))
          .path;
      doc = await PdfDocument.openFile(file);
    } else {
      doc = await PdfDocument.openAsset('assets/hello.pdf');
    }

    try {
      final page = await doc.getPage(1);
      final image = await page.render();
      print('${image.width}x${image.height}: ${image.pixels.lengthInBytes} bytes.');
    } finally {
      doc.dispose();
    }
  }
}
