import 'package:background_downloader/background_downloader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class Inputs extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController publisherController;
  final TextEditingController nameController;
  final TaskStatus? taskStatus;
  final String publisher;
  final String name;
  final String version;
  final String url;
  final Function(String) setPublisher;
  final Function(String) setName;
  final Function(String) setVersion;
  final Function(String) setUrl;
  final Function(String) setPublisherValue;
  final Function(String) setNameValue;

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
    required this.url,
    required this.setUrl,
    required this.publisherController,
    required this.nameController,
    required this.setPublisherValue,
    required this.setNameValue,
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
            SizedBox(
              width: 99,
              child: ElevatedButton(
                onPressed: taskStatus == TaskStatus.running
                    ? null
                    : () async {
                        String? directory = await FilePicker.platform
                            .getDirectoryPath();
                        if (directory != null) {
                          controller.text = directory;
                        }
                      },
                child: Text('Choose'),
              ),
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
                  labelText: 'Url',
                ),
                onChanged: (value) => setUrl(value),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: taskStatus == TaskStatus.running
                  ? null
                  : () async {
                      try {
                        final uri = Uri.parse(url);
                        if (!uri.isAbsolute ||
                            uri.origin !=
                                "https://marketplace.visualstudio.com") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Seems that the link isn't from Visual Studio Marketplace",
                              ),
                            ),
                          );
                          return;
                        }
                        if (!uri.queryParameters.containsKey("itemName")) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Can't analyze publisher and name from url",
                              ),
                            ),
                          );
                          return;
                        }
                        final itemName = uri.queryParameters["itemName"]!;
                        if (itemName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Can't analyze publisher and name from url",
                              ),
                            ),
                          );
                          return;
                        }
                        final info = itemName.split(".");
                        if (info.length != 2 || info.contains("")) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Can't analyze publisher and name from url",
                              ),
                            ),
                          );
                          return;
                        }
                        final [pub, nam, ..._] = info;
                        setPublisherValue(pub);
                        setNameValue(nam);
                      } on FormatException {
                        return;
                      }
                    },
              child: Text('Analyze'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: publisherController,
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
                controller: nameController,
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
