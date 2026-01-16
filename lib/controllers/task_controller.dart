import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';
import '../helpera/constants.dart';
import '../services/api/todo_api.dart';
import 'auth_controller.dart';

class TaskController extends GetxController {
  late Box<Task> taskBox;
  String? selectedCategoryId;
  String? currentUserId;

  @override
  void onInit() {
    super.onInit();
    taskBox = Hive.box<Task>(AppConstants.boxTasks);
    final authController = Get.find<AuthController>();
    currentUserId = authController.currentUser.value?.id.toString();
    print('TaskController onInit, currentUserId: $currentUserId');
    ever(authController.currentUser, (user) {
      currentUserId = user?.id.toString();
      print('currentUser changed, new currentUserId: $currentUserId');
      update();
    });
  }

  List<Task> get tasks {
    final filtered = taskBox.values
        .where((t) => t.userId == currentUserId.toString())
        .toList();
    print(
        'tasks getter: currentUserId=$currentUserId, filtered count=${filtered.length}');
    return filtered;
  }

  List<Task> get filteredTasks {
    final f = tasks
        .where((t) =>
            selectedCategoryId == null || t.categoryId == selectedCategoryId)
        .toList();
    print(
        'filteredTasks: selectedCategoryId=$selectedCategoryId, tasks count=${tasks.length}, filtered count=${f.length}');
    return f;
  }

  List<Task> get completedTasks =>
      filteredTasks.where((t) => t.isCompleted).toList();
  List<Task> get pendingTasks =>
      filteredTasks.where((t) => !t.isCompleted).toList();

  Future<void> addTask(Task task) async {
    print('addTask called with userId: ${task.userId}');
    await _addRemoteAndLocal(task);
  }

  Future<void> updateTask(Task task) async {
    await _updateRemoteAndLocal(task);
  }

  Future<void> deleteTask(String id) async {
    await _deleteRemoteAndLocal(id);
  }

  final TodoApi _api = TodoApi(debug: true);

  Future<void> _addRemoteAndLocal(Task task) async {
    try {
      print(
          'TaskController: addTask request -> id=${task.id} title=${task.title} completed=${task.isCompleted} description=${task.description}');
      final created = await _api.addTask(task);
      print(
          'TaskController: addTask response -> id=${created.id} title=${created.title} completed=${created.isCompleted}');
      // Preserve the original id and categoryId
      created.id = task.id;
      created.categoryId = task.categoryId;
      created.userId = task.userId; // Preserve the userId
      print('Saving task with id=${created.id}, userId=${created.userId}');
      taskBox.put(created.id, created);
      print('Task saved, calling update()');
      update();
      Get.snackbar('Success', 'Task added',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('TaskController: addTask error -> $e');
      Get.snackbar('Error', 'Failed to add task',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _updateRemoteAndLocal(Task task) async {
    try {
      print(
          'TaskController: updateTask request -> id=${task.id} title=${task.title} completed=${task.isCompleted} description=${task.description}');
      final updated = await _api.updateTask(task);
      print(
          'TaskController: updateTask response -> id=${updated.id} title=${updated.title} completed=${updated.isCompleted}');
      // Preserve the categoryId from the original task
      updated.categoryId = task.categoryId;
      taskBox.put(updated.id, updated);
      update();
      Get.snackbar('Success', 'Task updated',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('TaskController: updateTask error -> $e');
      if (e is DioException && e.response?.statusCode == 404) {
        // Remote resource not found — apply local update as fallback
        taskBox.put(task.id, task);
        update();
        Get.snackbar('Warning', 'Remote not found; updated locally',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', 'Failed to update task',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Future<void> _deleteRemoteAndLocal(String id) async {
    try {
      print('TaskController: deleteTask request -> id=$id');
      await _api.deleteTask(id);
      print('TaskController: deleteTask response -> id=$id deleted');
      taskBox.delete(id);
      update();
      Get.snackbar('Success', 'Task deleted',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print('TaskController: deleteTask error -> $e');
      if (e is DioException && e.response?.statusCode == 404) {
        // Remote resource not found — delete locally as fallback
        taskBox.delete(id);
        update();
        Get.snackbar('Warning', 'Remote not found; deleted locally',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', 'Failed to delete task',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  void toggleComplete(String id) {
    final task = taskBox.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      task.save();
      update();
    }
  }

  void setFilter(String? categoryId) {
    selectedCategoryId = categoryId;
    update();
  }

  Task? getTask(String id) => taskBox.get(id);
}
