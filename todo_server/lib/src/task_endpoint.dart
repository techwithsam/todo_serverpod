import 'generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint providing CRUD operations for [Task].
class TaskEndpoint extends Endpoint {
  static const String channel = 'tasks';

  /// Returns all tasks.
  Future<List<Task>> list(Session session) async {
    return await Task.db.find(session);
  }

  /// Returns a task by [id], or null if not found.
  Future<Task?> getById(Session session, int id) async {
    return await Task.db.findFirstRow(
      session,
      where: (t) => t.id.equals(id),
    );
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
    final numDeleted = await Task.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    if (numDeleted > 0) {
      await session.messages.postMessage(
        channel,
        TaskEvent(type: 'deleted', task: null, id: id),
      );
      return true;
    }
    return false;
  }
}
