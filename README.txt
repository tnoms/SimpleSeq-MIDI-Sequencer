///////////////////////////////////////////////////////
//
//SimpleSeq MIDI Sequencer
//
///////////////////////////////////////////////////////
//
//  Small manual: 
//
//  pushbutton 1 moves right <SELECT-R>, pushbutton 2 is enter <ENTER>, pushbutton 3 moves left <SELECT-L>
//
//  scroll trough the steps with <SELECT-L>||<SELECT-R>
//
//  pressing <ENTER> in sequence view (initial view) will take you to Mode Selection
//    - select note on/off, pitch, velocity for each voice by pressing <SELECT-L>||<SELECT-R>
//    - 7 modes total; the mode LEDs will show you the mode
//      * LED1 = (voice 1) note on/off
//      * LED2 = (voice 1) pitch
//      * LED3 = (voice 1) velocity
//      * LEDs inverted for voice 2
//      * No LED = exit mode selection, back to step scolling
//    - choose mode with <ENTER>
//    - adjust mode parameters with potentiometer
//
//  pressing <SELECT-L>&&<SELECT-R> simultaneously will take you to the Menu
//    - 4 menu options, indicated by the first 4 step LEDs
//    - 3 submenu items for each menu option, indicated by the last 3 step LEDs
//    - Menu/submenu breakdown
//      * 1st = change BPM
//        - <ENTER> to select
//        - all submenu items are the same
//        - <ENTER> again to change BPM with potentiometer
//      * 2nd = change play mode
//        - <ENTER> to select
//        - submenu items
//          * 1 = 8-Step sequence
//          * 2 = 16-Step sequence (step LEDs inverted for second 8 steps)
//          * 3 = Shift 8 (8-Step sequence repeated 8 times with ability to shift all notes up or down each time)
//            - edit shiftings with second 8 steps
//        - <ENTER> to choose submenu item
//      * 3rd = read preset from memory
//        - <ENTER> to select
//        - submenu items: presets 1, 2, 3
//        - <ENTER> to load preset
//      * 4th = write preset to memory
//        - <ENTER> to select
//        - submenu items: presets 1, 2, 3
//        - <ENTER> twice to write preset to memory
//  
//  pressing <SELECT-L>&&<ENTER> simultaneously will mute all notes (velocity=0)
//
//  pressing <ENTER>&&<SELECT-R> simultaneously will enter MIDI Control Mode (MIDI CC)
//  - used to control arbitrary functions (eg. delay, filter cutoff frequency, resonance, portamento, etc.)
//  - 8 MIDI CC values available, 0x01 to 0x08 (on most synthesizers 0x01 = modulation wheel)
//  - <ENTER> to write MIDI CC data
//    * value determined by potentiometer
//  - <ENTER> again to stop
//  - NOTE: when setting up MIDI CC on a device listening for a MIDI event (eg. Ableton Live),
//          it is helpful to mute all notes prior to writing MIDI CC data
//
//////////////////////////////////////////////