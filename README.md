# fnx_rest

Set of REST tools which work nicely with Dart 2 / Angular.

fnx_rest is oriented to be developer and Angular friendly and is particularly useful
when creating boring CRUD applications with many similar API calls. 

## Example

```dart
    import 'package:fnx_rest/fnx_rest_browser.dart';
//     import 'package:fnx_rest/fnx_rest_io.dart'; (when not in a browser)       

    RestClient root = BrowserRestClient.root("/api/v1");        
    RestResult response = await root.child("/users").get();
    List users = response.data;
```
    
## Angular support

You can define `root` REST client, add your API keys and other additional headers to it
and inject this root client with Angular's dependency injection to your elements and/or services.
    
```dart
    RestClient root = BrowserRestClient.root("/api/v1");            
          
    // your component
    class MyApp {
        RestClient restRoot;
        MyApp(this.restRoot);        
    }
    
    // add custom headers, for example after user's signing in
    restRoot.setHeader("Authorization", authKey);       
```

(see Angular docs for DI details)     
    
RestClient is hierarchical:
    
```dart
    RestClient root = BrowserRestClient.root("/api/v1");   //  /api/v1
    RestClient users = root.child("/users");            //  /api/v1/users            
    RestClient john = users.child("/123");              //  /api/v1/users/123
```
    
All children inherit configuration of their parents, but are allowed
to override it.

RestClient supports query parameters:
    
```dart
    RestClient limitedUsers = users.setParam('limit', '1000');  //  /api/v1/users?limit=1000            
```

Typically you would create a child of the root rest
client in your component like this:

```dart
    class UserManagement {
        RestClient users;
        UserManagement(RestClient root) {
            users = root.child("/users"); // endpoint /api/v1/users
        }
    }
```
    
Every instance of RestClient has bool `working` property, which indicates whether this client
is currently processing a request/response or not. You can use it to indicate "working"
state to the user:

    <p *ngIf="users.working">Sending user data to server ...</p>
    
This property is recursively propagated to client's parents so you can indicate
this "working" state on any level. Locally (for a form),
or globally (for the whole app).
     
    // update user     
    users.put(...);

Until the request is processed, `john.working == true`, `users.working == true` and `root.working == true`.

    // read users
    users.get( ... )

In this case `john.working == false` but `users.working == true` and `root.working == true`.

You can easily
use this behaviour to disable a form and all it's buttons after submitting edited
user data, but in the same time you can have universal
global indicator of any HTTP communication (in your app status bar, for example).

## HTTP methods

RestClient has following methods:

```dart
    Future<RestResult> get({dynamic data, Map<String, String> headers}) ...
    Future<RestResult> post(dynamic data, {Map<String, String> headers}) ...
    Future<RestResult> put(dynamic data, {Map<String, String> headers}) ...
    Future<RestResult> delete({dynamic data, Map<String, String> headers}) ...
    Future<RestResult> head({Map<String, String> headers}) ...
```
    
Use optional parameter `headers` to specify custom ad-hoc headers you need
in this call only. Headers will be merged with your `RestClient` default headers,
it's parent's headers etc. up to the root `RestClient`. 

Don't use this parameter to specify `Content-Type` or `Accept` headers, see below. 

## RestResult

Each call returns `Future<RestResult>`. RestResult contains `status` (HTTP status, int) 
and `data` which are already converted to your
desired type (see below) - Dart Map or Dart List by default. 

## Request/response serialization

By default, the root client is configured to produce and consume JSON and
Dart Maps and Lists.
You can easily customize this behaviour to accept or produce any binary data:
 
```dart
    RestClient img = root.child("/images");        //  /api/v1/images     
    img.acceptsBinary("image/png");
    img.producesBinary("image/png");
```
    
Such data will be sent and received as `List<int>` or
inject any custom text based serialization or deserialization you need:

```dart
    /*
    typedef dynamic Serializer(dynamic payload);
    typedef dynamic Deserializer(String payload);
    */

    client.accepts("text/csv", myCsvDeserializeFunction);
    client.produces("text/csv", myCsvSerializeFunction);
```
    
This configuration is inherited by client's children.                        
                
## Work in progress
                
Suggestions, pull requests and bugreports are more than welcome.                