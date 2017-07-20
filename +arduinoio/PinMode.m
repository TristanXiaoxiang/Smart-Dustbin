classdef (Enumeration) PinMode < arduinoio.internal.StringEnum
    %PinMode Arduino PinMode enumeration
    
    % Copyright 2014 The MathWorks, Inc.
    %
    
    enumeration
        Input
        Pullup
        Output
        Servo
        PWM
        I2C
        SPI
        Unset
    end
    
    methods(Hidden, Static)
        function obj = setValue(value)
            obj = arduinoio.internal.StringEnum.enumFactory(...
                'arduinoio.PinMode',...
                value);
        end
    end
end

