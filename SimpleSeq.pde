//////////////////////////////////////////////
//
//  SimpleSeq v.1.0 (2011-11-09)
//   - by Trey Norman
//   - based on design and firmware of Michael Roebbeling's "SimplenZAR"
//
//////////////////////////////////////////////

#include <EEPROM.h>        // Include EEPROM library for saving presets (memory addresses 0-422); 512 memory slots total; (memory addresses 423-511 left over)

const int stepLed1 = 6; 
const int stepLed2 = 7;
const int stepLed3 = 8; 
const int stepLed4 = 9;
const int stepLed5 = 10; 
const int stepLed6 = 11;
const int stepLed7 = 12;
const int stepLed8 = 13;

const int modeLed1 = 3;
const int modeLed2 = 4;
const int modeLed3 = 5;

  
  int pos1 = 1;
  int pos2 = 1;
  int pos3 = 1;
  
  int stepPosi = 1;
  int workPosi = 1;
  int stepLength = 8;
  
  int beat = 120;                     // BPM
  int delayMS = (60000 / (beat*4));   // milliseconds of delay = # miliseconds in a minute divided by (BPM x 4); assumes (1 beat = 4 steps)
  
  int note[17];  //0 off / 1 on
  int note2[17];  //0 off / 1 on
  int pitch[17]; //starting at C3 -> Hex 30
  int pitch2[17]; //starting at C3 -> Hex 30
  int velo[17];  // 0 - 127
  int velo2[17]; // 0 - 127
  int prevPitch; //used to start the next enabled note at the last pitch selected
  
  int oldnote[17];  //To stop old note
  int oldnote2[17];  //To stop old note
  
  int shift[9];  //amount of shift from the basenote
  
  int mode = 7; //mode 1 = voice1 note on/off 
                //mode 2 = voice1 pitch
                //mode 3 = velocity
                //mode 4 = voice2 note on/off
                //mode 5 = voice2 pitch
                //mode 6 = voice2 velocity
                //mdoe 7 = back
                
  int button1 = A1; //<SELECT-R> Analogpin 1
  boolean button1Pressed = false; //Shows if Button 1 was pressed
  boolean button1State = false;  //Was there a state change?
  int button2 = A2; //<ENTER> Analogpin 2
  boolean button2Pressed = false; //Shows if Button 2 was pressed
  boolean button2State = false;  //Was there a state change?
  int button3 = A3; //<SELECT-L> Analogpin 3
  boolean button3Pressed = false; //Shows if Button 3 was pressed
  boolean button3State = false;  //Was there a state change?
  boolean oneThreePressed = false;  //Shows if Buttons 1&3 were pressed simultateously
  boolean oneThreeState = false;   //Was there a state change?
  boolean oneTwoPressed = false;  //Shows if Buttons 1&2 were pressed simultateously
  boolean oneTwoState = false;   //Was there a state change?
  boolean twoThreePressed = false;  //Shows if Buttons 2&3 were pressed simultateously
  boolean twoThreeState = false;   //Was there a state change?
  int pot1 = A0; // Analogpin 0
  int potposition;
  int programpos = 1;
  int presetCount = 0;   // How many times has enter been pressed when storing preset (2x to store in EEPROM)
  boolean edit = false;  // LED will blink in Edit mode
  
  int menupos = 0;     // menu  0=normal play&edit 
                       // 1=change tempo
                       // 2=change steps (8-16-shift)
                       // 3=memory read
                       // 4=memory write
                       
  int submenupos = 1; // used in menupos2 to select play mode, and in menupos3&4 to select memory preset
                     
  //int stepdirection = 1;  // 1 = forward, 2 reverse, 3 bounce MAYBE IN THE FUTURE

  int shiftpos = 1;            // position incremented after each step
  
  boolean mute = false;           // Used to mute note playback when setting MIDI control parameters (e.g. in Ableton Live)
  boolean menuactive = false;     // If Menu Active, allow selection of menu items 
  boolean menuon = false;         // Menumodus
  boolean shifting = false;       // shift modus on/off
  boolean memWriteArmed = false;     // can only write to memory if true (<ENTER> must be pressed twice)
  boolean midiCCon = false;       // for using pot1 to send MIDI CC (control) messages
  boolean midiCCactive = false;   // If MIDI CC active, send MIDI CC messages
  int midiCC = 0x01;              // Which MIDI control value to use?
  
  int basenote;
  
  int shift816 = 1;            // indicator for 8/16 steps or Shifting, default 8 steps
  
  int ledSetCount = 0;         // used for flashing LEDs on/off; found in main loop under "Final - Set LEDs" section
  
  long prevCheckMS = 0;        // keeps track of last time buttons were checked
  long prevLedMS = 0;          // keeps track of last time LEDs were set
  long prevPlayMS = 0;         // keeps track of last time notes were played

