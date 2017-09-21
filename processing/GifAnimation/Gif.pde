/*
 * GifAnimation is a processing library to play gif animations and to 
 * extract frames from a gif file. It can also export animated GIF animations
 * This file class is under a GPL license. The Decoder used to open the
 * gif files was written by Kevin Weiner. please see the separate copyright
 * notice in the header of the GifDecoder / GifEncoder class.
 * 
 * by extrapixel 2007
 * http://extrapixel.ch
 * 
  
  	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import java.awt.image.BufferedImage;
import java.io.*;

//import processing.core.*;

public class Gif extends PImage implements PConstants, Runnable {
	PApplet parent;
	Thread runner;
	// if the animation is currently playing
	boolean play;
	// if the animation is currently looping
	boolean loop;
	// wehter the repeat setting from the gif-file should be ignored
	boolean ignoreRepeatSetting = false;
	// nr of repeats specified in the gif-file. 0 means repeat forever
	int repeatSetting = 1;
	// how often this animation has repeated since last call to play()
	int repeatCount = 0;
	// the current frame number
	int currentFrame;
	// array containing the frames as PImages
	PImage[] frames;
	// array containing the delay in ms of every frame
	int[] delays;
	// last time the frame changed
	int lastJumpTime;
	// version
	String version = "2.4";

	Gif(PApplet parent, String filename) {
		// this creates a fake image so that the first time this
		// attempts to draw, something happens that's not an exception
		super(1, 1, ARGB);

		this.parent = parent;

		// create the GifDecoder
		GifDecoder gifDecoder = createDecoder(parent, filename);

		// fill up the PImage and the delay arrays
		frames = extractFrames(gifDecoder);
		delays = extractDelays(gifDecoder);

		// get the GIFs repeat count
		repeatSetting = gifDecoder.getLoopCount();

		// re-init our PImage with the new size
		super.init(frames[0].width, frames[0].height, ARGB);
		jump(0);
		parent.registerMethod("dispose", this);

		// and now, make the magic happen
		runner = new Thread(this);
		runner.start();
	}

	void dispose() {
		// fin
		// System.out.println("disposing");
		parent.unregisterMethod("dispose", this);
		stop();
		runner = null;
	}

	 // the thread's run method
	void run() {
		while (Thread.currentThread() == runner) {
			try {
				Thread.sleep(5);
			} catch (InterruptedException e) { }

			if (play) {
				// if playing, check if we need to go to next frame

				if (parent.millis() - lastJumpTime >= delays[currentFrame]) {
					// we need to jump

					if (currentFrame == frames.length - 1) {
						// its the last frame
						if (loop) {
							jump(0); // loop is on, so rewind
						} else if (!ignoreRepeatSetting) {
							// we're not looping, but we need to respect the
							// GIF's repeat setting
							repeatCount++;
							if (repeatSetting == 0) {
								// we need to repeat forever
								jump(0);
							} else if (repeatCount == repeatSetting) {
								// stop repeating, we've reached the repeat
								// setting
								stop();
							}
						} else {
							// no loop & ignoring the repeat setting, so just
							// stop.
							stop();
						}
					} else {
						// go to the next frame
						jump(currentFrame + 1);
					}
				}
			}
		}
	}

	 // creates an input stream using processings createInput() method to read from the sketch data-directory
	InputStream createInputStream(PApplet parent, String filename) {
		InputStream inputStream = parent.createInput(filename);
		return inputStream;
	}

	 // In case someone wants to mess with the frames directly, they can get an array of PImages 
   // containing the animation frames. without having a gif-object with a seperate thread.
	 // It takes a filename of a file in the datafolder.
	PImage[] getPImages(PApplet parent, String filename) {
		GifDecoder gifDecoder = createDecoder(parent, filename);
		return extractFrames(gifDecoder);
	}

	// probably someone wants all the frames even if he has a playback-gif...
	PImage[] getPImages() {
		return frames;
	}

	 // creates a GifDecoder object and loads a gif file
	GifDecoder createDecoder(PApplet parent, String filename) {
		GifDecoder gifDecoder = new GifDecoder();
		gifDecoder.read(createInputStream(parent, filename));
		return gifDecoder;
	}

	 // creates a PImage-array of gif frames in a GifDecoder object
	PImage[] extractFrames(GifDecoder gifDecoder) {
		int n = gifDecoder.getFrameCount();

		PImage[] frames = new PImage[n];

		for (int i = 0; i < n; i++) {
			BufferedImage frame = gifDecoder.getFrame(i);
			frames[i] = new PImage(frame.getWidth(), frame.getHeight(), ARGB);
			System.arraycopy(frame.getRGB(0, 0, frame.getWidth(), frame
					.getHeight(), null, 0, frame.getWidth()), 0,
					frames[i].pixels, 0, frame.getWidth() * frame.getHeight());
		}
		return frames;
	}

	 // creates an int-array of frame delays in the gifDecoder object
	int[] extractDelays(GifDecoder gifDecoder) {
		int n = gifDecoder.getFrameCount();
		int[] delays = new int[n];
		for (int i = 0; i < n; i++) {
			delays[i] = gifDecoder.getDelay(i); // display duration of frame in
			// milliseconds
		}
		return delays;
	}

	 // Can be called to ignore the repeat-count set in the gif-file. this does not affect loop()/noLoop() settings.
	void ignoreRepeat() {
		ignoreRepeatSetting = true;
	}

	 // returns the number of repeats that is specified in the gif-file 0 means repeat forever
	int getRepeat() {
		return repeatSetting;
	}

	 // returns true if this GIF object is playing
	boolean isPlaying() {
		return play;
	}

	 // returns the current frame number
	int currentFrame() {
		return currentFrame;
	}

	 // returns true if the animation is set to loop
	boolean isLooping() {
		return loop;
	}

	 // returns true if this animation is set to ignore the file's repeat setting
	boolean isIgnoringRepeat() {
		return ignoreRepeatSetting;
	}
	
	 // returns the version of the library
	String version() {
		return version;
	}

	 // The following methods mimic the behaviour of processing's movie class.

	 // Begin playing the animation, with no repeat.
	void play() {
		play = true;
		if (!ignoreRepeatSetting) {
			repeatCount = 0;
		}
	}

	 // Begin playing the animation, with repeat.
	void loop() {
		play = true;
		loop = true;
	}

	 // Shut off the repeating loop.
	void noLoop() {
		loop = false;
	}

	 // Pause the animation at its current frame.
	void pause() {
		// System.out.println("pause");
		play = false;
	}

	 // Stop the animation, and rewind.
	void stop() {
		//System.out.println("stop");
		play = false;
		currentFrame = 0;
		repeatCount = 0;
	}

	 // Jump to a specific location (in frames). if the frame does not exist, go to last frame
	void jump(int where) {
		if (frames.length > where) {
			currentFrame = where;

			// update the pixel-array
			loadPixels();
			System.arraycopy(frames[currentFrame].pixels, 0, pixels, 0, width
					* height);
			updatePixels();

			// set the jump time
			lastJumpTime = parent.millis();
		}
	}

	// Return the number of frame of the gif
	int getGifLength() {
		return frames.length;
		
	}

}

import java.awt.AlphaComposite;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferInt;
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.ArrayList;

/**
 * Class GifDecoder - Decodes a GIF file into one or more frames. <br>
 * 
 * <pre>
 *  Example:
 *     GifDecoder d = new GifDecoder();
 *     d.read(&quot;sample.gif&quot;);
 *     int n = d.getFrameCount();
 *     for (int i = 0; i &lt; n; i++) {
 *        BufferedImage frame = d.getFrame(i);  // frame i
 *        int t = d.getDelay(i);  // display duration of frame in milliseconds
 *        // do something with frame
 *     }
 * </pre>
 * 
 * No copyright asserted on the source code of this class. May be used for any
 * purpose, however, refer to the Unisys LZW patent for any additional
 * restrictions. Please forward any corrections to kweiner@fmsware.com.
 * 
 * @author Kevin Weiner, FM Software; LZW decoder adapted from John Cristy's
 *         ImageMagick.
 * @version 1.03 November 2003
 * 
 */

