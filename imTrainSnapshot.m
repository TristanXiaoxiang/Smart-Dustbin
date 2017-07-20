function [ numberOfCases ] = imTrainSnapshot( obj,a,object,counter )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
numberOfCases = 0;
%a = arduino('com3','Uno');
configureDigitalPin(a,6,'pullup');

while(numberOfCases<counter)
    SensorState = readDigitalPin(a,6);
    if SensorState == 0
        pause(2);
        if object == 1
           % imwrite(getsnapshot(obj), strcat('image\\imFanta',num2str(numberOfCases,'%04d'),'.jpg'));
            imwrite(getsnapshot(obj), strcat('image\\',num2str(numberOfCases,'%d'),'.jpg'));
        elseif object == 2
            imwrite(getsnapshot(obj), strcat('image\\imColaZero',num2str(numberOfCases,'%04d'),'.jpg'));
        elseif object == 3
            imwrite(getsnapshot(obj), strcat('image\\imBeer',num2str(numberOfCases,'%04d'),'.jpg'));
        else
            imwrite(getsnapshot(obj), strcat('image\\imOthers',num2str(numberOfCases,'%04d'),'.jpg'));
        end
        numberOfCases=numberOfCases+1;
    end
    
end
end

