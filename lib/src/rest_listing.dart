import 'dart:async';
import 'package:fnx_rest/src/rest_client.dart';

/// Simple utility which allows to load pages of results for a given API endpoint
///
/// To load the results it requires configured [RestClient].
///
/// It accepts [RestListingDriver] which handles paging for requests and unpacking
/// final List of data from returned response
class RestListing {

  RestClient rest;

  List<dynamic> list = [];
  int page = 0;

  bool _hasNext = true;
  int _version = 0;
  RestListingDriver _driver;

  RestListing(RestClient rest, RestListingDriver driver) {
    this.rest = rest.child('');
    this._driver = driver;
  }

  bool get working => rest.working;
  bool get hasNext => _hasNext;

  /// Use this to indicate that next page should be loaded.
  Future<bool> loadNextPage() async {
    if (working) {
      return false;
    }

    RestClient client = _driver.prepareClient(rest, page);

    int reqVersion = _version;
    RestResult rr = await client.get();
    if (_version != reqVersion) return false;

    UnpackedData data = _driver.unpackData(rr.data);
    page++;

    if (data.data != null && data.data.isNotEmpty) {
      list.addAll(data.data);
    }
    _hasNext = data.hasNext;

    return true;
  }

  /// Clears accumulated data and starts fetching page 0
  Future<bool> refresh() {
    _version++;
    list.clear();
    _hasNext = true;
    return loadNextPage();
  }
}

/// Allows to hook into the process of requesting data from the API
/// and then unwrapping List of results from provided response
abstract class RestListingDriver {

  /// Extract interesting data from the API response
  UnpackedData unpackData(dynamic data);

  /// Configure rest client so that it will request given `page` of data
  RestClient prepareClient(RestClient client, int page);

}

/// Expects the API to return List of data directly in its response.
class SimpleListDriver implements RestListingDriver {

  @override
  RestClient prepareClient(RestClient client, int page) {
    return queryParamPager(client, page);
  }

  @override
  UnpackedData unpackData(dynamic data) {
    data = data ?? [];
    return new UnpackedData(data.isNotEmpty, data);
  }

  static RestClient queryParamPager(RestClient client, int page) {
    client.setParam('page', page.toString());
    return client;
  }
}

/// Expects the API to return a Map with 'data' attribute which contains
/// the actual List of results
class ListResultDriver implements RestListingDriver {

  @override
  RestClient prepareClient(RestClient client, int page) {
    return SimpleListDriver.queryParamPager(client, page);
  }

  @override
  UnpackedData unpackData(dynamic data) {
    if (data is Map) {
      if (data != null && data['data'] is! List) {
        throw "Expected 'data' key to be a List, but was $data['data']";
      }
      List<dynamic> list = data ?? [];
      return new UnpackedData(list.isNotEmpty, list);
    } else {
      throw "Expected result to be a map with 'data' key containing results";
    }
  }
}

/// Contains the data itself and flag whether we think (or know) that
/// there is more data to fetch (next page)
class UnpackedData {
  final bool hasNext;
  final List<dynamic> data;

  UnpackedData(this.hasNext, this.data);

  UnpackedData.empty(): this(false, []);
}
