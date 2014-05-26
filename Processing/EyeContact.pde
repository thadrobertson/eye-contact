// v0.9

// Acknowledgements
//---------------
// This code is derived in part from the "Movie" example to accompany the now defunct
// Adavision DIY LED video wall project written by Philip Burgess. This is the host PC-side code written in Processing, intended for use
// with a USB-connected Arduino microcontroller running accompanying LED streaming code.
// 
// Movie loading routines are based on code from the Processing/Arduino video mixer project by Joseph Gray
//
// Sunset calculations are provided via the accompanying SunriseSunset.java library. Full release notes are provided in that file.


import java.util.Date;
import processing.serial.*;
import codeanticode.gsvideo.*;
import ws2801.*;


// ------------- Configuration variables -------------------------------------

boolean          arduino      = false;  // set to false if an Arduino is not hooked up
boolean          stats        = false;  // print realtime framerate and current use stats to the console
boolean          allowKeys    = true;  // flag to allow for keybord control. See 'keys' file
boolean          debug        = true;  // print info to the console
boolean          osd          = true;  // print status info to the computer display
boolean          useSunset    = true;  // utilise the sunset calculations for automatic content changes depending on time of day

static final int arrayWidth   = 38,     // Width of LED array
                 arrayHeight  = 9,      // Height of LED array
                 imgScale     = 30;     // Size of pixels in the displayed preview
                 

float            fadeRate     = 5;    // bigger number for faster fades.
float            skipToTime   = 17.0;   // seconds before end of movie that 'n' key should skip to.
float            NightSkipToTime = 6.0;   // seconds before end of movie that 'n' key should skip to. 
float            dayMovieIn   = 15.0;   // seconds from the head of a daytime video that we should start playing from                                        
int              dayMovieOut  = 15;     // seconds from the end of a daytime video that we should transition out
int              nightMovieOut= 4;      // seconds before end of movie that asleep, awaken or fall asleep transition should trigger
int              sensorPoll   = 5000;   // milliseconds between polling the sensor. This deals with the problem of repeated sensor triggers.                                        
float            lat          = 49.70; // latidude for sunrise/sunset calcs
float            lon          = 7.30; // longatude ditto
String           tzone        = "CEST"; // timezone code


// ------------- Shouldn't need to change anything below this line -------------

boolean          daytime      = true;   // time of day mode to be used on startup

Serial           port;
WS2801           LEDmatrix;
int[]            remap;

PImage           scaled       = createImage(arrayWidth, arrayHeight, RGB);
PImage           fadeBuffer   = createImage(arrayWidth, arrayHeight, RGB);
PImage           LEDout       = createImage(arrayWidth, arrayHeight, RGB);

String           path           = "";
float            fadeFloor      = 0.0;
boolean          runPlay        = true;
boolean          fade           = false;
boolean          sensorDetected = false;
boolean          wakeUpSeq      = false;
boolean          awakeSeq       = false;
boolean          fallAsleepSeq  = false;
boolean          dayFirstRun    = true;
boolean          nightFirstRun  = true;

int              dayVideoDur; 
int              nightVideoDur; 
int              currentMovie;
int              nextMovie;
int              movieDuration;
int              movieTransitionPoint;
long             timerStart;

int              cropX, cropY, cropWidth, cropHeight;
int              state;
float            srcAspect, dstAspect;

// setup sunrise/sunset 
Date date = new Date();
SunriseSunset ss = new SunriseSunset(lat, lon, date, TimeZone.getTimeZone(tzone));
  
void setup() { 
  size(arrayWidth * imgScale, arrayHeight * imgScale, JAVA2D);
  frameRate(60);
  
  // make movie objects and find durations
  setupVideoFiles();
  
  // get the crop dimensions from a video file
  setCrop();
  
  // Open serial connection to the Arduino running LEDstream code.
  // As written, this assumes the Arduino is the first/only USB serial
  // device; you may need to change the second parameter here to a
  // different port index or an absolute port name (e.g. "COM6").
   if (debug) println(Serial.list());
   if (arduino) port = new Serial(this, Serial.list()[8], 115200);
   
  // Init LED library.
   if (arduino)  LEDmatrix = new WS2801(port, arrayWidth * arrayHeight);
  
  // If the sketch freezes after the first frame, reset the Arduino and
  // uncomment the following line, a temporary workaround for an obscure
  // combination of hardware and code.  Unfortunately may flicker a bit.
  // LEDmatrix.useShortWrites = true;
  
  // Adjust color balance; you may need to tweak this for best output.
  if (arduino) LEDmatrix.setGamma(0, 255, 2.3, 0, 255, 2.2, 0, 200, 2.4);
  
  // Generate zigzag remap array to reconstitute image into LED order.
  if (arduino)   remap = LEDmatrix.zigzag(arrayWidth, arrayHeight,
   WS2801.START_BOTTOM | WS2801.START_LEFT | WS2801.ROW_MAJOR);
   
  // set some intial movie numbers
  currentMovie = getNextMovie();
  nextMovie = getNextMovie();
}


