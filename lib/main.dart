import 'package:background_downloader/background_downloader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_dir/open_dir.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VSCode Extension Downloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'VSCode Extension Downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final TextEditingController _controller = TextEditingController();
  String publisher = "";
  String name = "";
  String version = "";
  bool startDownload = false;
  DownloadTask? downloadTask;
  TaskStatus? taskStatus;
  double progress = 0;

  Future<bool> showDownloadConfirmationDialog(
    BuildContext context,
    String publisher,
    String name,
    String version,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Download Confirmation'),
          content: Text(
            'Are you sure you want to download the extension $publisher.$name@$version?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Download'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  bool validateVersion(String version) {
    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    return regex.hasMatch(version);
  }

  Future<void> downloadExtension(
    String publisher,
    String name,
    String version,
    String savePath,
  ) async {
    downloadTask = DownloadTask(
      url:
          "https://$publisher.gallery.vsassets.io/_apis/public/gallery/publisher/$publisher/extension/$name/$version/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage",
      filename: "$publisher.$name-$version.vsix",
      baseDirectory: BaseDirectory.root,
      directory: savePath,
    );
    final result = await FileDownloader().download(
      downloadTask!,
      onProgress: (progress) {
        setState(() {
          this.progress = progress;
        });
      },
      onStatus: (status) {
        setState(() {
          taskStatus = status;
        });
      },
    );
    if (!mounted) return;
    if (result.status == TaskStatus.complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text('Download completed successfully!'),
          action: SnackBarAction(
            label: "Show",
            onPressed: () async {
              await OpenDir().openNativeDir(
                path: savePath,
                highlightedFileName: "$publisher.$name-$version.vsix",
              );
            },
          ),
        ),
      );
      setState(() {
        downloadTask = null;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed')));
      setState(() {
        downloadTask = null;
        progress = 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getDownloadsDirectory().then((directory) {
      if (directory == null) {
        return;
      }
      _controller.text = directory.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 16, right: 16, left: 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Save to',
                    ),
                    controller: _controller,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    String? directory = await FilePicker.platform
                        .getDirectoryPath();
                    if (directory != null) {
                      _controller.text = directory;
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
                    onChanged: (value) => setState(() {
                      publisher = value;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Name',
                    ),
                    onChanged: (value) => setState(() {
                      name = value;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Version',
                    ),
                    onChanged: (value) => setState(() {
                      version = value;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (publisher.isEmpty ||
                          name.isEmpty ||
                          version.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill in all fields.')),
                        );
                        return;
                      }
                      if (!validateVersion(version)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invalid version format. Use x.x.x'),
                          ),
                        );
                        return;
                      }
                      final result = await showDownloadConfirmationDialog(
                        context,
                        publisher,
                        name,
                        version,
                      );
                      if (result) {
                        await downloadExtension(
                          publisher,
                          name,
                          version,
                          _controller.text,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      "Download",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (downloadTask != null) ...[
              Text('Download Status: ${taskStatus?.name ?? 'Unknown'}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text('Progress: ${(progress * 100).toStringAsFixed(2)}%'),
            ],
          ],
        ),
      ),
    );
  }
}
