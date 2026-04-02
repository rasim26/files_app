import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  late final CollectionReference mediaCollection = FirebaseFirestore.instance
      .collection("media_items");

  Future<void> addItem(
    String base64File,
    String description,
    String fileName,
    String fileExtension,
  ) async {
    final doc = mediaCollection.doc();

    if (description.trim().isEmpty) {
      description = "User File";
    }

    await doc.set({
      "id": doc.id,
      "fileBase64": base64File,
      "description": description,
      "status": "Active",
      "recoveryStatus": "",
      "fileName": fileName,
      "fileExtension": fileExtension,
      "createdAt": DateTime.now().toIso8601String(),
    });
  }

  Future<void> delete(String id) async {
    await mediaCollection.doc(id).update({
      "status": "Inactive",
      "deletedAt": DateTime.now().toIso8601String(),
    });
  }

  Future<void> recover(String id) async {
    await mediaCollection.doc(id).update({
      "status": "Active",
      "recoveryStatus": "Recovered",
      "recoveredAt": DateTime.now().toIso8601String(),
    });
  }
}
