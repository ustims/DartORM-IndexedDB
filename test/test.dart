@TestOn("browser")
import 'dart:async';

import 'package:test/test.dart';

import 'package:logging/logging.dart';
import 'package:dart_orm/dart_orm.dart' as ORM;
import 'package:dart_orm_adapter_indexeddb/dart_orm_adapter_indexeddb.dart';


@ORM.DBTable('users')
class User extends ORM.Model {
  @ORM.DBField()
  @ORM.DBFieldPrimaryKey()
  int id;

  @ORM.DBField()
  String firstName;

  @ORM.DBField()
  String lastName;
}

void main() {
  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord rec) {
    print(
        '[${rec.loggerName}] ${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  ORM.AnnotationsParser.initialize();

  group('tests', () {
    setUpAll(() async {
      IndexedDBAdapter adapter = new IndexedDBAdapter('dart_orm_test');
      await adapter.connect();

      ORM.addAdapter('indexedDB', adapter);
      ORM.Model.ormAdapter = adapter;
    });

    test('Model should be saved and retrieved', () async {
      User u = new User();
      u.firstName = 'Sergey';
      u.lastName = 'Ustimenko';

      bool saveResult = await u.save();
      expect(saveResult, equals(true));

      ORM.FindOne f = new ORM.FindOne(User)
        ..where(new ORM.Equals('id', u.id)); // id will be set by .save()

      User foundUser = await f.execute();

      expect(foundUser.firstName, equals('Sergey'));
    });

    test('Update model', () async {
      User u = new User();

      u.firstName = 'Sergey';
      u.lastName = 'Ustimenko';

      bool saveResult = await u.save();
      expect(saveResult, equals(true));

      // firstly check if model was properly saved
      ORM.FindOne f = new ORM.FindOne(User)
        ..where(new ORM.Equals('id', u.id)); // id will be set by .save()

      User foundUser = await f.execute();

      expect(foundUser.firstName, equals('Sergey'));

      u.firstName = 'Yegres';
      await u.save();

      // now lets retrieve user again and check if it was modified

      ORM.FindOne findModified = new ORM.FindOne(User)
        ..where(new ORM.Equals('id', u.id)); // id will be set by .save()

      User foundModifiedUser = await findModified.execute();

      expect(foundModifiedUser.firstName, equals('Yegres'));
    });

    test('Delete model', () async {
      User u = new User();

      u.firstName = 'Sergey';
      u.lastName = 'Ustimenko';

      bool saveResult = await u.save();
      expect(saveResult, equals(true));

      // firstly check if model was properly saved
      ORM.FindOne f = new ORM.FindOne(User)
        ..where(new ORM.Equals('id', u.id)); // id will be set by .save()

      User foundUser = await f.execute();

      expect(foundUser.firstName, equals('Sergey'));

      // now lets delete that model

      await u.delete();

      ORM.FindOne findDeleted = new ORM.FindOne(User)
        ..whereEquals('id', u.id);

      User foundDeleted = await findDeleted.execute();

      print(foundDeleted);

      expect(foundDeleted, equals(null));
    });

    test('Select should be possible only by primary key', () async {
      ORM.Find f = new ORM.Find(User)
        ..where(new ORM.Equals('firstName', 'qwerty'));

      expect(f.execute(), throwsArgumentError);
    });
  });
}

