IndexedDB adapter for DartORM.
===============================

IndexedDB adapter for DartORM to use on client side.

This allows to use same annotated models for both backend and frontend.

Example could be found in test package:

https://github.com/ustims/DartORM-IndexedDB/blob/master/test/test.dart

https://github.com/ustims/DartORM

Development
-----------

Use this commands to run tests on any browser installed in the system:

`pub run test:test -p chrome test/test.dart`

`pub run test:test -p firefox test/test.dart`

`pub run test:test -p safari test/test.dart`

Fast run without compiling to javascript could be done using headless dartium:

`pub run test:test -p content-shell test/test.dart`