public class GifDecoder {

   // File read status: No errors.
  static final int STATUS_OK = 0;

   // File read status: Error decoding file (may be partially decoded)
  static final int STATUS_FORMAT_ERROR = 1;

   // File read status: Unable to open source.
  static final int STATUS_OPEN_ERROR = 2;

  BufferedInputStream in;

  int status;

  int width; // full image width

  int height; // full image height

  boolean gctFlag; // global color table used

  int gctSize; // size of global color table

  int loopCount = 1; // iterations; 0 = repeat forever

  int[] gct; // global color table

  int[] lct; // local color table

  int[] act; // active color table

  int bgIndex; // background color index

  int bgColor; // background color

  int lastBgColor; // previous bg color

  int pixelAspect; // pixel aspect ratio

  boolean lctFlag; // local color table flag

  boolean interlace; // interlace flag

  int lctSize; // local color table size

  int ix, iy, iw, ih; // current image rectangle

  Rectangle lastRect; // last image rect

  BufferedImage image; // current frame

  BufferedImage lastImage; // previous frame

  byte[] block = new byte[256]; // current data block

  int blockSize = 0; // block size

  // last graphic control extension info
  int dispose = 0;

  // 0=no action; 1=leave in place; 2=restore to bg; 3=restore to prev
  int lastDispose = 0;

