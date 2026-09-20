import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:common_utils/logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppConfig {
  // Singleton 구현
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // 기본 설정값 정의
  static const Map<String, dynamic> _defaultConfig = {
    'app_name': 'Boilerplate App',
    'auth_service_type': 'firebase', // 'firebase' 또는 'kakao'
    'admin_uids': [],
    'enable_analytics': true,
    'maintenance_mode': false,
  };

  // 인스턴스 변수
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  Map<String, dynamic> _configValues = {};
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _configSubscription;

  // 초기화
  Future<void> initialize() async {
    Log.d('AppConfig: 초기화 시작');

    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _configValues = Map.from(_defaultConfig);

    // Auth 상태 변경 감지
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen(
      (User? user) async {
        Log.d('AppConfig: 인증 상태 변경 - User: ${user?.uid}');
        if (user != null) {
          await _setupConfigListener();
        } else {
          _configSubscription?.cancel();
        }
      },
      onError: (error) {
        Log.e('AppConfig: 인증 상태 스트림 오류: $error');
      },
    );

    // 현재 로그인된 상태면 바로 설정 리스너 설정
    if (_auth.currentUser != null) {
      await _setupConfigListener();
    }

    Log.d('AppConfig: 초기화 완료');
  }

  // 설정 변경 리스너 설정
  Future<void> _setupConfigListener() async {
    _configSubscription?.cancel();
    final docRef = _firestore.collection('config').doc('app_settings');

    // 초기 설정 가져오기
    await _fetchConfigFromFirestore();

    // 실시간 업데이트 리스너 설정
    _configSubscription = docRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _configValues = snapshot.data() as Map<String, dynamic>;
        Log.d('AppConfig: 설정 업데이트됨');
      }
    }, onError: (error) {
      Log.e('AppConfig: 설정 스트림 오류: $error');
    });
  }

  // Firestore에서 설정 가져오기
  Future<void> _fetchConfigFromFirestore() async {
    try {
      final docRef = _firestore.collection('config').doc('app_settings');
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // 설정 문서가 없으면 기본값으로 생성
        await docRef.set(_defaultConfig);
        _configValues = Map.from(_defaultConfig);
      } else {
        _configValues = docSnapshot.data() as Map<String, dynamic>;
      }
    } catch (e) {
      Log.e('AppConfig: 설정 가져오기 오류: $e');
      _configValues = Map.from(_defaultConfig);
    }
  }

  // dispose 시 모든 리스너 해제
  void dispose() {
    _authSubscription?.cancel();
    _configSubscription?.cancel();
  }

  // 설정값 getter
  String get appName => _configValues['app_name'] ?? _defaultConfig['app_name'];
  
  String get authServiceType => _configValues['auth_service_type'] ?? _defaultConfig['auth_service_type'];
  
  bool get enableAnalytics => _configValues['enable_analytics'] ?? _defaultConfig['enable_analytics'];
  
  bool get maintenanceMode => _configValues['maintenance_mode'] ?? _defaultConfig['maintenance_mode'];

  // 관리자 확인
  bool isAdmin(String? uid) {
    if (uid == null) return false;
    final adminUids = _configValues['admin_uids'] ?? [];
    return adminUids.contains(uid);
  }
}