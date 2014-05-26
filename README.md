# Eye Contact

Low-res video wall with Processing, Arduino and WS2801s

## Description

This project creates a video wall by playing video with Processing and streaming RGB data via USB to a Teensy 2.0 running Arduino code. The Teensy interfaces through SDI with an array of WS2801 based LED pixels.

There are 342 pixels in an array of 38 x 9. Each pixel is actually made from 4 individual WS2801 modules running in parallel. We therefore are running 1368 LED modules, each with 6 RGB leds, so 8,208 LEDs in total. The pixels are at 300mm centres and the interconnects are 360mm long.

More information can be found at the [artist's website](http://www.peterdavidhudson.com/?p=51).

## Power

The LED modules are designed to run at 24v. A 2.5A 24V switchmode power supply resides at the base of each of the 38 coloumns. The power is supplied in parallel with anti feedback diodes placed at the +ve leg of each PSU.

## Operation

The display fades between video clips of eyes continuously on a 24/7 basis. Clips are chosen at random from a bank of around 60 files. Between the hours of dawn and sunset the eyes are awake. After sunset the system chooses from clips that show closed eyes. There is a sensor which causes the display to 'wake up' when activated. After some time the display again falls asleep.

A Java library is used to determine the sunrise and sunset times each day for the given location of the display.

### Video structure

There is a day video and a corresponding night video for each person's eyes. The day videos all start with about 13 seconds of the person asleep, leading to the person waking up and staying awake for an arbitrary time, then ending with about 13 seconds of the person falling asleep. For night videos, the person stays asleep for the entire length.

### Logic

In day mode, videos play from the 15 second mark and fade to the next video 15 seconds before their end. At night, videos play back to back until a sensor event occurs. At this time a fade to the head of the corresponding day video takes place, which then plays through its falling asleep phase before fading back to the corresponding night video.

## Sensor

The intended unit is the X-Band Motion Detector from Parallax. This doppler radar detector has been chosen because it is able to operate behind glass which is required for our application. This sensor operates by sending a digital HIGH at a frequency which increases as an object comes closer of moves past with some velocity. 

## Reference

- [Teensy 2.0](http://www.pjrc.com/store/teensy.html)
- [WS2801 LED pixel modules](http://led-studien.de/docs/RGB-Pixel_Datenblatt.pdf)
- [X-Band Motion Detector](http://www.parallax.com/product/32213)
- [SunriseSunset Java Lib](https://github.com/mikereedell/sunrisesunsetlib-java)
 