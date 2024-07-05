import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../utils.dart';

/// Check when no consent is required and manual session handling is enabled, the behavior of the SDK
/// details of the requests are mentioned below
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('207_CNR_M_id_change', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableManualSessionHandling();
    await Countly.initWithConfig(config);

    // These calls should not work
    await Countly.instance.sessions.endSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.updateSession();

    await Future.delayed(Duration(seconds: 2));

    await Countly.changeDeviceId('newID', true); // should not reporty session duration

    await Countly.instance.sessions.beginSession(); // should work
    await Future.delayed(Duration(seconds: 2));
    await Countly.instance.sessions.endSession(); // should work

    await Countly.changeDeviceId('newID_2', false);

    await Countly.instance.sessions.endSession(); // should not work
    await Countly.instance.sessions.beginSession();
    await Future.delayed(Duration(seconds: 2));
    await Countly.changeDeviceId('newID_3', false);

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // There should be:
    // - device ID change
    // - begin session
    // - end session
    // - begin session
    // - end session
    expect(requestList.length, Platform.isAndroid ? 5 : 4);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (i == 0) {
        expect(queryParams['device_id']?[0], 'newID');
        expect(queryParams['old_device_id']?[0].isNotEmpty, true);
      } else if (i == 1 || i == 3) {
        expect(queryParams['begin_session']?[0], '1');
        expect(queryParams['device_id']?[0], i == 1 ? 'newID' : 'newID_2');
      } else if (i == 2 || (Platform.isAndroid && i == 4)) {
        expect(queryParams['end_session']?[0], '1');
        expect(queryParams['session_duration']?[0], '2');
        expect(queryParams['device_id']?[0], i == 2 ? 'newID' : 'newID_2');
      }

      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}