void setup()
{
  // set the digital pin for the 8 step leds
  pinMode(stepLed1, OUTPUT);
  pinMode(stepLed2, OUTPUT);
  pinMode(stepLed3, OUTPUT);
  pinMode(stepLed4, OUTPUT);
  pinMode(stepLed5, OUTPUT);
  pinMode(stepLed6, OUTPUT);    
  pinMode(stepLed7, OUTPUT);
  pinMode(stepLed8, OUTPUT);   
  
  pinMode(modeLed1, OUTPUT);
  pinMode(modeLed2, OUTPUT);
  pinMode(modeLed3, OUTPUT);
  
  pinMode(button1, INPUT);
  pinMode(button2, INPUT);  
  pinMode(pot1, INPUT);
  
  // cool looking boot sequence 
  digitalWrite(modeLed1, HIGH);
  digitalWrite(modeLed2, HIGH);
  digitalWrite(modeLed3, HIGH);
  
  for(int i = 0; i <= 3; i++)
  {
    digitalWrite(10+i, HIGH);
    digitalWrite(9-i, HIGH);
    delay(250);
  }
  
  for(int led = 13; led >= 6; led--)
  {
    digitalWrite(led, LOW);
    delay(100);
  }
  
  digitalWrite(5, LOW);
  digitalWrite(4, LOW);
  digitalWrite(3, LOW);
 
  
  // initialization of step parameter
  for (int a = 1; a <= 16; a++)
  {
    note[a]=0;
    note2[a]=0;
    pitch[a]=0;
    pitch2[a]=0;
    velo[a]=60;
    velo2[a]=60;
  }
  
  for (int a = 1; a <= 8; a++)
   shift[a]=0;
  
  // 1st Note as index 
  note[1]=1;
  pitch[1]=0;
  velo[1]=55;
  
 Serial.begin(31250); //Baudrate for Midi 
// Serial.begin(9600); //Baudrate for Serial communication = Debugging
  

}




void memRead(int preset)
{
  noteOn(0x80, oldnote[stepPosi], 0);        //Turn note off
  noteOn(0x80, oldnote2[stepPosi], 0);       //Turn note off
  
  int addr;    //Incremented to keep track of EEPROM address
  switch (preset)
  {
    case 1:
    addr = 0;              //For Preset 1, first memory address used is address 0
    break;
    
    case 2:
    addr = 141;            //For Preset 2, first memory address used is address 141
    break;
       
    case 3:
    addr = 282;            //For Preset 3, first memory address used is address 282
    break;
       
  }
  
  //The following comments are for the Preset 1 case; add 141 for Preset 2, 282 for Preset 3
  
  beat = EEPROM.read(addr);         //BPM stored at address 0
  delayMS = (60000 / (beat*4));     // delayMS = # miliseconds in a minute divided by (BPM x 4); assumes (1 beat = 4 steps)
  addr++;

  for (int x = 1; x <= 16; x++)     //All values for notes, pitches, and velocities are interlaced in addresses 1-8 for step1, 9-16 for step2, ... , 113-128 for step16
  {
    note[x] = EEPROM.read(addr);
    addr++;
    note2[x] = EEPROM.read(addr);
    addr++;
    pitch[x] = EEPROM.read(addr);
    addr++;
    pitch2[x] = EEPROM.read(addr);
    addr++;
    velo[x] = EEPROM.read(addr);
    addr++;
    velo[x] = EEPROM.read(addr);
    addr++;
    oldnote[x] = EEPROM.read(addr);
    addr++;
    oldnote2[x] = EEPROM.read(addr);
    addr++;
  }
    
  for (int x = 1; x <= 8; x++)
  {
    shift[x] = EEPROM.read(addr);      //Amount of shift stored at addresses 129-136
    addr++;
  }
  
  prevPitch = EEPROM.read(addr);       //prevPitch stored at address 137
  addr++;
  stepLength = EEPROM.read(addr);      //stepLength stored at address 138
  addr++;
  shift816 = EEPROM.read(addr);        //shift816 stored at address 139
  addr++;
  
  if (EEPROM.read(addr) == 1)          //shifting stored at address 140 (0 for "false" 1 for "true")
    shifting = true;
  else
    shifting = false;
}




