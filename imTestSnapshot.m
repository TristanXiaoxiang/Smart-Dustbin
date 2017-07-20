function [ numberOfTest ] = imTestSnapshot( obj,a )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
numberOfTest = 0;
%a = arduino('com3','Uno');


%while(numberOfTest == 0)
    SensorState = readDigitalPin(a,6);
    
    if SensorState == 0
        pause(1);
        imwrite(getsnapshot(obj), strcat('imTest.jpg'));
        [  object , similarity ] = imKNN();
        returnError = arduinoAction(a,object);
        numberOfTest = 1;
    end
    
    
%end
%'[  object , similarity ] = imKNN();' ...
%        'returnError = arduinoAction(a,object);' ...

end

