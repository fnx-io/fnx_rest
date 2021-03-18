import 'dart:async';

import 'package:fnx_rest/src/rest_client.dart';
import 'package:http/http.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'simple_rest_client_test.mocks.dart';

List<int> binaryData = [
  0x48,
  0x65,
  0x6C,
  0x6C,
  0x6F,
  0x20,
  0x77,
  0x6F,
  0x72,
  0x6C,
  0x64,
  0x21
];

@GenerateMocks([RestHttpClient])
void main() {
  var r = RestClient(MockRestHttpClient(), null, 'a.c/',
      headers: {'a': 'a', 'b': 'b'});
  group('RestClient URL', () {
    test('can be empty string', () {
      expect(RestClient(MockRestHttpClient(), null, '').url, equals(''));
    });
    test("inherit parent's base", () {
      expect(r.child('/users').url, equals('a.c/users'));
    });
  });

  group("RestClient's headers", () {
    test('can be null', () {
      expect(RestClient(MockRestHttpClient(), null, '').headers, equals({}));
    });
    test('can be empty', () {
      expect(RestClient(MockRestHttpClient(), null, '', headers: {}).headers,
          equals({}));
    });
    test('are preserved', () {
      expect(
          RestClient(MockRestHttpClient(), null, '',
              headers: {'b': 'b', 'c': 'c'}).headers,
          equals({'b': 'b', 'c': 'c'}));
    });
    test("are merged with parent's", () {
      expect(r.child('/a', headers: {'c': 'c'}).headers,
          equals({'a': 'a', 'b': 'b', 'c': 'c'}));
    });
    test('overwrite same headers from parent', () {
      expect(r.child('/a', headers: {'b': 'bb'}).headers,
          equals({'a': 'a', 'b': 'bb'}));
    });
  });

  group('Parameters', () {
    test('are rememebered', () {
      var rc = RestClient(MockRestHttpClient(), null, '');
      rc.setParam('a', 'b');
      rc.setParams('c', ['1', '2']);

      expect(rc.getParam('a'), equals('b'));
      expect(rc.getParams('c'), equals(['1', '2']));
    });

    test('are type checked (sort-of)', () {
      var rc = RestClient(MockRestHttpClient(), null, '');
      rc.setParams('a', ['1', '2']);

      expect(
          () => rc.getParam('a'), throwsA(contains('Invalid parameter type')));
    });

    test(
        'if single param accessed by getParams, it is converted to list automatically',
        () {
      var rc = RestClient(MockRestHttpClient(), null, '');
      rc.setParam('a', 'b');
      expect(rc.getParams('a'), equals(['b']));
    });

    test('cannot be modified directly', () {
      var rc = RestClient(MockRestHttpClient(), null, '');
      rc.setParams('a', ['b', 'c']);
      var params = rc.getParams('a')!;
      params.add('d');
      expect(rc.getParams('a'), equals(['b', 'c']));
    });

    test('are hierarchical', () {
      var rc = RestClient(MockRestHttpClient(), null, '');
      rc.setParam('a', 'b');
      var ch = rc.child('/a');
      ch.setParam('c', 'd');
      expect(ch.getParam('a'), equals('b'));
      expect(ch.getParam('c'), equals('d'));
    });

    test('child params do not overwrite parent params', () {
      var rc = RestClient(MockRestHttpClient(), null, '');
      rc.setParam('a', 'b');
      var ch = rc.child('/a');
      ch.setParam('a', '1');
      expect(rc.getParam('a'), equals('b'));
      expect(ch.getParam('a'), equals('1'));
    });

    test('are seeded from the url', () {
      var rc =
          RestClient(MockRestHttpClient(), null, '/something?is=wrong&1=2');
      expect(rc.getParam('is'), equals('wrong'));
      expect(rc.getParam('1'), equals('2'));
      expect(rc.url, equals('/something'));
    });

    test('for child urls are also seeded', () {
      var rc =
          RestClient(MockRestHttpClient(), null, '/something?is=wrong&1=2');
      var child = rc.child('/somewhere?is=good&becomes=better');
      expect(child.getParam('is'), equals('good'));
      expect(child.getParam('becomes'), equals('better'));
      expect(child.getParam('1'), equals('2'));
      expect(child.url, equals('/something/somewhere'));
    });

    test('are rendered in the request URL', () {
      RestHttpClient client = successReturningHttpClient();
      var rc = RestClient(client, null, '/something?is=wrong&1=2');
      rc.setParam('3', '4');
      rc.get();

      verify(client.get('/something?is=wrong&1=2&3=4',
          headers: anyNamed('headers')));
    });

    test('are rendered in urlWithParams', () {
      var rc = RestClient(successReturningHttpClient(), null, '/something')
          .setParam('param', '4');

      expect(rc.urlWithParams, contains('param'));
    });
  });

  group('When parsing responses', () {
    Future<RestResult> processResponse(Deserializer d, Future<Response> resp) {
      return RestClient.processResponse(Accepts('some/thing', d), resp);
    }

    Deserializer d = (Response r) => r.body is String ? int.parse(r.body) : -1;
    group('and deserializer is called', () {
      test('when the result is successful', () {
        var r =
            processResponse(d, buildMockResponse(null, status: 200, body: '1'))
                .then((RestResult r) => r.data);
        expect(r, completion(equals(1)));
      });
      test('when the result is failure', () {
        var r =
            processResponse(d, buildMockResponse(null, status: 401, body: '1'))
                .then((RestResult r) => r.data);
        expect(r, completion(equals(1)));
      });
      test('when the result is failure', () {
        var r =
            processResponse(d, buildMockResponse(null, status: 500, body: '1'))
                .then((RestResult r) => r.data);
        expect(r, completion(equals(1)));
      });
    });
  });

  group('get method', () {
    test('delegates to underlying httpClient correctly', () {
      var httpClient = successReturningHttpClient();
      var r = RestClient(httpClient, null, 'a.c/', headers: {'a': 'a'});
      r.get(headers: {'b': 'b'});
      verify(httpClient.get('a.c/', headers: {
        'a': 'a',
        'b': 'b',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }));
    });
    test('passes body data correctly', () {
      var httpClient = successReturningHttpClient();
      var r = RestClient(httpClient, null, 'a.c/');
      r.get(data: {'punk': 'floid'});
      var dataJSON = '{"punk":"floid"}';
      verify(
          httpClient.get('a.c/', data: dataJSON, headers: anyNamed('headers')));
    });
  });

  group('post method', () {
    test('delegates to underlying httpClient correctly', () {
      var httpClient = successReturningHttpClient();
      var r = RestClient(httpClient, null, 'a.c/', headers: {'a': 'a'});
      r.post({'zz': 'top'}, headers: {'b': 'b'});
      var reqJSON = '{"zz":"top"}';
      verify(httpClient.post('a.c/', reqJSON, headers: {
        'a': 'a',
        'b': 'b',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }));
    });
  });

  group('put method', () {
    test('delegates to underlying httpClient correctly', () {
      var httpClient = successReturningHttpClient();
      var r = RestClient(httpClient, null, 'a.c/', headers: {'a': 'a'});
      r.put({'zz': 'top'}, headers: {'b': 'b'});
      var reqJSON = '{"zz":"top"}';
      verify(httpClient.put('a.c/', reqJSON, headers: {
        'a': 'a',
        'b': 'b',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }));
    });
  });

  group('delete method', () {
    test('delegates to underlying httpClient correctly', () {
      var httpClient = successReturningHttpClient();
      var r = RestClient(httpClient, null, 'a.c/', headers: {'a': 'a'});
      r.delete(headers: {'b': 'b'});
      verify(httpClient.delete('a.c/', data: null, headers: {
        'a': 'a',
        'b': 'b',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }));
    });
  });

  group('head method', () {
    test('delegates to underlying httpClient correctly', () {
      var httpClient = successReturningHttpClient();
      var r = RestClient(httpClient, null, 'a.c/', headers: {'a': 'a'});
      r.head(headers: {'b': 'b'});
      verify(httpClient.head('a.c/',
          headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json'}));
    });
  });

  group('RestClient supports binary content-types', () {
    test('GET can passthrough binary response', () {
      var httpClient = successReturningHttpClient(
          respFactory: (Invocation i) =>
              buildMockResponse(i, status: 200, binaryBody: binaryData));
      var rc = RestClient(httpClient, null, '/');
      rc.acceptsBinary('image/png');
      var futRr = rc.get();
      var rr = futRr.then((RestResult rr) => rr.data);
      verify(httpClient.get('/', headers: anyNamed('headers')));
      expect(rr, completion(equals(binaryData)));
    });
    group('POST', () {
      test('can make binary requests', () {
        var httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        var rc = RestClient(httpClient, null, '/');
        rc.producesBinary('image/png');
        rc.acceptsBinary('image/png');
        rc.post(binaryData).then((RestResult rr) => rr.data);
        verify(httpClient.post('/', binaryData, headers: anyNamed('headers')));
      });

      test('can receive binary responses', () {
        var httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        var rc = RestClient(httpClient, null, '/');
        rc.producesBinary('image/png');
        rc.acceptsBinary('image/png');

        var rr = rc.post(binaryData).then((RestResult rr) => rr.data);
        expect(rr, completion(equals(binaryData)));
      });
    });

    group('PUT', () {
      test('can make binary requests', () {
        var httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        var rc = RestClient(httpClient, null, '/');
        rc.producesBinary('image/png');
        rc.acceptsBinary('image/png');
        rc.put(binaryData);
        verify(httpClient.put('/', binaryData, headers: anyNamed('headers')));
      });

      test('can receive binary responses', () {
        var httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        var rc = RestClient(httpClient, null, '/');
        rc.producesBinary('image/png');
        rc.acceptsBinary('image/png');

        var rr = rc.put(binaryData).then((RestResult rr) => rr.data);
        expect(rr, completion(equals(binaryData)));
      });
    });

    group('DELETE', () {
      test('can receive binary responses', () {
        var httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        var rc = RestClient(httpClient, null, '/');
        rc.producesBinary('image/png');
        rc.acceptsBinary('image/png');

        var rr = rc.delete().then((RestResult rr) => rr.data);
        expect(rr, completion(equals(binaryData)));
      });
    });
  });

  group('RestClient inherites properties', () {
    test('GET inherites deserializer ', () async {
      var httpClient = successReturningHttpClient(
          respFactory: (Invocation i) =>
              buildMockResponse(i, status: 200, binaryBody: binaryData));
      var rc = RestClient(httpClient, null, '/');
      final alwaysTheSamePayload = 'payload';
      rc.accepts('custom/type', (_) => alwaysTheSamePayload);

      final rcChild = rc.child('childPath');
      final resultData = (await rcChild.get()).successData;
      expect(resultData, equals(alwaysTheSamePayload));
    });
    test('POST inherites serializer', () async {
      var httpClient = successReturningHttpClient(
          respFactory: (Invocation i) =>
              buildMockResponse(i, status: 200, binaryBody: binaryData));
      var rc = RestClient(httpClient, null, '/');
      final alwaysTheSamePayload = 'payload';
      rc.produces('custom/type', (_, __) => alwaysTheSamePayload);
      rc.accepts('custom/type', (_) => alwaysTheSamePayload);

      final rcChild = rc.child('childPath');
      await rcChild.post('whatever');
      verify(httpClient.post(any, alwaysTheSamePayload,
          headers: anyNamed('headers')));
    });
  });

  group('Serializer and deserializer', () {
    test('not break on whitespace string', () async {
      final whiteSpace = '      ';
      var httpClient = successReturningHttpClient(
          respFactory: (Invocation i) =>
              buildMockResponse(i, status: 200, body: whiteSpace));
      var rc = RestClient(httpClient, null, '/');
      var rr = await rc.post(whiteSpace);
      expect(rr.success, isTrue);
    });

    test('Serializer can modify headers in GET', () {
      var httpClient = successReturningHttpClient();
      var r = RestClient(httpClient, null, 'a.c/', headers: {'a': 'a'});
      r.produces('huhle/debuz', (_, h) {
        h['X-Huhle'] = 'Debuz';
        return 'Yessir';
      });
      r.get(headers: {'b': 'b'});
      verify(httpClient.get('a.c/', data: 'Yessir', headers: {
        'a': 'a',
        'b': 'b',
        'X-Huhle': 'Debuz',
        'Accept': 'application/json',
        'Content-Type': 'huhle/debuz'
      }));
    });

    test('Serializer can modify headers in POST', () {
      var httpClient = successReturningHttpClient();
      var r = RestClient(httpClient, null, 'a.c/', headers: {'a': 'a'});
      r.produces('huhle/debuz', (_, h) {
        h['X-Huhle'] = 'Debuz';
        return 'Yessir';
      });
      r.post('Whateva', headers: {'b': 'b'});
      verify(httpClient.post('a.c/', 'Yessir', headers: {
        'a': 'a',
        'b': 'b',
        'X-Huhle': 'Debuz',
        'Accept': 'application/json',
        'Content-Type': 'huhle/debuz'
      }));
    });
  });

  group('Working attribute', () {
    test('is set when working', () async {
      var r = Response('', 200);
      var completer = Completer<Response>();
      var fut = completer.future;

      var httpClient =
          successReturningHttpClient(respFactory: (Invocation i) => fut);
      var client = RestClient(httpClient, null, '/');
      var resp = client.get();
      expect(client.working, isTrue);
      completer.complete(r);
      await resp;
      expect(client.working, isFalse);
    });

    test('is set when working', () async {
      var r1 = Response('', 200);
      var r2 = Response('', 200);
      var completer1 = Completer<Response>();
      var completer2 = Completer<Response>();
      var fut1 = completer1.future;
      var fut2 = completer2.future;

      var httpClient = MockRestHttpClient();
      when(httpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) => fut1);
      when(httpClient.delete(any,
              data: anyNamed('data'), headers: anyNamed('headers')))
          .thenAnswer((_) => fut2);

      var client = RestClient(httpClient, null, '/');
      var resp1 = client.get();
      var resp2 = client.delete();

      expect(client.working, isTrue);
      completer1.complete(r1);
      await resp1;

      expect(client.working, isTrue);
      completer2.complete(r2);
      await resp2;

      expect(client.working, isFalse);
    });

    test('should return true if any of parent\'s child are working', () async {
      var r1 = Response('', 200);
      var r2 = Response('', 200);
      var completer1 = Completer<Response>();
      var completer2 = Completer<Response>();
      var fut1 = completer1.future;
      var fut2 = completer2.future;

      var httpClient = MockRestHttpClient();
      when(httpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) => fut1);
      when(httpClient.delete(any,
              data: anyNamed('data'), headers: anyNamed('headers')))
          .thenAnswer((_) => fut2);

      var client = RestClient(httpClient, null, '/');
      var ch1 = client.child('/something');
      var ch2 = ch1.child('/somewhere');

      var resp1 = ch1.get();
      var resp2 = ch2.delete();

      expect(ch2.working, isTrue);
      expect(ch1.working, isTrue);
      expect(client.working, isTrue);

      // intermediate completes
      // everyone should be still working, since grand child is still working
      completer1.complete(r1);
      await resp1;

      expect(ch2.working, isTrue);
      expect(ch1.working, isTrue);
      expect(client.working, isTrue);

      // grandchild completes
      // everyone should be finished
      completer2.complete(r2);
      await resp2;

      expect(ch2.working, isFalse);
      expect(ch1.working, isFalse);
      expect(client.working, isFalse);
    });

    test('behaves correctly even when http call fails', () async {
      var completer = Completer<Response>();
      var fut = completer.future;

      var httpClient = MockRestHttpClient();
      when(httpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) => fut);

      var client = RestClient(httpClient, null, '/');

      var response = client.get();
      expect(client.working, isTrue);

      completer.completeError('Call failed');
      try {
        await response;
        fail('response should fail');
      } catch (exception) {
        expect(exception, isNotNull);
      }
      expect(client.working, isFalse);
    });
  });
}