  boolean transparency = false; // use transparent color

  int delay = 0; // delay in milliseconds

  int transIndex; // transparent color index

  static final int MaxStackSize = 4096;

  // max decoder pixel stack size

  // LZW decoder working arrays
  short[] prefix;

  byte[] suffix;

  byte[] pixelStack;

  byte[] pixels;

  ArrayList frames; // frames read from current file

  int frameCount;

  public class GifFrame {
    GifFrame(BufferedImage im, int del) {
      image = im;
      delay = del;
    }

    BufferedImage image;

    int delay;
  }

   // Gets display duration for specified frame.
   // @param n, int index of frame
   // @return delay in milliseconds
  int getDelay(int n) {
    //
    delay = -1;
    if ((n >= 0) && (n < frameCount)) {
      delay = ((GifFrame) frames.get(n)).delay;
    }
    return delay;
  }

   // Gets the number of frames read from file.
   // @return frame count
  int getFrameCount() {
    return frameCount;
  }

   // Gets the first (or only) image read.
   // @return BufferedImage containing first frame, or null if none.
  BufferedImage getImage() {
    return getFrame(0);
  }

   // Gets the "Netscape" iteration count, if any. A count of 0 means repeat indefinitiely.
   // @return iteration count if one was specified, else 1.
  int getLoopCount() {
    return loopCount;
  }

   // Creates new frame image from current data (and previous frames as specified by their disposition codes).
  void setPixels() {
    // expose destination image's pixels as int array
    int[] dest = ((DataBufferInt) image.getRaster().getDataBuffer()).getData();

    // fill in starting image contents based on last image's dispose code
    if (lastDispose > 0) {
      if (lastDispose == 3) {
        // use image before last
        int n = frameCount - 2;
        if (n > 0) {
          lastImage = getFrame(n - 1);
        } else {
          lastImage = null;
        }
      }

      if (lastImage != null) {
        int[] prev = ((DataBufferInt) lastImage.getRaster().getDataBuffer()).getData();
        System.arraycopy(prev, 0, dest, 0, width * height);
        // copy pixels

        if (lastDispose == 2) {
          // fill last image rect area with background color
          Graphics2D g = image.createGraphics();
          Color c = null;
          if (transparency) {
            c = new Color(0, 0, 0, 0); // assume background is transparent
          } else {
            c = new Color(lastBgColor); // use given background color
          }
          g.setColor(c);
          g.setComposite(AlphaComposite.Src); // replace area
          g.fill(lastRect);
          g.dispose();
        }
      }
    }

    // copy each source line to the appropriate place in the destination
    int pass = 1;
    int inc = 8;
    int iline = 0;
    for (int i = 0; i < ih; i++) {
      int line = i;
      if (interlace) {
        if (iline >= ih) {
          pass++;
          switch (pass) {
          case 2:
            iline = 4;
            break;
          case 3:
            iline = 2;
            inc = 4;
            break;
          case 4:
            iline = 1;
            inc = 2;
          }
        }
        line = iline;
        iline += inc;
      }
      line += iy;
      if (line < height) {
        int k = line * width;
        int dx = k + ix; // start of line in dest
        int dlim = dx + iw; // end of dest line
        if ((k + width) < dlim) {
          dlim = k + width; // past dest edge
        }
        int sx = i * iw; // start of line in source
        while (dx < dlim) {
          // map color and insert in destination
          int index = ((int) pixels[sx++]) & 0xff;
          int c = act[index];
          if (c != 0) {
            dest[dx] = c;
          }
          dx++;
        }
      }
    }
  }

