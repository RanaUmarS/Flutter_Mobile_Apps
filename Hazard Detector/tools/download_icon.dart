import 'dart:io';

void main() async {
  var request = await HttpClient().getUrl(Uri.parse('https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Fire_Icon.svg/512px-Fire_Icon.svg.png'));
  request.headers.set('User-Agent', 'Mozilla/5.0');
  var response = await request.close();
  await response.pipe(File('assets/icon.png').openWrite());
}
