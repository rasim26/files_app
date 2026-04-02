import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
// it will open the file with the native file opener.
class FileOpener {

  static Future<void> openFile(BuildContext context, String base64String, String fileName) async {
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Opening $fileName..."), duration: const Duration(seconds: 1)),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/$fileName";
      
      final file = File(filePath);
      if (!await file.exists()) {
        final bytes = base64Decode(base64String);
        await file.writeAsBytes(bytes);
      }

      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
  
