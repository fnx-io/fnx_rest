import 'package:fnx_rest/src/rest_client.dart';
import 'package:fnx_rest/src/rest_listing.dart';
import 'package:test/test.dart';

import 'simple_rest_client_test.mocks.dart';

void main() {
  group('SimpleListDriver', () {
    group('when unpacking data, should', () {
      var simpleRestListingDriver = SimpleListDriver();
      test('set hasNext to true when data were accepted', () {
        var data = simpleRestListingDriver.unpackData([1, 2, 3]);
        expect(data.hasNext, isTrue);
      });
      test('set hasNext to false when data is empty', () {
        var data = simpleRestListingDriver.unpackData([]);
        expect(data.hasNext, isFalse);
      });
      test('return the whole response', () {
        var data = simpleRestListingDriver.unpackData([1, 2, 3]);
        expect(data.data, equals([1, 2, 3]));
      });
    });
    group('when preparing client', () {
      test('include the page query parameter with given page', () {
        var dummyClient = RestClient(MockRestHttpClient(), null, '/');
        var driver = SimpleListDriver();
        var c = driver.prepareClient(dummyClient, 10);
        expect(c.params['page'], equals('10'));
      });
    });
  });

  group('ListResultDriver', () {
    group('when unpacking data, should', () {
      group('fail if', () {
        test('response is not a map', () {
          var driver = ListResultDriver();
          expect(
              () => driver.unpackData([1, 2, 3]),
              throwsA(
                  (String msg) => msg.contains('Expected result to be a map')));
        });
        test("response has no property 'data'", () {
          var driver = ListResultDriver();
          expect(
              () => driver.unpackData({'data': 'string'}),
              throwsA((String msg) =>
                  msg.contains("Expected 'data' key to be a List")));
        });
      });
    });
  });
}
