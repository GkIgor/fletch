import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fletch/core/app_config.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/widgets/body_editor.dart';
import 'package:fletch/widgets/dialogs/auto_collections_generator_dialog.dart';
import 'package:fletch/widgets/dialogs/payload_bulk_importer_dialog.dart';

void main() {
  late Directory tempDir;
  late String originalWorkspaceDir;
  late String originalCollectionsDir;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    originalWorkspaceDir = AppConfig.workspaceDir;
    originalCollectionsDir = AppConfig.collectionsDir;
    tempDir = await Directory.systemTemp.createTemp('tools_test_');
    AppConfig.workspaceDir = '${tempDir.path}/workspaces';
    AppConfig.collectionsDir = '${tempDir.path}/collections';
    await Directory(AppConfig.workspaceDir).create(recursive: true);
    await Directory(AppConfig.collectionsDir).create(recursive: true);
  });

  tearDown(() async {
    AppConfig.workspaceDir = originalWorkspaceDir;
    AppConfig.collectionsDir = originalCollectionsDir;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('RequestProvider bulkImportPayloads adds and replaces request bodies in single transaction', () async {
    final provider = RequestProvider();
    final workspaceId = 'test-ws-id';

    final collectionA = RequestCollection(
      name: 'Collection A',
      workspaceId: workspaceId,
      sortOrder: 0,
    );
    await provider.addCollection(collectionA);

    final request1 = HttpRequest(
      id: 'req-1',
      name: 'Get User',
      method: HttpMethod.get,
      url: 'https://api.example.com/user',
    );
    provider.addRequestToCollection(collectionA.id, request1);

    // Prepare bulk import inputs
    final newRequest = HttpRequest(
      id: 'req-new',
      name: 'New Create Request',
      method: HttpMethod.post,
      url: 'https://api.example.com/create',
      bodyType: BodyType.json,
      body: '{"foo": "bar"}',
    );
    final updatedRequest = request1.copyWith(
      bodyType: BodyType.json,
      body: '{"updated": true}',
    );

    await provider.bulkImportPayloads(
      newRequestsWithCollectionId: [MapEntry(collectionA.id, newRequest)],
      updatedRequests: [updatedRequest],
    );

    // Verify results
    expect(provider.collections[0].requests.length, equals(2));
    
    // Find the updated request
    final req1 = provider.collections[0].requests.firstWhere((r) => r.id == 'req-1');
    expect(req1.body, equals('{"updated": true}'));
    expect(req1.bodyType, equals(BodyType.json));

    // Find the newly imported request
    final reqNew = provider.collections[0].requests.firstWhere((r) => r.id == 'req-new');
    expect(reqNew.name, equals('New Create Request'));
    expect(reqNew.method, equals(HttpMethod.post));
    expect(reqNew.body, equals('{"foo": "bar"}'));
    expect(reqNew.bodyType, equals(BodyType.json));
  });

  testWidgets('AutoCollectionsGeneratorDialog - End to End Outline Parser and Generator Test', (WidgetTester tester) async {
    final provider = RequestProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<RequestProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const Dialog(
                        child: AutoCollectionsGeneratorDialog(isDark: false),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tap Open to show dialog
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Find the TextField for outline input
    final outlineInputFinder = find.byType(TextField);
    expect(outlineInputFinder, findsOneWidget);

    // Enter outline text
    await tester.enterText(
      outlineInputFinder,
      '+ Auth API\n  - POST /login\n  - GET /me\n+ Users API\n  - GET /profile',
    );
    await tester.pump();

    // Tap the "Populate Visual Builder" button
    final populateBtnFinder = find.text('Populate Visual Builder');
    expect(populateBtnFinder, findsOneWidget);
    await tester.tap(populateBtnFinder);
    await tester.pumpAndSettle();

    // Now we should be in Tab 2 (Visual Tree Builder)
    // Check that collections and requests are shown in TextFormField inputs
    expect(find.text('Auth API'), findsOneWidget);
    expect(find.text('Users API'), findsOneWidget);
    expect(find.text('/login'), findsOneWidget);
    expect(find.text('/me'), findsOneWidget);
    expect(find.text('/profile'), findsOneWidget);

    // Tap "Generate Collections & Requests" button
    final generateBtnFinder = find.text('Generate Collections & Requests');
    expect(generateBtnFinder, findsOneWidget);
    await tester.tap(generateBtnFinder);
    await tester.pumpAndSettle();

    // Verify that the collections and requests were added to the provider
    expect(provider.collections.length, equals(2));
    
    final authColl = provider.collections.firstWhere((c) => c.name == 'Auth API');
    expect(authColl.requests.length, equals(2));
    expect(authColl.requests[0].name, equals('/login'));
    expect(authColl.requests[0].method, equals(HttpMethod.post));
    expect(authColl.requests[1].name, equals('/me'));
    expect(authColl.requests[1].method, equals(HttpMethod.get));

    final usersColl = provider.collections.firstWhere((c) => c.name == 'Users API');
    expect(usersColl.requests.length, equals(1));
    expect(usersColl.requests[0].name, equals('/profile'));
    expect(usersColl.requests[0].method, equals(HttpMethod.get));
  });

  testWidgets('AutoCollectionsGeneratorDialog - Direct Generation from Tab 0 Test', (WidgetTester tester) async {
    final provider = RequestProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<RequestProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const Dialog(
                        child: AutoCollectionsGeneratorDialog(isDark: false),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tap Open to show dialog
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Find the TextField for outline input (we are on Tab 0)
    final outlineInputFinder = find.byType(TextField);
    expect(outlineInputFinder, findsOneWidget);

    // Enter outline text
    await tester.enterText(
      outlineInputFinder,
      '+ Direct Tab0 API\n  - PUT /update',
    );
    await tester.pump();

    // Tap "Generate Collections & Requests" button directly
    final generateBtnFinder = find.text('Generate Collections & Requests');
    expect(generateBtnFinder, findsOneWidget);
    
    // The button should be enabled and clickable
    await tester.tap(generateBtnFinder);
    await tester.pumpAndSettle();

    // Verify that the collections and requests were added to the provider directly
    expect(provider.collections.length, equals(1));
    final directColl = provider.collections.firstWhere((c) => c.name == 'Direct Tab0 API');
    expect(directColl.requests.length, equals(1));
    expect(directColl.requests[0].name, equals('/update'));
    expect(directColl.requests[0].method, equals(HttpMethod.put));
  });

  testWidgets('AutoCollectionsGeneratorDialog - Visual Builder Quick Add and Keyboard Focus Test', (WidgetTester tester) async {
    final provider = RequestProvider();
    
    await tester.pumpWidget(
      ChangeNotifierProvider<RequestProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const Dialog(
                        child: AutoCollectionsGeneratorDialog(isDark: false),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tap Open to show dialog
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Go to Tab 2
    await tester.tap(find.text('Visual Tree Outline Builder'));
    await tester.pumpAndSettle();

    // By default there's an empty collection "Auth API"
    expect(find.text('Auth API'), findsOneWidget);

    // Tap the quick "+ GET" method button to add a GET request
    final getBtnFinder = find.descendant(
      of: find.byType(InkWell),
      matching: find.text('GET'),
    );
    expect(getBtnFinder, findsAtLeastNWidgets(1));
    await tester.tap(getBtnFinder.first);
    await tester.pumpAndSettle();

    // A request row with empty name and method GET should be added.
    final pathFieldFinder = find.widgetWithText(TextFormField, 'e.g. /users/profile or Get User Profile');
    expect(pathFieldFinder, findsOneWidget);

    // Type a path
    await tester.enterText(pathFieldFinder, '/users');
    await tester.pump();

    // Press Enter to trigger onFieldSubmitted
    await tester.showKeyboard(pathFieldFinder);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // This should have generated another GET request row!
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields.length, equals(3));
    expect(fields[0].initialValue ?? (fields[0].controller?.text), equals('Auth API'));
    expect(fields[1].controller?.text ?? fields[1].initialValue, equals('/users'));
    expect(fields[2].controller?.text ?? fields[2].initialValue, isEmpty);
  });

  testWidgets('PayloadBulkImporterDialog - Bulk Importer UI and Flow Test', (WidgetTester tester) async {
    final provider = RequestProvider();
    final workspaceId = 'test-ws-id';

    // Add a collection and a request to target
    final collection = RequestCollection(
      id: 'coll-1',
      name: 'Coll 1',
      workspaceId: workspaceId,
      sortOrder: 0,
    );
    await tester.runAsync(() async {
      await provider.addCollection(collection);
    });

    final request = HttpRequest(
      id: 'req-1',
      name: 'Target Request',
      method: HttpMethod.get,
      url: 'https://api.example.com/target',
    );
    provider.addRequestToCollection(collection.id, request);
    provider.selectRequest(request);

    final filesData = [
      const MapEntry('payload_new.json', '{"status": "ok"}'),
      const MapEntry('payload_replace.json', '{"auth": "success"}'),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider<RequestProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: PayloadBulkImporterDialog(
                          filesData: filesData,
                          isDark: false,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tap Open to show dialog
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify files are listed
    expect(find.text('payload_new.json'), findsOneWidget);
    expect(find.text('payload_replace.json'), findsOneWidget);

    // Verify file names are auto-populated as request names in the TextFormFields
    expect(find.text('payload_new'), findsOneWidget);
    expect(find.text('payload_replace'), findsOneWidget);

    // Find the action dropdown for the second file (index 1)
    final secondActionDropdownFinder = find.byKey(const ValueKey('action_dropdown_1'));
    expect(secondActionDropdownFinder, findsOneWidget);
    
    // Trigger onChanged programmatically to avoid hang on route animations
    final dropdownWidget = tester.widget<DropdownButtonFormField<ImportAction>>(secondActionDropdownFinder);
    dropdownWidget.onChanged!(ImportAction.replaceBody);
    await tester.pumpAndSettle();

    // Now tap "Import Selected Payloads"
    final importBtnFinder = find.text('Import Selected Payloads');
    expect(importBtnFinder, findsOneWidget);
    await tester.tap(importBtnFinder);
    
    // Since showing the snackbar starts a timer/animation, let's use a short pump sequence
    // to process the tap and dialog pop, rather than waiting forever with pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the provider was updated
    expect(provider.collections[0].requests.length, equals(2));
    
    final newReq = provider.collections[0].requests.firstWhere((r) => r.id != 'req-1');
    expect(newReq.name, equals('payload_new'));
    expect(newReq.method, equals(HttpMethod.post)); // Default is POST
    expect(newReq.body, equals('{"status": "ok"}'));
    expect(newReq.bodyType, equals(BodyType.json));

    final updatedReq = provider.collections[0].requests.firstWhere((r) => r.id == 'req-1');
    expect(updatedReq.body, equals('{"auth": "success"}'));
    expect(updatedReq.bodyType, equals(BodyType.json));
  });

  testWidgets('AutoCollectionsGeneratorDialog - Draft Saving and Loading Test', (WidgetTester tester) async {
    final provider = RequestProvider();
    
    // 1. Initial State: No draft file exists. Verify dialog shows empty initial state.
    final draftFile = File('${AppConfig.collectionsDir}/../generator_draft.json');
    if (draftFile.existsSync()) {
      draftFile.deleteSync();
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<RequestProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const Dialog(
                        child: AutoCollectionsGeneratorDialog(isDark: false),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tap Open to show dialog
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify initial layout
    expect(find.text('PASTE OUTLINE TEXT'), findsOneWidget);
    
    // Type outline text to trigger draft saving
    await tester.enterText(find.byType(TextField).first, '+ Users API\n  - GET /profile');
    await tester.pumpAndSettle();

    // Verify draft file got saved and exists (using synchronous check)
    expect(draftFile.existsSync(), isTrue);
    final draftContent = draftFile.readAsStringSync();
    expect(draftContent.contains('+ Users API'), isTrue);

    // Close the dialog using Cancel button
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    // 2. Load draft State: Reopen. Verify state is restored.
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify draft restored outline text
    final newTextField = tester.widget<TextField>(find.byType(TextField).first);
    expect(newTextField.controller?.text, equals('+ Users API\n  - GET /profile'));

    // Populate visual builder
    final populateBtnFinder = find.widgetWithText(ElevatedButton, 'Populate Visual Builder');
    expect(populateBtnFinder, findsOneWidget);
    await tester.tap(populateBtnFinder);
    await tester.pumpAndSettle();

    // Check we transitioned to visual builder tab
    expect(find.text('Visual Tree Outline Builder'), findsOneWidget);

    // Check visual builder contains "Users API" and "/profile"
    expect(find.text('Users API'), findsOneWidget);
    expect(find.text('/profile'), findsOneWidget);

    // Change collection name to trigger draft save
    final formFields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(formFields.length, equals(2));
    await tester.enterText(find.byType(TextFormField).first, 'Users API Modified');
    await tester.pumpAndSettle();

    // Verify draft content updated (using synchronous check)
    final draftContent2 = draftFile.readAsStringSync();
    expect(draftContent2.contains('Users API Modified'), isTrue);

    // Tap "Generate Collections & Requests" to clear the draft
    final generateBtn = find.text('Generate Collections & Requests');
    await tester.runAsync(() async {
      await tester.tap(generateBtn);
      // Allow real asynchronous I/O tasks to finish
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    // Verify draft file was deleted (using synchronous check)
    expect(draftFile.existsSync(), isFalse);
  });
}
