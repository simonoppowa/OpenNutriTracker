import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ShareQrDialog extends StatefulWidget {
  final String title;
  final String code;
  final String fileBaseName;
  final SharePlus? sharePlus;
  final Future<List<int>> Function(String data)? qrImageRenderer;

  /// Optional "Copy to profile" action shown beneath the share buttons.
  /// Only the meal-share flow supplies it (and only when more than one
  /// profile exists); the dialog dismisses itself before invoking it.
  final VoidCallback? onCopyToProfile;

  const ShareQrDialog({
    super.key,
    required this.title,
    required this.code,
    required this.fileBaseName,
    this.sharePlus,
    this.qrImageRenderer,
    this.onCopyToProfile,
  });

  @override
  State<ShareQrDialog> createState() => _ShareQrDialogState();
}

class _ShareQrDialogState extends State<ShareQrDialog> {
  static const int _errorCorrectionLevel = QrErrorCorrectLevel.M;
  static const int _quietZoneModules = 4;

  final GlobalKey _shareButtonKey = GlobalKey();
  late QrValidationResult _validation = _validateQr();

  @override
  void didUpdateWidget(covariant ShareQrDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) _validation = _validateQr();
  }

  QrValidationResult _validateQr() {
    final result = QrValidator.validate(
      data: widget.code,
      version: QrVersions.auto,
      errorCorrectionLevel: _errorCorrectionLevel,
    );
    if (!result.isValid || result.qrCode == null) return result;
    try {
      // qr defers the version-40 capacity check until matrix generation.
      QrImage(result.qrCode!);
      return result;
    } on InputTooLongException catch (error) {
      return QrValidationResult(
        status: QrValidationStatus.contentTooLong,
        error: error,
      );
    } on Exception catch (error) {
      return QrValidationResult(status: QrValidationStatus.error, error: error);
    }
  }

  static final ButtonStyle _pillStyle = OutlinedButton.styleFrom(
    shape: const StadiumBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final qr = _validation.qrCode;
    final screen = MediaQuery.sizeOf(context);
    // Keep the whole QR visible, leaving room for the title and actions.
    final availableSize = math.max(
      0.0,
      math.min(screen.width - 80, screen.height - 240),
    );
    final size = math.min(
      math.max(260.0, ((qr?.moduleCount ?? 0) + 2 * _quietZoneModules) * 4.0),
      availableSize,
    );
    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      constraints: BoxConstraints(maxWidth: size + 48),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (qr != null)
              SizedBox.square(
                dimension: size,
                child: QrImageView.withQr(
                  qr: qr,
                  size: size,
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(
                    _quietZoneModules *
                        size /
                        (qr.moduleCount + 2 * _quietZoneModules),
                  ),
                  errorStateBuilder: (context, _) =>
                      Text(S.of(context).shareQrUnavailableLabel),
                ),
              )
            else
              Text(
                _validation.status == QrValidationStatus.contentTooLong
                    ? S.of(context).shareQrTooLargeLabel
                    : S.of(context).shareQrUnavailableLabel,
              ),
            const SizedBox(height: Dimens.spacing12),
            Wrap(
              spacing: Dimens.spacing8,
              runSpacing: Dimens.spacing8,
              alignment: WrapAlignment.center,
              children: [
                Semantics(
                  identifier: 'share-copy-code',
                  child: OutlinedButton.icon(
                    style: _pillStyle,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(S.of(context).copyCodeLabel),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).codeCopiedLabel)),
                      );
                    },
                  ),
                ),
                Semantics(
                  identifier: 'share-code',
                  child: OutlinedButton.icon(
                    key: _shareButtonKey,
                    style: _pillStyle,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(S.of(context).shareCodeLabel),
                    onPressed: _share,
                  ),
                ),
              ],
            ),
            if (widget.onCopyToProfile != null) ...[
              const SizedBox(height: Dimens.spacing8),
              Semantics(
                identifier: 'share-copy-to-profile',
                child: OutlinedButton.icon(
                  style: _pillStyle,
                  icon: const Icon(Icons.people_alt_rounded, size: 18),
                  label: Text(S.of(context).copyToProfileLabel),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onCopyToProfile!();
                  },
                ),
              ),
            ],
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
    final sharePlus = widget.sharePlus ?? SharePlus.instance;
    final qr = _validation.qrCode;
    if (qr != null) {
      try {
        final qrBytes = widget.qrImageRenderer != null
            ? await widget.qrImageRenderer!(widget.code)
            : await _renderQrToImage(qr);
        if (qrBytes.isEmpty) throw StateError('Empty QR image');
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${widget.fileBaseName}.png');
        await file.writeAsBytes(qrBytes);
        await sharePlus.share(
          ShareParams(
            files: [XFile(file.path)],
            text: widget.code,
            sharePositionOrigin: origin,
          ),
        );
        return;
      } catch (_) {
        // Image rendering, writing or sharing failed; retain the exact code.
      }
    }
    try {
      await sharePlus.share(
        ShareParams(text: widget.code, sharePositionOrigin: origin),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).shareCodeErrorLabel)),
      );
    }
  }

  Rect? _shareButtonOrigin() {
    final box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<List<int>> _renderQrToImage(QrCode qr) async {
    final pixelsPerModule = math.max(
      4,
      (512 / (qr.moduleCount + 2 * _quietZoneModules)).ceil(),
    );
    final size =
        (qr.moduleCount + 2 * _quietZoneModules) * pixelsPerModule.toDouble();
    final margin = _quietZoneModules * pixelsPerModule.toDouble();
    final contentSize = size - 2 * margin;
    final painter = QrPainter.withQr(
      qr: qr,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        color: Color(0xFF000000),
        eyeShape: QrEyeShape.square,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        color: Color(0xFF000000),
        dataModuleShape: QrDataModuleShape.square,
      ),
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size, size),
      ui.Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.save();
    canvas.translate(margin, margin);
    painter.paint(canvas, Size(contentSize, contentSize));
    canvas.restore();
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(size.toInt(), size.toInt());
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw StateError('Could not encode QR image');
        return byteData.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }
}
