classdef Servo < arduinoio.ServoMotorBase & matlab.mixin.CustomDisplay
    %   Attach a servo motor to specified pin on Arduino board.
    %
    %   Syntax:
    %   s = servo(a, pin)
    %   s = servo(a, pin,Name,Value)
    %
    %   Description:
    %   s = servo(a, pin)            Creates a servo motor object connected to the specified pin on the Arduino board.
    %   s = servo(a, pin,Name,Value) Creates a servo motor object with additional options specified by one or more Name-Value pair arguments.
    %
    %   Example:
    %       a = arduino();
    %       s = servo(a,3);
    %
    %   Example:
    %       a = arduino();
    %       s = servo(a,3,'MinPulseDuration',1e-3,'MaxPulseDuration',2e-3);
    %
    %   Input Arguments:
    %   a   - Arduino
    %   pin - Digital pin number (numeric)
    %
    %   Name-Value Pair Input Arguments:
    %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value.
    %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
    %
    %   NV Pair:
    %   'MinPulseDuration' - The pulse duration for the servo at its minimum position (numeric,
    %                     default 5.44e-4 seconds.
    %   'MaxPulseDuration' - The pulse duration for the servo at its maximum position (numeric,
    %                     default 2.4e-3 seconds.
    %
    
    %   Copyright 2014 The MathWorks, Inc.
    
    methods(Hidden, Access = public)
        function obj = Servo(parentObj, pin, varargin)
            obj = obj@arduinoio.ServoMotorBase(parentObj, pin, varargin);
        end
    end
        
    methods (Access=protected)
        function delete(~)
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            header = arduinoio.internal.insertHelpLinkInDisplay(header);
            disp(header);
            
            % Display main options
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
