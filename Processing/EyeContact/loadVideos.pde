GSMovie[] dayVideoFiles = new GSMovie[0];
GSMovie[] nightVideoFiles = new GSMovie[0];

int[] dayTimeDuration;
int[] nightTimeDuration;

//String dayVideoFileListTxt = "dayVideoFileList.txt.clr";
//String nightVideoFileListTxt = "nightVideoFileList.txt.clr";
String dayVideoFileListTxt = "dayVideoFileList.txt";
String nightVideoFileListTxt = "nightVideoFileList.txt";
//String dayVideoFileListTxt = "sensorDay.txt";
//String nightVideoFileListTxt = "sensorNight.txt";

String[] dayVideoFileList = new String[0];
String[] nightVideoFileList = new String[0];

void setupVideoFiles() {
  loadVideoFileLists();
  int totalDayFiles = dayVideoFileList.length;
  int totalNightFiles = nightVideoFileList.length;
  // apply sizes to the duration arrays
  dayTimeDuration = new int[totalDayFiles];
  nightTimeDuration = new int[totalNightFiles];
  for(int i=0; i<totalDayFiles; i++) {
    loadDayVideoFile(dayVideoFileList[i]);
  }
  for(int i=0; i<totalNightFiles; i++) {
    loadNightVideoFile(nightVideoFileList[i]);
  }
}

// reads the text files on disk and loads each line into an array of filenames
void loadVideoFileLists() {
  dayVideoFileList = loadStrings(path+dayVideoFileListTxt);
  nightVideoFileList = loadStrings(path+nightVideoFileListTxt);
}


// creates and appends a new GSMovie object (for each video file) to the array of video objects 
// and appends each video's duration to a corrosponding array of durations
void loadDayVideoFile(String fileName) {
  String URL = path+fileName;
  dayVideoFiles = (GSMovie[])append(dayVideoFiles, new GSMovie(this, URL));
  int index = dayVideoFiles.length-1;
  dayVideoFiles[index].play(); 
  while (dayVideoFiles[index].ready() == false);
  dayTimeDuration[index] = int(dayVideoFiles[index].duration());
  dayVideoFiles[index].stop(); 
  println("loaded: "+fileName);
}

void loadNightVideoFile(String fileName) {
  String URL = path+fileName;
  nightVideoFiles = (GSMovie[])append(nightVideoFiles, new GSMovie(this, URL));
  int index = nightVideoFiles.length-1;
  nightVideoFiles[index].play(); 
  while (nightVideoFiles[index].ready() == false);
  nightTimeDuration[index] = int(nightVideoFiles[index].duration());
  nightVideoFiles[index].stop(); 
  println("loaded: "+fileName);
}

