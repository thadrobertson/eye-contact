void keyPressed() {
  
        if(key == 'R'){
          Rmax += 1;
          if (Rmax >= 255) Rmax = 255;
          if (arduino) LEDmatrix.setGamma(Rmin, Rmax, Rgam, Gmin, Gmax, Ggam, Bmin, Bmax, Bgam);
          println(Rmax);
        }  
       
          if(key == 'r'){
          Rmax -= 1;
          if (Rmax <= 0) Rmax = 0;
          if (arduino) LEDmatrix.setGamma(Rmin, Rmax, Rgam, Gmin, Gmax, Ggam, Bmin, Bmax, Bgam);
                    println(Rmax);

        }  
       
        
    //   }
       
       
  if (allowKeys) {
    
        if (key == CODED){
      if (keyCode == UP) {

       }
      if (keyCode == DOWN) { 
       // if (key == 'r'){
         if(keyEvent.isShiftDown()){
           println("RRR");
       }
       // }
        
        }
        //if (arduino) LEDmatrix.setGamma(Rmin, Rmax, Rgam, Gmin, Gmax, Ggam, Bmin, Bmax, Bgam);

      }
      if (keyCode == LEFT) { 
      
      }
      if (keyCode == RIGHT) { 
     
      }
    }
    

    // Skip to n seconds before end of currently playing video
    if(key == 'n' | key == 'N'){
      if (debug) println("Skipping to "+int(skipToTime)+" seconds from end of this video");
      if (daytime | awakeSeq) { 
        dayVideoFiles[currentMovie].jump(dayVideoFiles[currentMovie].duration()-skipToTime);
      } else {
        nightVideoFiles[currentMovie].jump(nightVideoFiles[currentMovie].duration()-NightSkipToTime);
      }
     }
    
    // Toggle Pause
    if(key == 'p' | key == 'P'){
      if (daytime | awakeSeq) { 
        if (dayVideoFiles[currentMovie].isPaused()) {
        if (debug) println("Playing video");
        dayVideoFiles[currentMovie].play();
      } else {
        if (debug) println("Video pause");
        dayVideoFiles[currentMovie].pause();      
      }        
     } else {
      if (nightVideoFiles[currentMovie].isPaused()) {
        if (debug) println("Playing video");
        nightVideoFiles[currentMovie].play();
      } else {
        if (debug) println("Video pause");
        nightVideoFiles[currentMovie].pause();      
      }        
     }
    }
    
    // Toggle on-screen status display
    if(key == 'o' | key == 'O'){
      osd = !osd;
      if (debug) println("Screen status is: "+osd);
    }
    
    // Toggle Day/Night mode
    if(key == 't' | key == 'T'){
      daytime = !daytime;
      if (daytime) dayFirstRun = true;
      if (!daytime) nightFirstRun = true;
      if (debug) println("Daytime mode is: "+daytime);
    }
    
    // Toggle debug info
    if(key == 'd' | key == 'D'){
      debug = !debug;
    }
    
    // Simulate a sensor input
    if(key == 's' | key == 'S'){
      if (!daytime) {
        if (!sensorDetected) {
          if (okToSense) {
            timerStart = millis();
            sensorDetected = true;
            wakeUpSeq = true;
            if (debug) println("Simulated sensor input");
          } else {
            if (debug) println("In tail of asleep awake sequence. Can't sense.");          
          }
        } else {
          timerStart = millis();
          if (debug) println("Sensor already triggered");
        }
      } else {
        if (debug) println("The sensor only works in night mode");
      }           
    }
  }

