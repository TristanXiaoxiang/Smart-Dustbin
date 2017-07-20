%a = arduino('com3','Uno');
a = arduino('com3','Uno');
%outputs from network
outputs = [0.85,0.12; %plastic bottle
           0.56,0.90; %metal beer can
           0.22,0.22; %waste
           0.33,0.67; %metal beer can
           0.88,0.88; %same? what action should be taken?
           0.44,0.44; %waste
           0.76,0.60; %plastic bottle
           ];
i = 1; 
length = 6;

while(1)
    SensorState = readDigitalPin(a,6);
    if SensorState == 0
        pause(1);%time consumption for image processing and analysis
        if((outputs(i,1)<0.5) && (outputs(i,2)<0.5))  % waste, outputpin 12,13 =[1,1] 
            writeDigitalPin(a, 12, 1);
            writeDigitalPin(a, 13, 1);
        elseif(outputs(i,1)> outputs(i,2))            %plastic bottle, outputpin 12,13 =[0,1] 
            writeDigitalPin(a, 12, 0);
            writeDigitalPin(a, 13, 1);
        elseif(outputs(i,1)< outputs(i,2))            %plastic bottle, outputpin 12,13 =[1,0] 
            writeDigitalPin(a, 12, 1);
            writeDigitalPin(a, 13, 0);
        else                                          %outputs(i,1) = outputs(i,2)?
            writeDigitalPin(a, 12, 0);
            writeDigitalPin(a, 13, 0);
        end
        i=mod(i+1,length+1)+fix((i+1)/(length+1));
    else %no object
        writeDigitalPin(a, 12, 0);
        writeDigitalPin(a, 13, 0);
    end
    pause(2);
end