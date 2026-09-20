import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:common_utils/logger/logger.dart';
import 'package:firebase_utils/repositories/base/base_repository.dart';
import '../models/user.dart';

class UserRepository extends BaseRepository<User> {
  UserRepository()
      : super(
          collectionName: 'users',
          fromJson: (json) => User.fromJson(json),
        );

  // CRUD 메서드들

  // Create
  Future<User> createUser(User user) async {
    try {
      await set(user.uid, user);
      return user;
    } catch (e) {
      Log.e('UserRepository: createUser 오류: $e');
      rethrow;
    }
  }

  // Read
  Future<User?> getUser(String uid) async {
    try {
      return await get(uid);
    } catch (e) {
      Log.e('UserRepository: getUser 오류: $e');
      rethrow;
    }
  }

  // Update
  Future<void> updateUser(User user) async {
    try {
      await update(user.uid, user);
    } catch (e) {
      Log.e('UserRepository: updateUser 오류: $e');
      rethrow;
    }
  }

  // Delete
  Future<void> deleteUser(String uid) async {
    try {
      await delete(uid);
    } catch (e) {
      Log.e('UserRepository: deleteUser 오류: $e');
      rethrow;
    }
  }

  // 추가 쿼리 메서드들

  // 이메일로 사용자 찾기
  Future<User?> getUserByEmail(String email) async {
    try {
      final users = await queryByField('email', email);
      return users.isNotEmpty ? users.first : null;
    } catch (e) {
      Log.e('UserRepository: getUserByEmail 오류: $e');
      rethrow;
    }
  }

  // 상태별 사용자 목록
  Future<List<User>> getUsersByStatus(UserStatus status) async {
    try {
      return await queryByField('status', status.name);
    } catch (e) {
      Log.e('UserRepository: getUsersByStatus 오류: $e');
      rethrow;
    }
  }

  // 최근 로그인 사용자 목록
  Future<List<User>> getRecentUsers({int limit = 10}) async {
    try {
      // BaseRepository는 복잡한 쿼리를 지원하지 않으므로 직접 Firestore 쿼리 사용
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('users')
          .orderBy('lastLoginAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => User.fromJson({...doc.data(), 'uid': doc.id}))
          .toList();
    } catch (e) {
      Log.e('UserRepository: getRecentUsers 오류: $e');
      rethrow;
    }
  }

  // 사용자 수 집계
  Future<int> getUserCount() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final aggregateQuery = firestore.collection('users').count();
      final snapshot = await aggregateQuery.get();
      return snapshot.count ?? 0;
    } catch (e) {
      Log.e('UserRepository: getUserCount 오류: $e');
      rethrow;
    }
  }
}