void memWrite(int preset)
{
  int addr;                       //Incremented to keep track of EEPROM address
  switch (preset)
  {
    case 1:
    addr = 0;              //For Preset 1, first memory address used is address 0
    break;
    
    case 2:
    addr = 141;            //For Preset 2, first memory address used is address 141
    break;
       
    case 3:
    addr = 282;            //For Preset 3, first memory address used is address 282
    break;
       
  }

  //The following comments are for the Preset 1 case; add 141 for Preset 2, 282 for Preset 3

  EEPROM.write(addr, beat);       //BPM stored at address 0
  addr++;
  
  for (int x = 1; x <= 16; x++)   //All values for notes, pitches, and velocities are interlaced in addresses 1-8 for step1, 8-16 for step2, ... , 113-128 for step16
  {
    EEPROM.write(addr, note[x]);
    addr++;
    EEPROM.write(addr, note2[x]);
    addr++;
    EEPROM.write(addr, pitch[x]);
    addr++;
    EEPROM.write(addr, pitch2[x]);
    addr++;
    EEPROM.write(addr, velo[x]);
    addr++;
    EEPROM.write(addr, velo2[x]);
    addr++;
    EEPROM.write(addr, oldnote[x]);
    addr++;
    EEPROM.write(addr, oldnote2[x]);
    addr++;
  }
  
  for (int x = 1; x <= 8; x++)
  {
    EEPROM.write(addr, shift[x]);      //Amount of shift stored at addresses 129-136
    addr++;
  }
  
  EEPROM.write(addr, prevPitch);       //prevPitch stored at address 137
  addr++;
  EEPROM.write(addr, stepLength);      //stepLength stored at address 138
  addr++;
  EEPROM.write(addr, shift816);        //shift816 stored at address 139
  addr++;
  
  if (shifting == true)                 //shifting stored at address 140 (0 for "false" 1 for "true")
    EEPROM.write(addr, 1);
  else
    EEPROM.write(addr, 0);
}




