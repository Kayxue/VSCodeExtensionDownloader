import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:open_dir/open_dir.dart';
import 'package:vscode_extension_downloader/Widgets/Inputs.dart';
import 'Widgets/DownloadStatus.dart';
import 'package:folder_permission_checker/folder_permission_checker.dart';

Future<void> main() async {
  FolderPermissionChecker.init();
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

  void setPublisher(String value) {
    setState(() {
      publisher = value;
    });
  }

  void setName(String value) {
    setState(() {
      name = value;
    });
  }

  void setVersion(String value) {
    setState(() {
      version = value;
    });
  }

  bool validateVersion(String version) {
    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    return regex.hasMatch(version);
  }

  void checkFields() {
    if (publisher.isEmpty ||
        name.isEmpty ||
        version.isEmpty ||
        _controller.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields.')));
      return;
    }
    if (!validateVersion(version)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid version format. Use x.x.x')),
      );
      return;
    }
  }

  Future<bool> checkLocationPermission(String path) async {
    final readonly = await FolderPermissionChecker.isReadonly(path);
    if (!mounted) return false;
    if (readonly) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No write permission to the selected folder. Please choose another folder.',
          ),
        ),
      );
      return false;
    }
    final writable = await FolderPermissionChecker.isDirectoryWritable(path);
    if (!mounted) return false;
    if (!writable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No write permission to the selected folder. Please choose another folder.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> downloadExtension(
    String publisher,
    String name,
    String version,
    String savePath,
  ) async {
    if (!await checkLocationPermission(savePath)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No write permission to the selected folder. Please choose another folder.',
          ),
        ),
      );
      return;
    }
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
            Inputs(
              taskStatus: taskStatus,
              publisher: publisher,
              name: name,
              version: version,
              setPublisher: setPublisher,
              setName: setName,
              setVersion: setVersion,
              controller: _controller,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: taskStatus == TaskStatus.running
                        ? null
                        : () async {
                            checkFields();
                            final confirmResult =
                                await showDownloadConfirmationDialog(
                                  context,
                                  publisher,
                                  name,
                                  version,
                                );
                            if (confirmResult) {
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
            if (downloadTask != null)
              Downloadstatus(taskStatus: taskStatus, progress: progress),
          ],
        ),
      ),
    );
  }
}
