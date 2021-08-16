//set program ID
uint16_t programIDint = 1000; //controller 1000 (thermoV2 controller)
uint8_t programNum = 1; //controller #1
uint8_t versionID = 1; //V1

bool rundemo = 0; //for testing controller without scripts

//include necessary libraries
#include "SPI.h"

//pinouts
uint8_t relayPins[4] = {2, 3, 4, 5};
uint8_t sensorPins[4] {A1, A2, A0, A3};
#define CS 10 //chip-select
//#define TFT_MOSI 11 //no need to define SPI pins unless you use non-hardware SPI pins
//#define TFT_MISO 12
//#define TFT_CLK 13

typedef union {
  float floatingPoint;
  byte binary[4];
} binaryFloat;

typedef union {
  int integer;
  byte binary[2];
} binaryInt;

typedef union {
  unsigned long longInteger;
  byte binary[4];
} binaryLong;

//initialize variables
uint8_t pin, commandID, tmp, i;
int sensorVal;
binaryLong timestamp;
binaryFloat dur;
binaryInt programID;
unsigned long startTime, sentTime;
int readDelay = 10;
bool endCommand = 0;


//setup (runs once)
void setup() {
  programID.integer = programIDint;
  Serial.begin(57600);

  //set output pins
  for (i=0;i<8;i++) {
      pinMode(relayPins[i], OUTPUT);
      delay(1);
      digitalWrite(relayPins[i], HIGH);
  }

}


//wait for desired amount of available serial data bytes
void wait4Serial(int wait, int num2wait4) {
  while (Serial.available()<num2wait4) {
    delay(wait);
  }
}

bool check4end() {
  //end current command if stop command is recieved
  endCommand = 0;
  if (Serial.available()>0) {
    if (Serial.peek()==200) {
      endCommand = 1;
      commandID = Serial.read();
      Serial.write(commandID);
      timestamp.longInteger = millis();
      Serial.write(timestamp.binary,4);
    } 
  }
  //end current command if duration is reached
  if ((dur.floatingPoint>0) && ((millis()-startTime)>=(dur.floatingPoint*1000)-1)) {
    endCommand = 1;
  }
  return endCommand;
}
void runDemo() {
  while (1) { //repeat indefinitely
    Serial.println("Testing relays");
    Serial.print("Pins: ");
    for (i=0;i<4;i++) {
      digitalWrite(relayPins[i], LOW);
      Serial.print(relayPins[i]);
      Serial.print(" ");
      delay(500);
      digitalWrite(relayPins[i], HIGH);
    }
    Serial.println("");

    Serial.println("Testing sensors");
    Serial.print("Pins: ");
    for (i=0;i<4;i++) {
      sensorVal = analogRead(sensorPins[i]);
      Serial.print(i);
      Serial.print(": ");
      Serial.print(sensorVal);
      Serial.print("    ");
    }
    Serial.println("");
    delay(1000);
  }
}


void loop() { //main program loop
  if (rundemo==1) {runDemo();} //self-explanatory, right?
  
  //wait for incoming instructions over serial connection
  wait4Serial(readDelay, 1); //wait for (at least) 1 available byte
  
  //read incoming command and data over serial
  commandID = Serial.read(); //read incoming message ID byte (specifies what data is coming next)
  switch (commandID) {
    case 0: //command to send version ID back over serial
      Serial.write(commandID);
      Serial.write(programID.binary,2); //send program ID as 2 bytes
      Serial.write(programNum);
      Serial.write(versionID);
      break;
      
    case 1: //send timestamp
      Serial.write(commandID);
      timestamp.longInteger = millis();
      Serial.write(timestamp.binary,4);
      break;
      
    case 120: //command to toggle a relay for a set duration
      wait4Serial(readDelay, 5); //wait for 5 available bytes

      //read parameters
      dur.binary[0] = Serial.read(); //byte 1
      dur.binary[1] = Serial.read(); //byte 2
      dur.binary[2] = Serial.read(); //byte 3
      dur.binary[3] = Serial.read(); //byte 4
      pin = Serial.read(); //byte 5
      
      //send pattern parameters back for verification
      Serial.write(commandID);
      timestamp.longInteger = millis();
      Serial.write(timestamp.binary,4);
      Serial.write(dur.binary,4);
      Serial.write(pin);

      digitalWrite(relayPins[pin-1], LOW);
      delay(1000*dur.floatingPoint);
      digitalWrite(relayPins[pin-1], HIGH);
      break;


    case 122: //command to read the sensors for a set duration, until the first detection, or until stop command
      wait4Serial(readDelay, 4); //wait for 4 available bytes

      //read parameters
      dur.binary[0] = Serial.read(); //byte 1
      dur.binary[1] = Serial.read(); //byte 2
      dur.binary[2] = Serial.read(); //byte 3
      dur.binary[3] = Serial.read(); //byte 4

      //send pattern parameters back for verification
      Serial.write(commandID);
      timestamp.longInteger = millis();
      Serial.write(timestamp.binary,4);
      Serial.write(dur.binary,4);

      startTime = millis();
      endCommand = check4end();
      while (endCommand==0) {
        timestamp.longInteger = millis();
        for (i=0;i<4;i++) {
          sensorVal = analogRead(sensorPins[i]);
          if ((sensorVal<512) && ((millis()-sentTime)>500)){
            Serial.write(152);
            Serial.write(timestamp.binary,4);
            Serial.write(i+1);
            sentTime = millis();
            break;
          }
        }
        delay(2);
        endCommand = check4end();
      }
      break;


    case 200: //stop command recieved
      Serial.write(commandID);
      timestamp.longInteger = millis();
      Serial.write(timestamp.binary,4);
      break;

      
    default: //send back unknown command
      Serial.write(commandID);
      timestamp.longInteger = millis();
      Serial.write(timestamp.binary,4);
      Serial.print("unknown bytes: ");
      while (Serial.available()>0) {
        tmp = Serial.read();
        Serial.print(tmp);
        Serial.print(" ");
      }
      Serial.print("\n");
      break;
  }
}
//loop end