Future<Response> buildMockResponse(Invocation? i,
    {int? status, String? body, List<int>? binaryBody}) {
  status ??= 200;
  Response r;
  if (binaryBody != null) {
    r = Response.bytes(binaryBody, status);
  } else {
    body ??= '';
    r = Response(body, status);
  }
  return Future.value(r);
}

//class MockRestHttpClient extends Mock implements RestHttpClient {}

MockRestHttpClient successReturningHttpClient({ResponseFactory? respFactory}) {
  var httpClient = MockRestHttpClient();
  respFactory ??= buildMockResponse;
  when(httpClient.get(any,
          data: anyNamed('data'), headers: anyNamed('headers')))
      .thenAnswer(respFactory);
  when(httpClient.delete(any,
          data: anyNamed('data'), headers: anyNamed('headers')))
      .thenAnswer(respFactory);
  when(httpClient.post(any, any, headers: anyNamed('headers')))
      .thenAnswer(respFactory);
  when(httpClient.put(any, any, headers: anyNamed('headers')))
      .thenAnswer(respFactory);
  when(httpClient.head(any, headers: anyNamed('headers')))
      .thenAnswer(respFactory);
  return httpClient;
}

// ignore: prefer_generic_function_type_aliases
typedef Future<Response> ResponseFactory(Invocation i);
