classdef i2cdev < arduinoio.LibraryBase & matlab.mixin.CustomDisplay
    %I2CDEV Create an I2C device object.
    %
    % dev = i2cdev(bus, address) creates an I2C device object.
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties(SetAccess = immutable)
        Bus
        Address
    end
    
    properties(Access = private, Constant = true)
        MaxI2CData     = 16
    end
    
    properties(Access = private, Constant = true)
        START_I2C       = hex2dec('00')
        READ            = hex2dec('02')
        WRITE           = hex2dec('03')
        READ_REGISTER   = hex2dec('04')
        WRITE_REGISTER  = hex2dec('05')
        AvailablePrecisions = {'int8', 'uint8', 'int16', 'uint16'}
        SIZEOF = struct('int8', 1, 'uint8', 1, 'int16', 2, 'uint16', 2)
    end
    
    properties(Access = private)
        ResourceOwner
    end
    
    properties(Access = protected, Constant = true)
        LibraryName = 'I2C'
        DependentLibraries = {}
        CXXIncludeDirectories = struct('avr', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'avr', 'libraries', 'Wire'), fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'avr', 'libraries', 'Wire', 'utility'), fullfile(arduinoio.SPPKGRoot, '+arduinoio', 'src')}, ...
            'sam', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'sam', 'libraries', 'Wire'), fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'avr', 'libraries', 'Wire', 'utility'), fullfile(arduinoio.SPPKGRoot, '+arduinoio', 'src')})
        CXXFiles = struct('avr', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'avr', 'libraries', 'Wire', 'Wire.cpp')}, ...
            'sam', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'sam', 'libraries', 'Wire', 'Wire.cpp')})
        CIncludeDirectories = struct('avr', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'avr', 'libraries', 'Wire', 'utility')}, ...
            'sam', [])
        CFiles = struct('avr', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'avr', 'libraries', 'Wire', 'utility', 'twi.c')}, ...
            'sam', [])
        WrapperClassHeaderFile = 'I2CBase.h'
        WrapperClassName = 'I2CBase'
    end
    
    methods (Hidden, Access = public)
        function obj = i2cdev(parentObj, address, varargin)
            obj.Parent = parentObj;
            obj.ResourceOwner = 'I2C';
            
            address = validateAddress(obj, address);
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
            obj.Address = address;
            
            I2CTerminals = parentObj.getI2CTerminals();
            isAnalog = parentObj.IsAnalogTerminal(I2CTerminals(1));
            
            try
                p = inputParser;
                addOptional(p, 'Bus', 0);
                parse(p, varargin{:});
            catch
                obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyName',...
                    obj.ResourceOwner, ...
                    arduinoio.internal.renderCellArrayOfStringsToString(p.Parameters, ', '));
            end
            
            obj.Bus = validateBus(obj, p.Results.Bus);
            
            if strcmp(parentObj.Board, 'Due') && (obj.Bus == 1)
                obj.Pins = [];
            else
                switch isAnalog
                    case true
                        sda = parentObj.getAnalogPinsFromTerminals(I2CTerminals(obj.Bus*2+1));
                        scl = parentObj.getAnalogPinsFromTerminals(I2CTerminals(obj.Bus*2+2));
                        
                        sdaConfig = parentObj.configureAnalogResource(sda);
                        if ~(strcmp(sdaConfig, 'Unset') || strcmp(sdaConfig, 'I2C'))
                            obj.localizedError('MATLAB:arduinoio:general:reservedI2CPins', ...
                                parentObj.Board, 'analog', ['A' num2str(sda)], ['A' num2str(scl)], ...
                                num2str(sda), sdaConfig, 'configureAnalogPin');
                        end
                        configureAnalogResource(parentObj, ...
                            sda, ...
                            obj.ResourceOwner, ...
                            'I2C', ...
                            false);
                        
                        sclConfig = parentObj.configureAnalogResource(scl);
                        if ~(strcmp(sclConfig, 'Unset') || strcmp(sclConfig, 'I2C'))
                            obj.localizedError('MATLAB:arduinoio:general:reservedI2CPins', ...
                                parentObj.Board, 'analog', ['A' num2str(sda)], ['A' num2str(scl)], ...
                                num2str(scl), sclConfig, 'configureAnalogPin');
                        end
                        configureAnalogResource(parentObj, ...
                            scl, ...
                            obj.ResourceOwner, ...
                            'I2C', ...
                            false);
                        obj.Pins = [sda scl];
                    case false
                        sda = parentObj.getDigitalPinsFromTerminals(I2CTerminals(obj.Bus*2+1));
                        scl = parentObj.getDigitalPinsFromTerminals(I2CTerminals(obj.Bus*2+2));
                        
                        sdaConfig = parentObj.configureDigitalResource(sda);
                        if ~(strcmp(sdaConfig, 'Unset') || strcmp(sdaConfig, 'I2C'))
                            obj.localizedError('MATLAB:arduinoio:general:reservedI2CPins', ...
                                parentObj.Board, 'digital', ['D' num2str(sda)], ['D' num2str(scl)], ...
                                num2str(sda), sdaConfig, 'configureDigitalPin');
                        end
                        configureDigitalResource(parentObj, ...
                            sda, ...
                            obj.ResourceOwner, ...
                            'I2C', ...
                            false);
                        
                        sclConfig = parentObj.configureDigitalResource(scl);
                        if ~(strcmp(sclConfig, 'Unset') || strcmp(sclConfig, 'I2C'))
                            obj.localizedError('MATLAB:arduinoio:general:reservedI2CPins', ...
                                parentObj.Board, 'digital', ['D' num2str(sda)], ['D' num2str(scl)], ...
                                num2str(scl), sclConfig, 'configureDigitalPin');
                        end
                        configureDigitalResource(parentObj, ...
                            scl, ...
                            obj.ResourceOwner, ...
                            'I2C', ...
                            false);
                        obj.Pins = [sda scl];
                end
            end
            
            startI2C(obj);
        end
    end
    
    %% Destructor
    methods (Access=protected)
        function delete(obj)
            try
                parentObj = obj.Parent;
                I2CTerminals = parentObj.getI2CTerminals();
                isAnalog = parentObj.IsAnalogTerminal(I2CTerminals(1));
                
                i2cAddresses = getResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses');
                i2cAddresses(i2cAddresses==obj.Address) = [];
                setResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses', i2cAddresses);
                
                switch isAnalog
                    case true
                        try
                            sda = parentObj.getAnalogPinsFromTerminals(I2CTerminals(obj.Bus+1));
                            configureAnalogResource(obj.Parent, ...
                                sda, ...
                                obj.ResourceOwner, ...
                                'Unset', ...
                                true);
                        catch
                        end
                        try
                            scl = parentObj.getAnalogPinsFromTerminals(I2CTerminals(obj.Bus+2));
                            configureAnalogResource(obj.Parent, ...
                                scl, ...
                                obj.ResourceOwner, ...
                                'Unset', ...
                                true);
                        catch
                        end
                    case false
                        try
                            sda = parentObj.getDigitalPinsFromTerminals(I2CTerminals(obj.Bus+1));
                            configureDigitalResource(obj.Parent, ...
                                sda, ...
                                obj.ResourceOwner, ...
                                'Unset', ...
                                true);
                        catch
                        end
                        try
                            scl = parentObj.getDigitalPinsFromTerminals(I2CTerminals(obj.Bus+2));
                            configureDigitalResource(obj.Parent, ...
                                scl, ...
                                obj.ResourceOwner, ...
                                'Unset', ...
                                true);
                        catch
                        end
                end
            catch
                % Do not throw errors on destroy.
                % This may result from an incomplete construction.
            end
        end
    end
    
    methods(Access = public)
        function dataOut = read(obj, count, precision)
            %   Read data from I2C device.
            %
            %   Syntax:
            %   dataOut = read(dev,count,precision)
            %
            %   Description:
            %   Returns the count number of data from the I2C device
            %
            %   Example:
            %       a = arduino();
            %       dev = i2cdev(a, '0x48');
            %       dataOut = read(dev,1);
            %
            %   Input Arguments:
            %   dev       - I2C device
            %   count	  - Number of data to read from the device (double)
            %   precision - Data precision that matches with size of the register on the device (string)
            %
            %   Example:
            %       a = arduino();
            %       dev = i2cdev(a, '0x48');
            %       dataOut = read(dev,1,'uint16');
            %
            %   Output Argument:
            %   dataOut   - Register value(s) read from the device with the specified data precision
            %
            %   See also write, writeRegister, readRegister
            
            try
                if (nargin < 3)
                    precision = 'uint8';
                else
                    precision = validatestring(precision, obj.AvailablePrecisions, ...
                        '', 'precision');
                end
            catch e
                if strcmp(e.identifier, 'MATLAB:unrecognizedStringChoice')
                    id = 'MATLAB:arduinoio:general:invalidPrecision';
                    e = MException(id, getString(message(id, strjoin(obj.AvailablePrecisions, ', '))));
                end
                throwAsCaller(e);
            end
            
            try
                arduinoio.internal.validateIntParameterRanged('count', count, 1, floor(obj.MaxI2CData/obj.SIZEOF.(precision)));
            catch
                obj.localizedError('MATLAB:arduinoio:general:maxI2CData');
            end
            numBytes = uint8(count * obj.SIZEOF.(precision));
            
            commandID = obj.READ;
            try
                cmd = arduinoio.BinaryToASCII(numBytes);
                output = sendCommand(obj, obj.LibraryName, commandID, cmd);
                if isempty(output)
                    obj.localizedError('MATLAB:arduinoio:general:communicationLostI2C', num2str(obj.Bus));
                end
                returnedCMDId = output(1);
                readSuccessFlag = output(4);
                if returnedCMDId ~= obj.READ
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                elseif readSuccessFlag == hex2dec('FF') % error code
                    obj.localizedError('MATLAB:arduinoio:general:unsuccessfulI2CRead', num2str(count), precision);
                else
                    dataOut = uint8(output(5:end));
                    dataOut = typecast(dataOut, precision);
                end
            catch e
                if strcmp(e.identifier, 'MATLAB:badsubscript')
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                end
                throwAsCaller(e);
            end
        end
        
        function write(obj, dataIn, precision)
            %   Write data to I2C device.
            %
            %   Syntax:
            %   write(dev,dataIn,precision)
            %
            %   Description:
            %   Writes the data, dataIn, with the specified precision to the I2C device
            %
            %   Example:
            %       a = arduino();
            %       dev = i2cdev(a, '0x48');
            %       write(dev,[hex2dec('20') hex2dec('51')]);
            %
            %   Input Arguments:
            %   dev       - I2C device
            %   dataIn	  - Data to write to the I2C device (double)
            %   precision - Data precision that matches with size of the register on the device (string)
            %
            %   Example:
            %       a = arduino();
            %       dev = i2cdev(a, '0x48');
            %       write(dev,[hex2dec('20') hex2dec('51')], 'uint16');
            %
            %   See also read, writeRegister, readRegister
            
            try
                if (nargin < 3)
                    precision = 'uint8';
                else
                    precision = validatestring(precision, obj.AvailablePrecisions, ...
                        '', 'precision');
                end
            catch e
                if strcmp(e.identifier, 'MATLAB:unrecognizedStringChoice')
                    id = 'MATLAB:arduinoio:general:invalidPrecision';
                    e = MException(id, getString(message(id, strjoin(obj.AvailablePrecisions, ', '))));
                end
                throwAsCaller(e);
            end
            
            dataIn = cast(dataIn, precision);
            dataIn = typecast(dataIn, 'uint8');
            numBytes = uint8(numel(dataIn) * obj.SIZEOF.(precision));
            
            try
                if numBytes > obj.MaxI2CData
                    obj.localizedError('MATLAB:arduinoio:general:maxI2CData');
                end
            catch e
                throwAsCaller(e);
            end
            
            commandID = obj.WRITE;
            try
                cmd = arduinoio.BinaryToASCII(numBytes);
                tmp = [];
                for ii = 1:numBytes
                    tmp = [tmp; dataIn(ii)]; %#ok<AGROW>
                end
                cmd = [cmd; arduinoio.BinaryToASCII(tmp)];
                output = sendCommand(obj, obj.LibraryName, commandID, cmd);
                if isempty(output)
                    obj.localizedError('MATLAB:arduinoio:general:communicationLostI2C', num2str(obj.Bus));
                end
                returnedCMDId = output(1);
                if returnedCMDId ~= obj.WRITE
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                end
            catch e
                if strcmp(e.identifier, 'MATLAB:badsubscript')
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                end
                throwAsCaller(e);
            end
        end
        
        function out = readRegister(obj, register, precision)
            %   Read from register on I2C device.
            %
            %   Syntax:
            %   out = readRegister(dev,register,precision)
            %
            %   Description:
            %   Returns data with specified precision from the register on the I2C device
            %
            %   Example:
            %       a = arduino();
            %       dev = i2cdev(a, '0x48');
            %       value = readRegister(dev,hex2dec('20'));
            %
            %   Input Arguments:
            %   dev       - I2C device
            %   register  - Address of the register on the I2C device (double or string)
            %   precision - Data precision that matches with size of the register on the device (string)
            %
            %   Example:
            %       a = arduino();
            %       dev = i2cdev(a, '0x48');
            %       value = readRegister(dev,hex2dec('20'),'uint16');
            %
            %   Output Argument:
            %   out  - Value of the register with the specified data precision
            %
            %   See also read, write, writeRegister
            
            try
                arduinoio.internal.validateIntParameterRanged('register', register, 0, 255);
                if (nargin < 3)
                    precision = 'uint8';
                else
                    precision = validatestring(precision, obj.AvailablePrecisions, ...
                        '', 'precision');
                end
            catch e
                if strcmp(e.identifier, 'MATLAB:unrecognizedStringChoice')
                    id = 'MATLAB:arduinoio:general:invalidPrecision';
                    e = MException(id, getString(message(id, strjoin(obj.AvailablePrecisions, ', '))));
                end
                throwAsCaller(e);
            end
            numBytes = obj.SIZEOF.(precision);
            
            register = uint8(register);
            
            commandID = obj.READ_REGISTER;
            try
                cmd = [arduinoio.BinaryToASCII(register); numBytes];
                output = sendCommand(obj, obj.LibraryName, commandID, cmd);
                if isempty(output)
                    obj.localizedError('MATLAB:arduinoio:general:communicationLostI2C', num2str(obj.Bus));
                end
                returnedCMDId = output(1);
                readSuccessFlag = output(4);
                if returnedCMDId ~= obj.READ_REGISTER
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                elseif readSuccessFlag == hex2dec('FF') % error code
                    obj.localizedError('MATLAB:arduinoio:general:unsuccessfulI2CReadRegister', precision, dec2hex(register));
                else
                    % Little endian
                    out = uint8(output(end:-1:5));
                    out = typecast(out, precision);
                end
            catch e
                if strcmp(e.identifier, 'MATLAB:badsubscript')
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                end
                throwAsCaller(e);
            end
        end
        
        function writeRegister(obj, register, dataIn, precision)
            %   Write to register on I2C device.
            %
            %   Syntax:
            %   writeRegister(dev,register,dataIn,precision)
            %
            %   Description:
            %   Writes data, dataIn, with specified precision to the register on the I2C device
            %
            %   Example:
            %       a = arduino();
            %       dev = i2cdev(a, '0x48');
            %       writeRegister(dev,hex2dec('20'),10);
            %
            %   Input Arguments:
            %   dev       - I2C device
            %   register  - Address of the register on the I2C device (double or string)
            %   dataIn	  - Data to write to the register (double)
            %   precision - Data precision that matches with size of the register on the device (string)
            %
            %   Example:
            %       a = arduino();
            %       dev = i2cdev(a, '0x48');
            %       writeRegister(dev,hex2dec('20'),10,'uint16');
            %
            %   See also read, write, readRegister
            
            try
                arduinoio.internal.validateIntParameterRanged('register', register, 0, 255);
                if (nargin < 4)
                    precision = 'uint8';
                else
                    precision = validatestring(precision, obj.AvailablePrecisions, ...
                        '', 'precision');
                end
            catch e
                if strcmp(e.identifier, 'MATLAB:unrecognizedStringChoice')
                    id = 'MATLAB:arduinoio:general:invalidPrecision';
                    e = MException(id, getString(message(id, strjoin(obj.AvailablePrecisions, ', '))));
                end
                throwAsCaller(e);
            end
            
            dataIn = cast(dataIn, precision);
            dataIn = typecast(dataIn, 'uint8');
            numBytes = obj.SIZEOF.(precision);
            
            register = uint8(register);
            
            commandID = obj.WRITE_REGISTER;
            try
                cmd = [arduinoio.BinaryToASCII(register); numBytes];
                tmp = [];
                for ii = 1:numBytes
                    % Little endian
                    tmp = [tmp; dataIn(1+numBytes-ii)]; %#ok<AGROW>
                end
                cmd = [cmd; arduinoio.BinaryToASCII(tmp)];
                output = sendCommand(obj, obj.LibraryName, commandID, cmd);
                if isempty(output)
                    obj.localizedError('MATLAB:arduinoio:general:communicationLostI2C', num2str(obj.Bus));
                end
                returnedCMDId = output(1);
                if returnedCMDId ~= obj.WRITE_REGISTER
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                end
            catch e
                if strcmp(e.identifier, 'MATLAB:badsubscript')
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                end
                throwAsCaller(e);
            end
        end
    end
    
    %% Private methods
    methods (Access = private)
        function startI2C(obj)
            commandID = obj.START_I2C;
            try
                cmd = obj.Address;
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods(Access = protected)
        function output = sendCommand(obj, libName, commandID, varargin)
            cmd = [commandID; obj.Bus; obj.Address];
            if nargin > 3
                cmd = [cmd; varargin{1}];
            end
            output = sendCustomMessage(obj.Parent, libName, cmd);
        end
        
        function bus = validateBus(obj, bus)
            parentObj = obj.Parent;
            I2CTerminals = parentObj.getI2CTerminals();
            
            if strcmp(parentObj.Board, 'Due')
                numBuses = 0:1;
            else
                numBuses = 0:floor(numel(I2CTerminals)/2)-1;
            end
            
            try
                bus = arduinoio.internal.validateIntParameterRanged('I2C Bus', bus, 0, numBuses(end));
            catch
                numBuses = sprintf('%d, ', numBuses);
                numBuses = numBuses(1:end-2);
                obj.localizedError('MATLAB:arduinoio:general:invalidBoardBusNumber',...
                    parentObj.Board, numBuses);
            end
        end
        
        function addr = validateAddress(obj, address)
            if ~ischar(address)
                try
                    addr = arduinoio.internal.validateIntParameterRanged('address', address, 0, 127);
                    return;
                catch
                    printableAddress = false;
                    try
                        printableAddress = (size(num2str(address), 1) == 1);
                    catch
                    end
                    
                    if printableAddress
                        obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', num2str(address), num2str(0), num2str(127));
                    else
                        obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddressType');
                    end
                end
                
            else
                tmpAddr = address;
                if strcmpi(tmpAddr(1:2), '0x')
                    tmpAddr = tmpAddr(3:end);
                end
                if strcmpi(tmpAddr(end), 'h')
                    tmpAddr(end) = [];
                end
                
                try
                    dec = hex2dec(tmpAddr);
                catch
                    obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', address,num2str(0), num2str(127));
                end
                
                if dec < 0 || dec > 127
                    obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', address, num2str(0), num2str(127));
                end
            end
            
            addr = dec;
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            header = arduinoio.internal.insertHelpLinkInDisplay(header);
            disp(header);
            
            % Display main options
            parentObj = obj.Parent;
            
            if strcmp(parentObj.Board, 'Due') && (obj.Bus == 1)
                fprintf('       Pins: %-15s\n', 'SDA1, SCL1');
            else
                I2CTerminals = parentObj.getI2CTerminals();
                isAnalog = parentObj.IsAnalogTerminal(I2CTerminals(1));
                if isAnalog
                    pins = ['A' num2str(obj.Pins(1)) '(SDA), A' num2str(obj.Pins(2)) '(SCL)'];
                else
                    pins = ['D' num2str(obj.Pins(1)) '(SDA), D' num2str(obj.Pins(2)) '(SCL)'];
                end
                fprintf('       Pins: %-15s\n', pins);
            end
            
            fprintf('        Bus: %-1d\n', obj.Bus);
            fprintf('    Address: %-1d (0x%02s)\n', obj.Address, dec2hex(obj.Address));
            fprintf('\n');
            
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end


