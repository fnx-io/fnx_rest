# Changelog

## 3.2.0

* RestResult now allows you to access response headers.

## 3.1.0

* serializers can now modify outgoing headers
* HTTP methods (get, post, ...) never throw a HttpException,
    not even with 500 http status response
* method RestResult.assertSuccess() when you are not interested in response body (successData)        

## 3.0.0

* More flexible serializers and deserializers. (_Breaking api change if you implement your own custom serializers or deserializers_)
* Added `urlWithParams` getter for simpler access to url rendered with parameters
* Default json de/serializers now not throw on whitespace string  
* Updated readme

## 2.2.0

Newer version of http client.
Example.

## 2.1.0

Added support for streaming requests.

## 0.0.1

- Initial version
