import 'dart:async';

import 'package:fnx_rest/src/rest_client.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

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

void main() {
  RestClient r =
      new RestClient(null, null, "a.c/", headers: {'a': 'a', 'b': 'b'});
  group("RestClient URL", () {
    test("can be null", () {
      expect(new RestClient(null, null, null).url, equals(''));
    });
    test("can be empty string", () {
      expect(new RestClient(null, null, '').url, equals(''));
    });
    test("inherit parent's base", () {
      expect(r.child("/users").url, equals("a.c/users"));
    });
  });

  group("RestClient's headers", () {
    test("can be null", () {
      expect(
          new RestClient(null, null, null, headers: null).headers, equals({}));
    });
    test("can be empty", () {
      expect(new RestClient(null, null, null, headers: {}).headers, equals({}));
    });
    test("are preserved", () {
      expect(
          new RestClient(null, null, null, headers: {'b': 'b', 'c': 'c'})
              .headers,
          equals({'b': 'b', 'c': 'c'}));
    });
    test("are merged with parent's", () {
      expect(r.child("/a", headers: {'c': 'c'}).headers,
          equals({'a': 'a', 'b': 'b', 'c': 'c'}));
    });
    test("overwrite same headers from parent", () {
      expect(r.child("/a", headers: {'b': 'bb'}).headers,
          equals({'a': 'a', 'b': 'bb'}));
    });
  });

  group("Parameters", () {
    test("are rememebered", () {
      RestClient rc = new RestClient(null, null, null);
      rc.setParam('a', 'b');
      rc.setParams('c', ['1', '2']);

      expect(rc.getParam('a'), equals('b'));
      expect(rc.getParams('c'), equals(['1', '2']));
    });

    test("are type checked (sort-of)", () {
      RestClient rc = new RestClient(null, null, null);
      rc.setParams('a', ['1', '2']);

      expect(
          () => rc.getParam('a'), throwsA(contains("Invalid parameter type")));
    });

    test(
        "if single param accessed by getParams, it is converted to list automatically",
        () {
      RestClient rc = new RestClient(null, null, null);
      rc.setParam('a', 'b');
      expect(rc.getParams('a'), equals(['b']));
    });

    test("cannot be modified directly", () {
      RestClient rc = new RestClient(null, null, null);
      rc.setParams('a', ['b', 'c']);
      var params = rc.getParams('a');
      params.add('d');
      expect(rc.getParams('a'), equals(['b', 'c']));
    });

    test("are hierarchical", () {
      RestClient rc = new RestClient(null, null, null);
      rc.setParam('a', 'b');
      RestClient ch = rc.child("/a");
      ch.setParam('c', 'd');
      expect(ch.getParam('a'), equals('b'));
      expect(ch.getParam('c'), equals('d'));
    });

    test("child params do not overwrite parent params", () {
      RestClient rc = new RestClient(null, null, null);
      rc.setParam('a', 'b');
      RestClient ch = rc.child("/a");
      ch.setParam('a', '1');
      expect(rc.getParam('a'), equals('b'));
      expect(ch.getParam('a'), equals('1'));
    });

    test("are seeded from the url", () {
      RestClient rc = new RestClient(null, null, "/something?is=wrong&1=2");
      expect(rc.getParam('is'), equals('wrong'));
      expect(rc.getParam('1'), equals('2'));
      expect(rc.url, equals('/something'));
    });

    test("for child urls are also seeded", () {
      RestClient rc = new RestClient(null, null, "/something?is=wrong&1=2");
      RestClient child = rc.child("/somewhere?is=good&becomes=better");
      expect(child.getParam('is'), equals('good'));
      expect(child.getParam('becomes'), equals('better'));
      expect(child.getParam('1'), equals('2'));
      expect(child.url, equals('/something/somewhere'));
    });

    test("are rendered in the request URL", () {
      RestHttpClient client = successReturningHttpClient();
      RestClient rc = new RestClient(client, null, "/something?is=wrong&1=2");
      rc.setParam("3", "4");

      rc.get();
      verify(client.get("/something?is=wrong&1=2&3=4",
          headers: anyNamed("headers")));
    });
  });

  group("When parsing responses", () {
    Future<RestResult> processResponse(Deserializer d, Future<Response> resp) {
      return RestClient.processResponse(
          new Accepts("some/thing", d, false), resp);
    }

    Deserializer d = (dynamic v) => v is String ? int.parse(v) : -1;
    group("and deserializer is called", () {
      test("when the result is successful", () {
        Future<dynamic> r =
            processResponse(d, buildMockResponse(null, status: 200, body: "1"))
                .then((RestResult r) => r.data);
        expect(r, completion(equals(1)));
      });
      test("when the result is failure", () {
        Future<dynamic> r =
            processResponse(d, buildMockResponse(null, status: 401, body: "1"))
                .then((RestResult r) => r.data);
        expect(r, completion(equals(1)));
      });
    });
    test("and the status is > 500, it throws HttpException", () {
      Future<RestResult> r =
          processResponse(d, buildMockResponse(null, status: 500, body: "1"));
      expect(r, throwsA(equals(new TypeMatcher<HttpException>())));
    });
  });

  group("get method", () {
    test("delegates to underlying httpClient correctly", () {
      MockHttpClient httpClient = successReturningHttpClient();
      RestClient r =
          new RestClient(httpClient, null, "a.c/", headers: {'a': 'a'});
      r.get(headers: {'b': 'b'});
      verify(httpClient.get('a.c/',
          headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json'}));
    });
  });

  group("post method", () {
    test("delegates to underlying httpClient correctly", () {
      MockHttpClient httpClient = successReturningHttpClient();
      RestClient r =
          new RestClient(httpClient, null, "a.c/", headers: {'a': 'a'});
      r.post({'zz': 'top'}, headers: {'b': 'b'});
      String reqJSON = '{"zz":"top"}';
      verify(httpClient.post('a.c/', reqJSON, headers: {
        'a': 'a',
        'b': 'b',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }));
    });
  });

  group("put method", () {
    test("delegates to underlying httpClient correctly", () {
      MockHttpClient httpClient = successReturningHttpClient();
      RestClient r =
          new RestClient(httpClient, null, "a.c/", headers: {'a': 'a'});
      r.put({'zz': 'top'}, headers: {'b': 'b'});
      String reqJSON = '{"zz":"top"}';
      verify(httpClient.put('a.c/', reqJSON, headers: {
        'a': 'a',
        'b': 'b',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }));
    });
  });

  group("delete method", () {
    test("delegates to underlying httpClient correctly", () {
      MockHttpClient httpClient = successReturningHttpClient();
      RestClient r =
          new RestClient(httpClient, null, "a.c/", headers: {'a': 'a'});
      r.delete(headers: {'b': 'b'});
      verify(httpClient.delete('a.c/', data: null, headers: {
        'a': 'a',
        'b': 'b',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }));
    });
  });

  group("head method", () {
    test("delegates to underlying httpClient correctly", () {
      MockHttpClient httpClient = successReturningHttpClient();
      RestClient r =
          new RestClient(httpClient, null, "a.c/", headers: {'a': 'a'});
      r.head(headers: {'b': 'b'});
      verify(httpClient.head('a.c/',
          headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json'}));
    });
  });

  group("RestClient supports binary content-types", () {
    test("GET can passthrough binary response", () {
      MockHttpClient httpClient = successReturningHttpClient(
          respFactory: (Invocation i) =>
              buildMockResponse(i, status: 200, binaryBody: binaryData));
      RestClient rc = new RestClient(httpClient, null, "/");
      rc.acceptsBinary("image/png");
      Future<RestResult> futRr = rc.get();
      Future<dynamic> rr = futRr.then((RestResult rr) => rr.data);
      verify(httpClient.get("/", headers: anyNamed("headers")));
      expect(rr, completion(equals(binaryData)));
    });
    group("POST", () {
      test("can make binary requests", () {
        MockHttpClient httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");
        Future<dynamic> rr =
            rc.post(binaryData).then((RestResult rr) => rr.data);
        verify(httpClient.post("/", binaryData, headers: anyNamed("headers")));
      });

      test("can receive binary responses", () {
        MockHttpClient httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");

        Future<dynamic> rr =
            rc.post(binaryData).then((RestResult rr) => rr.data);
        expect(rr, completion(equals(binaryData)));
      });
    });

    group("PUT", () {
      test("can make binary requests", () {
        MockHttpClient httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");
        Future<RestResult> r = rc.put(binaryData);
        verify(httpClient.put("/", binaryData, headers: anyNamed("headers")));
      });

      test("can receive binary responses", () {
        MockHttpClient httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");

        Future<dynamic> rr =
            rc.put(binaryData).then((RestResult rr) => rr.data);
        expect(rr, completion(equals(binaryData)));
      });
    });

    group("DELETE", () {
      test("can receive binary responses", () {
        MockHttpClient httpClient = successReturningHttpClient(
            respFactory: (Invocation i) =>
                buildMockResponse(i, status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");

        Future<dynamic> rr = rc.delete().then((RestResult rr) => rr.data);
        expect(rr, completion(equals(binaryData)));
      });
    });
  });

  group("Working attribute", () {
    test("is set when working", () async {
      Response r = new Response("", 200);
      Completer<Response> completer = new Completer<Response>();
      Future<Response> fut = completer.future;

      MockHttpClient httpClient =
          successReturningHttpClient(respFactory: (Invocation i) => fut);
      RestClient client = new RestClient(httpClient, null, "/");
      Future<RestResult> resp = client.get();
      expect(client.working, isTrue);
      completer.complete(r);
      await resp;
      expect(client.working, isFalse);
    });

    test("is set when working", () async {
      Response r1 = new Response("", 200);
      Response r2 = new Response("", 200);
      Completer<Response> completer1 = new Completer<Response>();
      Completer<Response> completer2 = new Completer<Response>();
      Future<Response> fut1 = completer1.future;
      Future<Response> fut2 = completer2.future;

      RestHttpClient httpClient = new MockHttpClient();
      when(httpClient.get(any, headers: anyNamed("headers")))
          .thenAnswer((_) => fut1);
      when(httpClient.delete(any,
              data: anyNamed("data"), headers: anyNamed("headers")))
          .thenAnswer((_) => fut2);

      RestClient client = new RestClient(httpClient, null, "/");
      Future<RestResult> resp1 = client.get();
      Future<RestResult> resp2 = client.delete();

      expect(client.working, isTrue);
      completer1.complete(r1);
      await resp1;

      expect(client.working, isTrue);
      completer2.complete(r2);
      await resp2;

      expect(client.working, isFalse);
    });

    test("should return true if any of parent's child are working", () async {
      Response r1 = new Response("", 200);
      Response r2 = new Response("", 200);
      Completer<Response> completer1 = new Completer<Response>();
      Completer<Response> completer2 = new Completer<Response>();
      Future<Response> fut1 = completer1.future;
      Future<Response> fut2 = completer2.future;

      RestHttpClient httpClient = new MockHttpClient();
      when(httpClient.get(any, headers: anyNamed("headers")))
          .thenAnswer((_) => fut1);
      when(httpClient.delete(any,
              data: anyNamed("data"), headers: anyNamed("headers")))
          .thenAnswer((_) => fut2);

      RestClient client = new RestClient(httpClient, null, "/");
      RestClient ch1 = client.child("/something");
      RestClient ch2 = ch1.child("/somewhere");

      Future<RestResult> resp1 = ch1.get();
      Future<RestResult> resp2 = ch2.delete();

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

    test("behaves correctly even when http call fails", () async {
      Completer<Response> completer = new Completer<Response>();
      Future<Response> fut = completer.future;

      RestHttpClient httpClient = new MockHttpClient();
      when(httpClient.get(any, headers: anyNamed("headers")))
          .thenAnswer((_) => fut);

      RestClient client = new RestClient(httpClient, null, "/");

      Future<RestResult> response = client.get();
      expect(client.working, isTrue);

      completer.completeError("Call failed");
      try {
        await response;
        fail("response should fail");
      } catch (exception) {
        expect(exception, isNotNull);
      }
      expect(client.working, isFalse);
    });
  });
}

Future<Response> buildMockResponse(Invocation i,
    {int status, String body, List<int> binaryBody}) {
  if (status == null) status = 200;
  Response r;
  if (binaryBody != null) {
    r = new Response.bytes(binaryBody, status);
  } else {
    if (body == null) body = "";
    r = new Response(body, status);
  }
  return new Future.value(r);
}

class MockHttpClient extends Mock implements RestHttpClient {}

MockHttpClient successReturningHttpClient({ResponseFactory respFactory}) {
  MockHttpClient httpClient = new MockHttpClient();
  if (respFactory == null) respFactory = buildMockResponse;
  when(httpClient.get(any, headers: anyNamed("headers")))
      .thenAnswer(respFactory);
  when(httpClient.delete(any,
          data: anyNamed("data"), headers: anyNamed("headers")))
      .thenAnswer(respFactory);
  when(httpClient.post(any, any, headers: anyNamed("headers")))
      .thenAnswer(respFactory);
  when(httpClient.put(any, any, headers: anyNamed("headers")))
      .thenAnswer(respFactory);
  when(httpClient.head(any, headers: anyNamed("headers")))
      .thenAnswer(respFactory);
  return httpClient;
}

typedef Future<Response> ResponseFactory(Invocation i);
