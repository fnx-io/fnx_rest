# fnx_rest

Set of REST tools which work nicely with Angular2 Dart.

This is a plain old REST client, if you are looking for something more sophisticated,
try [streamy](https://pub.dartlang.org/packages/streamy) for instance.

fnx_rest is oriented to be developer and Angular friendly and is particularly useful
when creating boring CRUD applications with many similar API calls. 

## Example

    RestClient root = HttpRestClient.root("/api/v1");        
    RestResult response = await root.child("/users").get();
    List users = response.data;
    
## Angular support

You can define `root` REST client, add your API keys and other additional headers to it
and inject this root client with Angular's
dependency injection to your elements and/or services.
    
    # Angular initialization
    RestClient root = HttpRestClient.root("/api/v1");            
    bootstrap(MyApp, [ provide(RestClient, useValue: root) ]);
          
    # your component
    class MyApp {
        RestClient restRoot;
        MyApp(this.restRoot);        
    }
    
    # add custom headers, for example after user's signing in
    restRoot.setHeader("Authorization", authKey);        
    
RestClient is hierarchical:
    
    RestClient root = HttpRestClient.root("/api/v1");   //  /api/v1
    RestClient users = root.child("/users");            //  /api/v1/users            
    RestClient john = users.child("/123");              //  /api/v1/users/123
    
All children inherit configuration of their parents, but are allowed
to override it.

Typically you would create a child of the root rest
client in your component like this:

    class UserManagement {
        RestClient users;
        UserManagement(RestClient root) {
            users = root.child("/users"); // endpoint /api/v1/users
        }
    }
    
Every instance of RestClient has bool `working` property, which indicates whether this client
is currently processing a request/response or not. You can us it to indicate "working"
state to the user:

    <p *ngIf="john.working">Sending user data to server ...</p>
    
This property is recursively propagated to client's parents so you can indicate
this "working" state on any level. Locally (for a form),
or globally (for the whole app).
     
    // update user     
    john.put(...);

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

    Future<RestResult> get({Map<String, String> headers}) ...
    Future<RestResult> post(dynamic data, {Map<String, String> headers}) ...
    Future<RestResult> put(dynamic data, {Map<String, String> headers}) ...
    Future<RestResult> delete({Map<String, String> headers}) ...
    
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
 
    RestClient users = root.child("/images");        //  /api/v1/images     
    img.acceptsBinary("image/png");
    img.producesBinary("image/png");
    
Such data will be sent and received as `List<int>` or
inject any custom text based serialization or deserialization you need:

    /*
    typedef dynamic Serializer(dynamic payload);
    typedef dynamic Deserializer(String payload);
    */

    client.accepts("text/csv", myCsvDeserializeFunction);
    client.produces("text/csv", myCsvSerializeFunction);
    
This configuration is inherited by client's children.    
    
## Custom HTTP client
    
This client is mainly intended for client side, but you can use it on server side too,
just provide custom HTTP client to the RestClient constructor.
     
     RestClient(HttpClient httpClient, RestClient parent, String url, {Map<String, String> headers});
     
For usage on the web client use convenient predefined client:

    RestClient root = HttpRestClient.root("/api/v1");
                
                
## Work in progress
                
Suggestions, pull requests and bugreports are more then welcome.                