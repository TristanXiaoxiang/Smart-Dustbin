clc; clear all; close all;

%%camera
imaqhwinfo
obj = videoinput('winvideo');
%%obj = videoinput('winvideo',1,'YUY2_320x240');
%%preview( src );
set(obj, 'FramesPerTrigger', 1);
set(obj, 'TriggerRepeat', Inf);
%%start(obj);
preview(obj);%GUI

%%arduino
a = arduino('com3','Uno');
configureDigitalPin(a,6,'pullup');
writeDigitalPin(a, 8, 0);
writeDigitalPin(a, 9, 0);

while(1)
    SensorState = readDigitalPin(a,6);
    if SensorState == 0
        pause(1);
        imwrite(getsnapshot(obj), strcat('imTest.jpg'));
        [  object , similarity ] = imKNN2();
        returnError = arduinoAction(a,object);
    %else
        %arduinoAction(a,0);
    end
end