void ledSet(int steppos, int workpos, int mode, int meunpos, int shiftpos, boolean shifting)
{
  int workpos2, steppos2;
  int invert = 0;                           // if workpos >8 invert modes
   // All LEDs OFF
  for(int x = 3; x < 14; x++)               //digital outputs 6 - 14 for step leds, 3-5 mode leds
    digitalWrite(x, LOW);
  
  if (menupos > 0)                          //Menu is turned on
  {
                                            //Menuindication  
     digitalWrite(2+mode, HIGH);            //Sets Mode runlight
     digitalWrite(5+menupos, HIGH);         //Sets Menuposition
     
     switch(submenupos)
     {
       case 1:
       digitalWrite(11, HIGH);              //6th LED for 8 Steps
       break;
       
       case 2:
       digitalWrite(12, HIGH);              //7th LED for 16 setps 
       break;
       
       case 3:
       digitalWrite(13, HIGH);              //8th LED for Shifting 
       break;
       
     }
  }
  else //Normal work -> no Menu active
  {
  
    //set Step LED 
    if (((steppos > 8) && (workpos > 8))||((steppos < 9)&&(workpos < 9))) // if Step and work are in the same 8 steps
    {
      if(steppos > 8)
        steppos = steppos-8;
        
      digitalWrite(5+steppos, HIGH);  
    }
    
    // Shift LED on
    if (workpos > 8 && shifting == true)
       digitalWrite(5+shiftpos, HIGH);
    
    // workpos set
    if(workpos > 8)
    {
        workpos = workpos-8;
        invert = 1;
    }
    
    digitalWrite(5+workpos, HIGH); 
    
    
       
      
      
    
    // mode set
    if(programpos>2)
    {
       if(edit == true) 
       {
          if (((invert == 0) && ((mode == 1) || (mode == 4) || (mode == 6))) || ((invert == 1) && ((mode == 2) || (mode == 3) || (mode == 5))))            // note on-off
            digitalWrite(5, HIGH);   // pin 5
          if (((invert == 0) && ((mode == 2) || (mode == 4) || (mode == 5))) || ((invert == 1) && ((mode == 1) || (mode == 3) || (mode == 6))))            // pitch
            digitalWrite(4, HIGH);   // pin 4
          if (((invert == 0) && ((mode == 3) || (mode == 5) || (mode == 6))) || ((invert == 1) && ((mode == 1) || (mode == 2) || (mode == 4))))            // velocity
            digitalWrite(3, HIGH);   // pin 3
          edit = false;
       }
       else
         edit = true;
    }
    else 
    {
      if (((invert == 0) && ((mode == 1) || (mode == 4) || (mode == 6))) || ((invert == 1) && ((mode == 2) || (mode == 3) || (mode == 5))))            // note on-off
        digitalWrite(5, HIGH);   // pin 5
      if (((invert == 0) && ((mode == 2) || (mode == 4) || (mode == 5))) || ((invert == 1) && ((mode == 1) || (mode == 3) || (mode == 6))))            // pitch
        digitalWrite(4, HIGH);   // pin 4
      if (((invert == 0) && ((mode == 3) || (mode == 5) || (mode == 6))) || ((invert == 1) && ((mode == 1) || (mode == 2) || (mode == 4))))            // velocity
        digitalWrite(3, HIGH);   // pin 3
      if ((mode==7)&&(invert ==1)) //if no mode choosen and workpos >8, invert
      {
        digitalWrite(5, HIGH);   // pin 5
        digitalWrite(4, HIGH);   // pin 4
        digitalWrite(3, HIGH);   // pin 3
      }
    }
  }
}





void noteOn(int cmd, int pitch, int velocity)
{
  if (mute)                      // all note velocities set to 0 when muted
  {
    Serial.print(cmd, BYTE);
    Serial.print(pitch, BYTE);
    Serial.print(0, BYTE);
  }
  else
  {
    Serial.print(cmd, BYTE);
    Serial.print(pitch, BYTE);
    Serial.print(velocity, BYTE);
  }
}




void checkbuttons()
{

  //Button 1 <SELECT-R>
  if(digitalRead(button1)&&button1Pressed==false)
  {
    button1Pressed = true;
    button1State = true;
  }
  else if (button1Pressed == true&&digitalRead(button1)==false)
    button1Pressed = false;  
    
  //Button2 <ENTER>
  if(digitalRead(button2)&&button2Pressed==false)
  {
    button2Pressed = true;
    button2State = true; 
  }
  else if (button2Pressed == true&&digitalRead(button2)==false)
    button2Pressed = false;
    
  //Button 3 <SELECT-L>
  if(digitalRead(button3)&&button3Pressed==false)
  {
    button3Pressed = true;
    button3State = true;
  }
  else if (button3Pressed == true&&digitalRead(button3)==false)
    button3Pressed = false;
    
  //Buttons 1&3 <MENU>
  if(digitalRead(button1)&&digitalRead(button3)&&oneThreePressed==false)
  {
    oneThreePressed = true;
    oneThreeState = true;    
  }
  else if (oneThreePressed == true&&digitalRead(button1)==false&&digitalRead(button3)==false)
    oneThreePressed = false;
    
  //Buttons 1&2 <MIDI-CC>
  if(digitalRead(button1)&&digitalRead(button2)&&oneTwoPressed==false)
  {
    oneTwoPressed = true;
    oneTwoState = true;    
  }
  else if (oneTwoPressed == true&&digitalRead(button1)==false&&digitalRead(button2)==false)
    oneTwoPressed = false;
    
  //Buttons 2&3 <MUTE>
  if(digitalRead(button2)&&digitalRead(button3)&&twoThreePressed==false)
  {
    twoThreePressed = true;
    twoThreeState = true;    
  }
  else if (twoThreePressed == true&&digitalRead(button2)==false&&digitalRead(button3)==false)
    twoThreePressed = false;
    

}

