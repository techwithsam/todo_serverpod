import 'package:serverpod/serverpod.dart';

import 'generated/protocol.dart';

/// Endpoint providing CRUD operations for [Task] along with real-time updates.
class TaskEndpoint extends Endpoint {
  // Use the endpoint name 'task' as the channel so client EndpointRef.stream
  // receives messages (the client routes websocket messages by endpoint
  // name). This allows clients to listen on `client.task.stream`.
  static const String channel = 'task';

  /// Returns all tasks.
  Future<List<Task>> list(Session session) async {
    return Task.db.find(session);
  }

  /// Returns a task by [id], or null if not found.
  Future<Task?> getById(Session session, int id) async {
    return Task.db.findById(session, id);
  }

  /// Creates a new task. Returns the created row with id set.
  Future<Task> create(Session session, Task task) async {
    final created = await Task.db.insertRow(session, task);
    // Publish real-time event
    await session.messages.postMessage(
      channel,
      TaskEvent(type: 'created', task: created, id: created.id),
    );
    return created;
  }

  /// Updates an existing task (matched by [task.id]). Returns the updated row.
  Future<Task> update(Session session, Task task) async {
    if (task.id == null) {
      throw ArgumentError('Task.id is required for update');
    }
    final updated = await Task.db.updateRow(session, task);
    await session.messages.postMessage(
      channel,
      TaskEvent(type: 'updated', task: updated, id: updated.id),
    );
    return updated;
  }

  /// Deletes a task by [id]. Returns true if a row was deleted.
  Future<bool> delete(Session session, int id) async {
    final deletedRows = await Task.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    if (deletedRows.isNotEmpty) {
      await session.messages.postMessage(
        channel,
        TaskEvent(type: 'deleted', task: null, id: id),
      );
      return true;
    }
    return false;
  }
}