   // Gets the image contents of frame n.
   // @return BufferedImage representation of frame, or null if n is invalid.
  BufferedImage getFrame(int n) {
    BufferedImage im = null;
    if ((n >= 0) && (n < frameCount)) {
      im = ((GifFrame) frames.get(n)).image;
    }
    return im;
  }

   // Gets image size.
   // @return GIF image dimensions
  Dimension getFrameSize() {
    return new Dimension(width, height);
  }

   // Reads GIF image from stream
   // @param BufferedInputStream containing GIF file.
   // @return read status code (0 = no errors)
  int read(BufferedInputStream is) {
    init();
    if (is != null) {
      in = is;
      readHeader();
      if (!err()) {
        readContents();
        if (frameCount < 0) {
          status = STATUS_FORMAT_ERROR;
        }
      }
    } else {
      status = STATUS_OPEN_ERROR;
    }
    try {
      is.close();
    } catch (IOException e) {
    }
    return status;
  }

   // Reads GIF image from stream
   // @param InputStream containing GIF file.
   // @return read status code (0 = no errors)
  int read(InputStream is) {
    init();
    if (is != null) {
      if (!(is instanceof BufferedInputStream))
        is = new BufferedInputStream(is);
      in = (BufferedInputStream) is;
      readHeader();
      if (!err()) {
        readContents();
        if (frameCount < 0) {
          status = STATUS_FORMAT_ERROR;
        }
      }
    } else {
      status = STATUS_OPEN_ERROR;
    }
    try {
      is.close();
    } catch (Exception e) { }
    return status;
  }

   // Reads GIF file from specified file/URL source (URL assumed if name contains ":/" or "file:")
   // @param name, String containing source
   // @return read status code (0 = no errors)
  int read(String name) {
    status = STATUS_OK;
    try {
      name = name.trim().toLowerCase();
      if ((name.indexOf("file:") >= 0) || (name.indexOf(":/") > 0)) {
        URL url = new URL(name);
        in = new BufferedInputStream(url.openStream());
      } else {
        in = new BufferedInputStream(new FileInputStream(name));
      }
      status = read(in);
    } catch (IOException e) {
      status = STATUS_OPEN_ERROR;
    }

    return status;
  }

