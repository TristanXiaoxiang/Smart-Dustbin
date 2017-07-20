classdef (Abstract)ServoMotorBase < arduinoio.LibraryBase

    %   Copyright 2014 The MathWorks, Inc.
    properties(SetAccess = immutable)
        MinPulseDuration
        MaxPulseDuration
    end
    
    properties(Access = private)
        ResourceMode
        ResourceOwner
        ReservePWMPins
        CountCutOff
        Slot
        MaxServos
        IsServoAttached
        DefaultMinPulseDuration = 544e-6
        DefaultMaxPulseDuration = 2400e-6
    end
    
    properties(Access = private, Constant = true)
        ATTACH_SERVO    = hex2dec('00')
        CLEAR_SERVO     = hex2dec('01')
        READ_POSITION   = hex2dec('02')
        WRITE_POSITION  = hex2dec('03')
    end
    
    properties(Access = protected, Constant = true)
        LibraryName = 'Servo'
        DependentLibraries = {}
        CXXIncludeDirectories = struct('avr', {fullfile(arduinoio.IDERoot, 'libraries', 'Servo', 'src'), fullfile(arduinoio.IDERoot, 'libraries', 'Servo', 'src', 'avr'), fullfile(arduinoio.SPPKGRoot, '+arduinoio', 'src')}, ...
            'sam', {fullfile(arduinoio.IDERoot, 'libraries', 'Servo', 'src'), fullfile(arduinoio.IDERoot, 'libraries', 'Servo', 'src', 'sam'), fullfile(arduinoio.SPPKGRoot, '+arduinoio', 'src')})
        CXXFiles = struct('avr', {fullfile(arduinoio.IDERoot, 'libraries', 'Servo', 'src', 'avr', 'Servo.cpp')}, ...
            'sam', {fullfile(arduinoio.IDERoot, 'libraries', 'Servo', 'src', 'sam', 'Servo.cpp')})
        CIncludeDirectories = {}
        CFiles = {}
        WrapperClassHeaderFile = 'ServoBase.h'
        WrapperClassName = 'ServoBase'
    end
    
    methods
        function obj = ServoMotorBase(parentObj, pin, params)
            obj.Pins = pin;
            obj.Parent = parentObj;
            obj.IsServoAttached = false;
            
            switch obj.Parent.Board
                % Arduino Servo Library limtation by by board type
                % http://arduino.cc/en/reference/servo
                %
                case {'Mega2560', 'Mega1280', 'MegaADK'}
                    obj.ReservePWMPins = 11:12;
                    obj.CountCutOff = 12;
                    obj.MaxServos = 48;
                otherwise
                    obj.ReservePWMPins = 9:10;
                    obj.CountCutOff = 0;
                    obj.MaxServos = 12;
            end
            
            terminal = getTerminalFromDigitalPin(parentObj, pin);
            validateServoTerminal(parentObj, terminal);
            
            try
                p = inputParser;
                addParameter(p, 'MinPulseDuration', obj.DefaultMinPulseDuration);
                addParameter(p, 'MaxPulseDuration', obj.DefaultMaxPulseDuration);
                addParameter(p, 'ResourceMode', 'Servo');
                addParameter(p, 'ResourceOwner', 'Servo');
                parse(p, params{:});
            catch
                parameters = {p.Parameters{1}, p.Parameters{2}};
                obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyName',...
                    'Servo', ...
                    arduinoio.internal.renderCellArrayOfStringsToString(parameters, ', '));
            end
            
            obj.MinPulseDuration = ...
                arduinoio.internal.validateDoubleParameterRanged('MinPulseDuration', ...
                                                             p.Results.MinPulseDuration, ...
                                                             0, 4e-3, 's');
            obj.MaxPulseDuration = ...
                arduinoio.internal.validateDoubleParameterRanged('MaxPulseDuration', ...
                                                             p.Results.MaxPulseDuration, ...
                                                             0, 4e-3, 's');
            
            if (any(ismember(p.UsingDefaults, 'MinPulseDuration')) && ~any(ismember(p.UsingDefaults, 'MaxPulseDuration'))) ||...
               (any(ismember(p.UsingDefaults, 'MaxPulseDuration')) && ~any(ismember(p.UsingDefaults, 'MinPulseDuration')))
                obj.localizedError('MATLAB:arduinoio:general:requiredBothMinMaxPulseDurations');
            end
            obj.ResourceMode = p.Results.ResourceMode;
            obj.ResourceOwner = p.Results.ResourceOwner;
            
            if obj.MinPulseDuration >= obj.MaxPulseDuration
                obj.localizedError('MATLAB:arduinoio:general:invalidMinMaxPulseDurations');
            else
                obj.allocateResource(pin);
                try
                    attachServo(obj, pin, obj.MinPulseDuration*1e6, obj.MaxPulseDuration*1e6);
                catch e
                    clearResourceSlot(obj.Parent, obj.ResourceOwner, obj.Slot);
                    throwAsCaller(e);
                end
            end
        end
    end
    
    methods (Access=protected)
        function delete(obj)
            orig_state = warning('off','MATLAB:class:DestructorError');
            try
                clearServo(obj);
            catch
            end
            
            try
                obj.freeResource();
            catch
            end
            warning(orig_state.state, 'MATLAB:class:DestructorError');
        end
    end
    
        %% Property set/get
     methods (Access = private)
        function attachServo(obj, pin, min, max)
            commandID = obj.ATTACH_SERVO;
            
            min = typecast(uint16(min), 'uint8');
            max = typecast(uint16(max), 'uint8');
            try
                cmd = [ ...
                    pin; ...
                    arduinoio.BinaryToASCII(min); ...
                    arduinoio.BinaryToASCII(max)  ...
                    ];
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
            obj.IsServoAttached = true;
        end
        
        function clearServo(obj)
            if ~obj.IsServoAttached
                return;
            end
            
            commandID = obj.CLEAR_SERVO;
            try
                cmd = [];
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
            obj.IsServoAttached = false;
        end
    end
    
    methods (Access = public)
        function value = readPosition(obj)
            %   Read the position of servo motor shaft.
            %
            %   Syntax:
            %   value = readPosition(s)
            %
            %   Description:
            %   Measures the position of a standard servo motor shaft as a
            %   ratio of the motor's min/max range, from 0 to 1
            %
            %   Example:
            %       a = arduino();
            %       s = servo(a, 9);
            %       pos = readPosition(s);
			%
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       dev = addon(a, 'Adafruit/MotorShieldV2');
            %       s = servo(dev,1);
            %       pos = readPosition(s);
			%
            %   Input Arguments:
            %   s       - Servo motor device 
            %
			%   Output Arguments:
            %   value   - Measured motor shaft position (double) 
			%
			%   See also writePosition
            
            commandID = obj.READ_POSITION;
            try
                value = sendCommand(obj, obj.LibraryName, commandID);
                if isempty(value)
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                end
                
                cmdID = value(1);
                if cmdID ~= obj.READ_POSITION
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                else
                    value = double(round(value(4)*100/180)/100);
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        function writePosition(obj, value)
            %   Set the position of servo motor shaft.
            %
            %   Syntax:
            %   writePosition(s, value)
            %
            %   Description:
            %   Set the position of a standard servo motor shaft as a
            %   ratio of the motor's min/max range, from 0 to 1
            %
            %   Example:
            %       a = arduino();
            %       s = servo(a, 9);
            %       writePosition(s, 0.6);
			%
            %   Example:
            %       a = arduino();
            %       dev = addon(a, 'Adafruit/MotorShieldV2');
            %       s = servo(dev,1);
            %       writePosition(s, 0.6);
			%
            %   Input Arguments:
            %   s       - Servo motor device 
            %   value   - Motor shaft position (double)
			%
			%   See also readPosition
            
            commandID = obj.WRITE_POSITION;
            try
                arduinoio.internal.validateDoubleParameterRanged('position', value, 0, 1);
                value = uint8(180*value);
                cmd = arduinoio.BinaryToASCII(value);
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods (Access = protected)
        function output = sendCommand(obj, libName, commandID, varargin)
            cmd = [obj.Slot-1; commandID];
            if nargin > 3
                cmd = [cmd; varargin{1}]; 
            end
            output = sendCustomMessage(obj.Parent, libName, cmd);
        end
    end
    
    %% Protected methods
    %
    %
    methods (Access = protected)       
        function disablePWMPins(obj, pins)
            for i = 1:numel(pins)
                resourceOwner = getResourceOwner(obj.Parent, pins(i));
                if ~strcmp(resourceOwner, 'Servo') 
                    mode = getTerminalMode(obj.Parent, pins(i));
                    switch mode
                        case {'Unset', 'PWM', 'Servo'}
                            % Take resource ownership from Arduino object
                            clearDigitalResource(obj.Parent, pins(i));
                            configureDigitalResource(obj.Parent, pins(i), obj.ResourceOwner, 'Reserved', true);
                        otherwise
                            obj.localizedError('MATLAB:arduinoio:general:reservedServoPins', ...
                                obj.Parent.Board, ...
                                'digital', num2str(pins));
                    end
                end
            end
        end
        
        function enablePWMPins(obj, pins)
            for i = 1:numel(pins)
                mode = getTerminalMode(obj.Parent, pins(i));
                if strcmp(mode, 'Reserved')
                    configureDigitalResource(obj.Parent, pins(i), obj.ResourceOwner, 'Unset', true);
                end
            end
        end
        
        function allocateResource(obj, pin)
            count = incrementResourceCount(obj.Parent, obj.ResourceOwner);
            
            if count > obj.MaxServos
                obj.localizedError('MATLAB:arduinoio:general:maxServos', ...
                    obj.Parent.Board, num2str(obj.MaxServos));
            end
            
            if count == obj.CountCutOff + 1
                obj.disablePWMPins(obj.ReservePWMPins)
            end
            
            mode = getTerminalMode(obj.Parent, pin);
            resourceOwner = getResourceOwner(obj.Parent, pin);
            if strcmp(mode, 'Servo') && strcmp(resourceOwner, '')
                % Take resource ownership from Arduino object
                clearDigitalResource(obj.Parent, pin);
                configureDigitalResource(obj.Parent, pin, obj.ResourceOwner, obj.ResourceMode, true);
            elseif strcmp(mode, 'Unset') || ...
                   (strcmp(mode, 'Reserved') || arduinoio.internal.endsWith(mode, '\Reserved') && ...
                   (strcmp(resourceOwner, 'Servo') || arduinoio.internal.endsWith(resourceOwner, '\Servo')))
                % We can only acquire unset resources (or resources
                % reserved by servo)
                clearDigitalResource(obj.Parent, pin);
                configureDigitalResource(obj.Parent, pin, obj.ResourceOwner, obj.ResourceMode, false);
            else
                obj.localizedError('MATLAB:arduinoio:general:reservedDigitalPin', ...
                    num2str(pin), mode, 'Servo');
            end
            
            % Allocate the resource slot only if resource allocation
            % succeeds
            obj.Slot = getFreeResourceSlot(obj.Parent, obj.ResourceOwner);
        end
        
        function freeResource(obj)
            count = decrementResourceCount(obj.Parent, obj.ResourceOwner);
            
            % Re-enable disabled pins if we are below the count cut-off
            if count == obj.CountCutOff
                obj.enablePWMPins(obj.ReservePWMPins)
            end
            
            resourceOwner = getResourceOwner(obj.Parent, obj.Pins);
            if ~strcmp(resourceOwner, obj.ResourceOwner)
                % If we're in the destructor because we failed to
                % construct (due to a resource conflict), we have no
                % pin configuration to repair...
                %
                return;
            end
            
            % Slot is empty is resource allocation failed during
            % construction
            if ~isempty(obj.Slot)
                clearResourceSlot(obj.Parent, obj.ResourceOwner, obj.Slot);
            
                % Free the servo pin.
                if count <= obj.CountCutOff || (count > obj.CountCutOff && ~ismember(obj.Pins, obj.ReservePWMPins))
                    configureDigitalResource(obj.Parent, obj.Pins, obj.ResourceOwner, 'Unset', true);
                else
                    configureDigitalResource(obj.Parent, obj.Pins, obj.ResourceOwner, 'Reserved', true);
                end
            end
        end
    end
end
