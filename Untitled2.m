clc; clear all; close all;
numberOfTrainCases = 100;


imaqhwinfo
obj = videoinput('winvideo');
%obj = videoinput('winvideo',1,'YUY2_320x240');
%preview( src );
set(obj, 'FramesPerTrigger', 1);
set(obj, 'TriggerRepeat', Inf);
%start(obj);
a = arduino('com5','Uno');

while(1)
    imTestSnapshot(obj,a);
        %'[ object , similarity ] = imIdentify( net,inputn,inputps,outputn,outputps );' ...
    [  object , similarity ] = imKNN();
    similarity
    returnError = arduinoAction(a,object, similarity);
end