   // Decodes LZW image data into pixel array. Adapted from John Cristy's ImageMagick.
  void decodeImageData() {
    int NullCode = -1;
    int npix = iw * ih;
    int available, clear, code_mask, code_size, end_of_information, in_code, old_code, bits, code, count, i, datum, data_size, first, top, bi, pi;

    if ((pixels == null) || (pixels.length < npix)) {
      pixels = new byte[npix]; // allocate new pixel array
    }
    if (prefix == null)
      prefix = new short[MaxStackSize];
    if (suffix == null)
      suffix = new byte[MaxStackSize];
    if (pixelStack == null)
      pixelStack = new byte[MaxStackSize + 1];

    // Initialize GIF data stream decoder.
    data_size = read();
    clear = 1 << data_size;
    end_of_information = clear + 1;
    available = clear + 2;
    old_code = NullCode;
    code_size = data_size + 1;
    code_mask = (1 << code_size) - 1;
    for (code = 0; code < clear; code++) {
      prefix[code] = 0;
      suffix[code] = (byte) code;
    }

    // Decode GIF pixel stream.
    datum = bits = count = first = top = pi = bi = 0;

    for (i = 0; i < npix;) {
      if (top == 0) {
        if (bits < code_size) {
          // Load bytes until there are enough bits for a code.
          if (count == 0) {
            // Read a new data block.
            count = readBlock();
            if (count <= 0)
              break;
            bi = 0;
          }
          datum += (((int) block[bi]) & 0xff) << bits;
          bits += 8;
          bi++;
          count--;
          continue;
        }

        // Get the next code.

        code = datum & code_mask;
        datum >>= code_size;
        bits -= code_size;

        // Interpret the code

        if ((code > available) || (code == end_of_information))
          break;
        if (code == clear) {
          // Reset decoder.
          code_size = data_size + 1;
          code_mask = (1 << code_size) - 1;
          available = clear + 2;
          old_code = NullCode;
          continue;
        }
        if (old_code == NullCode) {
          pixelStack[top++] = suffix[code];
          old_code = code;
          first = code;
          continue;
        }
        in_code = code;
        if (code == available) {
          pixelStack[top++] = (byte) first;
          code = old_code;
        }
        while (code > clear) {
          pixelStack[top++] = suffix[code];
          code = prefix[code];
        }
        first = ((int) suffix[code]) & 0xff;

        // Add a new string to the string table,

        if (available >= MaxStackSize)
          break;
        pixelStack[top++] = (byte) first;
        prefix[available] = (short) old_code;
        suffix[available] = (byte) first;
        available++;
        if (((available & code_mask) == 0) && (available < MaxStackSize)) {
          code_size++;
          code_mask += available;
        }
        old_code = in_code;
      }

      // Pop a pixel off the pixel stack.

      top--;
      pixels[pi++] = pixelStack[top];
      i++;
    }

    for (i = pi; i < npix; i++) {
      pixels[i] = 0; // clear missing pixels
    }

  }

  // Returns true if an error was encountered during reading/decoding
  boolean err() {
    return status != STATUS_OK;
  }

  // Initializes or re-initializes reader
  void init() {
    status = STATUS_OK;
    frameCount = 0;
    frames = new ArrayList();
    gct = null;
    lct = null;
  }

  // Reads a single byte from the input stream.
  int read() {
    int curByte = 0;
    try {
      curByte = in.read();
    } catch (IOException e) {
      status = STATUS_FORMAT_ERROR;
    }
    return curByte;
  }

   // Reads next variable length block from input.
   // @return number of bytes stored in "buffer"
  int readBlock() {
    blockSize = read();
    int n = 0;
    if (blockSize > 0) {
      try {
        int count = 0;
        while (n < blockSize) {
          count = in.read(block, n, blockSize - n);
          if (count == -1)
            break;
          n += count;
        }
      } catch (IOException e) {
      }

      if (n < blockSize) {
        status = STATUS_FORMAT_ERROR;
      }
    }
    return n;
  }

   // Reads color table as 256 RGB integer values
   // @param ncolors, int number of colors to read
   // @return int array containing 256 colors (packed ARGB with full alpha)
  int[] readColorTable(int ncolors) {
    int nbytes = 3 * ncolors;
    int[] tab = null;
    byte[] c = new byte[nbytes];
    int n = 0;
    try {
      n = in.read(c);
    } catch (IOException e) {
    }
    if (n < nbytes) {
      status = STATUS_FORMAT_ERROR;
    } else {
      tab = new int[256]; // max size to avoid bounds checks
      int i = 0;
      int j = 0;
      while (i < ncolors) {
        int r = ((int) c[j++]) & 0xff;
        int g = ((int) c[j++]) & 0xff;
        int b = ((int) c[j++]) & 0xff;
        tab[i++] = 0xff000000 | (r << 16) | (g << 8) | b;
      }
    }
    return tab;
  }

