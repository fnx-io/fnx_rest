import 'dart:async';
import 'dart:convert';

import 'package:http/src/response.dart';

/// The rest client, this is the class you want to use.
/// On web use the [new HttpRestClient.root] constructor to obtain preconfigured
/// RestClient.
///
class RestClient {

  HttpClient _httpClient;

  RestClient _parent;
  String _url;

  Map<String, String> _headers = {};
  Map<String, dynamic /* String or List<String> */> _params = {};

  Accepts _accepts;
  Produces _produces;
  int _workingCount = 0;

  RestClient(HttpClient httpClient, RestClient parent, String url, {Map<String, String> headers}) {
    _parent = parent;
    UrlParseResult parsedUrl = parseUrl(url);
    _url = parsedUrl.url;
    _params = parsedUrl.params;
    _httpClient = httpClient;
    if (headers == null) headers = {};
    _headers = headers;
    accepts('application/json', defaultJsonDeserializer);
    produces('application/json', defaultJsonSerializer);
  }

  RestClient child(String urlPart, {Map<String, String> headers}) {
    return new RestClient(_httpClient, this, urlPart, headers: headers);
  }

  /// Configure Accept header with appropriate [Deserializer].
  RestClient accepts(String mime, Deserializer deserializer) {
    this._accepts = new Accepts.nonbinary(mime, deserializer);

    return this;
  }

  /// Configure Accept header to receive binary data without any processing.
  RestClient acceptsBinary(String mime) {
    this._accepts = new Accepts(mime, null, true);

    return this;
  }

  /// Configure Content-Type header to submit data as List<int> without serialization.
  RestClient producesBinary(String mime) {
    this._produces = new Produces(mime, null, true);

    return this;
  }

  /// Configure Content-Type header with appropriate [Serializer].
  RestClient produces(String mime, Serializer serializer) {
    this._produces = new Produces.nonbinary(mime, serializer);

    return this;
  }

  /// HTTP get with optional additional headers.
  Future<RestResult> get({Map<String, String> headers}) {
    Map<String, String> allHeaders = _headersToSend(headers);
    _workStarted();
    Future<Response> resp = _httpClient.get(renderUrl(url, params), headers: allHeaders);
    return handleResponse(resp);
  }

  /// HTTP POST with optional additional headers. Data will be processed using configured [Serializer], JSON.encode(...) by default.
  Future<RestResult> post(dynamic data, {Map<String, String> headers}) {
    Map<String, String> headersToSend = _headersToSend(headers);
    _includeContentTypeHeader(headersToSend);
    _workStarted();
    Future<Response> resp = _httpClient.post(renderUrl(url, params), effProduces.serialize(data), headers: headersToSend);
    return handleResponse(resp);
  }

  /// HTTP PUT with optional additional headers. Data will be processed using configured [Serializer], JSON.encode(...) by default.
  Future<RestResult> put(dynamic data, {Map<String, String> headers}) {
    Map<String, String> headersToSend = _headersToSend(headers);
    _includeContentTypeHeader(headersToSend);
    _workStarted();
    Future<Response> resp = _httpClient.put(renderUrl(url, params), effProduces.serialize(data), headers: headersToSend);
    return handleResponse(resp);
  }

  /// HTTP DELETE with optional additional headers and optional body
  Future<RestResult> delete({dynamic data, Map<String, String> headers}) {
    Map<String, String> allHeaders = _headersToSend(headers);
    _includeContentTypeHeader(allHeaders);
    _workStarted();
    Future<Response> resp = _httpClient.delete(renderUrl(url, params), data: effProduces.serialize(data), headers: allHeaders);
    return handleResponse(resp);
  }

  /// HTTP HEAD with optional additional headers.
  Future<RestResult> head({Map<String, String> headers}) {
    Map<String, String> allHeaders = _headersToSend(headers);
    _workStarted();
    Future<Response> resp = _httpClient.head(renderUrl(url, params), headers: allHeaders);
    return handleResponse(resp);
  }

