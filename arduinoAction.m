function returnError = arduinoAction( a,object )
%%arduinoAction operates arduino according to the inputs
%input : object -  object being indentified by the system

%output: returnError - error information

%a = arduino('com3','Uno');
object

if object == 1
    
    %%open the dustbin for metal cans
    writeDigitalPin(a, 8, 1);
    writeDigitalPin(a, 9, 0);
    pause(3);
    returnError = 1
    
elseif object == 2
    
    %%open the dustbin for metal cans
    writeDigitalPin(a, 8, 0);
    writeDigitalPin(a, 9, 1);
    pause(3);
    returnError = 2  
    
elseif object == 0
    %%open the dustbin for smetal cans
    writeDigitalPin(a, 8, 1);
    writeDigitalPin(a, 9, 1);
    pause(3);
    returnError = 0;
else
    %writeDigitalPin(a, 8, 0);
    %writeDigitalPin(a, 9, 0);
    pause(3);
    returnError = 0
    
end
%pause(3);

writeDigitalPin(a, 8, 0);
writeDigitalPin(a, 9, 0);

end

