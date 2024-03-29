// Copyright (c) 2016, Tomucha. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

///
/// Developer and Angular 2 friendly REST client.
/// Do this:
///
///       RestClient root = HttpRestClient.root("http://myapi.example/api/v1");
///
/// ... and start using it. See [RestClient] for more information.
///
library fnx_rest;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:http/src/response.dart';
import 'package:pedantic/pedantic.dart';

import 'src/rest_client.dart';

export 'src/rest_client.dart';
export 'src/rest_listing.dart';

class IoRestClient extends RestClient {
  IoRestClient.root(String url, [HttpClient? inner]) : this(null, url, inner);
  IoRestClient(RestClient? parent, String url, [HttpClient? inner])
      : super(IOHttpClient(inner), parent, url);
}

class IOHttpClient extends RestHttpClient {
  final IOClient _client;

  IOHttpClient([HttpClient? inner]) : _client = IOClient(inner);

  @override
  Future<Response> get(String url,
      {dynamic data, Map<String, String>? headers}) async {
    var request = _createRequest('GET', url, data, headers);
    return Response.fromStream(await _client.send(request));
  }

  @override
  Future<Response> delete(String url,
      {dynamic data, Map<String, String>? headers}) async {
    var request = _createRequest('DELETE', url, data, headers);
    return Response.fromStream(await _client.send(request));
  }

  @override
  Future<Response> streamedRequest(
      String method, String url, int length, Stream uploadStream,
      {Map<String, String>? headers}) async {
    StreamSubscription? subscription;
    try {
      var request = StreamedRequest(method, Uri.parse(url));
      request.contentLength = length;
      if (headers != null) {
        request.headers.addAll(headers);
      }
      subscription = uploadStream
          .listen(request.sink.add as void Function(dynamic)?, onDone: () {
        request.sink.close();
        subscription!.cancel();
      });
      return await Response.fromStream(await _client.send(request));
    } finally {
      unawaited(subscription?.cancel());
    }
  }

  @override
  Future<Response> post(String url, data, {Map<String, String>? headers}) {
    return _client.post(Uri.parse(url), headers: headers, body: data);
  }

  @override
  Future<Response> put(String url, data, {Map<String, String>? headers}) {
    return _client.put(Uri.parse(url), headers: headers, body: data);
  }

  @override
  Future<Response> head(String url, {Map<String, String>? headers}) {
    return _client.head(Uri.parse(url), headers: headers);
  }

  @override
  Future<Response> patch(String url, data, {Map<String, String>? headers}) {
    return _client.patch(Uri.parse(url), body: data, headers: headers);
  }

  Request _createRequest(
      String method, String url, dynamic data, Map<String, String>? headers) {
    var request = Request(method, Uri.parse(url));
    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (data != null) {
      request.body = data;
    }
    return request;
  }
}
