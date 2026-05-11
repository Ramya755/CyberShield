// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scam_detection_realm.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class ScamDetectionRealm extends _ScamDetectionRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  ScamDetectionRealm(
    String id,
    String appName,
    String sender,
    String message,
    DateTime receivedAt,
    int riskScore,
    bool isScam,
    bool isSynced,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'appName', appName);
    RealmObjectBase.set(this, 'sender', sender);
    RealmObjectBase.set(this, 'message', message);
    RealmObjectBase.set(this, 'receivedAt', receivedAt);
    RealmObjectBase.set(this, 'riskScore', riskScore);
    RealmObjectBase.set(this, 'isScam', isScam);
    RealmObjectBase.set(this, 'isSynced', isSynced);
  }

  ScamDetectionRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get appName => RealmObjectBase.get<String>(this, 'appName') as String;
  @override
  set appName(String value) => RealmObjectBase.set(this, 'appName', value);

  @override
  String get sender => RealmObjectBase.get<String>(this, 'sender') as String;
  @override
  set sender(String value) => RealmObjectBase.set(this, 'sender', value);

  @override
  String get message => RealmObjectBase.get<String>(this, 'message') as String;
  @override
  set message(String value) => RealmObjectBase.set(this, 'message', value);

  @override
  DateTime get receivedAt =>
      RealmObjectBase.get<DateTime>(this, 'receivedAt') as DateTime;
  @override
  set receivedAt(DateTime value) =>
      RealmObjectBase.set(this, 'receivedAt', value);

  @override
  int get riskScore => RealmObjectBase.get<int>(this, 'riskScore') as int;
  @override
  set riskScore(int value) => RealmObjectBase.set(this, 'riskScore', value);

  @override
  bool get isScam => RealmObjectBase.get<bool>(this, 'isScam') as bool;
  @override
  set isScam(bool value) => RealmObjectBase.set(this, 'isScam', value);

  @override
  bool get isSynced => RealmObjectBase.get<bool>(this, 'isSynced') as bool;
  @override
  set isSynced(bool value) => RealmObjectBase.set(this, 'isSynced', value);

  @override
  Stream<RealmObjectChanges<ScamDetectionRealm>> get changes =>
      RealmObjectBase.getChanges<ScamDetectionRealm>(this);

  @override
  Stream<RealmObjectChanges<ScamDetectionRealm>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<ScamDetectionRealm>(this, keyPaths);

  @override
  ScamDetectionRealm freeze() =>
      RealmObjectBase.freezeObject<ScamDetectionRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'appName': appName.toEJson(),
      'sender': sender.toEJson(),
      'message': message.toEJson(),
      'receivedAt': receivedAt.toEJson(),
      'riskScore': riskScore.toEJson(),
      'isScam': isScam.toEJson(),
      'isSynced': isSynced.toEJson(),
    };
  }

  static EJsonValue _toEJson(ScamDetectionRealm value) => value.toEJson();
  static ScamDetectionRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'appName': EJsonValue appName,
        'sender': EJsonValue sender,
        'message': EJsonValue message,
        'receivedAt': EJsonValue receivedAt,
        'riskScore': EJsonValue riskScore,
        'isScam': EJsonValue isScam,
        'isSynced': EJsonValue isSynced,
      } =>
        ScamDetectionRealm(
          fromEJson(id),
          fromEJson(appName),
          fromEJson(sender),
          fromEJson(message),
          fromEJson(receivedAt),
          fromEJson(riskScore),
          fromEJson(isScam),
          fromEJson(isSynced),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(ScamDetectionRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      ScamDetectionRealm,
      'ScamDetectionRealm',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('appName', RealmPropertyType.string),
        SchemaProperty('sender', RealmPropertyType.string),
        SchemaProperty('message', RealmPropertyType.string),
        SchemaProperty('receivedAt', RealmPropertyType.timestamp),
        SchemaProperty('riskScore', RealmPropertyType.int),
        SchemaProperty('isScam', RealmPropertyType.bool),
        SchemaProperty('isSynced', RealmPropertyType.bool),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