  // Main file parser. Reads GIF content blocks.
  void readContents() {
    // read GIF file content blocks
    boolean done = false;
    while (!(done || err())) {
      int code = read();
      switch (code) {

      case 0x2C: // image separator
        readImage();
        break;

      case 0x21: // extension
        code = read();
        switch (code) {
        case 0xf9: // graphics control extension
          readGraphicControlExt();
          break;

        case 0xff: // application extension
          readBlock();
          String app = "";
          for (int i = 0; i < 11; i++) {
            app += (char) block[i];
          }
          if (app.equals("NETSCAPE2.0")) {
            readNetscapeExt();
          } else
            skip(); // don't care
          break;

        default: // uninteresting extension
          skip();
        }
        break;

      case 0x3b: // terminator
        done = true;
        break;

      case 0x00: // bad byte, but keep going and see what happens
        break;

      default:
        status = STATUS_FORMAT_ERROR;
      }
    }
  }

  // Reads Graphics Control Extension values
  void readGraphicControlExt() {
    read(); // block size
    int packed = read(); // packed fields
    dispose = (packed & 0x1c) >> 2; // disposal method
    if (dispose == 0) {
      dispose = 1; // elect to keep old image if discretionary
    }
    transparency = (packed & 1) != 0;
    delay = readShort() * 10; // delay in milliseconds
    transIndex = read(); // transparent color index
    read(); // block terminator
  }

  // Reads GIF file header information.
  void readHeader() {
    String id = "";
    for (int i = 0; i < 6; i++) {
      id += (char) read();
    }
    if (!id.startsWith("GIF")) {
      status = STATUS_FORMAT_ERROR;
      return;
    }

    readLSD();
    if (gctFlag && !err()) {
      gct = readColorTable(gctSize);
      bgColor = gct[bgIndex];
    }
  }

  // Reads next frame image
  void readImage() {
    ix = readShort(); // (sub)image position & size
    iy = readShort();
    iw = readShort();
    ih = readShort();

    int packed = read();
    lctFlag = (packed & 0x80) != 0; // 1 - local color table flag
    interlace = (packed & 0x40) != 0; // 2 - interlace flag
    // 3 - sort flag
    // 4-5 - reserved
    lctSize = 2 << (packed & 7); // 6-8 - local color table size

    if (lctFlag) {
      lct = readColorTable(lctSize); // read table
      act = lct; // make local table active
    } else {
      act = gct; // make global table active
      if (bgIndex == transIndex)
        bgColor = 0;
    }
    int save = 0;
    if (transparency) {
      save = act[transIndex];
      act[transIndex] = 0; // set transparent color if specified
    }

    if (act == null) {
      status = STATUS_FORMAT_ERROR; // no color table defined
    }

    if (err())
      return;

    decodeImageData(); // decode pixel data
    skip();

    if (err())
      return;

    frameCount++;

    // create new image to receive frame data
    image = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB_PRE);

    setPixels(); // transfer pixel data to image

    frames.add(new GifFrame(image, delay)); // add image to frame list

    if (transparency) {
      act[transIndex] = save;
    }
    resetFrame();

  }

  // Reads Logical Screen Descriptor
  void readLSD() {

    // logical screen size
    width = readShort();
    height = readShort();

    // packed fields
    int packed = read();
    gctFlag = (packed & 0x80) != 0; // 1 : global color table flag
    // 2-4 : color resolution
    // 5 : gct sort flag
    gctSize = 2 << (packed & 7); // 6-8 : gct size

    bgIndex = read(); // background color index
    pixelAspect = read(); // pixel aspect ratio
  }

  // Reads Netscape extenstion to obtain iteration count
  void readNetscapeExt() {
    do {
      readBlock();
      if (block[0] == 1) {
        // loop count sub-block
        int b1 = ((int) block[1]) & 0xff;
        int b2 = ((int) block[2]) & 0xff;
        loopCount = (b2 << 8) | b1;
      }
    } while ((blockSize > 0) && !err());
  }

  // Reads next 16-bit value, LSB first
  int readShort() {
    // read 16-bit value, LSB first
    return read() | (read() << 8);
  }

  // Resets frame state for reading next image.
  void resetFrame() {
    lastDispose = dispose;
    lastRect = new Rectangle(ix, iy, iw, ih);
    lastImage = image;
    lastBgColor = bgColor;
    int dispose = 0;
    boolean transparency = false;
    int delay = 0;
    lct = null;
  }

  // Skips variable length blocks up to and including next zero length block.
  void skip() {
    do {
      readBlock();
    } while ((blockSize > 0) && !err());
  }
}