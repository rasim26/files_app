import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:files_app_flutter/screens/function/file_opener.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:files_app_flutter/firestore_services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class Filesdisplay extends StatelessWidget {
  final FirestoreService service = FirestoreService();

  Filesdisplay({super.key});

  void deleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const Text("Do you want to delete this file?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                service.delete(id);
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Deleted")));
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      final bytes = await File(file.path!).readAsBytes();
      String base64File = base64Encode(bytes);
      String fileName = file.name;
      String fileExtension = file.extension ?? 'unknown';

      service.addItem(base64File, "User File", fileName, fileExtension);
    }
  }

  Future<void> fileOpen(String base64String, String fileName) async {
    try {
      final tempDir =
          await getTemporaryDirectory(); // Path to the temporary directory on the device that is not backed up and is suitable for storing caches of downloaded files.
      final filePath = "${tempDir.path}/$fileName";
      final bytes = base64Decode(base64String);
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        debugPrint("Could not open file: ${result.message}");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text(
              "My Files",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            // centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: Colors.grey.shade200, height: 1.0),
            ),
          ),
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("media_items")
                .where("status", isEqualTo: "Active")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs.toList();

              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>?;
                final bData = b.data() as Map<String, dynamic>?;
                final aTime = aData?['createdAt']?.toString() ?? '';
                final bTime = bData?['createdAt']?.toString() ?? '';
                // Sort descending (newest first)
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No Files Uploaded yet",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final data = docs[index];
                    final fileExtension = data["fileExtension"] ?? 'unknown';
                    final isImage = [
                      'jpg',
                      'jpeg',
                      'png',
                      'gif',
                      'bmp',
                      'webp',
                    ].contains(fileExtension.toLowerCase());

                    return GestureDetector(
                      onTap: () => FileOpener.openFile(
                        context,
                        data["fileBase64"],
                        data["fileName"],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: isImage
                                    ? Hero(
                                        tag: data["id"] ?? 'img_$index',
                                        child: Image.memory(
                                          base64Decode(data["fileBase64"]),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : Container(
                                        color: Colors.blue.withOpacity(0.05),
                                        child: Icon(
                                          _getFileIcon(fileExtension),
                                          size: 50,
                                          color: _getFileColor(fileExtension),
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data["description"] ?? "Unknown",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          fileExtension.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        deleteConfirmation(context, data["id"]);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: docs.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadScreen()),
          );
        },
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text("Upload"),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.purple;
      case 'mp3':
      case 'wav':
        return Colors.orange;
      default:
        return Colors.grey.shade600;
    }
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final FirestoreService service = FirestoreService();
  final TextEditingController descriptionController = TextEditingController();

  PlatformFile? selectedFile;
  bool _isUploading = false;
  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    if (_isUploading) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = await File(selectedFile!.path!).readAsBytes();
      String base64File = base64Encode(bytes);
      String fileName = selectedFile!.name;
      String fileExtension = selectedFile!.extension ?? 'unknown';

      String description = descriptionController.text.trim().isEmpty
          ? "User File"
          : descriptionController.text.trim();

      await service.addItem(base64File, description, fileName, fileExtension);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Uploaded")));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload File")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(),
            GestureDetector(
              onTap: pickFile,
              child: Column(
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                    ),
                    child: const Icon(Icons.add, size: 40),
                  ),
                  const SizedBox(height: 8),
                  const Text("Upload Files"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (selectedFile != null)
              selectedFile!.extension != null &&
                      [
                        'jpg',
                        'jpeg',
                        'png',
                        'gif',
                        'bmp',
                        'webp',
                      ].contains(selectedFile!.extension!.toLowerCase())
                  ? Image.file(File(selectedFile!.path!), height: 150)
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.insert_drive_file, size: 48),
                          const SizedBox(height: 8),
                          Text(selectedFile!.name, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: uploadFile,
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
