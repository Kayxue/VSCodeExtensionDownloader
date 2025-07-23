import 'package:background_downloader/background_downloader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class Inputs extends StatelessWidget {
  final TextEditingController controller;
  final TaskStatus? taskStatus;
  final String publisher;
  final String name;
  final String version;
  final Function(String) setPublisher;
  final Function(String) setName;
  final Function(String) setVersion;

  const Inputs({
    super.key,
    required this.taskStatus,
    required this.publisher,
    required this.name,
    required this.version,
    required this.setPublisher,
    required this.setName,
    required this.setVersion,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Save to',
                ),
                controller: controller,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: taskStatus == TaskStatus.running
                  ? null
                  : () async {
                      String? directory = await FilePicker.platform
                          .getDirectoryPath();
                      if (directory != null) {
                        controller.text = directory;
                      }
                    },
              child: Text('Choose Folder'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Publisher',
                ),
                onChanged: (value) => setPublisher(value),
                readOnly: taskStatus == TaskStatus.running,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
                onChanged: (value) => setName(value),
                readOnly: taskStatus == TaskStatus.running,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Version',
                ),
                onChanged: (value) => setVersion(value),
                readOnly: taskStatus == TaskStatus.running,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
