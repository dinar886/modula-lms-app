// lib/features/shared/pdf_viewer_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String documentTitle;

  const PdfViewerPage({
    super.key,
    required this.pdfUrl,
    this.documentTitle = 'Document',
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  // --- FONCTION CORRIGÉE AVEC MEILLEURE GESTION D'ERREURS ---
  Future<void> _loadPdf() async {
    try {
      final uri = Uri.parse(widget.pdfUrl);
      final response = await http.get(uri);

      // CORRECTION 1 : On vérifie que le statut de la réponse est '200 OK'.
      if (response.statusCode != 200) {
        throw Exception(
          'Le serveur a répondu avec le code d\'erreur : ${response.statusCode}',
        );
      }

      // CORRECTION 2 : On vérifie que le contenu reçu est bien un PDF.
      final contentType = response.headers['content-type'];
      if (contentType == null || !contentType.contains('application/pdf')) {
        throw Exception(
          'Le fichier reçu n\'est pas un PDF valide. Type reçu : $contentType',
        );
      }

      // Le reste de la logique pour sauvegarder le fichier.
      final dir = await getApplicationDocumentsDirectory();
      // On donne un nom de fichier unique pour éviter les conflits de cache.
      final file = File(
        '${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        setState(() {
          localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Si une erreur survient, on l'affiche à l'utilisateur.
      if (mounted) {
        setState(() {
          _errorMessage =
              "Impossible de charger le document.\nErreur : ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    if (localPath != null) {
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(localPath!)],
        text: 'Document: ${widget.documentTitle}',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentTitle),
        actions: [
          if (localPath != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Partager',
              onPressed: _sharePdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // Widget pour construire le corps de la page
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    if (localPath != null) {
      return PDFView(filePath: localPath!);
    }

    return const Center(child: Text("Une erreur inattendue est survenue."));
  }
}
