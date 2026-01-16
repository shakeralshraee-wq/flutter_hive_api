import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../services/api/dio_client.dart';
import '../helpera/routes.dart';
import '../helpera/constants.dart';
import '../helpera/themes.dart';

class AuthController extends GetxController {
  final _dioClient = DioClient();
  final _settingsBox = Hive.box(AppConstants.boxSettings);
  late Box<String> _usersBox;

  final isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _usersBox = Hive.box<String>(AppConstants.boxUsers);
    _loadUser();
  }

  void _loadUser() {
    final username = _settingsBox.get(AppConstants.keyCurrentUser);
    if (username != null) {
      final userJson = _usersBox.get(username);
      if (userJson != null) {
        try {
          currentUser.value = UserModel.fromJson(jsonDecode(userJson));
        } catch (e) {
          print('Error parsing user data: $e');
        }
      }
    }
  }

  Future<void> login(String username, String password) async {
    try {
      isLoading.value = true;
      print('Login attempt: username=$username, password=$password');

      // Always use local login for simplicity
      print('Using local login');
      final userJson = _usersBox.get(username);
      UserModel localUser;
      if (userJson != null) {
        localUser = UserModel.fromJson(jsonDecode(userJson));
        print('Loaded existing user: $username');
      } else {
        localUser = UserModel(
          id: username.hashCode,
          firstName: username.isNotEmpty ? username : 'Local',
          lastName: 'User',
          email: '$username@local.com',
          image: 'https://picsum.photos/150',
          username: username.isNotEmpty ? username : 'localuser',
          gender: 'unknown',
        );
        await _usersBox.put(username, jsonEncode(localUser.toJson()));
        print('Created new user: $username');
      }
      await _settingsBox.put(AppConstants.keyToken, 'local');
      await _settingsBox.put(AppConstants.keyCurrentUser, username);
      currentUser.value = localUser;
      await Future.delayed(
          const Duration(milliseconds: 500)); // Small delay for UI
      Get.offAllNamed(AppRoutes.MAIN);
      Get.snackbar('Success', 'Logged in locally',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.successContainer,
          colorText: AppColors.success);
    } catch (e) {
      print('Login error: $e');
      Get.snackbar('Error', 'Login failed: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorContainer,
          colorText: AppColors.error);
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    _settingsBox.delete(AppConstants.keyToken);
    _settingsBox.delete(AppConstants.keyCurrentUser);
    currentUser.value = null;
    // Do not clear tasks and categories to preserve data
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  void updateUser(UserModel user) {
    _usersBox.put(user.username, jsonEncode(user.toJson()));
    currentUser.value = UserModel.fromJson(user.toJson());
  }

  bool get isLoggedIn => _settingsBox.get(AppConstants.keyToken) != null;
}
