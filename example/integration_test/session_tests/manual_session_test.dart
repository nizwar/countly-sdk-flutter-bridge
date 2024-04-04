import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Check if manual end_session calls are:
/// -  not send if there is no session ongoing
/// Check if manual update_session calls are:
/// -  not send if there is no session ongoing
/// Check if begin_session calls are:
/// -  not send if there is a session ongoing
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Manual session tests', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableManualSessionHandling();
    await Countly.initWithConfig(config);

    // End session calls should not work
    await Countly.instance.sessions.endSession();
    await Countly.instance.sessions.endSession();

    // Update session calls should not work
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.updateSession();

    // Begin session call should work
    await Countly.instance.sessions.beginSession();
    // Second begin session call should not work
    await Countly.instance.sessions.beginSession();

    // Update calls now should work
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.updateSession();

    // End session call should work
    await Countly.instance.sessions.endSession();
    // Second end session call should not work
    await Countly.instance.sessions.endSession();

    // Update session calls should not work
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.updateSession();

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    List<String> eventList = await getEventQueue(); // List of json objects

    // Some logs for debugging
    print('RQ: $requestList');
    print('EQ: $eventList');
    print('RQ length: ${requestList.length}');
    print('EQ length: ${eventList.length}');

    // There should be:
    // - begin_session
    // - update_session
    // - update_session
    // - end_session
    expect(requestList.length, 4);

    var i = 0;
    for (var element in requestList) {
      Map<String, List<String>> queryParams = Uri.parse("?" + element).queryParametersAll;
      testCommonRequestParams(queryParams); // tests
      if (i == 0) {
        expect(queryParams['begin_session']?[0], '1');
      } else if (i == 1 || i == 2) {
        expect(queryParams['session_duration']?[0], '0');
        expect(queryParams['end_session'], null);
      } else if (i == 3) {
        expect(queryParams['end_session']?[0], '1');
      }
      print('RQ.$i: $queryParams');
      print('========================');
      i++;
    }
  });
}
