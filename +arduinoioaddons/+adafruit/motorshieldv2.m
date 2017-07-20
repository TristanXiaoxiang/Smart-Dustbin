classdef motorshieldv2 < arduinoio.LibraryBase & matlab.mixin.CustomDisplay
% MOTORSHIELDV2 Create an Adafruit motor shield v2 device object.

% Copyright 2014 The MathWorks, Inc.

    properties(Access = private, Constant = true)
        CREATE_MOTOR_SHIELD = hex2dec('00')
        DELETE_MOTOR_SHIELD = hex2dec('01')
    end

    properties(SetAccess = immutable)
        I2CAddress
        PWMFrequency
    end
    
    properties(Access = private)
        Bus
        CountCutOff
        ResourceOwner
    end
    
    properties(Access = protected, Constant = true)
        LibraryName = 'Adafruit/MotorShieldV2'
        DependentLibraries = {'Servo', 'I2C'}
        CXXIncludeDirectories = struct('all', {fullfile(arduinoio.IDERoot, 'libraries', 'Adafruit_MotorShield'), fullfile(arduinoio.IDERoot, 'libraries', 'Adafruit_MotorShield', 'utility'), fullfile(arduinoio.SPPKGRoot, '+arduinoioaddons', '+adafruit', 'src')})
        CXXFiles = struct('all', {fullfile(arduinoio.IDERoot, 'libraries', 'Adafruit_MotorShield', 'Adafruit_MotorShield.cpp'), fullfile(arduinoio.IDERoot, 'libraries', 'Adafruit_MotorShield', 'utility', 'Adafruit_PWMServoDriver.cpp')})
        CIncludeDirectories = {}
        CFiles = {}
        WrapperClassHeaderFile = 'MotorShieldV2Base.h'
        WrapperClassName = 'MotorShieldV2Base'
    end
    
    %% Constructor
    methods(Hidden, Access = public)
        function obj = motorshieldv2(parentObj, varargin)
            obj.Parent = parentObj;
            
            obj.Bus = 0;
            obj.ResourceOwner = 'AdafruitMotorShieldV2';
            
            if strcmp(obj.Parent.Board, 'Uno')
                obj.CountCutOff = 4;
            else
                obj.CountCutOff = 32;
            end
            
            count = incrementResourceCount(obj.Parent, obj.ResourceOwner);
            if count > obj.CountCutOff
                obj.localizedError('MATLAB:arduinoio:general:maxAddonLimit',...
                    num2str(obj.CountCutOff),...
                    obj.ResourceOwner,...
                    obj.Parent.Board);
            end
            
            try
                p = inputParser;
                addParameter(p, 'I2CAddress', hex2dec('60'));
                addParameter(p, 'PWMFrequency', 1600);
                parse(p, varargin{:});
            catch
                obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyName',...
                    obj.ResourceOwner, ...
                    arduinoio.internal.renderCellArrayOfStringsToString(p.Parameters, ', '));
            end
            
            address = validateAddress(obj, p.Results.I2CAddress);
            i2cAddresses = getResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses');
            if isempty(i2cAddresses)
                i2cAddresses = [];
            end
            if ismember(address, i2cAddresses)
                obj.localizedError('MATLAB:arduinoio:general:conflictI2CAddress', ...
                    num2str(address),...
                    dec2hex(address));
            end
            i2cAddresses = [i2cAddresses address];
            setResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses', i2cAddresses);
            obj.I2CAddress = address;
            
            frequency = arduinoio.internal.validateDoubleParameterRanged('PWM frequency', p.Results.PWMFrequency, 0, 32767, 'Hz');
            obj.PWMFrequency = frequency;
            
            configureI2C(obj);
            
            createMotorShield(obj);
        end
    end
    
    %% Destructor
    methods (Access=protected)
        function delete(obj)
            orig_state = warning('off','MATLAB:class:DestructorError');
            try
                parentObj = obj.Parent;
                i2cAddresses = getResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses');
                if ~isempty(i2cAddresses)
                    if ~isempty(obj.I2CAddress) 
                        % Can be empty if failed during construction
                        i2cAddresses(i2cAddresses==obj.I2CAddress) = [];
                    end
                end
                setResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses', i2cAddresses);
                
                count = decrementResourceCount(obj.Parent, obj.ResourceOwner);
                deleteMotorShield(obj);
            catch
                % Do not throw errors on destroy.
                % This may result from an incomplete construction.
            end
            warning(orig_state.state, 'MATLAB:class:DestructorError');
        end
    end
    
    %% Public methods
    methods (Access = public)
        function servoObj = servo(obj, motornum, varargin)
            %   Attach a servo motor to the specified port on Adafruit motor shield.
            %
            %   Syntax:
            %   s = servo(dev, motornum)
            %   s = servo(dev, motornum,Name,Value)
            %
            %   Description:
            %   s = servo(dev, motornum)            Creates a servo motor object connected to the specified port on the Adafruit motor shield.
            %   s = servo(dev, motornum,Name,Value) Creates a servo motor object with additional options specified by one or more Name-Value pair arguments.
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       s = servo(shield,1);
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       s = servo(shield,1,'MinPulseDuration',1e-3,'MaxPulseDuration',2e-3);
            %
            %   Input Arguments:
            %   dev      - Adafruit motor shield v2 object
            %   motornum - Port number the motor is connected to on the shield (numeric)
            %
            %   Name-Value Pair Input Arguments:
            %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value. 
            %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
            %
            %   NV Pair:
            %   'MinPulseDuration' - The pulse duration for the servo at its minimum position (numeric, 
            %                       default 5.44e-4 seconds.
            %   'MaxPulseDuration' - The pulse duration for the servo at its maximum position (numeric, 
            %                       default 2.4e-3 seconds.
            %
            %   See also dcmotor, stepper
            
            try
                servoObj = arduinoioaddons.adafruit.Servo(obj, motornum, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function dcmotorObj = dcmotor(obj, motornum, varargin)
            %   Attach a DC motor to the specified port on Adafruit motor shield.
            %
            %   Syntax:
            %   dcm = dcmotor(dev, motornum)
            %   dcm = dcmotor(dev, motornum,Name,Value)
            %
            %   Description:
            %   dcm = dcmotor(dev, motornum)            Creates a dcmotor motor object connected to the specified port on the Adafruit motor shield.
            %   dcm = dcmotor(dev, motornum,Name,Value) Creates a dcmotor motor object with additional options specified by one or more Name-Value pair arguments.
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       dcm = dcmotor(shield,1);
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       dcm = dcmotor(shield,1,'Speed'0.2);
            %
            %   Input Arguments:
            %   dev      - Adafruit motor shield v2 object
            %   motornum - Port number the motor is connected to on the shield (numeric)
            %
            %   Name-Value Pair Input Arguments:
            %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value. 
            %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
            %
            %   NV Pair:
            %   'Speed' - The speed of the motor that ranges from -1 to 1 (numeric, 
            %                     default 0.
            %
            %   See also servo, stepper
            
            try
                dcmotorObj = arduinoioaddons.adafruit.dcmotorv2(obj, motornum, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function stepperObj = stepper(obj, motornum, varargin)
            %   Attach a stepper motor to the specified port on Adafruit motor shield.
            %
            %   Syntax:
            %   sm = stepper(dev, motornum, sprev)
            %   sm = stepper(dev, motornum, sprev, Name, Value)
            %
            %   Description:
            %   sm = stepper(dev, motornum)            Creates a stepper motor object connected to the specified port on the Adafruit motor shield.
            %   sm = stepper(dev, motornum, sprev, Name,Value) Creates a stepper motor object with additional options specified by one or more Name-Value pair arguments.
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       sm = stepper(shield,1,200);
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       sm = stepper(shield,1,200,'RPM',10);
            %
            %   Input Arguments:
            %   dev      - Adafruit motor shield v2 object
            %   motornum - Port number the motor is connected to on the shield (numeric)
            %   sprev    - steps per revolution
            %
            %   Name-Value Pair Input Arguments:
            %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value. 
            %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
            %
            %   NV Pair:
            %   'RPM'      - The speed of the motor which is revolutions per minute (numeric, default 0).
            %
            %   'StepType' - The type of coil activation for the motor that can be,   
            %                     'Single', 'Double', 'Interleave', 'Microstep'(string, default 'Single').
            %
            %   See also dcmotor, servo
            
            try
                stepperObj = arduinoioaddons.adafruit.stepper(obj, motornum, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    %% Private methods
    methods (Access = private)
        function createMotorShield(obj)        
            commandID = obj.CREATE_MOTOR_SHIELD;
            frequency = typecast(uint16(obj.PWMFrequency), 'uint8');
            try
                cmd = arduinoio.BinaryToASCII(frequency);
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
        
        function deleteMotorShield(obj)
            commandID = obj.DELETE_MOTOR_SHIELD;
            try
                cmd = [];
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    %% Helper method to related classes
    methods (Access = {?arduinoioaddons.adafruit.Servo, ?arduinoioaddons.adafruit.dcmotorv2, ?arduinoioaddons.adafruit.stepper})
        function output = sendShieldCommand(obj, commandID, inputs, timeout)
            switch nargin
                case 3
                    output = sendCommand(obj, obj.LibraryName, commandID, inputs);
                case 4
                    output = sendCommand(obj, obj.LibraryName, commandID, inputs, timeout);
                otherwise
            end
        end
    end
    
    methods(Access = private)
        function addr = validateAddress(obj, address)
            min = hex2dec('60');
            max = hex2dec('80')-1;
            if ~ischar(address)
                try
                    addr = arduinoio.internal.validateIntParameterRanged('address', address, min, max);
                    return;
                catch
                    printableAddress = false;
                    try
                        printableAddress = (size(num2str(address), 1) == 1);
                    catch
                    end
                    
                    if printableAddress
                        obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', num2str(address), num2str(min), num2str(max));
                    else
                        obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddressType');
                    end
                end

            else            
                tmpAddr = address;
                
                try
                    index = strfind(lower(tmpAddr), '0x');
                    if index == 1
                        tmpAddr = tmpAddr(3:end);
                    elseif strcmpi(tmpAddr(end), 'h')
                        tmpAddr(end) = [];
                    end
                    dec = hex2dec(tmpAddr);
                catch 
                    obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', address, num2str(min), num2str(max));
                end
            
                if dec < min || dec > max
                    obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', address, num2str(min), num2str(max));
                end
            end
            
            addr = dec;
        end
    
        function configureI2C(obj)
            parentObj = obj.Parent;
            I2CTerminals = parentObj.getI2CTerminals();
            isAnalog = parentObj.IsAnalogTerminal(I2CTerminals(1));
            
            resourceOwner = 'I2C';
            switch isAnalog
                case true
                    sda = parentObj.getAnalogPinsFromTerminals(I2CTerminals(obj.Bus*2+1));
                    configureAnalogResource(parentObj, ...
                        sda, ...
                        resourceOwner, ...
                        'I2C', ...
                        false);
                    scl = parentObj.getAnalogPinsFromTerminals(I2CTerminals(obj.Bus*2+2));
                    configureAnalogResource(parentObj, ...
                        scl, ...
                        resourceOwner, ...
                        'I2C', ...
                        false);
                    obj.Pins = [sda scl];
                case false
                    sda = parentObj.getDigitalPinsFromTerminals(I2CTerminals(obj.Bus*2+1));
                    configureDigitalResource(parentObj, ...
                        sda, ...
                        resourceOwner, ...
                        'I2C', ...
                        false);
                    scl = parentObj.getDigitalPinsFromTerminals(I2CTerminals(obj.Bus*2+2));
                    configureDigitalResource(parentObj, ...
                        scl, ...
                        resourceOwner, ...
                        'I2C', ...
                        false);
                    obj.Pins = [sda scl];
            end
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function output = sendCommand(obj, libName, commandID, inputs, timeout)
            address = uint8(obj.I2CAddress);
            cmd = [commandID; arduinoio.BinaryToASCII(address); inputs]; 
            if nargin < 5
                output = sendCustomMessage(obj.Parent, libName, cmd);
            else
                output = sendCustomMessage(obj.Parent, libName, cmd, timeout);
            end
        end
        
        function displayScalarObject(obj)
            header = getHeader(obj);
            header = arduinoio.internal.insertHelpLinkInDisplay(header);
            disp(header);
            
            % Display main options
            parentObj = obj.Parent;

            I2CTerminals = parentObj.getI2CTerminals();
            isAnalog = parentObj.IsAnalogTerminal(I2CTerminals(1));
            if isAnalog
                pins = ['A' num2str(obj.Pins(1)) '(SDA), A' num2str(obj.Pins(2)) '(SCL)'];
            else
                pins = ['D' num2str(obj.Pins(1)) '(SDA), D' num2str(obj.Pins(2)) '(SCL)'];
            end
            fprintf('            Pins: %-15s\n', pins);
            fprintf('      I2CAddress: %-1d (0x%02s)\n', obj.I2CAddress, dec2hex(obj.I2CAddress));
            fprintf('    PWMFrequency: %.2d (Hz)\n', obj.PWMFrequency);
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end