void draw() {
  
  // check if its actually daytime
  if (useSunset && ss.isDaytime()) {
    daytime=true;
  } else {
    daytime=false;
  }
  
  //check for day mode
  if (daytime) {
     if (dayFirstRun) {
        daytime = true;
        dayFirstRun = false;
        nightFirstRun = true;
        sensorDetected = false;
        dayVideoFiles[currentMovie].play();    
        while(dayVideoFiles[currentMovie].ready() == false);
        dayVideoFiles[currentMovie].goToBeginning(); // have to add this otherwise the jump() function will not work. why????
        dayVideoFiles[currentMovie].jump(dayMovieIn); 
        movieDuration = dayTimeDuration[currentMovie];
        movieTransitionPoint = movieDuration-dayMovieOut;
        nightVideoFiles[currentMovie].stop();
     }
     
     if (fade) {
        crossFade(dayVideoFiles[currentMovie],dayVideoFiles[nextMovie]);   
        if (fadeFloor >= 255){ // out of bounds for tint() so fade is finished
          dayVideoFiles[currentMovie].stop();
          currentMovie = nextMovie;
          nextMovie = getNextMovie();
          fadeFloor  = 0;
          fade = false;
          if (debug) println("Fade finished");
         //Recreate the SunriseSunset object to check the time of day and so choose what media to play next
          updateTime();           }  
      } else { // fade = false
        // run the current movie  
        runVideo(dayVideoFiles[currentMovie]);  
        if (int(dayVideoFiles[currentMovie].time()) > movieTransitionPoint){
             // get the destination video rolling  
             dayVideoFiles[nextMovie].play();
             movieTransitionPoint = dayTimeDuration[nextMovie]-dayMovieOut;
             dayVideoFiles[nextMovie].goToBeginning(); 
             dayVideoFiles[nextMovie].jump(dayMovieIn);           
             if (debug) println("Set to play: Day movie No: "+nextMovie+" Duration = "+dayTimeDuration[nextMovie]+" secs. with a transition at: "+movieTransitionPoint+" secs.");   
             fade = true;
             if (debug) println("Fade initiated");
       }        
      }    
  } else {     // night time
    if (nightFirstRun) {
       daytime = false;
       nightFirstRun = false;
       dayFirstRun = true;
       timerStart = millis(); // initialise the timer
       nightVideoFiles[currentMovie].play();
       nightVideoFiles[currentMovie].goToBeginning(); 
       movieDuration = nightTimeDuration[currentMovie];
       movieTransitionPoint = movieDuration-nightMovieOut;        
       dayVideoFiles[currentMovie].stop();
    }   
    // check for sensor
    if (sensorDetected) {
      if (wakeUpSeq) { 
        // play the awake move
        dayVideoFiles[currentMovie].play();
        dayVideoFiles[currentMovie].goToBeginning(); 
        while(dayVideoFiles[currentMovie].ready() == false);
        // initiate a fade from night video to corrosponding day video
        crossFade(nightVideoFiles[currentMovie],dayVideoFiles[currentMovie]);
        if (fadeFloor >= 255){ // out of bounds for tint() so fade is finished
          nightVideoFiles[currentMovie].stop();
          movieTransitionPoint = dayTimeDuration[currentMovie]-nightMovieOut;
          dayVideoFiles[currentMovie].play();
          while(dayVideoFiles[currentMovie].ready() == false);
          dayVideoFiles[currentMovie].goToBeginning();
          fadeFloor  = 0;
          wakeUpSeq = false;
          awakeSeq = true;
          if (debug) println("Asleep to awake fade finished");
          if (debug) println("Now awake");
        } 
      }
      
      if (awakeSeq) {
          runVideo(dayVideoFiles[currentMovie]);       
         if (int(dayVideoFiles[currentMovie].time()) > movieTransitionPoint){
           awakeSeq = false;
           fallAsleepSeq = true;
           if (debug) println("Awake sequence finished");           
         }
      }
      
      if (fallAsleepSeq) {
        // play the asleep move
        nightVideoFiles[currentMovie].play();
        nightVideoFiles[currentMovie].goToBeginning(); 
        movieTransitionPoint = nightTimeDuration[currentMovie]-nightMovieOut;
        while(nightVideoFiles[currentMovie].ready() == false);
        // initiate a fade back from day video to corrosponding night video        
        crossFade(dayVideoFiles[currentMovie],nightVideoFiles[currentMovie]);
        if (fadeFloor >= 255){ // out of bounds for tint() so fade is finished
          dayVideoFiles[currentMovie].stop();
          fadeFloor = 0;
          awakeSeq = false;
          timerStart = millis(); // reset the sensor time and give a few more seconds of alseep play
          fallAsleepSeq = false;
          sensorDetected = false;
          state = 0;
          if (debug) println("Awake to asleep fade finished");
        }       
      }  
    } else { // sensor-not-detected
      if (fade) {
          // then initiate a fade
          crossFade(nightVideoFiles[currentMovie],nightVideoFiles[nextMovie]);
          if (fadeFloor >= 255) { // out of bounds for tint() so fade is finished
            nightVideoFiles[currentMovie].stop();
            currentMovie = nextMovie;
            nextMovie = getNextMovie();
            fadeFloor = 0;
            fade = false;
            if (debug) println("Fade finished");
            //Recreate the SunriseSunset object to check the time of day and choose what media to play next
            updateTime();
          }
        } else {
          // run the current movie  
          runVideo(nightVideoFiles[currentMovie]);  
          
             // check for sensor
             if (arduino) while(port.available() > 0) state = port.read();       
             if (state == 72) {
               int timeNow = millis();
               if (timeNow - timerStart > sensorPoll) {
                 port.clear();
                 timerStart = millis(); // reset the timer
                 sensorDetected = true;
                 wakeUpSeq = true;
                 state = 0;
               } 
             }
             if (int(nightVideoFiles[currentMovie].time()) > movieTransitionPoint){
                 // get the destination video rolling           
                 nightVideoFiles[nextMovie].play();
                 nightVideoFiles[nextMovie].goToBeginning(); 
                 while(nightVideoFiles[nextMovie].ready() == false);
                 movieTransitionPoint = nightTimeDuration[nextMovie]-nightMovieOut;
                 fade = true;
                 if (debug) println("Fade initiated");       
              }   
            } // end if-fade   
     } // end if-sensor-detected      
   }   
  showOSD(); 
  if (arduino && stats) LEDmatrix.printStats();
}


