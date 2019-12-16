import 'package:fnx_rest/fnx_rest_io.dart';

void main() async {
  // Init your Rest API client
  RestClient apiRoot = IoRestClient.root('https://jsonplaceholder.typicode.com'); // Use BrowserRestClient in browser ..

  // configure global headers
  apiRoot.setHeader('Authorization', 'FacelessMan');

  // follow serverside endpoints structure ...
  var apiUsers = apiRoot.child('/users');
  print(apiUsers.url);
  var rr = await apiUsers.get();
  if (!rr.success) rr.throwError();
  print(rr.data);

  // follow serverside endpoints structure ...
  var myApiUser = apiUsers.child('/1');
  print(myApiUser.url);
  rr = await myApiUser.get();
  if (!rr.success) rr.throwError();
  print(rr.data);

  // customize payload handling
  // var myApiUserPhoto = myApiUser.child("/photo");
  // myApiUserPhoto.acceptsBinary("image/png");
}
