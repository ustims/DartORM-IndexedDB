library dart_orm_adapter_indexeddb;

import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'dart:indexed_db' as idb;

import 'package:dart_orm/dart_orm.dart';
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';

class IndexedDBAdapter extends DBAdapter {
  final Logger log = new Logger('DartORM.IndexedDBAdapter');

  final String databaseName;

  idb.Database database = null;

  IndexedDBAdapter(this.databaseName);

  Future connect() async {
    this.database = await window.indexedDB
        .open(this.databaseName, version: 1, onUpgradeNeeded: _onUpgradeNeeded);

    log.finest('Connected to the database!');
    log.finest(this.database.objectStoreNames);
  }

  void _onUpgradeNeeded(idb.VersionChangeEvent e) {
    idb.Database db = (e.target as idb.OpenDBRequest).result;

    Map<String, Table> tables = AnnotationsParser.ormClasses;

    for (Table t in tables.values) {
      if (!db.objectStoreNames.contains(t.tableName)) {
        Field primaryKey = t.getPrimaryKeyField();

        if (primaryKey != null) {
          log.finest('Creating table:');
          log.finest('Table name: ${t}, primary key: ${primaryKey.fieldName}');

          db.createObjectStore(t.tableName,
              keyPath: primaryKey.fieldName, autoIncrement: true);
        }
      }
    }
  }

  /// Closes all connections to the database.
  void close() {
    this.database.close();
    log.finest('Connection closed.');
  }

  Future createTable(Table table) async {
    this.database.createObjectStore(table.tableName);
  }

  Future<List<Map>> select(Select select) async {
    log.finest('Select:');
    log.finest(select);

    Field primaryKey = select.table.getPrimaryKeyField();

    if (!this.database.objectStoreNames.contains(select.table.tableName)) {
      throw new TableNotExistException();
    }

    var trans = this.database.transaction(select.table.tableName, 'readwrite');
    idb.ObjectStore store = trans.objectStore(select.table.tableName);

    if (select.condition.firstVar != primaryKey.fieldName ||
        select.condition.conditionQueue.length > 0) {
      throw new ArgumentError(
          'IndexedDB adapter only supports simple selects by primary key');
    }

    var result = await store.getObject(select.condition.secondVar);

    log.finest('Result:');
    log.finest(result);

    return result != null ? [result] : [];
  }

  Future<int> insert(Insert insert) async {
    log.finest('Insert:');

    ensureTableExists(insert.table);

    Field primaryKey = insert.table.getPrimaryKeyField();

    var trans = this.database.transaction(insert.table.tableName, 'readwrite');
    idb.ObjectStore store = trans.objectStore(insert.table.tableName);

    var result = await store.add(insert.fieldsToInsert);

    log.finest('result:');
    log.finest(result);

    return result;
  }

  Future<int> update(Update update) async {
    log.finest('Update:');
    log.finest(update);

    ensureTableExists(update.table);

    Field primaryKey = update.table.getPrimaryKeyField();

    if (update.condition.firstVar != primaryKey.fieldName ||
        update.condition.conditionQueue.length > 0) {
      throw new ArgumentError(
          'IndexedDB adapter only supports simple updates by primary key');
    }

    var trans = this.database.transaction(update.table.tableName, 'readwrite');
    idb.ObjectStore store = trans.objectStore(update.table.tableName);

    update.fieldsToUpdate[primaryKey.fieldName] = update.condition.secondVar;

    log.finest('Fields to update:');
    log.finest(update.fieldsToUpdate);

    var result = await store.put(update.fieldsToUpdate);

    log.finest('Result');
    log.finest(result);

    return 1;
  }

  Future delete(Delete delete) async {
    log.finest('Delete:');
    log.finest(delete);

    ensureTableExists(delete.table);

    Field primaryKey = delete.table.getPrimaryKeyField();

    if (delete.condition.firstVar != primaryKey.fieldName ||
        delete.condition.conditionQueue.length > 0) {
      throw new ArgumentError(
          'IndexedDB adapter only supports simple deletes by primary key');
    }

    var trans = this.database.transaction(delete.table.tableName, 'readwrite');
    idb.ObjectStore store = trans.objectStore(delete.table.tableName);

    var result = await store.delete(delete.condition.secondVar);

    log.finest('Result:');
    log.finest(result);

    return 1;
  }

  ensureTableExists(Table table) {
    if (!this.database.objectStoreNames.contains(table.tableName)) {
      throw new TableNotExistException();
    }
  }
}
