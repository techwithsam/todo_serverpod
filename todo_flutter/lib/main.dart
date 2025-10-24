import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:todo_client/todo_client.dart';

/// Sets up a global client object that can be used to talk to the server from
/// anywhere in our app. The client is generated from your server code
/// and is set up to connect to a Serverpod running on a local server on
/// the default port. You will need to modify this to connect to staging or
/// production servers.
/// In a larger app, you may want to use the dependency injection of your choice
/// instead of using a global client object. This is just a simple example.
late final Client client;

late String serverUrl;

void main() {
  // When you are running the app on a physical device, you need to set the
  // server URL to the IP address of your computer. You can find the IP
  // address by running `ipconfig` on Windows or `ifconfig` on Mac/Linux.
  // You can set the variable when running or building your app like this:
  // E.g. `flutter run --dart-define=SERVER_URL=https://api.example.com/`
  const serverUrlFromEnv = String.fromEnvironment('SERVER_URL');
  final serverUrl =
      serverUrlFromEnv.isEmpty ? 'http://$localhost:8080/' : serverUrlFromEnv;

  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    // Open streaming connection and listen to the Task endpoint stream for
    // real-time TaskEvent updates. The server publishes TaskEvent objects to
    // the endpoint name 'task'.
    _initRealtime();
  }

  Future<void> _initRealtime() async {
    try {
      await client.openStreamingConnection();
      client.task.stream.listen((message) {
        if (message is TaskEvent) {
          setState(() {
            switch (message.type) {
              case 'created':
                if (message.task != null) {
                  // Deduplicate if we already added optimistically
                  final exists = _tasks.any((t) => t.id == message.task!.id);
                  if (!exists) _tasks.add(message.task!);
                }
                break;
              case 'updated':
                if (message.task != null) {
                  final i = _tasks.indexWhere((t) => t.id == message.task!.id);
                  if (i != -1) _tasks[i] = message.task!;
                }
                break;
              case 'deleted':
                _tasks.removeWhere((t) => t.id == message.id);
                break;
            }
          });
        }
      });
    } catch (e) {
      // If streaming fails, we silently ignore — UI will still work via
      // manual refresh. Consider showing a banner in production.
    }
  }

  /// Load all tasks from the server on init
  Future<void> _loadTasks() async {
    try {
      final tasks = await client.task.list();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tasks: $e';
        _isLoading = false;
      });
    }
  }

  /// Show dialog to create a new task
  Future<void> _showAddTaskDialog() async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Task title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _createTask(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Create a new task on the server
  Future<void> _createTask(String title) async {
    try {
      final created =
          await client.task.create(Task(title: title, completed: false));
      // Optimistic update: add immediately; real-time event will be deduped.
      setState(() {
        final exists = _tasks.any((t) => t.id == created.id);
        if (!exists) {
          _tasks.add(created);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
      }
    }
  }

  /// Toggle task completion
  Future<void> _toggleTask(Task task) async {
    try {
      final updated =
          await client.task.update(task.copyWith(completed: !task.completed));
      // Optimistic: replace in place (idempotent with event listener)
      setState(() {
        final i = _tasks.indexWhere((t) => t.id == updated.id);
        if (i != -1) _tasks[i] = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  /// Delete a task
  Future<void> _deleteTask(int id) async {
    try {
      // Optimistic: remove locally first
      setState(() {
        _tasks.removeWhere((t) => t.id == id);
      });
      await client.task.delete(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
    }
  }

  /// Rename a task (edit title)
  Future<void> _renameTask(Task task) async {
    final controller = TextEditingController(text: task.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle == null || newTitle.isEmpty || newTitle == task.title) return;

    try {
      final updated = await client.task.update(task.copyWith(title: newTitle));
      setState(() {
        final i = _tasks.indexWhere((t) => t.id == updated.id);
        if (i != -1) _tasks[i] = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet.\nTap + to add one!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Dismissible(
          key: Key('task_${task.id}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteTask(task.id!),
          child: ListTile(
            leading: Checkbox(
              value: task.completed,
              onChanged: (_) => _toggleTask(task),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.completed ? TextDecoration.lineThrough : null,
                color: task.completed ? Colors.grey : null,
              ),
            ),
            onTap: () => _toggleTask(task),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _renameTask(task),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTask(task.id!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
