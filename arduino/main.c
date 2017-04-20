#include <SoftwareSerial.h>

SoftwareSerial btSerial(0, 1);

const int analogInPin = 7;   // Analog input pin that the potentiometer is attached to
const int analogInPin1 = 9;  // Analog input pin that the potentiometer is attached to
const int analogInPin2 = 10; // Analog input pin that the potentiometer is attached to
const int analogInPin3 = 11; // Analog input pin that the potentiometer is attached to

int sensorValue = 0;  // value read from the pot
int sensorValue1 = 0; // value read from the pot
int sensorValue2 = 0; // value read from the pot
int sensorValue3 = 0; // value read from the pot

void setup()
{
  // put your setup code here, to run once:
  Serial.begin(9600);
  pinMode(7, INPUT_PULLUP);
  pinMode(9, INPUT_PULLUP);
  pinMode(10, INPUT_PULLUP);
  pinMode(11, INPUT_PULLUP);
  btSerial.begin(9600);
}

void loop()
{
  // put your main code here, to run repeatedly:
  // read the analog in value:
  sensorValue = analogRead(analogInPin);
  sensorValue1 = analogRead(analogInPin1);
  sensorValue2 = analogRead(analogInPin2);
  sensorValue3 = analogRead(analogInPin3);

  // Header Byte
  btSerial.write(255);

  // Guaranteed to not hit header byte value
  unsigned char a = (unsigned char)(sensorValue / 4) - 2;
  unsigned char b = (unsigned char)(sensorValue1 / 4) - 2;
  unsigned char c = (unsigned char)(sensorValue2 / 4) - 2;
  unsigned char d = (unsigned char)(sensorValue3 / 4) - 2;

  btSerial.write(a);
  btSerial.write(b);
  btSerial.write(c);
  btSerial.write(d);
}