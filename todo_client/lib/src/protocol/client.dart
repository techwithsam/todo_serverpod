/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:todo_client/src/protocol/greeting.dart' as _i3;
import 'package:todo_client/src/protocol/task.dart' as _i4;
import 'protocol.dart' as _i5;

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i3.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i3.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// Endpoint providing CRUD operations for [Task] along with real-time updates.
/// {@category Endpoint}
class EndpointTask extends _i1.EndpointRef {
  EndpointTask(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'task';

  /// Returns all tasks.
  _i2.Future<List<_i4.Task>> list() =>
      caller.callServerEndpoint<List<_i4.Task>>(
        'task',
        'list',
        {},
      );

  /// Returns a task by [id], or null if not found.
  _i2.Future<_i4.Task?> getById(int id) => caller.callServerEndpoint<_i4.Task?>(
        'task',
        'getById',
        {'id': id},
      );

  /// Creates a new task. Returns the created row with id set.
  _i2.Future<_i4.Task> create(_i4.Task task) =>
      caller.callServerEndpoint<_i4.Task>(
        'task',
        'create',
        {'task': task},
      );

  /// Updates an existing task (matched by [task.id]). Returns the updated row.
  _i2.Future<_i4.Task> update(_i4.Task task) =>
      caller.callServerEndpoint<_i4.Task>(
        'task',
        'update',
        {'task': task},
      );

  /// Deletes a task by [id]. Returns true if a row was deleted.
  _i2.Future<bool> delete(int id) => caller.callServerEndpoint<bool>(
        'task',
        'delete',
        {'id': id},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    _i1.AuthenticationKeyManager? authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
          host,
          _i5.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    greeting = EndpointGreeting(this);
    task = EndpointTask(this);
  }

  late final EndpointGreeting greeting;

  late final EndpointTask task;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'greeting': greeting,
        'task': task,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
