import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/task.dart';
import '../../helpera/constants.dart';
import 'dio_client.dart';

class TodoApi {
  final DioClient _client = DioClient();
  final bool debug;

  TodoApi({this.debug = false});

  Future<List<Task>> fetchTodos({int limit = 30, int skip = 0}) async {
    final path = '/todos';
    final query = {'limit': limit, 'skip': skip};
    if (debug) print('TodoApi: GET $path query=${jsonEncode(query)}');
    final resp = await _client.get(path, queryParameters: query);
    if (debug)
      print(
          'TodoApi: GET $path responseStatus=${resp.statusCode} data=${resp.data}');
    final data = resp.data;
    if (data == null || data['todos'] == null) return [];
    final todos = <Task>[];
    for (final item in data['todos']) {
      todos.add(_fromJson(item));
    }
    return todos;
  }

  Future<Task> addTask(Task task) async {
    final path = '/todos/add';
    final body = {
      'todo': task.title,
      'completed': task.isCompleted,
      'userId': 1,
      'description': task.description,
    };
    if (debug) print('TodoApi: POST $path body=${jsonEncode(body)}');
    final resp = await _client.post(path, data: body);
    if (debug)
      print(
          'TodoApi: POST $path responseStatus=${resp.statusCode} data=${resp.data}');
    return _fromJson(resp.data);
  }

  Future<Task> updateTask(Task task) async {
    final idNum = int.tryParse(task.id) ?? 0;
    final path = '/todos/$idNum';
    final body = {
      'todo': task.title,
      'completed': task.isCompleted,
      'description': task.description,
    };
    if (debug) print('TodoApi: PUT $path body=${jsonEncode(body)}');
    final resp = await _client.put(path, data: body);
    if (debug)
      print(
          'TodoApi: PUT $path responseStatus=${resp.statusCode} data=${resp.data}');
    return _fromJson(resp.data);
  }

  Future<void> deleteTask(String id) async {
    final idNum = int.tryParse(id) ?? 0;
    final path = '/todos/$idNum';
    if (debug) print('TodoApi: DELETE $path');
    final resp = await _client.delete(path);
    if (debug)
      print(
          'TodoApi: DELETE $path responseStatus=${resp.statusCode} data=${resp.data}');
  }

  Task _fromJson(dynamic json) {
    return Task(
      id: json['id'].toString(),
      title: json['todo'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: null,
      isCompleted: json['completed'] ?? false,
      createdAt: DateTime.now(),
      userId: '1', // Default userId
    );
  }
}
