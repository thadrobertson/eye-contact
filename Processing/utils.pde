GSMovie cropMovie;

// sets the crop dimensions based on one of the video files. This is called once only from setup() so all
// the video files should have the same dimensions
void setCrop() {  
    cropMovie  = new GSMovie(this, path+dayVideoFileList[0]); 
    cropMovie.play();
    while(cropMovie.ready() == false); // Can't query size until movie is playing 
    // Maintain aspect ratio by cropping; don't letterbox, don't stretch.
    // Use all those pixels!
    srcAspect = float(cropMovie.getSourceWidth()) / float(cropMovie.getSourceHeight());
    dstAspect = float(arrayWidth) / float(arrayHeight);
    if(srcAspect >= dstAspect) {
      // Crop left/right off video
      cropHeight = cropMovie.getSourceHeight();
      cropWidth  = int(float(cropHeight) * dstAspect);
      cropX      = (cropMovie.getSourceWidth() - cropWidth) / 2;
      cropY      = 0;
    } else {
      // Crop top/bottom off video
      cropWidth  = cropMovie.getSourceWidth();
      cropHeight = int(float(cropWidth) / dstAspect);
      cropX      = 0;
      cropY      = (cropMovie.getSourceHeight() - cropHeight) / 2;
    }
    cropMovie.stop();
    cropMovie.delete();
 }
 


// returns a random movie
int getNextMovie(){
       while (currentMovie == nextMovie) {
         nextMovie = int(random(0, dayVideoFiles.length));
     }
     return nextMovie;
}

void setInPoint () {
  dayVideoFiles[currentMovie].jump(dayMovieIn); 
  if (debug) println("IN");
}


void updateTime() {
    if (debug) println(date);

  if (debug) println("Time update");
  date = new Date();
  ss = new SunriseSunset(49.70f, 7.30f, date, TimeZone.getTimeZone("CEST"));
  if (ss.isDaytime()) {
    dayFirstRun=true;
  } else {
    nightFirstRun=true;
  } 
      if (debug) println(date);
      if (debug) println(ss.getSunrise());

}

void runVideo(PImage srcMovie){
    scaled.copy(srcMovie,cropX, cropY, cropWidth, cropHeight, 0, 0, scaled.width, scaled.height);
    image(scaled, 0, 0, width, height);
    driveLEDs(scaled);
}

void crossFade(PImage srcMovie, PImage destMovie){
    // fade out
    tint(255,255-fadeFloor);         
    scaled.copy(srcMovie,cropX, cropY, cropWidth, cropHeight, 0, 0, scaled.width, scaled.height);
    image(scaled,0,0,width,height);
    // store the fading out layer of the image
    fadeBuffer = get();
    // fade in
    tint(255,fadeFloor);           
    scaled.copy(destMovie,cropX, cropY, cropWidth, cropHeight, 0, 0, scaled.width, scaled.height);
    image(scaled,0,0,width,height);
    // grab the fading in layer of the image
    LEDout = get();
    // create a blend for output to the LEDs
    // untested with a large array -- suspect I will have to play with different blend modes
    LEDout.blend(fadeBuffer,0,0,width,height,0,0,width,height,BLEND);
    driveLEDs(LEDout);
    // alter the fade ratio
    fadeFloor += fadeRate;  
}

void driveLEDs(PImage LEDout){
  LEDout.loadPixels();
  if (arduino) LEDmatrix.refresh(LEDout.pixels, remap);
}

void showOSD(){
  if (osd) { 
     // create some feedback text on the preview screen
     fill(200, 200, 200);
     if (daytime) {
       text("This movie is: "+currentMovie+"\nNext movie is: "+nextMovie+"\nNext fade at: "+movieTransitionPoint+"\n"+int(dayVideoFiles[currentMovie].time()) + " / " + (int(dayVideoFiles[currentMovie].duration())), 10, 30);
     } else if (awakeSeq) {
       text("This movie is: "+currentMovie+" day\nNext movie is: "+currentMovie+" night \nNext fade at: "+movieTransitionPoint+"\n"+int(dayVideoFiles[currentMovie].time()) + " / " + (int(dayVideoFiles[currentMovie].duration())), 10, 30);    
     } else if (!daytime & !awakeSeq) {  
       text("This movie is: "+currentMovie+"\nNext movie is: "+nextMovie+"\nNext fade at: "+movieTransitionPoint+"\n"+int(nightVideoFiles[currentMovie].time()) + " / " + (int(nightVideoFiles[currentMovie].duration())), 10, 30);
     }
     // let us know if its day or night
     if (daytime) {
       fill(240, 240, 170);
       text("DAY", 10, 15);  
     } else {
       fill(210, 180, 245);
       text("NIGHT", 10, 15); 
     }     
     fill(240, 240, 170);    
     text("Sunrise: "+ss.getSunrise(), 10, 180);
     fill(210, 180, 245);
     text("Sunset: "+ss.getSunset(), 10, 210);
  }
}


// 'da old movie event handler
void movieEvent(GSMovie _videoFile) {
  try {
   _videoFile.read();
  }
  catch(Error e) {
    if (debug) println(e);
  }
}

