import 'package:test/test.dart';
import 'package:todo_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Task endpoint CRUD', (sessionBuilder, endpoints) {
    late Task
        created; // Keep the variable declaration for use in the combined test.

    test('CRUD flow works', () async {
      // Create
      created = await endpoints.task
          .create(sessionBuilder, Task(title: 'Write tests', completed: false));
      expect(created.id, isNotNull);
      expect(created.title, 'Write tests');
      expect(created.completed, isFalse);

      // List includes
      final list1 = await endpoints.task.list(sessionBuilder);
      expect(list1.any((t) => t.id == created.id), isTrue);

      // Update
      final updated = await endpoints.task
          .update(sessionBuilder, created.copyWith(completed: true));
      expect(updated.id, created.id);
      expect(updated.completed, isTrue);

      // Get by id
      final got = await endpoints.task.getById(sessionBuilder, created.id!);
      expect(got, isNotNull);
      expect(got!.id, created.id);
      expect(got.completed, isTrue);

      // Delete
      final ok = await endpoints.task.delete(sessionBuilder, created.id!);
      expect(ok, isTrue);
      final list2 = await endpoints.task.list(sessionBuilder);
      expect(list2.any((t) => t.id == created.id), isFalse);
    });
  });
}
