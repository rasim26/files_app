import 'dart:convert';

import 'package:files_app_flutter/screens/function/file_opener.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:files_app_flutter/firestore_services.dart';
import 'package:intl/intl.dart';

class DeleteScreen extends StatelessWidget {
  final FirestoreService service = FirestoreService();

  void scanPopup(BuildContext context, String? deletedAt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan Result"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Deleted Time: ${deletedAt != null ? DateFormat('dd/MM/yy hh:mm a').format(DateTime.parse(deletedAt)) : 'Unknown'}",
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              "Recovery 100%",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 23,
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => {
              Navigator.pop(context),
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Scanning Completed"))),
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void recoveryConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const Text("Do you want to recover?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                service.recover(id);
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Recovered")));
              },
              child: const Text("Recover"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text(
              "Trash",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: Colors.grey.shade200, height: 1.0),
            ),
          ),
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("media_items")
                .where("status", isEqualTo: "Inactive")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Trash is empty",
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
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final data = docs[index].data();
                    final fileExtension = data["fileExtension"] ?? 'unknown';
                    final isImage = [
                      'jpg',
                      'jpeg',
                      'png',
                      'gif',
                      'bmp',
                      'webp',
                    ].contains(fileExtension.toLowerCase());

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        onTap: () => FileOpener.openFile(
                          context,
                          data["fileBase64"],
                          data["fileName"],
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: isImage
                              ? Image.memory(
                                  base64Decode(data["fileBase64"]),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.blue.withOpacity(0.05),
                                  child: Icon(
                                    Icons.insert_drive_file,
                                    size: 30,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                        ),
                        title: Text(
                          data["description"] ?? "Unknown",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        // subtitle: Text(
                        //   "Deleted: ${data['deletedAt'] != null ? DateFormat('dd/MM/yy').format(DateTime.parse(data['deletedAt'])) : 'Unknown'}",
                        //   style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        // ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.search,
                                  size: 22,
                                  color: Colors.blueAccent,
                                ),
                                tooltip: 'Scan',
                                onPressed: () =>
                                    scanPopup(context, data["deletedAt"]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.restore,
                                  size: 22,
                                  color: Colors.green,
                                ),
                                tooltip: 'Restore',
                                onPressed: () {
                                  recoveryConfirmation(context, data["id"]);
                                },
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
    );
  }
}
