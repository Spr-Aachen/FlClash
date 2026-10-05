import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/boot_record.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/system_dns.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static Preferences? _instance;
  final _PreferencesStore _store;
  final Completer<Map<String, Object?>?> _preferencesCompleter = Completer();

  Preferences._internal({String? pathOverride})
    : _store = pathOverride != null
          ? _FileStore(pathOverride: pathOverride)
          : system.isDesktop
          ? _FileStore()
          : _SharedPreferencesStore() {
    _init();
  }

  factory Preferences() {
    _instance ??= Preferences._internal();
    return _instance!;
  }

  @visibleForTesting
  static Preferences createForTest({String? path}) {
    return Preferences._internal(pathOverride: path);
  }

  Future<Map<String, Object?>?> get _preferences async =>
      _preferencesCompleter.future;

  Future<bool> get isInit async => await _preferences != null;

  Future<void> _init() async {
    try {
      final data = await _store.load();
      _preferencesCompleter.complete(data);
    } catch (e) {
      commonPrint.log(
        'Failed to load preferences: $e',
        logLevel: LogLevel.warning,
      );
      _preferencesCompleter.complete(null);
    }
  }

  Future<bool> _save() async {
    final data = await _preferences;
    if (data == null) return false;
    return _store.save(data);
  }

  Future<int> getVersion() async {
    final preferences = await _preferences;
    return preferences?['version'] as int? ?? 0;
  }

  Future<void> setVersion(int version) async {
    final preferences = await _preferences;
    if (preferences == null) return;
    preferences['version'] = version;
    await _save();
  }

  Future<void> saveShareState(SharedState shareState) async {
    final preferences = await _preferences;
    if (preferences == null) return;
    preferences['sharedState'] = jsonEncode(shareState);
    await _save();
  }

  Future<Map<String, Object?>?> getConfigMap() async {
    try {
      final preferences = await _preferences;
      final configString = preferences?[configKey] as String?;
      if (configString == null) return null;
      final Map<String, Object?>? configMap = jsonDecode(configString);
      return configMap;
    } catch (e) {
      commonPrint.log(
        'getConfigMap error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<Map<String, Object?>?> getClashConfigMap() async {
    try {
      final preferences = await _preferences;
      final clashConfigString = preferences?[clashConfigKey] as String?;
      if (clashConfigString == null) return null;
      return json.decode(clashConfigString);
    } catch (e) {
      commonPrint.log(
        'getClashConfigMap error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> clearClashConfig() async {
    try {
      final preferences = await sharedPreferencesCompleter.future;
      await preferences?.remove(clashConfigKey);
      return;
    } catch (e) {
      commonPrint.log(
        'clearClashConfig error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return;
    }
  }

  Future<Config?> getConfig() async {
    final configMap = await getConfigMap();
    if (configMap == null) {
      return null;
    }
    return Config.fromJson(configMap);
  }

  Future<bool> saveConfig(Config config) async {
    final preferences = await sharedPreferencesCompleter.future;
    return preferences?.setString(configKey, json.encode(config)) ?? false;
  }

  Future<SystemDnsRecord?> getSystemDnsRecord() async {
    try {
      final sharedPreferencesIns = await sharedPreferencesCompleter.future;
      final raw = sharedPreferencesIns?.getString(systemDnsRecordKey);
      if (raw == null) {
        return null;
      }
      return SystemDnsRecord.fromJson(json.decode(raw));
    } catch (e) {
      commonPrint.log(
        'getSystemDnsRecord error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> saveSystemDnsRecord(SystemDnsRecord record) async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.setString(
      systemDnsRecordKey,
      json.encode(record),
    );
  }

  Future<void> clearSystemDnsRecord() async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.remove(systemDnsRecordKey);
  }

  Future<BootRecord?> getBootRecord() async {
    try {
      final sharedPreferencesIns = await sharedPreferencesCompleter.future;
      final raw = sharedPreferencesIns?.getString(bootRecordKey);
      if (raw == null) {
        return null;
      }
      return BootRecord.fromJson(json.decode(raw));
    } catch (e) {
      commonPrint.log(
        'getBootRecord error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> saveBootRecord(BootRecord record) async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.setString(bootRecordKey, json.encode(record));
  }

  Future<void> clearPreferences() async {
    final preferences = await _preferences;
    if (preferences == null) return;
    preferences.clear();
    await _save();
  }
}

final preferences = Preferences();