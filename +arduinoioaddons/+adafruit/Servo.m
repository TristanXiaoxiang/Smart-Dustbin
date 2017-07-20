classdef Servo < arduinoio.ServoMotorBase & matlab.mixin.CustomDisplay
    %Attach a servo motor to the specified port on Adafruit motor shield.
    %
    %Syntax:
    %s = servo(dev, motornum)
    %s = servo(dev, motornum,Name,Value)
    %
    %Description:
    %s = servo(dev, motornum)            Creates a servo motor object connected to the specified port on the Adafruit motor shield.
    %s = servo(dev, motornum,Name,Value) Creates a servo motor object with additional options specified by one or more Name-Value pair arguments.
    %
    %Example:
    %   a = arduino();
    %   shield = addon(a, 'Adafruit/MotorShieldV2');
    %   s = servo(shield,1);
    %
    %Example:
    %   a = arduino();
    %   shield = addon(a, 'Adafruit/MotorShieldV2');
    %   s = servo(shield,1,'MinPulseDuration',1e-3,'MaxPulseDuration',2e-3);
    %
    %Input Arguments:
    %dev      - Adafruit motor shield
    %motornum - Port number the motor is connected to on the shield (numeric)
    %
    %Name-Value Pair Input Arguments:
    %Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value.
    %Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
    %
    %NV Pair:
    %'MinPulseDuration' - The pulse duration for the servo at its minimum position (numeric,
    %                     default 5.44e-4 seconds.
    %'MaxPulseDuration' - The pulse duration for the servo at its maximum position (numeric,
    %                     default 2.4e-3 seconds.
    %
    % See also dcmotor, stepper
    
    %   Copyright 2014 The MathWorks, Inc.
    properties(SetAccess = immutable)
        MotorNumber
    end
    
    properties(Access = private)
        ResourceMode
        ResourceOwner
    end
    
    %% Constructor
    methods(Hidden, Access = public)
        function obj = Servo(parentObj, motornum, varargin)
            resourceOwner = 'Servo';
            resourceMode = 'AdafruitMotorShieldV2\Servo';
            motornum = arduinoio.internal.validateIntParameterRanged(...
                resourceOwner, ...
                motornum, ...
                1, 2);
            
            if motornum == 1
                pin = 10;
            elseif motornum == 2
                pin = 9;
            end
            
            varargin{end+1} = 'ResourceOwner';
            varargin{end+1} = resourceOwner;
            varargin{end+1} = 'ResourceMode';
            varargin{end+1} = resourceMode;
            obj = obj@arduinoio.ServoMotorBase(parentObj.Parent, pin, varargin);
            obj.ResourceMode = resourceMode;
            obj.ResourceOwner = resourceOwner;
            obj.MotorNumber = motornum;
        end
    end
    
    %% Destructor
    methods (Access=protected)
        function delete(~)
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            header = arduinoio.internal.insertHelpLinkInDisplay(header);
            disp(header);
            
            % Display main options
            fprintf('         MotorNumber: %d\n', obj.MotorNumber);
            fprintf('                Pins: %d\n', obj.Pins);
            fprintf('    MinPulseDuration: %.2e (s)\n', obj.MinPulseDuration);
            fprintf('    MaxPulseDuration: %.2e (s)\n', obj.MaxPulseDuration);  
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end