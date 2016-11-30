// Copyright (c) 2016, Tomucha. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library fnx_rest;

import 'dart:async';
import 'package:http/browser_client.dart' as http;

import 'package:http/src/response.dart';
import 'src/rest_client.dart';
export 'src/rest_client.dart';

class HttpRestClient extends RestClient {

  HttpRestClient.root(String url) : this(null, url);
  HttpRestClient(RestClient parent, String url) : super(new BrowserHttpClient(), parent, url);

}

class BrowserHttpClient extends HttpClient {

  http.BrowserClient _client = new http.BrowserClient();

  @override
  Future<Response> get(String url, {Map<String, String> headers}) {
    return _client.get(url, headers: headers);
  }

  @override
  Future<Response> delete(String url, {Map<String, String> headers}) {
    return _client.delete(url, headers: headers);
  }

  @override
  Future<Response> post(String url, data, {Map<String, String> headers}) {
    return _client.post(url, headers: headers, body: data);
  }

  @override
  Future<Response> put(String url, data, {Map<String, String> headers}) {
    return _client.post(url, headers: headers, body: data);
  }
}
