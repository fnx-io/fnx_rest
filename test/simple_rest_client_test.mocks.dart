// Mocks generated by Mockito 5.0.2 from annotations
// in fnx_rest/test/simple_rest_client_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i4;

import 'package:fnx_rest/src/rest_client.dart' as _i3;
import 'package:http/src/response.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: comment_references
// ignore_for_file: unnecessary_parenthesis

class _FakeResponse extends _i1.Fake implements _i2.Response {}

/// A class which mocks [RestHttpClient].
///
/// See the documentation for Mockito's code generation for more information.
class MockRestHttpClient extends _i1.Mock implements _i3.RestHttpClient {
  MockRestHttpClient() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.Response> get(String? url,
          {dynamic data, Map<String, String>? headers}) =>
      (super.noSuchMethod(
              Invocation.method(#get, [url], {#data: data, #headers: headers}),
              returnValue: Future.value(_FakeResponse()))
          as _i4.Future<_i2.Response>);
  @override
  _i4.Future<_i2.Response> post(String? url, dynamic data,
          {Map<String, String>? headers}) =>
      (super.noSuchMethod(
              Invocation.method(#post, [url, data], {#headers: headers}),
              returnValue: Future.value(_FakeResponse()))
          as _i4.Future<_i2.Response>);
  @override
  _i4.Future<_i2.Response> put(String? url, dynamic data,
          {Map<String, String>? headers}) =>
      (super.noSuchMethod(
              Invocation.method(#put, [url, data], {#headers: headers}),
              returnValue: Future.value(_FakeResponse()))
          as _i4.Future<_i2.Response>);
  @override
  _i4.Future<_i2.Response> delete(String? url,
          {dynamic data, Map<String, String>? headers}) =>
      (super.noSuchMethod(
          Invocation.method(#delete, [url], {#data: data, #headers: headers}),
          returnValue:
              Future.value(_FakeResponse())) as _i4.Future<_i2.Response>);
  @override
  _i4.Future<_i2.Response> head(String? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(Invocation.method(#head, [url], {#headers: headers}),
              returnValue: Future.value(_FakeResponse()))
          as _i4.Future<_i2.Response>);
  @override
  _i4.Future<_i2.Response> streamedRequest(String? method, String? url,
          int? length, _i4.Stream<dynamic>? uploadStream,
          {Map<String, String>? headers}) =>
      (super.noSuchMethod(
              Invocation.method(#streamedRequest,
                  [method, url, length, uploadStream], {#headers: headers}),
              returnValue: Future.value(_FakeResponse()))
          as _i4.Future<_i2.Response>);
}
