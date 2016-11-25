//import 'package:http/browser_client.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'package:http/src/response.dart';


class RestClient {

  Engine _engine;

  RestClient _parent;
  String _url;

  Map<String, String> _headers = {};
  String _acceptsMime;
  String _producesMime;
  Deserializer _deserializer;
  Serializer _serializer;

  RestClient(RestClient parent, String url, {Map<String, String> headers}): this.withEngine(null, parent, url, headers: headers);

  RestClient.withEngine(Engine engine, RestClient parent, String url, {Map<String, String> headers}) {
    _parent = parent;
    _url = cleanupUrl(url);
    _engine = engine;
    if (headers == null) headers = {};
    _headers = headers;
    accepts('application/json', defaultJsonDeserializer);
    produces('application/json', defaultJsonSerializer);
  }

  RestClient child(String urlPart, {Map<String, String> headers}) {
    return new RestClient.withEngine(_engine, this, urlPart, headers: headers);
  }

  RestClient accepts(String mime, Deserializer deserializer) {
    this._acceptsMime = mime;
    this._deserializer = deserializer;

    return this;
  }

  RestClient produces(String mime, Serializer serializer) {
    this._producesMime = mime;
    this._serializer = serializer;

    return this;
  }

  Future<RestResult> get({Map<String, String> headers}) {
    Map<String, String> allHeaders = _headersToSend(headers);
    Future<Response> resp = _engine.get(url, headers: allHeaders);
    return processResponse(deserializer, resp);
  }

  Future<RestResult> post(dynamic data, {Map<String, String> headers}) {
    Map<String, String> headersToSend = _headersToSend(headers);
    _includeContentTypeHeader(headersToSend);
    Future<Response> resp = _engine.post(url, serializer(data), headers: headersToSend);
    return processResponse(deserializer, resp);
  }

  Future<RestResult> put(dynamic data, {Map<String, String> headers}) {
    Map<String, String> headersToSend = _headersToSend(headers);
    _includeContentTypeHeader(headersToSend);
    Future<Response> resp = _engine.put(url, serializer(data), headers: headersToSend);
    return processResponse(deserializer, resp);
  }

  Future<RestResult> delete({Map<String, String> headers}) {
    Map<String, String> allHeaders = _headersToSend(headers);
    Future<Response> resp = _engine.delete(url, headers: allHeaders);
    return processResponse(deserializer, resp);
  }

  Map<String, String> _headersToSend(Map<String, String> headers) {
    Map<String, String> allHeaders = this.headers;
    allHeaders.addAll(headers ?? {});
    _includeAcceptHeader(allHeaders);
    return allHeaders;
  }

  static Future<RestResult> processResponse(deserializer, Future<Response> resp) {
    return resp.then((Response r) {
      dynamic data = null;
      if (r.body != null && !r.body.isEmpty) {
        data = deserializer(r.body);
      }
      RestResult result = new RestResult(r.statusCode, data);
      if (result.error) {
        result.throwError();
      } else {
        return result;
      }
    });
  }

  String get url {
    return joinUrls(_parent?.url, _url);
  }

  static RegExp SLASH_CHAR = new RegExp(r'\/');

  static String cleanupUrl(String url) {
    if (url == null || url.isEmpty){
      return '';
    } else {
      return url;
    }
  }

  static String joinUrls(String base, String part) {
    if (base == null) return part;
    if (part == null) return base;

    var baseEndsWithSlash = base.endsWith('/');
    var partStartsWithSlash = part.startsWith(SLASH_CHAR);

    if (baseEndsWithSlash && partStartsWithSlash) {
      part = part.substring(1);
    } else if (!baseEndsWithSlash && !partStartsWithSlash) {
      part = "/$part";
    }

    return "$base$part";
  }

  Map<String, String> _includeAcceptHeader(Map<String, String> headers) {
    if (headers == null) headers = {};
    var mime = acceptsMime;
    if (mime == null) return headers;
    headers['Accept'] = mime;
    return headers;
  }

  Map<String, String> _includeContentTypeHeader(Map<String, String> headers) {
    if (headers == null) headers = {};
    var mime = producesMime;
    if (mime == null) return headers;
    headers['Content-Type'] = mime;
    return headers;
  }

  String get producesMime => _producesMime != null ? _producesMime: _parent?.producesMime;
  String get acceptsMime => _acceptsMime != null ? _acceptsMime: _parent?.acceptsMime;

  Serializer get serializer => _serializer != null ? _serializer: _parent?.serializer;
  Deserializer get deserializer => _deserializer != null ? _deserializer: _parent?.deserializer;

  Map<String, String> get headers {
    Map<String, String> res = {};

    Map<String, String> parentHeaders = _parent?.headers;
    if ( parentHeaders != null && parentHeaders.isNotEmpty) {
      res.addAll(parentHeaders);
    }

    if (_headers != null && _headers.isNotEmpty) {
      res.addAll(_headers);
    }

    return res;
  }
}

abstract class Engine {

  Future<Response> get(String url, {Map<String, String> headers});
  Future<Response> post(String url, dynamic data, {Map<String, String> headers});
  Future<Response> put(String url, dynamic data, {Map<String, String> headers});
  Future<Response> delete(String url, {Map<String, String> headers});
  //http.BrowserClient client = new http.BrowserClient()..withCredentials = true;
}

typedef dynamic Serializer(dynamic payload);
typedef dynamic Deserializer(dynamic payload);

RegExp microRemoval = new RegExp(r'\.[0-9]{0,6}');

Object toJsonEncodable(Object value) {
  if (value is DateTime) {
    return value.toUtc().toIso8601String().replaceAll(microRemoval, r'');
  } else {
    return value;
  }
}

Deserializer defaultJsonDeserializer = (dynamic payload) {
  if (payload == null) {
    return null;
  } else  if (payload is String) {
    return JSON.decode(payload);
  } else {
    throw new RestClientException("Payload should be string if parsed as JSON");
  }
};

Serializer defaultJsonSerializer = (dynamic payload) {
  if (payload == null) {
    return null;
  } else {
    return JSON.encode(payload, toEncodable: toJsonEncodable);
  }
};

class RestClientException implements Exception {

  final String message;

  RestClientException(this.message);
}

class RestResult {
  final int status;
  final dynamic data;

  RestResult(this.status, this.data);

  get success => 200 <= status && status < 300;
  get failure => 400 <= status && status < 500;
  get error => 500 <= status;

  get notFound =>  status == 404;
  get notAuthorized => status == 401;
  get forbidden => status == 403;

  void throwError() {
    throw new HttpException(status, data);
  }
}

class HttpException {
  int httpStatus;
  var data;

  HttpException(this.httpStatus, [this.data]);
}
