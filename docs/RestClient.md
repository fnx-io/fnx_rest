# RestClient: simple client for communicating with REST services

## Usage:

### Creating "root" RestClient
It all starts from something we call `rootRest`. This instance is configured to talk to your APIs, can handle request authorization and searialization/deserialization of common payloads. To communicate with specific APIs, you then create child rest client instances, which inherit all settings from their parents, but still allow you to change specifics you may need to have to change, to do some concrete call.

Creating RestClient can be simple as this:

`Restclient root = new RestClient('https://api.fnx.io/v1/', headers: {'Authorization': 'Bearer pvyaTA...'})`

Calling an API is then easy:

`RestResult usersResult = await root.child("/users/search?q=bob").get()`

Each `.child()` call gives you back new instance of RestClient which shares configuration with its parent. You can then change particular setting for the child, which won't affect other RestClients but will be propagated down through the ancestors of this instance of RestClient, if you make some children of it.

```
RestClient usersRest = root.child("/users/search?q=bob");
userRest.accepts("text/xml", somXmlParser);
RestResult usersResult = await usersRest.get();
```