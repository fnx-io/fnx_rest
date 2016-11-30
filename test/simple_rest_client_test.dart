import 'dart:async';
import 'package:http/src/response.dart';
import 'package:test/test.dart';
import 'package:fnx_rest/src/rest_client.dart';
import 'package:mockito/mockito.dart';

class MockHttpClient extends Mock implements HttpClient {}

List<int> binaryData = [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64, 0x21];

void main() {
  RestClient r = new RestClient(null, null, "a.c/", headers: {'a': 'a', 'b': 'b'});
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
      expect(new RestClient(null, null, null, headers: null).headers, equals({}));
    });
    test("can be empty", () {
      expect(new RestClient(null, null, null, headers: {}).headers, equals({}));
    });
    test("are preserved", () {
      expect(new RestClient(null, null, null, headers: {'b': 'b', 'c': 'c'}).headers, equals({'b': 'b', 'c': 'c'}));
    });
    test("are merged with parent's", () {
      expect(r.child("/a", headers: {'c': 'c'}).headers, equals({'a': 'a', 'b': 'b', 'c': 'c'}));
    });
    test("overwrite same headers from parent", () {
      expect(r.child("/a", headers: {'b': 'bb'}).headers, equals({'a': 'a', 'b': 'bb'}));
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

      expect(() => rc.getParam('a'), throwsA(contains("Invalid parameter type")));
    });

    test("if single param accessed by getParams, it is converted to list automatically", () {
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
  });

  group("When parsing responses", () {
    Future<RestResult> processResponse(Deserializer d, Future<Response> resp) {
      return RestClient.processResponse(new Accepts("some/thing", d, false), resp);
    }
    Deserializer d = (dynamic v) => v is String ? int.parse(v) : -1;
    group("and deserializer is called", () {
      test("when the result is successful", () {
        Future<dynamic> r = processResponse(d, newResponse(status: 200, body: "1")).then((RestResult r) => r.data);
        expect(r, completion(equals(1)));
      });
      test("when the result is failure", () {
        Future<dynamic> r = processResponse(d, newResponse(status: 401, body: "1")).then((RestResult r) => r.data);
        expect(r, completion(equals(1)));
      });
    });
    test("and the status is > 500, it throws HttpException", () {
      Future<RestResult> r = processResponse(d, newResponse(status: 500, body: "1"));
      expect(r, throwsA(equals(new isInstanceOf<HttpException>())));
    });
  });

  group("get method", () {
    test("delegates to underlying httpClient correctly", () {
      MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient());
      RestClient r = new RestClient(httpClient, null, "a.c/", headers: {'a': 'a'});
      r.get(headers: {'b': 'b'});
      verify(httpClient.get('a.c/', headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json'}));
    });
  });

  group("post method", () {
    test("delegates to underlying httpClient correctly", () {
      MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient());
      RestClient r = new RestClient(httpClient, null, "a.c/", headers: {'a': 'a'});
      r.post({'zz': 'top'}, headers: {'b': 'b'});
      String reqJSON = '{"zz":"top"}';
      verify(httpClient.post('a.c/', reqJSON, headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json', 'Content-Type': 'application/json'}));
    });
  });

  group("put method", () {
    test("delegates to underlying httpClient correctly", () {
      MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient());
      RestClient r = new RestClient(httpClient, null, "a.c/", headers: {'a': 'a'});
      r.put({'zz': 'top'}, headers: {'b': 'b'});
      String reqJSON = '{"zz":"top"}';
      verify(httpClient.put('a.c/', reqJSON, headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json', 'Content-Type': 'application/json'}));
    });
  });

  group("delete method", () {
    test("delegates to underlying httpClient correctly", () {
      MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient());
      RestClient r = new RestClient(httpClient, null, "a.c/", headers: {'a': 'a'});
      r.delete(headers: {'b': 'b'});
      verify(httpClient.delete('a.c/', headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json'}));
    });
  });

  group("RestClient supports binary content-types", () {
    test("GET can passthrough binary response", () {
      MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient(), respFactory: () => newResponse(status: 200, binaryBody: binaryData));
      RestClient rc = new RestClient(httpClient, null, "/");
      rc.acceptsBinary("image/png");
      Future<RestResult> futRr = rc.get();
      Future<dynamic> rr = futRr.then((RestResult rr) => rr.data);
      verify(httpClient.get("/", headers: any));
      expect(rr, completion(equals(binaryData)));
    });
    group("POST", () {
      test("can make binary requests", () {
        MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient(), respFactory: () => newResponse(status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");
        Future<RestResult> post = rc.post(binaryData);
        verify(httpClient.post("/", binaryData, headers: any));
      });

      test("can receive binary responses", () {
        MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient(), respFactory: () => newResponse(status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");

        Future<dynamic> rr = rc.post(binaryData).then((RestResult rr) => rr.data);
        expect(rr, completion(equals(binaryData)));
      });
    });

    group("PUT", () {
      test("can make binary requests", () {
        MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient(), respFactory: () => newResponse(status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");
        Future<RestResult> r = rc.put(binaryData);
        verify(httpClient.put("/", binaryData, headers: any));
      });

      test("can receive binary responses", () {
        MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient(), respFactory: () => newResponse(status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");

        Future<dynamic> rr = rc.put(binaryData).then((RestResult rr) => rr.data);
        expect(rr, completion(equals(binaryData)));
      });
    });

    group("DELETE", () {
      test("can receive binary responses", () {
        MockHttpClient httpClient = successReturningHttpClient(new MockHttpClient(), respFactory: () => newResponse(status: 200, binaryBody: binaryData));
        RestClient rc = new RestClient(httpClient, null, "/");
        rc.producesBinary("image/png");
        rc.acceptsBinary("image/png");

        Future<dynamic> rr = rc.delete().then((RestResult rr) => rr.data);
        expect(rr, completion(equals(binaryData)));
      });
    });
  });
}

Future<Response> newResponse({int status, String body, List<int> binaryBody}) {
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

MockHttpClient successReturningHttpClient(HttpClient httpClient, {ResponseFactory respFactory}) {
  if (respFactory == null) respFactory = newResponse;
  when(httpClient.get(any, headers: any)).thenReturn(respFactory());
  when(httpClient.delete(any, headers: any)).thenReturn(respFactory());
  when(httpClient.post(any, any, headers: any)).thenReturn(respFactory());
  when(httpClient.put(any, any, headers: any)).thenReturn(respFactory());
  when(httpClient.put(any, any, headers: any)).thenReturn(respFactory());
  return httpClient;
}

typedef Future<Response> ResponseFactory();
