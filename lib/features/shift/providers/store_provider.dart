import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/store.dart';

/// 店舗の状態管理
class StoreNotifier extends StateNotifier<List<Store>> {
  StoreNotifier() : super([]) {
    _loadFromStorage();
  }

  static const String _storageKey = 'stores';

  // ==================== データ永続化 ====================

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final List<Store> stores = jsonList
            .map((json) => Store.fromJson(json as Map<String, dynamic>))
            .toList();

        state = stores;
      } else {
        // 初回起動時はデフォルト店舗を作成
        _createDefaultStore();
      }
    } catch (e) {
      print('Failed to load stores: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _createDefaultStore();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((store) => store.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('Failed to save stores: $e');
    }
  }

  void _createDefaultStore() {
    final defaultStore = Store(
      id: 'default',
      name: '本店',
      color: storeColorPalette[0],
    );
    state = [defaultStore];
    _saveToStorage();
  }

  // ==================== 店舗操作 ====================

  /// 店舗を追加
  Store addStore(String name) {
    // 次の色を選択
    final colorIndex = state.length % storeColorPalette.length;
    final color = storeColorPalette[colorIndex];

    final newStore = Store(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
    );

    state = [...state, newStore];
    _saveToStorage();
    return newStore;
  }

  /// 店舗を削除
  void removeStore(String storeId) {
    // デフォルト店舗は削除できない
    if (storeId == 'default') return;

    state = state.where((store) => store.id != storeId).toList();
    _saveToStorage();
  }

  /// 店舗名を変更
  void renameStore(String storeId, String newName) {
    state = state.map((store) {
      if (store.id == storeId) {
        return store.copyWith(name: newName);
      }
      return store;
    }).toList();
    _saveToStorage();
  }

  /// 店舗の色を変更
  void changeStoreColor(String storeId, Color newColor) {
    state = state.map((store) {
      if (store.id == storeId) {
        return store.copyWith(color: newColor);
      }
      return store;
    }).toList();
    _saveToStorage();
  }

  /// IDから店舗を取得
  Store? getStoreById(String storeId) {
    try {
      return state.firstWhere((store) => store.id == storeId);
    } catch (e) {
      return null;
    }
  }
}

/// 店舗プロバイダー
final storeProvider = StateNotifierProvider<StoreNotifier, List<Store>>((ref) {
  return StoreNotifier();
});

/// デフォルト店舗を取得するProvider
final defaultStoreProvider = Provider<Store>((ref) {
  final stores = ref.watch(storeProvider);
  return stores.firstWhere(
    (store) => store.id == 'default',
    orElse: () => stores.first,
  );
});
