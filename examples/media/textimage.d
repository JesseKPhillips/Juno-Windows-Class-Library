module juno.examples.media.textimage;

import juno.media.all;

void main() {
  // Create a bitmap 400 pixels wide by 200 pixels high
  scope image = new Bitmap(400, 200);

  // Get the image's drawing surface
  scope graphics = Graphics.fromImage(image);

  // Create a font
  scope font = new Font("Georgia", 30, FontStyle.Bold);

  // Create a brush
  scope brush = new SolidBrush(Color.crimson);

  // Draw the text on the surface
  graphics.clear(Color.aliceBlue);
  graphics.drawString("Hello, Juno!", font, brush, 10, 10);

  // Save the image to a file
  image.save("hello.gif");
}