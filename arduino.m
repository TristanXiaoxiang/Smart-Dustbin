classdef (Sealed) arduino < arduinoio.internal.BaseClass & matlab.mixin.CustomDisplay
%	Connect to an Arduino.
%
%   Syntax:
%       a = arduino
%       a = arduino(port)
%       a = arduino(port,board,Name,Value)
%
%   Description:
%       a = arduino                  Creates a connection to an Arduino® hardware.
%       a = arduino(port)            Creates a connection to an Arduino hardware on the specified port.
%       a = arduino(port,board,Name,Value) Creates a connection to the Arduino hardware on the specified
%       port and board with additional Name-Value options.
%
%   Example: 
%   Connect to an Arduino Uno board on COM port 3 on Windows:
%       a = arduino('com3','uno');
% 
%   Connect to an Arduino Uno board on a serial port on Mac:
%       a = arduino('/dev/tty.usbmodem1421');
%
%   Example:
%   Include only I2C library instead of default libraries set (I2C, SPI and Servo)
%       a = arduino('com3','uno','libraries','I2C');
%
%   Input Arguments:
%   port - Device port (string, e.g. 'com3' or '/dev/tty.usbmodem1421')
%   board - Arduino Board type (string, e.g. 'Uno', 'Mega2560', ...)
%
%   Name-Value Pair Input Arguments:
%   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value. 
%   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
%
%   NV Pair:
%   'libraries' - Name of Arduino library (string)
%              Default libraries downloaded to Arduino: I2C, SPI, Servo.
%
%   Name of the Arduino library specified as a string.
%   Example: a = arduino('com9','uno','libraries','spi')
%
%Output Arguments:
%a - Arduino hardware connection
%
%For more information, see <a href="matlab: open(fullfile(arduinoio.SPPKGRoot, 'arduinoio_ug_book.pdf'))">MATLAB Support Package for Arduino User's Guide.</a>

