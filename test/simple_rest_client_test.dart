import 'dart:async';
import 'package:http/src/response.dart';
import 'package:test/test.dart';
import 'package:fnx_rest/fnx_rest.dart';
import 'package:mockito/mockito.dart';

class MockEngine extends Mock implements Engine {}

void main() {
  RestClient r = new RestClient(null, "a.c/", headers: {'a': 'a', 'b': 'b'});
  group("RestClient URL", () {
    test("can be null", () {
      expect(new RestClient(null, null).url, equals(''));
    });
    test("can be empty string", () {
      expect(new RestClient(null, '').url, equals(''));
    });
    test("inherit parent's base", () {
      expect(r.child("/users").url, equals("a.c/users"));
    });
  });

  group("RestClient's headers", () {
    test("can be null", () {
      expect(new RestClient(null, null, headers: null).headers, equals({}));
    });
    test("can be empty", () {
      expect(new RestClient(null, null, headers: {}).headers, equals({}));
    });
    test("are preserved", () {
      expect(new RestClient(null, null, headers: {'b': 'b', 'c': 'c'}).headers, equals({'b': 'b', 'c': 'c'}));
    });
    test("are merged with parent's", () {
      expect(r.child("/a", headers: {'c': 'c'}).headers, equals({'a': 'a', 'b': 'b', 'c': 'c'}));
    });
    test("overwrite same headers from parent", () {
      expect(r.child("/a", headers: {'b': 'bb'}).headers, equals({'a': 'a', 'b': 'bb'}));
    });
  });

  group("When parsing responses", () {
    Future<RestResult> processResponse(Deserializer d, Future<Response> resp) {
      return RestClient.processResponse(d, resp);
    }
    Deserializer d = (dynamic v) => v is String ? int.parse(v) : -1;
    group("and deserializer is called", () {
      test("then the result is successful", () {
        Future<dynamic> r = processResponse(d, newResponse(200, "1")).then((RestResult r) => r.data);
        expect(r, completion(equals(1)));
      });
      test("then the result is failure", () {
        Future<dynamic> r = processResponse(d, newResponse(401, "1")).then((RestResult r) => r.data);
        expect(r, completion(equals(1)));
      });
    });
    test("and the status is > 500, it throws HttpException", () {
      Future<RestResult> r = processResponse(d, newResponse(500, "1"));
      expect(r, throwsA(equals(new isInstanceOf<HttpException>())));
    });
  });

  group("get method", () {
    test("delegates to underlying engine correctly", () {
      MockEngine engine = successReturningEngine(new MockEngine());
      RestClient r = new RestClient.withEngine(engine, null, "a.c/", headers: {'a': 'a'});
      r.get(headers: {'b': 'b'});
      verify(engine.get('a.c/', headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json'}));
    });
  });

  group("post method", () {
    test("delegates to underlying engine correctly", () {
      MockEngine engine = successReturningEngine(new MockEngine());
      RestClient r = new RestClient.withEngine(engine, null, "a.c/", headers: {'a': 'a'});
      r.post({'zz': 'top'}, headers: {'b': 'b'});
      String reqJSON = '{"zz":"top"}';
      verify(engine.post('a.c/', reqJSON, headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json', 'Content-Type': 'application/json'}));
    });
  });

  group("put method", () {
    test("delegates to underlying engine correctly", () {
      MockEngine engine = successReturningEngine(new MockEngine());
      RestClient r = new RestClient.withEngine(engine, null, "a.c/", headers: {'a': 'a'});
      r.put({'zz': 'top'}, headers: {'b': 'b'});
      String reqJSON = '{"zz":"top"}';
      verify(engine.put('a.c/', reqJSON, headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json', 'Content-Type': 'application/json'}));
    });
  });

  group("delete method", () {
    test("delegates to underlying engine correctly", () {
      MockEngine engine = successReturningEngine(new MockEngine());
      RestClient r = new RestClient.withEngine(engine, null, "a.c/", headers: {'a': 'a'});
      r.delete(headers: {'b': 'b'});
      verify(engine.delete('a.c/', headers: {'a': 'a', 'b': 'b', 'Accept': 'application/json'}));
    });
  });
}

dynamic newResponse([int status, String body]) {
  if (status == null) status = 200;
  if (body == null) body = "";
  Response r = new Response(body, status);
  return new Future.sync(() => r);
}

MockEngine successReturningEngine(Engine engine) {
  when(engine.get(any, headers: any)).thenReturn(newResponse());
  when(engine.delete(any, headers: any)).thenReturn(newResponse());
  when(engine.post(any, any, headers: any)).thenReturn(newResponse());
  when(engine.put(any, any, headers: any)).thenReturn(newResponse());
  when(engine.put(any, any, headers: any)).thenReturn(newResponse());
  return engine;
}
