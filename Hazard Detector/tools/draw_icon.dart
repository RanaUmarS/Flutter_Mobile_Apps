import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 512, height: 512);

  // Fill background with bright red
  img.fill(image, color: img.ColorRgb8(220, 30, 30));

  // Draw a white circle for the generic alarm shape
  img.fillCircle(
    image,
    x: 256,
    y: 256,
    radius: 170,
    color: img.ColorRgb8(255, 255, 255),
  );

  // Draw inner red circle
  img.fillCircle(
    image,
    x: 256,
    y: 256,
    radius: 120,
    color: img.ColorRgb8(220, 30, 30),
  );

  // Draw a small "light" blip
  img.fillCircle(
    image,
    x: 256,
    y: 120,
    radius: 30,
    color: img.ColorRgb8(255, 200, 0),
  );

  File('assets/icon.png').writeAsBytesSync(img.encodePng(image));
  print('Icon generated.');
}