  Map<String, String> _headersToSend(Map<String, String> headers) {
    Map<String, String> allHeaders = this.headers;
    allHeaders.addAll(headers ?? {});
    _includeAcceptHeader(allHeaders);
    return allHeaders;
  }

  Future<RestResult> handleResponse(Future<Response> resp) {
    return processResponse(effAccepts, resp.whenComplete(_workCompleted));
  }

  static Future<RestResult> processResponse(Accepts accepts, Future<Response> resp) {
    return resp.then((Response r) {
      dynamic data = null;
      data = accepts.deserialize(r);
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

  static UrlParseResult parseUrl(String url) {
    if (url == null || url.isEmpty){

      return new UrlParseResult('', {});
    } else {
      Uri parsed = Uri.parse(url);
      Map<String, dynamic> parsedParams = {};
      // split the parameters from the url given
      var queryParameters = parsed.queryParameters;
      if (queryParameters != null) parsedParams.addAll(queryParameters);

      // we are only interested into plain url without query parameters (we store these separately)
      Uri plain = parsed.replace(queryParameters: {}, query: null);
      String plainUrl = plain.toString();
      if (plainUrl.endsWith('?')) plainUrl = plainUrl.substring(0, plainUrl.length - 1);
      return new UrlParseResult(plainUrl, parsedParams);
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

  static String renderUrl(String template, Map<String, dynamic> params) {
    Uri parsed = Uri.parse(template);
    if (params.isEmpty) params = null;
    return parsed.replace(queryParameters: params).toString();
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

  Accepts get effAccepts => _accepts != null ? _accepts : _parent?._accepts;
  Produces get effProduces => _produces != null ? _produces : _parent?._produces;

  String get producesMime => effProduces?.mime;
  String get acceptsMime => effAccepts?.mime;

  Serializer get serializer => effProduces?.serializer;
  Deserializer get deserializer => effAccepts?.deserializer;

  bool get working => _workingCount > 0;

  void _workStarted() {
    _workingCount++;
    _parent?._workStarted();
  }

  void _workCompleted() {
    _workingCount--;
    _parent?._workCompleted();
  }

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

  /// Configure additional header. Will be inherited by all children.
  RestClient setHeader(String name, String value) {
    _headers[name] = value;
    return this;
  }

  /// Remove additional header. Will be inherited by all children.
  RestClient removeHeader(String name) {
    _headers.remove(name);
    return this;
  }

  Map<String, dynamic /* String or List<String>*/> get params {
    Map<String, dynamic> res = {};
    if (_parent != null) {
      res.addAll(_parent.params ?? {});
    }
    res.addAll(_params ?? {});
    return res;
  }

  /// Add query parameter.
  RestClient setParam(String name, String value) {
    return _setParam(name, value);
  }

  /// Add query parameter.
  RestClient setParams(String name, List<String> value) {
    return _setParam(name, value);
  }

  String getParam(String name) {
    dynamic res = _getParam(name);
    if (res is String) {
      return res;
    } else if (res == null) {
      return null;
    } else {
      throw "Invalid parameter type! \"$name\" should be of type String. Was $res";
    }
  }

  List<String> getParams(String name) {
    dynamic res = _getParam(name);

    if (res is String) {
      return [res];
    } else if (res is List<String>) {
      List<String> all = [];
      all.addAll(res);
      return all;
    } else if (res == null ){
      return null;
    } else {
      throw "Invalid parameter type! Only String an List<String> are supported ${res}";
    }
  }

  dynamic _getParam(String name) {
    Map<String, dynamic> allParams = params;
    return allParams[name];
  }

  RestClient _setParam(String name, /* String or List<String>*/ dynamic value) {
    if (value == null) {
      _params.remove(name);
    } else {
      _params[name] = value;
    }

    return this;
  }
}

///
/// Create your own implementation of this class if you
/// need to inject your own HTTP client into RestClient.
/// On server, for example. See [new RestClient].
///
abstract class HttpClient {

  Future<Response> get(String url, {Map<String, String> headers});
  Future<Response> post(String url, dynamic data, {Map<String, String> headers});
  Future<Response> put(String url, dynamic data, {Map<String, String> headers});
  Future<Response> delete(String url, {dynamic data, Map<String, String> headers});
  Future<Response> head(String url, {Map<String, String> headers});
}

///
/// Defines function which si able to take Dart objects and serialize them for upload (POST, PUT).
typedef dynamic Serializer(dynamic payload);

///
/// Defines function which is able to take HTTP response body and deserialize is into a Dart object.
/// Should return a String or List<int>.
typedef dynamic Deserializer(String payload);

RegExp microRemoval = new RegExp(r'\.[0-9]{0,6}');

Object toJsonEncodable(Object value) {
  if (value is DateTime) {
    return value.toUtc().toIso8601String().replaceAll(microRemoval, r'');
  } else {
    return value;
  }
}

///
/// Uses JSON.decode(...) from dart:convert.
Deserializer defaultJsonDeserializer = (String payload) {
  if (payload == null) {
    return null;
  } else  if (payload is String) {
    if (payload.isEmpty) {
      return null;
    } else {
      return JSON.decode(payload);
    }
  } else {
    throw new RestClientException("Payload should be string if parsed as JSON");
  }
};

///
/// Uses JSON.encode(...) from dart:convert.
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

///
/// Result of REST call.
class RestResult {

  /// HTTP status
  final int status;

  /// Deserialized response body.
  final dynamic data;

  RestResult(this.status, this.data);

  /// Convenient interpretation of HTTP status (>=200 && < 300)
  bool get success => 200 <= status && status < 300;

  /// Convenient interpretation of HTTP status (>=400 && < 500)
  bool get failure => 400 <= status && status < 500;

  /// Convenient interpretation of HTTP status (>=500)
  bool get error => 500 <= status;

  /// Convenient interpretation of HTTP status (404)
  bool get notFound =>  status == 404;

  /// Convenient interpretation of HTTP status (401)
  bool get notAuthorized => status == 401;

  /// Convenient interpretation of HTTP status (403)
  bool get forbidden => status == 403;

  /// If the result is success method returns data. If it's not, it throws 'this'.
  dynamic get successData {
    if (!success) throw this;
    return data;
  }

  void throwError() {
    throw new HttpException(status, data);
  }
}

class HttpException {
  int httpStatus;
  var data;

  HttpException(this.httpStatus, [this.data]);
}

class UrlParseResult {
  String url;
  Map<String, dynamic> _params = {};

  UrlParseResult(this.url, Map<String, dynamic> argParams) {
    if (argParams == null) argParams = {};
    this._params = argParams;
  }

  Map<String, dynamic> get params => _params;
}

///
/// Couple of mime type and Deserializer.
///
class Accepts {
  final String mime;
  final Deserializer deserializer;
  final bool binary;

  Accepts.nonbinary(String mime, Deserializer deserializer): this(mime, deserializer, false);
  Accepts(this.mime, this.deserializer, this.binary);

  dynamic deserialize(Response resp) {
    if (binary) {
      return resp.bodyBytes;
    }
    dynamic body = resp.body;
    if (body == null) return null;
    return deserializer(resp.body);
  }
}

///
/// Couple of mime type and Serializer.
///
class Produces {
  final String mime;
  final Serializer serializer;
  final bool binary;

  Produces.nonbinary(String mime, Serializer serializer): this(mime, serializer, false);
  Produces(this.mime, this.serializer, this.binary);

  dynamic serialize(dynamic payload) {
    if (binary) {
      return payload;
    } else {
      return serializer(payload);
    }
  }
}