%   Copyright 2014 The MathWorks, Inc.
    
    properties(SetAccess = private)
        %Port Arduino object is connected to.
        Port
        
        %Arduino hardware type.
        Board
        
        %Available analog pins on Arduino hardware
        AvailableAnalogPins
        
        %Available digital pins on Arduino hardware
        AvailableDigitalPins
        
        %Libraries compiled and downloaded to Arduino hardware
        Libraries
    end
    
    properties(Hidden, SetAccess = private)
        %Display debug trace of commands executed on Arduino hardware
        TraceOn
        
        %Force compile and download of Arduino server.
        ForceBuildOn
        
        %Flag of whether uploading a library or not
        LibrariesSpecified
    end
    
    properties(SetAccess = private, GetAccess = {?arduinoio.LibraryBase})
        ResourceManager
    end
    
    properties(Access = private)
        Utility
        Protocol
        LibraryIDs
        ResourceOwner
        ResourceMap
        SerialConnection
    end
    
    properties(Access = private, Constant = true)
        DefaultLibList = {'I2C', 'SPI', 'Servo'}
    end
    
    % Aref not officially supported, but may be needed for correct PWM
    % calculations.
    properties(Hidden)
        Aref
    end
 
    %% Constructor
    methods(Hidden, Access = public)
        function obj = arduino(varargin)
            narginchk(0, 9);
            
            try
                initUtility(obj);
                initProperties(obj, varargin);
                % Resource Owner (Arduino = '')
                obj.ResourceOwner = '';
                
                % Analog reference, for PWM scaling
                initResourceManager(obj, obj.Board);
                obj.Board = obj.ResourceManager.Board;
                tAnalog = obj.ResourceManager.TerminalsAnalog;
                tDigital = obj.ResourceManager.TerminalsDigital;
                obj.AvailableAnalogPins = obj.ResourceManager.getAnalogPinsFromTerminals(tAnalog);
                obj.AvailableDigitalPins = obj.ResourceManager.getDigitalPinsFromTerminals(tDigital);
                
                if ismember(obj.Board, {'Due'})
                    obj.Aref = 3.3;
                else
                    obj.Aref = 5.0;
                end
                
                % ResourceMap
                obj.ResourceMap = containers.Map;
                
                % Setup and initialize host and target connection.
                initServerConnection(obj, '');

                % update preference last to ensure preference is only
                % updated when an arduino object is successfully created
                updatePreference(obj.Utility, obj.Port, obj.Board);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    %% Destructor
    methods (Access=protected)
        function delete(obj)
            % User delete of Arduino objects is disabled. Use clear
            % instead.
            if ~isempty(obj.SerialConnection) % Delete the serial object arduino creates
                % Reset all pins state to input
                try
                    resetPinsState(obj.Protocol);
                catch 
                    % not error out
                end
                
                delete(obj.SerialConnection)
                clear obj.SerialConnection;
            end
        end
    end
    
    %% Public methods
    methods(Access = public)
        function varargout = configureDigitalPin(obj, pin, mode)
            %   Set digital pin mode.
            %
            %   Syntax:
            %       configureDigitalPin(a,pin,mode)
            %
            %   Description:
            %       Sets the specified digital pin on the Arduino hardware to the specified mode.
            %
            %   Example:
            %       a = arduino();
            %       configureDigitalPin(a,12,'pullup');
            %
            %   Example:
            %       a = arduino();
            %       configureDigitalPin(a,12,'PWM');
            %
            %   Input Arguments:
            %   a    - Arduino
            %   pin  - Digital pin number on the physical hardware (numeric).
            %   mode - Digital pin mode (string, e.g. input, pullup, output, pwm, ...)
            %
            %   Example:
            %       a = arduino();
            %       config = configureDigitalPin(a,2);
            %
            %   Output Arguments:
            %   config - Current mode (string) for specified digital pin.
            %
            %	See also configureAnalogPin
            try
                if nargout > 1
                    error('Too many output arguments');
                end

                if (nargout > 0 && nargin > 2) || (nargin > 3)
                    obj.localizedError('MATLAB:maxrhs');
                end

                if nargin ~= 2
                    % Writing pin configuration
                    configureDigitalResource(obj, pin, obj.ResourceOwner, mode, true);
                else
                    % Reading pin configuration
                    varargout = {configureDigitalPin(obj.ResourceManager, pin)};
                    return;
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        function varargout = configureAnalogPin(obj, pin, mode)
            %   Set analog pin mode.
            %
            %   Syntax:
            %   configureAnalogPin(a,pin,mode)
            %
            %   Description:
            %   Sets the specified analog pin on the Arduino hardware to the specified mode.
            %
            %   Example:
            %       a = arduino();
            %       configureAnalogPin(a,2,'input');
            %
            %   Example:
            %       a = arduino();
            %       configureAnalogPin(a,2,'I2C');
            %
            %   Input Arguments:
            %   a    - Arduino
            %   pin  - Analog pin number on the physical board (numeric).
            %   mode - Analog pin mode (string, e.g. input, I2C...)
            %
            %   Example:
            %       a = arduino();
            %       config = configureAnalogPin(a,2);
            %
            %   Output Arguments:
            %   config - Current mode (string) for specified analog pin.
            %
            %	See also configureDigitalPin
            try
                if nargout > 1
                    error('Too many output arguments');
                end

                if (nargout > 0 && nargin > 2) || (nargin > 3)
                    obj.localizedError('MATLAB:maxrhs');
                end

                if nargin ~= 2
                    % Writing pin configuration
                    configureAnalogResource(obj, pin, obj.ResourceOwner, mode, true);
                else
                    % Reading pin configuration
                    varargout = {configureAnalogPin(obj.ResourceManager, pin)};
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        function writeDigitalPin(obj, pin, value)
            %   Write digital pin value to Arduino hardware.
            %
            %   Syntax:
            %   writeDigitalPin(a,pin,value)
            %
            %   Description:
            %   Writes specified value to the specified pin on the Arduino hardware.
            %
            %   Example:
            %       a = arduino();
            %       writeDigitalPin(a,13,1);
            %
            %   Input Arguments:
            %   a     - Arduino hardware
            %   pin   - Digital pin number on the Arduino hardware (numeric)
            %   value - Digital value (0, 1) or (true, false) to write to the specified pin (double).
            %
            %   See also readDigitalPin, writePWMVoltage, writePWMDutyCycle
            
            try
                configureDigitalResource(obj, pin, obj.ResourceOwner, 'Output', false);
                value = arduinoio.internal.validateDigitalParameter(value);
                writeDigitalPin(obj.Protocol, pin, value);
            catch e
                throwAsCaller(e);
            end
        end
        
        function value = readDigitalPin(obj, pin)
            %   Read digital pin value on Arduino hardware.
            %
            %   Syntax:
            %   value = readDigitalPin(a,pin)
            %
            %   Description:
            %   Reads logical value from the specified pin on the Arduino hardware.
            %
            %   Example:
            %       a = arduino();
            %       value = readDigitalPin(a,13);
            %
            %   Input Arguments:
            %   a   - Arduino hardware
            %   pin - Digital pin number on the Arduino hardware (numeric)
            %
            %   Output Arguments:
            %   value - Digital (0, 1) value acquired from digital pin (double)
            %
            %   See also writeDigitalPin
            
            try
                configureDigitalResource(obj, pin, obj.ResourceOwner, 'Input', false);
                value = readDigitalPin(obj.Protocol, pin);
            catch e
                throwAsCaller(e);
            end
        end
        
        function writePWMVoltage(obj, pin, voltage)
            %   Output a PWM signal on a digital pin on the Arduino hardware.
            %
            %   Syntax:
            %   writePWMVoltage(a,pin,voltage)
            %
            %   Description:
            %   Write the specified voltage to the specified PWM pin on the Arduino hardware.
            %
            %   Example:
            %       a = arduino();
            %       writePWMVoltage(a,13,2.5);
            %
            %   Input Arguments:
            %   a       - Arduino hardware
            %   pin     - Digital pin number on the Arduino hardware (numeric)
            %   voltage - PWM signal voltage to write to the Arduino pin (double).
            %
            %   See also writeDigitalPin, writePWMDutyCycle
            try
                configureDigitalPin(obj.ResourceManager, pin, obj.ResourceOwner, 'PWM', false);
                voltage = arduinoio.internal.validateDoubleParameterRanged('PWM voltage', voltage, 0, obj.Aref, 'V');
                writePWMVoltage(obj.Protocol, pin, voltage, obj.Aref);
            catch e
                throwAsCaller(e);
            end
        end
        
        function writePWMDutyCycle(obj, pin, dutyCycle)
            %   Output a PWM signal on a digital pin on the Arduino hardware.
            %
            %   Syntax:
            %   writePWMDutyCycle(a,pin,dutyCycle)
            %
            %   Description:
            %   Set the specified duty cycle on the specified digital pin on the Arduino hardware.
            %
            %   Example:
            %   Set the bightness of the LED on digital pin 13 of the Arduino hardware to 33%
            %       a = arduino();
            %       writePWMDutyCycle(a,13,0.33);
            %
            %   Input Arguments:
            %   a         - Arduino hardware
            %   pin       - Digital pin number on the Arduino hardware (numeric)
            %   dutyCycle - PWM signal duty cycle to write to the Arduino pin (double).
            %
            %   See also writeDigitalPin, writePWMVoltage
            try
                configureDigitalPin(obj.ResourceManager, pin, obj.ResourceOwner, 'PWM', false);
                dutyCycle = arduinoio.internal.validateDoubleParameterRanged('PWM duty cycle', dutyCycle, 0, 1);
                writePWMDutyCycle(obj.Protocol, pin, dutyCycle);
            catch e
                throwAsCaller(e);
            end
        end
        
        function value = readVoltage(obj, pin)
            %   Read analog pin value on Arduino hardware.
            %
            %   Syntax:
            %   value = readVoltage(a,pin)
            %
            %   Description:
            %   Reads analog voltage value from the specified pin on the Arduino hardware.
            %
            %   Example:
            %       a = arduino();
            %       value = readVoltage(a,2);
            %
            %   Input Arguments:
            %   a   - Arduino hardware
            %   pin - Analog pin number on the Arduino hardware (numeric)
            %
            %   Output Arguments:
            %   value - Voltage value acquired from analog pin (double)
            %
            %   See also readDigitalPin
            try
                configureAnalogPin(obj.ResourceManager, pin, obj.ResourceOwner, 'Input', false);
                value = readVoltage(obj.Protocol, pin, obj.Aref);
            catch e
                throwAsCaller(e);
            end    
        end
        
        function playTone(obj, pin, varargin)
            %   Play a tone on piezo speaker
            %
            %   Syntax:
            %   playTone(a,pin)                    Plays a 1000Hz, 1s tone on a piezo speaker attached to
            %                                   the Arduino hardware at a specified pin.
            %   playTone(a,pin,frequency)          Plays a 1s tone at specified frequency.
            %   playTone(a,pin,frequency,duration) Plays a tone at specified frequency and duration.
            %
            %   Example:
            %   Play a tone connected to pin 5 on the Arduino for 30 seconds at 2400Hz.
            %       a = arduino();
            %       playTone(a,5,2400,30);
            %
            %   Example:
            %   Stop playing tone.
            %       a = arduino();
            %       playTone(a,5,0,0);
            %
            %   Input Arguments:
            %   a         - Arduino
            %   pin       - Digital pin number (numeric)
            %   frequency - Frequency of tone (numeric, 0 - 32767Hz)
            %   duration  - Duration of tone to be played (numeric, 0 - 30s)

            %   defaults
            frequency = 1000;
            duration = 1;
            
            if nargin > 4
                obj.localizedError('MATLAB:maxrhs');
            end
            
            if nargin > 3
                duration = varargin{2};
            end
            
            if nargin > 2
                frequency = round(varargin{1});
            end
                        
            try
                configureDigitalPin(obj.ResourceManager, pin, obj.ResourceOwner, 'PWM', false);
                frequency = arduinoio.internal.validateDoubleParameterRanged('tone frequency', frequency, 0, 32767, 'Hz');
                duration = arduinoio.internal.validateDoubleParameterRanged('tone duration', duration, 0, 30, 's');
                playTone(obj.Protocol, pin, frequency, duration);
            catch e
                throwAsCaller(e);
            end
        end
        
        function servoObj = servo(obj, pin, varargin)
            %   Attach a servo motor to specified pin on Arduino hardware.
            %
            %   Syntax:
            %   s = servo(a,pin)
            %   s = servo(a,pin,Name,Value)
            %
            %   Description:
            %   s = servo(a,pin)            Creates a servo motor object connected to the specified pin on the Arduino hardware.
            %   s = servo(a,pin,Name,Value) Creates a servo motor object with additional options specified by one or more Name-Value pair arguments.
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
            %   See also i2cdev, spidev, addon
            try
                servoObj = arduinoio.Servo(obj, pin, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function i2cObj = i2cdev(obj, address, varargin)
            %   Connect to the I2C device at the specified address on the I2C bus of the Arduino hardware.
            %
            %   Syntax:
            %   device = i2cdev(a,address)
            %   device = i2cdev(a,address,Name,Value)
            %
            %   Description:
            %   device = i2cdev(a,address)      Connects to an I2C device at the specified address on the 
            %                                 default I2C bus of the Arduino hardware.
            %
            %   Example:
            %       a = arduino();
            %       tmp102 = i2cdev(a,'0x48');
            %
            %   Example:
            %       a = arduino();
            %       tmp102 = i2cdev(a,'0x48','Bus',1);
            %
            %   Input Arguments:
            %   a       - Arduino
            %   address - I2C address of device (numeric or string)
            %
            %   Name-Value Pair Input Arguments:
            %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value. 
            %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
            %
            %   NV Pair:
            %   'bus'     - The I2C bus (numeric, default 0)
            %
            %   See also spidev, servo, addon
            try
                i2cObj = arduinoio.i2cdev(obj, address, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function spiObj = spidev(obj, cspin, varargin)
            %   Connect to the SPI device on the specified chip select pin on the Arduino hardware.
            %
            %   Syntax:
            %   device = spidev(a,cspin)
            %   device = spidev(a,cspin,Name,Value)
            %
            %   Description:
            %   device = spidev(a,cspin)      Connects to an SPI device on the specified chip select pin
            %
            %   Example:
            %       a = arduino();
            %       ad5231 = spidev(a,10);
            %
            %   Example:
            %       a = arduino();
            %       ad5231 = spidev(a,10,'bitorder','msbfirst','mode',3);
            %
            %   Input Arguments:
            %   a     - Arduino
            %   cspin - Chip select pin (numeric)
            %
            %   Name-Value Pair Input Arguments:
            %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value. 
            %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
            %
            %   NV Pair:
            %   'bitorder' - The SPI communication bit order for the device (string, e.g. msbfirst, lsbfirst)
            %   'mode'     - The SPI communication mode for clock polarity and phase (numeric, 0 - 3)
            %
            %   See also i2cdev, servo, addon
            try
                spiObj = arduinoio.spidev(obj, cspin, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
        
        function addonObj = addon(obj, libname, varargin)
            %   Connect to an add-on device on the Arduino hardware.
            %
            %   Syntax:
            %   device = addon(a,libname)
            %   device = addon(a,libname,Name,Value)
            %
            %   Description:
            %   device = addon(a,libname)      Connects to an add-on device that uses the specified library
            %
            %   Example:
            %       a = arduino('COM7','Uno','Libraries','Adafruit\MotorShieldV2');
            %       shield = addon(a,'Adafruit\MotorShieldV2');
            %
            %   Example:
            %       a = arduino('COM7','Uno','Libraries','Adafruit\MotorShieldV2');
            %       shield = addon(a,'Adafruit\MotorShieldV2','I2CAddress','0x62');
            %
            %   Input Arguments:
            %   a       - Arduino
            %   libname - The library needs to be used (string)
            %
            %   Name-Value Pair Input Arguments:
            %   Specify optional comma-separated pairs of Name,Value arguments. Name is the argument name and Value is the corresponding value. 
            %   Name must appear inside single quotes (' '). You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
            %
            %   NV Pair:
            %   'I2CAddress'     - The I2C address of the add-on shield device (numeric or string)
            %   'PWMFrequency'   - The frequency of the PWM signals that drive the DC motors (numeric)
            %
            %   See also i2cdev, servo, spidev
            
            try       
               if ischar(libname)
                  givenLibrary = strrep(libname, '\', '/');
               	  if isempty(strfind(givenLibrary, '/'))
                      validAddonLibs = {};
                      temp = strfind(obj.Libraries, '/');
                      for libCount = 1:length(temp)
                          if ~isempty(temp{libCount})
                              validAddonLibs = [validAddonLibs, obj.Libraries(libCount)]; %#ok<AGROW>
                          end
                      end
                      if isempty(validAddonLibs)
                          obj.localizedError('MATLAB:arduinoio:general:noAddonLibraryUploaded');
                      else
                          obj.localizedError('MATLAB:arduinoio:general:invalidAddonLibraryValue', libname, strjoin(validAddonLibs, ', '));
                      end
                  end
               else
                   obj.localizedError('MATLAB:arduinoio:general:invalidAddonLibraryType');
               end
               
               if isempty(obj.Libraries)
                   obj.localizedError('MATLAB:arduinoio:general:noAddonLibraryUploaded');
               else
                   givenLibrary = validatestring(givenLibrary, obj.Libraries); % check given libraries all exist
               end
               constructCmd = strcat(arduinoio.internal.getLibraryClassName(givenLibrary), '(obj, varargin{:})');
               addonObj = eval(constructCmd);
            catch e
                if isequal(e.identifier, 'MATLAB:unrecognizedStringChoice')
                    validAddonLibs = {};
                    temp = strfind(obj.Libraries, '/');
                    for libCount = 1:length(temp)
                        if ~isempty(temp{libCount})
                            validAddonLibs = [validAddonLibs, obj.Libraries(libCount)]; %#ok<AGROW>
                        end
                    end
                    if ~isempty(validAddonLibs)
                        id = 'MATLAB:arduinoio:general:invalidAddonLibraryValue';
                        e = MException(id, getString(message(id, strrep(libname,'\', '\\'), strjoin(validAddonLibs, ', '))));
                    else
                        id = 'MATLAB:arduinoio:general:noAddonLibraryUploaded';
                        e = MException(id, getString(message(id)));
                    end
                end
                throwAsCaller(e);
            end
        end
        
        function addrs = scanI2CBus(obj, bus)
            %   Scan Arduino I2C bus for connected I2C devices and return the device addresses.
            %
            %   Syntax:
            %   addrs = scanI2CBus(a,bus);
            %
            %   Description: 
            %   Scans the specified Arduino hardware I2C bus for conected I2C devices, and returns a cell array of the I2C device addresses in hex. 
            %
            %   Example:
            %   TMP102 I2C device connected on I2C bus 0.
            %       a = arduino('com9');
            %       addrs = scanI2CBus(a);
            %
            %   Input Arguments:
            %   a   - Arduino
            %   bus - I2C bus number (numeric, default 0)
            %
            %   Output Arguments:
            %   addrs - I2C bus addresses in hex (cell array of strings)
            %
            %   See also i2cdev
            
            if nargin < 2
                bus = 0;
            end
            
            try
                terminals = obj.getI2CTerminals();
                
                if strcmp(obj.Board, 'Due')
                    buses = 0:1;
                else
                    buses = 0:floor(numel(terminals)/2)-1;
                end
                
                try
                    bus = arduinoio.internal.validateIntParameterRanged('I2C Bus', bus, 0, buses(end));
                catch
                    buses = sprintf('%d, ', buses);
                    buses = buses(1:end-2);
                    obj.localizedError('MATLAB:arduinoio:general:invalidBoardBusNumber',...
                        obj.Board, buses);
                end

                % Configure I2C pins
                if (floor(numel(terminals)-1)/2) >= bus
                    isAnalog = obj.IsAnalogTerminal(terminals(bus*2+1));
                    if isAnalog
                        pins = obj.getAnalogPinsFromTerminals(terminals);
                        sda = pins(bus*2+1);
                        scl = pins(bus*2+2);

                        sdaConfig = obj.configureAnalogResource(sda);
                        if ~(strcmp(sdaConfig, 'Unset') || strcmp(sdaConfig, 'I2C'))
                            obj.localizedError('MATLAB:arduinoio:general:reservedI2CPins', ...
                                obj.Board, 'analog', ['A' num2str(sda)], ['A' num2str(scl)], ...
                                num2str(sda), sdaConfig, 'configureAnalogPin');
                        end

                        sclConfig = obj.configureAnalogResource(scl);
                        if ~(strcmp(sclConfig, 'Unset') || strcmp(sclConfig, 'I2C'))
                            obj.localizedError('MATLAB:arduinoio:general:reservedI2CPins', ...
                                obj.Board, 'analog', ['A' num2str(sda)], ['A' num2str(scl)], ...
                                num2str(scl), sclConfig, 'configureAnalogPin');
                        end

                        % If all validations have passed, reserve the sda/scl pins
                        % for I2C
                        configureAnalogPin(obj.ResourceManager, sda, 'I2C', 'I2C', true);
                        configureAnalogPin(obj.ResourceManager, scl, 'I2C', 'I2C', true);
                    else
                        pins = obj.getDigitalPinsFromTerminals(terminals);
                        sda = pins(bus*2+1);
                        scl = pins(bus*2+2);

                        sdaConfig = obj.configureDigitalResource(sda);
                        if ~(strcmp(sdaConfig, 'Unset') || strcmp(sdaConfig, 'I2C'))
                            obj.localizedError('MATLAB:arduinoio:general:reservedI2CPins', ...
                                obj.Board, 'digital', ['D' num2str(sda)], ['D' num2str(scl)], ...
                                num2str(sda), sdaConfig, 'configureDigitalPin');
                        end

                        sclConfig = obj.configureDigitalResource(scl);
                        if ~(strcmp(sclConfig, 'Unset') || strcmp(sclConfig, 'I2C'))
                            obj.localizedError('MATLAB:arduinoio:general:reservedI2CPins', ...
                                obj.Board, 'digital', ['D' num2str(sda)], ['D' num2str(scl)], ...
                                num2str(scl), sclConfig, 'configureDigitalPin');
                        end

                        % If all validations have passed, reserve the sda/scl pins
                        % for I2C
                        configureDigitalPin(obj.ResourceManager, sda, 'I2C', 'I2C', true);
                        configureDigitalPin(obj.ResourceManager, scl, 'I2C', 'I2C', true);
                    end
                end
                
                libID = getLibraryID(obj, 'I2C');
                addrs = scanI2CBus(obj.Protocol, libID, bus);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    %% Private methods
    methods(Access = private)    
        function output = parseInputs(obj, inputs)
        % Parse validate given inputs
            output = struct('Port', '', 'Board', '', 'Libraries', {{''}}, 'TraceOn', false, 'ForceBuildOn', false);
            nInputs = length(inputs);
            switch nInputs
                case 0
                    % return empty fields
                case 1
                    % only Port parameter can be provided alone
                    port = inputs{1};
                    % Validate Port data type and value
                    if ~ischar(port)
                        obj.localizedError('MATLAB:arduinoio:general:invalidPortType');
                    elseif (ispc && ~isequal(lower(port(1)), 'c')) || ...
                            (~ispc && ~isequal(lower(port(1)), '/'))
                        obj.localizedError('MATLAB:arduinoio:general:invalidPortValue', port);
                    end
                    output.Port = port;
                otherwise
                    % Port and Board parameters have to be both given to
                    % provide any additional parameter-value pair
                    port = inputs{1};
                    % 1. Validate Port data type and value
                    if ~ischar(port)
                        obj.localizedError('MATLAB:arduinoio:general:invalidPortType');
                    elseif (ispc && ~isequal(lower(port(1)), 'c')) || ...
                            (~ispc && ~isequal(lower(port(1)), '/'))
                        obj.localizedError('MATLAB:arduinoio:general:invalidPortValue', port);
                    end
                    board = inputs{2};
                    % 2. Validate Board data type
                    if ~ischar(board)
                        obj.localizedError('MATLAB:arduinoio:general:invalidBoardType');
                    end
                    if nInputs > 2
                        % Check both Port and Board values have been given
                        if mod(nInputs, 2) % odd number of parameters have been given
                            obj.localizedError('MATLAB:arduinoio:general:paramNotInPairs');
                        end
                        
                        inputs = inputs(3:end);
                        p = inputParser;
                        p.PartialMatching = true;
                        addParameter(p, 'Libraries', {''});
                        addParameter(p, 'TraceOn', false, @islogical);
                        addParameter(p, 'ForceBuildOn', false, @islogical);
                        parse(p, inputs{:});
                        output = p.Results;
                        
                        % 3. Validate Libraries data type
                        if iscellstr(output.Libraries)
                        elseif ischar(output.Libraries)
                            if isempty(output.Libraries) % '' remains empty
                                % do nothing
                            else % 'servo, i2c' -> {'servo', 'i2c'}
                                output.Libraries = strtrim(strsplit(output.Libraries, ','));
                            end
                        else
                            obj.localizedError('MATLAB:arduinoio:general:invalidLibrariesType');
                        end
                    end
                    output.Port = port;
                    output.Board = board;
            end
        end
        
        function initProperties(obj, inputs) 
        % Populate all properties of arduino object based on given inputs
            try 
                props = parseInputs(obj, inputs); 
                props = populateArduinoProperties(obj.Utility, props);
            catch e
                switch e.identifier
                    case 'MATLAB:InputParser:ParamMissingValue'
                        message = e.message;
                        index = strfind(message, '''');
                        param = e.message(index(1):index(2)+1);
                        obj.localizedError('MATLAB:arduinoio:general:missingParamValue', param);
                    case 'MATLAB:InputParser:UnmatchedParameter'
                        message = e.message;
                        index = strfind(message, '''');
                        param = e.message(index(1):index(2)+1);
                        obj.localizedError('MATLAB:arduinoio:general:invalidParam', param);
                    otherwise
                        throwAsCaller(e);
                end
            end
            obj.Port = props.Port;
            obj.Board = props.Board;
            obj.Libraries = props.Libraries;
            obj.TraceOn = props.TraceOn;
            obj.ForceBuildOn = props.ForceBuildOn;
            obj.LibrariesSpecified = props.LibrariesSpecified;
        end
        
        function initUtility(obj)
            obj.Utility = arduinoio.internal.UtilityCreator.getInstance();
        end
        
        function initResourceManager(obj, boardType)
            obj.ResourceManager = arduinoio.internal.ResourceManager(boardType);
        end
        
        function flag = initCommunication(obj, connectionObj)
            flag = true;
            try
                obj.Protocol = arduinoio.internal.Firmata(connectionObj, obj.TraceOn); 
            catch e
                if strcmp(e.identifier, 'MATLAB:serial:fopen:opfailed')
                    obj.localizedError('MATLAB:arduinoio:general:openFailed', obj.Port, obj.Board);
                else
                    flag = false;
                end
            end
        end
        
        function initServerConnection(obj, transportLayerObj)
            % If serial object is not passed in, create one with
            % default value
            if isempty(transportLayerObj) 
                obj.SerialConnection = serial(obj.Port, 'BaudRate', 115200);
                obj.SerialConnection.InputBufferSize = 65536;
                obj.SerialConnection.OutputBufferSize = 65536;
                obj.SerialConnection.Timeout = 10;
                obj.SerialConnection.Terminator = 'LF'; % New line feed
            end
            
            successFlag = initCommunication(obj, obj.SerialConnection); % TODO be modified to add serialdev object

            if ~successFlag % open serial port failed or expected number of bytes was not received
                if ~obj.LibrariesSpecified && isempty(obj.Libraries)
                    obj.Libraries = obj.DefaultLibList;
                end
                obj.Libraries = validateLibraries(obj.Utility, obj.Libraries); % check existence and completeness of libraries
                obj.LibraryIDs = 0:(length(obj.Libraries)-1);
                buildInfo = getBuildInfo(obj.ResourceManager);
                buildInfo.Port = obj.Port;
                buildInfo.Libraries = obj.Libraries;
                buildInfo.TraceOn = obj.TraceOn;
                disp(obj.getLocalizedText('MATLAB:arduinoio:general:programmingArduino', buildInfo.Board, buildInfo.Port));
                updateServer(obj.Utility, buildInfo);
                successFlag = initCommunication(obj, obj.SerialConnection); % To be modified to add serialdev object
                if ~successFlag 
                    obj.localizedError('MATLAB:arduinoio:general:incorrectServerInitialization');
                end
            else
                % check already downloaded libraries if any and retrieve IDs
                % If nothing has been downloaded, update server code
                % If server code exists but libraries are different, update
                % server code
                % If server code exists and libraries are the same, reuse old
                % library IDs
                [getInfoSuccessFlag, oldLibNames, oldLibIDs, oldBoard, oldTraceOn] = getServerInfo(obj.Protocol);
                if ~obj.LibrariesSpecified && isempty(obj.Libraries) % no libraries are given
                    if getInfoSuccessFlag % use the retrieved libs from the board
                        obj.Libraries = oldLibNames;
                    else % use default libraries
                        obj.Libraries = obj.DefaultLibList;
                    end
                end
                obj.Libraries = validateLibraries(obj.Utility, obj.Libraries); % check existence and completeness of libraries
                obj.LibraryIDs = 0:(length(obj.Libraries)-1);
                if ~getInfoSuccessFlag || ~isequal(sort(oldLibNames), sort(obj.Libraries)) || obj.ForceBuildOn || ~isequal(oldTraceOn, obj.TraceOn) || ~isequal(oldBoard, obj.Board)
                    buildInfo = getBuildInfo(obj.ResourceManager);
                    buildInfo.Port = obj.Port;
                    buildInfo.Libraries = obj.Libraries;
                    buildInfo.TraceOn = obj.TraceOn;
                    closeTransportLayer(obj.Protocol);
                    disp(obj.getLocalizedText('MATLAB:arduinoio:general:programmingArduino', buildInfo.Board, buildInfo.Port));
                    updateServer(obj.Utility, buildInfo);
                    openTransportLayer(obj.Protocol);
                else
                    updateLibraryIDs(obj, oldLibNames, oldLibIDs);
                end
            end
            
            % Initialize all pins state to input 
            try
                resetPinsState(obj.Protocol);
            catch e
                throwAsCaller(e);
            end
        end
        
        function updateLibraryIDs(obj, libNames, libIDs)
            for whichLib = 1:numel(obj.Libraries)
                IndexC = strfind(libNames, obj.Libraries{whichLib});
                obj.LibraryIDs(whichLib) = libIDs(not(cellfun('isempty', IndexC)));
            end
        end
    end
       
    %% Public methods for arduino libraries implementing LibraryBase
    methods(Access = {?arduinoio.LibraryBase,...
                      ?arduinoio.AddonBase,...
                      ?arduinoio.accessor.UnitTest})
                  
        function id = getLibraryID(obj, libName)
            if ~isempty(strfind(strjoin(obj.Libraries), libName))
                id = sum(obj.LibraryIDs.*strcmp(obj.Libraries, libName));
            else
                obj.localizedError('MATLAB:arduinoio:general:libraryNotUploaded', libName);
            end
        end
        
        function count = getAvailableRAM(obj)
            count = getAvailableRAM(obj.Protocol);
        end
        
        function value =  sendCustomMessage(obj, libName, cmd, timeout)
            libID = getLibraryID(obj, libName);
            if nargin < 4
                value = obj.Protocol.sendCustomMessage(libID, cmd);
            else
                value = obj.Protocol.sendCustomMessage(libID, cmd, timeout);
            end
        end
        
        function result = getMCU(obj)
            result = obj.ResourceManager.MCU;
        end
        
        function result = IsAnalogTerminal(obj, terminal)
            result = ismember(terminal, obj.ResourceManager.TerminalsAnalog);
        end
        
        function pins = getAnalogPinsFromTerminals(obj, terminals)
            pins = obj.ResourceManager.getAnalogPinsFromTerminals(terminals);
        end
        
        function pins = getDigitalPinsFromTerminals(~, terminals)
            pins = terminals;
        end
        
        function result = isTerminalAnalog(obj, terminal)
            result = obj.ResourceManager.isTerminalAnalog(terminal);
        end
        
        function result = isTerminalDigital(obj, terminal)
            result = obj.ResourceManager.isTerminalDigital(terminal);
        end
        
        function result = isTerminalI2C(obj, terminal)
            result = obj.ResourceManager.isTerminalI2C(terminal);
        end
        
        function result = isTerminalSPI(obj, terminal)
            result = obj.ResourceManager.isTerminalSPI(terminal);
        end
        
        function result = isTerminalPWM(obj, terminal)
            result = obj.ResourceManager.isTerminalPWM(terminal);
        end
        
        function result = isTerminalServo(obj, terminal)
            result = obj.ResourceManager.isTerminalServo(terminal);
        end
        
        function value = getTerminalMode(obj, terminal)
            value = obj.ResourceManager.getTerminalMode(terminal);
        end
        
        function pins = getI2CTerminals(obj, bus)
            if nargin < 2
                bus = 0;
            end
            pins = obj.ResourceManager.getI2CTerminals(bus);
        end
        
        function pins = getSPITerminals(obj)
            pins = obj.ResourceManager.getSPITerminals();
        end
        
        function terminal = getTerminalFromDigitalPin(obj, pin)
            terminal = obj.ResourceManager.getTerminalFromDigitalPin(pin);
        end
        
        function terminal = getTerminalFromAnalogPin(obj, pin)
            terminal = obj.ResourceManager.getTerminalFromAnalogPin(pin);
        end
        
        function varargout = configureAnalogResource(obj, pin, resourceOwner, mode, forceConfig)
            if nargout > 0
                varargout = {obj.ResourceManager.configureAnalogPin(pin)};
            else
                obj.ResourceManager.configureAnalogPin(pin, resourceOwner, mode, forceConfig);
            end
        end
        
        function varargout = configureDigitalResource(obj, pin, resourceOwner, mode, forceConfig)
            if nargout > 0
                varargout = {obj.ResourceManager.configureDigitalPin(pin)};
            else
                prevMode = configureDigitalPin(obj.ResourceManager, pin);
                obj.ResourceManager.configureDigitalPin(pin, resourceOwner, mode, forceConfig);
                mode = configureDigitalPin(obj.ResourceManager, pin);
                if ismember(mode, {'Input', 'Output', 'Pullup'})
                    if ~strcmp(prevMode, mode) && ...
                       ~(strcmp(prevMode, 'Pullup') && strcmp(mode, 'Input'))
                        configureDigitalPin(obj.Protocol, pin, mode)
                    end
                end
            end
        end
        
        % Pin Validation Methods
        function validateAnalogTerminal(obj, terminal)
            obj.ResourceManager.validateAnalogTerminal(terminal);
        end
        
        function validateDigitalTerminal(obj, terminal)
            obj.ResourceManager.validateDigitalTerminal(terminal);
        end
        
        function validateServoTerminal(obj, terminal)
            obj.ResourceManager.validateServoTerminal(terminal);
        end
        
        function validateSPITerminal(obj, terminal)
            obj.ResourceManager.validateSPITerminal(terminal);
        end
        
        %% A simple resource manager for clients of the Arduino object
        %
        %
        
        % Resource Count Methods
        function count = incrementResourceCount(obj, resourceName)
            if any(ismember(keys(obj.ResourceMap), resourceName))
                resource = obj.ResourceMap(resourceName);
                if ~isfield(resource, 'Count')
                    resource.Count = 1;
                else
                    resource.Count = resource.Count + 1;
                end
            else
                resource.Count = 1;
            end
            count = resource.Count;
            obj.ResourceMap(resourceName) = resource;
        end
        
        function count = decrementResourceCount(obj, resourceName)
            count = 0;
            if any(ismember(keys(obj.ResourceMap), resourceName))
                resource = obj.ResourceMap(resourceName);
                if isfield(resource, 'Count')
                    resource.Count = resource.Count - 1;
                    count = resource.Count;
                    obj.ResourceMap(resourceName) = resource;
                end
            end
        end
        
        function count = getResourceCount(obj, resourceName)
            count = 0;
            if any(ismember(keys(obj.ResourceMap), resourceName))
                resource = obj.ResourceMap(resourceName);
                count = resource.Count;
            end
        end
        
        % Resource Slots
        function slot = getFreeResourceSlot(obj, resourceName)
            if any(ismember(keys(obj.ResourceMap), resourceName))
                resource = obj.ResourceMap(resourceName);
                if ~isfield(resource, 'Slot')
                    slot = 1;
                    resource.Slot(slot) = true;
                    obj.ResourceMap(resourceName) = resource;
                    return;
                end
                for slot = 1:numel(resource.Slot)
                    if resource.Slot(slot) ==  false
                        resource.Slot(slot) = true;
                        obj.ResourceMap(resourceName) = resource;
                        return;
                    end
                end
                slot = numel(resource.Slot) + 1;
                resource.Slot(slot) = true;
                obj.ResourceMap(resourceName) = resource;
                return;
            end
            
            slot = 1;
            resource.Slot(slot) = true;
            obj.ResourceMap(resourceName) = resource;
        end
        
        function clearResourceSlot(obj, resourceName, slot)
            if any(ismember(keys(obj.ResourceMap), resourceName))
                resource = obj.ResourceMap(resourceName);
                if slot > 0 && slot <= numel(resource.Slot)
                    resource.Slot(slot) = false;
                    obj.ResourceMap(resourceName) = resource;
                end
            end
        end
        
        % Resource Properties
        function setResourceProperty(obj, resourceName, propertyName, propertyValue)
            if any(ismember(keys(obj.ResourceMap), resourceName))
                resource = obj.ResourceMap(resourceName);
            end
            resource.(propertyName) = propertyValue;
            obj.ResourceMap(resourceName) = resource;
        end
        
        function propertyValue = getResourceProperty(obj, resourceName, propertyName)
            propertyValue = [];
            if any(ismember(keys(obj.ResourceMap), resourceName))
                resource = obj.ResourceMap(resourceName);
                if isfield(resource, propertyName)
                    propertyValue = resource.(propertyName);
                end
            end
        end
        
        % Get/Set Pin ResourceOwner
        function resourceOwner = getResourceOwner(obj, pin)
            resourceOwner = getResourceOwner(obj.ResourceManager, pin);
        end
        
        % Clear Digital/Analog Resource
        function clearDigitalResource(obj, pin)
            overrideDigitalResource(obj.ResourceManager, pin, '', 'Unset');
        end
        
        function clearAnalogResource(obj, pin)
            overrideAnalogResource(obj.ResourceManager, pin, '', 'Unset');
        end
        
        % Override Resource Parameters (Mode and ResourceOwner)
        function overrideAnalogResource(obj, pin, resourceOwner, pinMode)
            overrideAnalogResource(obj.ResourceManager, pin, resourceOwner, pinMode);
        end
        
        function overrideDigitalResource(obj, pin, resourceOwner, pinMode)
            overrideDigitalResource(obj.ResourceManager, pin, resourceOwner, pinMode);
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            header = arduinoio.internal.insertHelpLinkInDisplay(header);
            disp(header);

            sAvailableAnalogPins = sprintf('%d, ', obj.AvailableAnalogPins);
            sAvailableAnalogPins(end-1:end) = [];
            sAvailableDigitalPins = sprintf('%d, ', obj.AvailableDigitalPins);
            sAvailableDigitalPins(end-1:end) = [];
            
            % Display main options
            fprintf('                    Port: ''%s''\n', obj.Port);
            fprintf('                   Board: ''%s''\n', obj.Board);
            fprintf('     AvailableAnalogPins: [%s]\n', sAvailableAnalogPins);
            fprintf('    AvailableDigitalPins: [%s]\n', sAvailableDigitalPins);
            if ~isempty(obj.Libraries)
            fprintf('               Libraries: {''%s''}\n', ...
                arduinoio.internal.renderCellArrayOfStringsToString(obj.Libraries, ''', '''));
            else
            fprintf('               Libraries: {}\n');
            end
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end
