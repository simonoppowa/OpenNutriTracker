import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ShareQrDialog extends StatefulWidget {
  final String title;
  final String code;
  final String fileBaseName;

  const ShareQrDialog({
    super.key,
    required this.title,
    required this.code,
    required this.fileBaseName,
  });

  @override
  State<ShareQrDialog> createState() => _ShareQrDialogState();
}

class _ShareQrDialogState extends State<ShareQrDialog> {
  static const int _errorCorrectionLevel = QrErrorCorrectLevel.M;
  static const int _quietZoneModules = 3;

  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: QrImageView(
                data: widget.code,
                version: QrVersions.auto,
                errorCorrectionLevel: _errorCorrectionLevel,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16.0),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(S.of(context).copyCodeLabel),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context).codeCopiedLabel)),
                    );
                  },
                ),
                OutlinedButton.icon(
                  key: _shareButtonKey,
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(S.of(context).shareCodeLabel),
                  onPressed: _share,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }

  Future<void> _share() async {
    final origin = _shareButtonOrigin();
    try {
      final qrBytes = await _renderQrToImage(widget.code);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${widget.fileBaseName}.png');
      await file.writeAsBytes(qrBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.code,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      await Share.share(widget.code, sharePositionOrigin: origin);
    }
  }

  Rect? _shareButtonOrigin() {
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<List<int>> _renderQrToImage(String data) async {
    const size = 512.0;
    final validation = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: _errorCorrectionLevel,
    );
    final qrCode = validation.qrCode!;
    final margin = _quietZoneModules * size / qrCode.moduleCount;
    final contentSize = size - 2 * margin;
    final painter = QrPainter.withQr(
      qr: qrCode,
      eyeStyle: const QrEyeStyle(
          color: Color(0xFF000000), eyeShape: QrEyeShape.square),
      dataModuleStyle: const QrDataModuleStyle(
          color: Color(0xFF000000), dataModuleShape: QrDataModuleShape.square),
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, size, size),
      ui.Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.save();
    canvas.translate(margin, margin);
    painter.paint(canvas, Size(contentSize, contentSize));
    canvas.restore();
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