void loop()
{

//---------------------------------------------
//---------- Play the next note ---------------
//---------------------------------------------

  if (millis() - prevPlayMS > delayMS)
  {
    
    noteOn(0x80, oldnote[stepPosi], 0);        //Turn note off
    noteOn(0x80, oldnote2[stepPosi], 0);        //Turn note off
                                                //Next step calculation
    stepPosi++;
    
    if (stepPosi > stepLength)
    {
      stepPosi = 1;
      shiftpos++;                               //after 8 Steps shiftposition +1
      if (shiftpos > 8)                         // There are 8 shift positions
        shiftpos=1;
    }
      
                                                //Check if shift is on
    if(shifting)
       basenote = 0x30+shift[shiftpos];         //Basenote incremented by Shift value
    else
      basenote = 0x30;                          //Basenote stays at hex30
      
      
                                                // Now we Play the note of the step
  
    if (note[stepPosi])                         // If Note is on, we play the note
    {
  
      noteOn(0x90, basenote+pitch[stepPosi], velo[stepPosi]);
      oldnote[stepPosi]=basenote+pitch[stepPosi];  // Save the note, to turn it off for the next step
    }
    
    if (note2[stepPosi])                         // If Note is on, we play the note
    {
  
      noteOn(0x90, basenote+pitch2[stepPosi], velo2[stepPosi]);
      oldnote2[stepPosi]=basenote+pitch2[stepPosi];  // Save the note, to turn it off for the next step
    }
    
    prevPlayMS = millis();
    
  }    
    
      //----------------------------------------------------
      //----------------- Set LEDs -------------------------
      //----------------------------------------------------
      
      if (millis() - prevLedMS > 25)             // Only allow LEDs to change every 25ms
      { 
        if(menuon && menuactive==false)          // running mode LEDs inside menu level
        {
          ledSetCount++;
          
          if(ledSetCount%4 == 0)
            mode++;
          
          if(mode>3)
          {
            mode=1;
            ledSetCount=0;
          }
              
          ledSet(stepPosi, workPosi, mode, menupos, shiftpos, shifting); 
        }
        
        if(menuon && menuactive)                // flashing step LEDs when menu item selected
        {
          ledSetCount++;
          
          if(ledSetCount%4 == 0)                // running mode LEDs inside menu
            mode++;
          
          if(mode>3)
            mode=1;
          
          if(ledSetCount<8)
          {
            ledSet(stepPosi, workPosi, mode, menupos, shiftpos, shifting);
            digitalWrite(5+menupos, LOW);
            digitalWrite(10+submenupos, LOW);
          }
          else if(ledSetCount>=8 && ledSetCount<16)
            ledSet(stepPosi, workPosi, mode, menupos, shiftpos, shifting);
          else
          {
            ledSetCount=0;
            ledSet(stepPosi, workPosi, mode, menupos, shiftpos, shifting);
          }
          
          if(memWriteArmed)                    // all step LEDs illuminated when memWriteArmed = true; warns user that preset is about to be overwritten
          {
            for(int x=6; x<14; x++)
              digitalWrite(x, HIGH);
          }
          
        }
        
        if(midiCCon && midiCCactive==false)
          ledSet(midiCC+8, midiCC+8, 7, menupos, shiftpos, false);  // step & work positions the same with all menu LEDs illuminated in MIDI CC mode
        
        if(midiCCon && midiCCactive)                                   // flash step LEDs illuminated when MIDI CC active
        {
          ledSetCount++;
          
          if(ledSetCount<8)
          {
            ledSet(midiCC+8, midiCC+8, 7, menupos, shiftpos, false);
          }
          else if(ledSetCount>=8 & ledSetCount<16)
          {
            for(int x=6; x<14; x++)
              digitalWrite(x, HIGH);
          }
          else
            ledSetCount=0;
        }
        
        if(midiCCon==false && menuon==false)
          ledSet(stepPosi, workPosi, mode, menupos, shiftpos, shifting);
         
        prevLedMS = millis(); 
      }
      
      //------------------------------------------------
      //--- Check the buttons and process them ---------
      //------------------------------------------------
    
      if (millis() - prevCheckMS > 50)
      {
        checkbuttons();   
        
        //--------------------------------------------Buttons 1&3 <MODE> is pressed, toggle menu
        if (oneThreePressed == true && oneThreeState == true)
        {
          if (menuon==false)                        // toggle menu
          {
            midiCCon=false;                         // Disable MIDI CC
            midiCCactive=false;
            mode=7;                                 // Mode to 7 (no LED)
            programpos=1;                           // Programmpos to 1 
            
            memWriteArmed=false;                      // Deactivate ability to write to memory
            
            menuon=true;
            menupos = 1;                            // Menu position to 1 
          }
          else                                      // was already on, will be off now
          {
            menuon=false;
            menupos = 0;                            // Menupos to 0
            mode=7;                                 // Mode to 7 (no LED)
            programpos=1;                           // Programmpos to 1 
            menuactive=false;                       // There is no Menu
          }
         button1State=false;                        // both buttons are processed
         button3State=false;
         oneThreeState=false;
        }
        
        //--------------------------------------------Buttons 1&2 <MIDI-CC> is pressed, toggle MIDI CC
        if (oneTwoPressed == true && oneTwoState == true)
        {
          if (midiCCon==false)                        // toggle MIDI CC on
          {
            menuon=false;                           // Disable menu
            menuactive=false;                       // There is no Menu
            menupos = 0;                            // Menupos to 0
            mode=7;                                 // Mode to 7 (no LED)
            programpos=1;                           // Programmpos to 1 
            
            memWriteArmed=false;                      // Deactivate ability to write to memory
            
            midiCCon=true;
            midiCCactive=false;
          }
          else                                      // was already on , will be off now
          {
            midiCCon=false;
            midiCCactive=false;
            mode=7;                                 // Mode to 7 (no LED)
            programpos=1;                           // Programmpos to 1 
          }
         button1State=false;                        // both buttons are processed
         button2State=false;
         oneTwoState=false;
        }
        
        //--------------------------------------------Buttons 2&3 <MUTE> is pressed, toggle note playing on/off
        if (twoThreePressed == true && twoThreeState == true)
        {
          if (mute)                                 // toggle mute
            mute=false;
          else                                      // was already on, will be off now
          {
            mute=true;
          }
         button2State=false;                        // both buttons are processed
         button3State=false;
         twoThreeState=false;
        }
        
        //----------------------------------------------Button 1 - <SELECT-R>
        if (button1Pressed==true && button1State==true)
        {
          if (memWriteArmed==true)
          {
            memWriteArmed=false;                      // Disable ability to write to memory
            menuactive=false;                         // Deactivate Menu
            submenupos=1;
          }
          
          if (menuon == true && menuactive == false)  // If in menumode and no menu is active
          {
             menupos++;                             // <SELECT-R> will scoll trough the menus
             if (menupos > 4)                       // 4 Menupos - Speed, 8/16/Shift, Memory Read, Memory Write
               menupos = 1;
               
             programpos = 0;
          }
          
          if (menuon == true && menuactive == true) //If in menumode and a menu is active
          {
            submenupos++;                           // <SELECT-R> will scoll trough the submenus
            if (submenupos > 3)                     // 3 Submenupos: play mode - step8,step16,shift8; memory read/write - presets 1,2,3
              submenupos = 1;
              
            programpos = 0;
          }
          
          if (midiCCon)                            // Scroll Right through MIDI CC options
          {
            if (midiCC < 0x08)
              midiCC++;
            else
              midiCC = 0x01;
            programpos = 0;
          }
          
                                                    // 1st program level - select moves the cursor
          if (programpos == 1)
          {  
            workPosi++;                             // If Shifing is off and workposi > steplengt back to 1
            if (shifting==false && workPosi > stepLength) 
              workPosi = 1;                         // If Shifting is on, there are 8 steps, if workposi > 8, Workposi is for Shifting
            if (shifting == true && workPosi >16)
              workPosi = 1;
          }
          
                                                     // 2nd program level - select changes the mode -1
          if (programpos == 2)
          {
            mode--;
            if (workPosi > stepLength && mode < 1)      // only one mode available for shifting
                mode = 7;
            if (mode<1)
              mode = 7;
          }
          
                                                       // 3rd,4th,5th,6th,7th,8th Program level - select moves back to 2 level  
          if (programpos > 2)
          {
            programpos = 2;
          }
          
                                                       // Buttonstate to false, button is processed
            button1State=false;
        }
        
        
        //--------------------------------------------------Button 2 - <ENTER>
        if (button2Pressed==true && button2State==true)
        {
          ledSetCount=0;
          
          if (menuon == true)                          // If in menu level
          {                                                 
             if (menuactive==false)                     // Menu is turned active 
             {                                          
               submenupos=1;                            // Submenu defaults to position 1
               menuactive=true;
             }
             else
             {
               // Note: menupos = 1 case => BPM - controlled by potentiometer
               
               if(menupos==2)          // <SELECT> cycles play modes, <ENTER> sets mode and deactivates menu
               {
                 if(submenupos==1)     // Change play mode to 8-Steps
                 {
                   stepLength=8;
                   shifting=false;
                   shift816=1;
                 } 
                 if(submenupos==2)     // Change play mode to 16-Steps
                 {
                   stepLength=16;
                   shifting=false;
                   shift816=2;
                 }              
                 if(submenupos==3)     // Change play mode to Shifting
                 {
                   shifting=true;                                        
                   stepLength=8;
                   shift816=3;
                 }           
               }
               
               if(menupos==3)           // <SELECT> cycles presets, <ENTER> loads preset and deactivates menu
                 memRead(submenupos);
     
               if(menupos==4)           // <SELECT> cycles presets, <ENTER> saves preset and deactivates menu
               {
                 if(memWriteArmed)
                 {
                   memWrite(submenupos);
                   memWriteArmed = false;
                   submenupos=1;
                   menuactive=false;
                 }
                 else
                   memWriteArmed = true;
               }           
               else
               {
                 submenupos=1;
                 menuactive=false;
               }
             }
             
             
             button2State=false;
          }
          
          if (midiCCon && button2State)                 // <ENTER> activates MIDI CC
          {
            if (midiCCactive)
              midiCCactive=false;
            else
              midiCCactive=true;
              
            programpos=1;
            button2State=false;
          }
                                                         // 1st program level - ENTER changes to Program level 2 
          if (programpos==1 && button2State==true)
          {  
             programpos=2;
             mode=1;
             button2State=false;
          }
          
                                                          // 2nd program level - Enter changes to program level 3,4,5,6,7,8 (Note on/off, Pitch, Velocity, Voice2 Note on/off, Voice2 Pitch, Voice2 Velocity)
          if (programpos==2 && button2State==true)
          {
            if (workPosi > stepLength && mode == 1)
                programpos = 3;                           // Change amount of shift
            else
            {
              if (mode == 1)
                programpos = 3;                             // Note on/off
              if (mode == 2)
                programpos = 4;                             // Pitch
              if (mode == 3)
                programpos = 5;                             // Velocity
              if (mode == 4)
                programpos = 6;                             // Voice2 Note on/off
              if (mode == 5)
                programpos = 7;                             // Voice2 Pitch
              if (mode == 6)
                programpos = 8;                             // Voice2 Velocity
            }
            
            if (mode == 7)                                // there is no Mode 7, is used to go back
              programpos = 1;                             // back
              
            button2State=false;                           // Button is processed
          }
          
                                                          // 3rd,4th,5th,6th,7th,8th Program level - ENTER will go back to level 2  
          if (programpos>2 && button2State==true)
          {
            programpos=2;
            button2State=false;                          // Button is processed
          }
         
        }
        
        
        //----------------------------------------------Button 3 - <SELECT-L>
        if (button3Pressed==true && button3State==true)
        {
          if (memWriteArmed==true)
          {
            memWriteArmed=false;                      // Disable ability to write to memory
            menuactive=false;                         // Deactivate Menu
            submenupos=1;
          }
          
          if (menuon == true && menuactive == false)  // If in menumode and no menu is active
          {
             menupos--;                             // <SELECT-L> will scoll trough the menus
             if (menupos < 1)                       // 4 Menupos - Speed, 8/16/Shift, Memory Read, Memory Write
               menupos = 4;
               
             programpos = 0;
          }
          
          if (menuon == true && menuactive == true) // If in menumode and a menu is active
          {
            submenupos--;                           // <SELECT-L> will scoll trough the submenus
            if (submenupos < 1)                     // 3 Submenupos: play mode - step8,step16,shift8; memory read/write - presets 1,2,3
              submenupos = 3;
              
            programpos = 0;
          }
          
          if (midiCCon)                            // Scroll Left through MIDI CC options
          {
            if (midiCC > 0x01)
              midiCC--;
            else
              midiCC = 0x08;
            programpos = 0;
          }
          
                                                    // 1st program level - select moves the cursor
          if (programpos == 1)
          {  
            workPosi--;                             // If Shifing is off and workposi < 1, back to stepLength
            if (shifting==false && workPosi < 1) 
              workPosi = stepLength;                         // If Shifting is on, there are 8 steps, if workposi < 1, Workposi is for Shifting
            if (shifting == true && workPosi < 1)
              workPosi = 16;
          }
          
                                                     // 2nd program level - select changes the mode +1
          if (programpos == 2)
          {
            mode++;
            if (workPosi > stepLength && mode > 1)      // only one mode available for shifting
                mode = 7;
            if (mode>7)
              mode = 1;
          }
                                                       // 3rd,4th,5th,6th,7th,8th Program level - select moves back to 2 level  
          if (programpos > 2)
          {
            programpos = 2;
          }
          
                                                       // Buttonstate to false, button is processed
            button3State=false;
        }
      
      
        //---------------------------------------------------
        //--- Potentiometer ---------------------------------
        //---------------------------------------------------
        if(programpos==3 && menupos==0 && workPosi <= stepLength)  // Note on/off mode
        {
          note[workPosi] = analogRead(pot1)/512;
          if(oldnote[workPosi] == 0)
            pitch[workPosi] = prevPitch;                           // Starts new note using previous pitch to keep everything in key
        }
        
        if(programpos==3 && menupos==0 && workPosi > stepLength)   // ATTENTION this is the change for basenote shifting
          shift[workPosi-8] = analogRead(pot1)/28 - 18;            // can shift up or down 18 half-steps from basenote (C2)
        
        if(programpos==4 && menupos==0)                            // Pitch mode
        {
          pitch[workPosi] = analogRead(pot1)/28;
          if(oldnote2[workPosi] == 0)
            prevPitch = pitch[workPosi];
        }
        
        if(programpos==5 && menupos==0)                            // Velocity mode
          velo[workPosi] = analogRead(pot1)/8;
          
        if(programpos==6 && menupos==0 && workPosi <= stepLength)  // Voice2 Note on/off mode
        {
          note2[workPosi] = analogRead(pot1)/512;
          pitch2[workPosi] = prevPitch;                            // Starts new note using previous pitch to keep everything in key
        }
        
        if(programpos==7 && menupos==0)                            // Voice2 Pitch mode
        {
          pitch2[workPosi] = analogRead(pot1)/28;
          prevPitch = pitch2[workPosi];
        }
        
        if(programpos==8 && menupos==0)                            // Voice2 Velocity mode
          velo2[workPosi] = analogRead(pot1)/8;
        
        if(menupos==1 && menuactive==true)                        // If menuactive and menu 1 chosen
        {
          beat = 60 + .2346*(analogRead(pot1));                   // set BPM (60 to 300) | .2346 = 1023/240
          delayMS = (60000 / (beat*4));                           // delayMS = # miliseconds in a minute divided by (BPM x 4); assumes (1 beat = 4 steps)
        }
          
        if(midiCCactive)                                          // Send pot value (0-127) to slected MIDI CC
        {
          Serial.print(0xB0, BYTE);
          Serial.print(midiCC, BYTE);
          Serial.print((analogRead(pot1)/8), BYTE);
        }
      
        prevCheckMS = millis();
      }
}
