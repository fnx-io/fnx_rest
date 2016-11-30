# Fnx_rest
Is set of REST tool which work nicely with fnx_ui and Angular2.Dart in general.

## Components

### [RestClient](docs/RestClient.md)

Simple client which provides neccessary API for you when interacting with remote services exposed over REST and HTTP.

Main properties:

 - Hierarchichal: `rootRest.child("/users")` creates new RestClient with different URL but sharing all configuration with its parent
 - `Future` oriented results play nicely with `async/await`: `RestResult user = await userRest.get()`
 - Configurable: speaks json natively, but lets you support APIs of any kind (binary, xml, text/plain)