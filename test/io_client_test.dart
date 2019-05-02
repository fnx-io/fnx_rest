import 'package:fnx_rest/fnx_rest_io.dart';
import 'package:test/test.dart';

void main() {
  IoRestClient r = new IoRestClient.root("https://ruian.fnx.io/");
  RestClient rch = r.child(
      "api/v1/ruian/validate?apiKey=d9a14b87e627c3afea6a5b0ee6c836de065524de7e36f71acfe645c3e186928a&municipalityName=Fr%C3%BDdlant&zip=46401&cp=4001&street=Z%C3%A1meck%C3%A1");
  group("IoRestClient", () {
    test("basically works", () async {
      RestResult rr = await rch.get();
      expect(rr.data, isMap);
      expect(rr.data, isNotEmpty);
      expect((rr.data as Map)["status"], isNotNull);
    });
  });
}
