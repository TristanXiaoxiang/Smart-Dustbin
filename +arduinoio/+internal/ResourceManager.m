classdef (Hidden,Sealed) ResourceManager < arduinoio.internal.BaseClass
    %RESOURCEMANAGER Manages resources based on board type
    % matlab\test\toolbox\matlab\hardware\supportpackages\arduinoio\unit
    
    %   Copyright 2014 The MathWorks, Inc.
    
    properties (SetAccess = private, GetAccess = {?arduino, ...
            ?arduinoio.accessor.UnitTest})
        Board
        Protocol
        MemorySize
        BaudRate
        MCU
        FCPU
        Core
        Variant
        VIDPID
        NumTerminals
        TerminalsDigital
        TerminalsAnalog
        TerminalsPWM
        TerminalsServo
        TerminalsI2C
        TerminalsSPI

        AnalogPinModes
        DigitalPinModes
        
        % Array struture of terminals (absolute pin numbers) used to track
        % status of each resource.
        Terminals
        
        AnalogOffset
    end
    
    methods
        function obj = ResourceManager(boardType)
            b = arduinoio.internal.BoardInfo.getInstance();
            try
                boardType = validatestring(boardType, {b.Boards.Name});
            catch e
                switch (e.identifier)
                    case 'MATLAB:ambiguousStringChoice'
                        matches = strfind(lower({b.Boards.Name}), lower(boardType));
                        matchedBoards = {};
                        for ii = 1:numel(matches)
                            if ~isempty(matches{ii}) && matches{ii}==1
                                matchedBoards = [matchedBoards, b.Boards(ii).Name]; %#ok<AGROW>
                            end
                        end
                        obj.localizedError('MATLAB:arduinoio:general:ambiguousBoardName', boardType, strjoin(matchedBoards, ', '));
                    otherwise
                        obj.localizedError('MATLAB:arduinoio:general:invalidBoardName', boardType, ...
                            arduinoio.internal.renderCellArrayOfStringsToString({b.Boards.Name}, ', '));
                end
            end
            idx = find(arrayfun(@(x) ~isempty(strfind(x.Name, boardType)), b.Boards), 1);
            if isempty(idx)
                obj.localizedError('MATLAB:arduinoio:general:invalidBoardName', boardType, ...
                            arduinoio.internal.renderCellArrayOfStringsToString({b.Boards.Name}, ', '));
            end
            
            obj.Board            = b.Boards(idx).Name;
            obj.Protocol         = b.Boards(idx).Protocol;
            obj.MemorySize       = b.Boards(idx).MemorySize;
            obj.BaudRate         = b.Boards(idx).BaudRate;
            obj.MCU              = b.Boards(idx).MCU;
            obj.FCPU             = b.Boards(idx).FCPU;
            obj.Core             = b.Boards(idx).Core;
            obj.Variant          = b.Boards(idx).Variant;
            obj.VIDPID           = b.Boards(idx).VIDPID;
            obj.NumTerminals     = b.Boards(idx).NumPins;
            obj.TerminalsDigital = b.Boards(idx).PinsDigital;
            obj.TerminalsAnalog  = b.Boards(idx).PinsAnalog;
            obj.TerminalsPWM     = b.Boards(idx).PinsPWM;
            obj.TerminalsServo   = b.Boards(idx).PinsServo;
            obj.TerminalsI2C     = b.Boards(idx).PinsI2C;
            obj.TerminalsSPI     = b.Boards(idx).PinsSPI;
            
            % Arrange in MOSI, MISO, SCK, SS
            if ~isempty(obj.TerminalsSPI)
                if all(sort(obj.TerminalsSPI) == 10:13)
                    obj.TerminalsSPI = [11 12 13 10];
                elseif all(sort(obj.TerminalsSPI) == 50:53)
                    obj.TerminalsSPI = [51 50 52 53];
                end
            end
            
            % Define a structure for terminal data
            terminals.Mode = 'Unset';
            terminals.ResourceOwner = '';
            
            % Arduino pins are zero based. Use the getTerminalMode() method to
            % access this array with correct pin indexing.
            %
            obj.Terminals = repmat(terminals, 1, obj.NumTerminals);
            obj.Terminals(1).Mode = 'Rx';
            obj.Terminals(2).Mode = 'Tx';
            
            if isTerminalAnalog(obj, obj.TerminalsI2C(1))
                obj.AnalogPinModes = {'Input', 'I2C', 'Unset'};
                obj.DigitalPinModes = {'Input', 'Output', 'Pullup', 'PWM', 'Servo', 'SPI', 'Unset'};
            else
                obj.AnalogPinModes = {'Input', 'Unset'};
                obj.DigitalPinModes = {'Input', 'Output', 'Pullup', 'PWM', 'Servo', 'SPI', 'I2C', 'Unset'};
            end
            
            obj.AnalogOffset = obj.TerminalsDigital(end) + 1;
        end
    end
    
    %% Friend methods
    %
    %
    methods (Access = {?arduino, ...
            ?arduinoio.accessor.UnitTest})
        
        function varargout = configureDigitalPin(obj, pin, resourceOwner, mode, forceConfig)
            % Work with absolute microcontroller pin numbers (terminals)
            terminal = obj.getTerminalFromDigitalPin(pin);
            if nargout > 0
                if nargin ~= 2
                    error('Internal Error: configureDigitalPin invalid number of input arguments');
                end
                terminal = obj.validateDigitalTerminal(terminal, 'Unset');
                varargout = {obj.getTerminalMode(terminal)};
                return;
            end
            
            %% Validate input parameter types
            terminal = obj.validateDigitalTerminal(terminal, mode);
            mode = obj.validateTerminalMode(terminal, mode);
            validateattributes(forceConfig, {'logical'}, {'scalar'});
            validateattributes(resourceOwner, {'char'}, {'2d'});
            
            %% Only the resource owner may make changes to a terminal configuration.
            obj.validateResourceOwner(terminal, resourceOwner);
            
            %% Check if the terminal is already in the requested target mode
            if strcmp(obj.getTerminalMode(terminal), mode)
                obj.updateResource(terminal, resourceOwner, mode);
                return;
            end
            
            %% Validate that the target mode is supported by the terminal.
            obj.validateTerminalSupportsTerminalMode(terminal, mode);
            
            %% Validate terminal mode conversion is compatible with previous
            % terminal mode
            if ~forceConfig
                obj.validateCompatibleTerminalModeConversion(terminal, mode);
            end
            
            % Apply new terminal mode (if applicable)
            obj.applyFilterTerminalModeChange(terminal, resourceOwner, mode, forceConfig);
        end
        
        function varargout = configureAnalogPin(obj, pin, resourceOwner, mode, forceConfig)
            % Work with absolute microcontroller pin numbers (terminals)
            terminal = obj.getTerminalFromAnalogPin(pin);
            
            if nargout > 0
                if nargin ~= 2
                    error('Internal Error: configureAnalogPin invalid number of input arguments');
                end
                terminal = obj.validateAnalogTerminal(terminal, 'Unset');
                varargout = {obj.getTerminalMode(terminal)};
                return;
            end
            
            %% Validate input parameter types
            terminal = obj.validateAnalogTerminal(terminal, mode);
            mode = obj.validateTerminalMode(terminal, mode);
            validateattributes(forceConfig, {'logical'}, {'scalar'});
            validateattributes(resourceOwner, {'char'}, {'2d'});
            
            %% Only the resource owner may make changes to a terminal configuration.
            obj.validateResourceOwner(terminal, resourceOwner);
            
            %% Check if the terminal is already in the requested target mode
            if strcmp(obj.getTerminalMode(terminal), mode)
                obj.updateResource(terminal, resourceOwner, mode);
                return;
            end
            
            %% Validate that the target terminal mode is supported by analog pins.
            obj.validateTerminalSupportsTerminalMode(terminal, mode);
            
            %% Validate to/from terminal configuration conversion compatibility
            if ~forceConfig
                obj.validateCompatibleTerminalModeConversion(terminal, mode);
            end
            
            %% Validate terminal mode conversion rules
            obj.validateTerminalConversionRules(terminal, mode);
                
            % Apply new terminal mode (if applicable)
            obj.applyFilterTerminalModeChange(terminal, resourceOwner, mode, forceConfig);
        end
        
        function buildInfo = getBuildInfo(obj)
            buildInfo.Board      = obj.Board;
            buildInfo.Protocol   = obj.Protocol;
            buildInfo.MemorySize = num2str(obj.MemorySize);
            buildInfo.BaudRate   = num2str(obj.BaudRate);
            buildInfo.MCU        = obj.MCU;
            buildInfo.FCPU       = num2str(obj.FCPU);
            buildInfo.Core       = obj.Core;
            buildInfo.Variant    = obj.Variant;
            buildInfo.VIDPID     = obj.VIDPID;
        end
        
        function result = isTerminalAnalog(obj, terminal)
            obj.validateTerminalType(terminal);
            result = ismember(terminal, obj.TerminalsAnalog);
        end
        
        function result = isTerminalDigital(obj, terminal)
            obj.validateTerminalType(terminal);
            result = ismember(terminal, obj.TerminalsDigital);
        end
        
        function result = isTerminalI2C(obj, terminal)
            obj.validateTerminalType(terminal);
            result = ismember(terminal, obj.TerminalsI2C);
        end
        
        function result = isTerminalSPI(obj, terminal)
            obj.validateTerminalType(terminal);
            result = ismember(terminal, obj.TerminalsSPI);
        end
        
        function result = isTerminalPWM(obj, terminal)
            obj.validateTerminalType(terminal);
            result = ismember(terminal, obj.TerminalsPWM);
        end
        
        function result = isTerminalServo(obj, terminal)
            obj.validateTerminalType(terminal);
            result = ismember(terminal, obj.TerminalsServo);
        end
        
        function value = getTerminalMode(obj, terminal)
            % Arduino terminal numbers are zero based
            value = obj.Terminals(terminal+1).Mode;
        end
        
        function pins = getAnalogPinsFromTerminals(obj, terminals)
            pins = terminals - obj.AnalogOffset;
        end
        
        function pins = getDigitalPinsFromTerminals(~, terminals)
            pins = terminals;
        end
        
        function terminal = getTerminalFromDigitalPin(~, pin)
            terminal = pin;
        end
        
        function terminal = getTerminalFromAnalogPin(obj, pin)
            terminal = pin + obj.AnalogOffset;
        end
        
        function terminals = getI2CTerminals(obj, bus)
            if nargin < 2
                bus = 0;
            end
            terminals = obj.TerminalsI2C(2*bus+1:2*bus+2);
        end
        
        function terminals = getSPITerminals(obj)
            terminals = obj.TerminalsSPI;
        end
        
        function resourceOwner = getResourceOwner(obj, terminal)
            resourceOwner = '';
            r = obj.Terminals(terminal+1).ResourceOwner;
            if ~isempty(r)
                resourceOwner = r;
            end
        end
        
        function result = validateAnalogTerminal(obj, terminal, mode)
            obj.validateTerminalType(terminal);
            try
                obj.validateTerminalMode(terminal, mode);
            catch
                % Allow this method to validate the terminal even is mode
                % is invalid
                mode = 'Unset';
            end
            
            validTerminals = obj.TerminalsAnalog;
            switch mode
                case 'I2C'
                    validTerminals = intersect(validTerminals, obj.TerminalsI2C);
                otherwise
            end
            
            switch mode
                case 'Unset'
                    pinType = 'analog';
                case {'Input', 'Output', 'Pullup', 'Servo'}
                    pinType = ['analog ' lower(mode)];
                otherwise
                    pinType = ['analog ' mode];
            end
            
            if ~ismember(terminal, validTerminals)
                validPins = obj.getAnalogPinsFromTerminals(validTerminals);
                obj.localizedError('MATLAB:arduinoio:general:invalidPin', ...
                    obj.Board, pinType, obj.validPins(validPins));
            end
            result = double(terminal);
        end
        
        function result = validateDigitalTerminal(obj, terminal, mode)
            obj.validateTerminalType(terminal);
            try
                obj.validateTerminalMode(terminal, mode);
            catch
                % Allow this method to validate the terminal even is mode
                % is invalid
                mode = 'Unset';
            end
            
            validTerminals = obj.TerminalsDigital;
            switch mode
                case 'PWM'
                    validTerminals = intersect(validTerminals, obj.TerminalsPWM);
                case 'Servo'
                    validTerminals = intersect(validTerminals, obj.TerminalsServo);
                case 'I2C'
                    validTerminals = intersect(validTerminals, obj.TerminalsI2C);
                case 'SPI'
                    validTerminals = intersect(validTerminals, obj.TerminalsSPI);
                otherwise
            end
            
            switch mode
                case 'Unset'
                    pinType = 'digital';
                case {'Input', 'Output', 'Pullup', 'Servo'}
                    pinType = ['digital ' lower(mode)];
                otherwise
                    pinType = ['digital ' mode];
            end
            
            if ~ismember(terminal, validTerminals)
                validPins = obj.getDigitalPinsFromTerminals(validTerminals);
                obj.localizedError('MATLAB:arduinoio:general:invalidPin', ...
                    obj.Board, pinType, obj.validPins(validPins));
            end
            result = double(terminal);
        end
        
        function result = validateServoTerminal(obj, terminal)
            if ~obj.isTerminalServo(terminal)
                obj.localizedError('MATLAB:arduinoio:general:invalidPin', ...
                    obj.Board, 'servo', obj.validPins(obj.getDigitalPinsFromTerminals(obj.TerminalsServo)));
            end
            result = double(terminal);
        end
        
        function result = validateSPITerminal(obj, terminal)
            if ~obj.isTerminalSPI(terminal)
                obj.localizedError('MATLAB:arduinoio:general:invalidPin', ...
                    obj.Board, 'SPI', obj.validPins(obj.getDigitalPinsFromTerminals(obj.TerminalsSPI)));
            end
            result = double(terminal);
        end
        
        function overrideDigitalResource(obj, pin, resourceOwner, mode)
            terminal = getTerminalFromDigitalPin(obj, pin);
            updateResource(obj, terminal, resourceOwner, mode)
        end
        
        function overrideAnalogResource(obj, pin, resourceOwner, mode)
            terminal = getTerminalFromAnalogPin(obj, pin);
            updateResource(obj, terminal, resourceOwner, mode)
        end
    end
    
    %% Private methods
    %
    %
    methods (Access = {?arduinoio.accessor.UnitTest})
        function terminalMode = validateTerminalMode(obj, terminal, mode)
            if strcmp(mode, '')
                mode = 'Unset';
            end
            
            % Composit modes
            parentMode = '';
            try
                k = strfind(mode, '\');
                if ~isempty(k)
                    kk = k(end);
                    parentMode = mode(1:kk);
                    mode = mode(kk+1:end);
                end
            catch
            end
            
            if isTerminalAnalog(obj, terminal)
                subsystem = 'analog';
                validUserPinModes = obj.AnalogPinModes;
            else
                subsystem = 'digital';
                validUserPinModes = obj.DigitalPinModes;
            end
            
            allValidPinModes = validUserPinModes;
            allValidPinModes{end+1} = 'Reserved';
            try
                mode = validatestring(mode, allValidPinModes);
            catch
                obj.localizedError('MATLAB:arduinoio:general:invalidPinMode', ...
                    subsystem, ...
                    arduinoio.internal.renderCellArrayOfStringsToString(validUserPinModes, ', '));
            end
            terminalMode = [parentMode mode];
        end
        
        function validateTerminalType(obj, terminal)
            try
                validateattributes(terminal, {'numeric'}, {'scalar', 'integer', 'real', 'finite', 'nonnan'});
            catch
                obj.localizedError('MATLAB:arduinoio:general:invalidPinType');
            end
        end
        
        function validateTerminalSupportsTerminalMode(obj, terminal, mode)
            if obj.isTerminalAnalog(terminal)
                subsystem = 'analog';
                if ismember(mode, {'Pullup', 'Servo', 'PWM'})
                    obj.localizedError('MATLAB:arduinoio:general:invalidPinMode', 'analog', obj.AnalogPinModes);
                end
            else
                subsystem = 'digital';
            end
            
            switch(mode)
                case 'I2C'
                    if ~obj.isTerminalI2C(terminal)
                        obj.localizedError('MATLAB:arduinoio:general:invalidPin', obj.Board, [subsystem ' I2C'], obj.validPins(obj.TerminalsI2C));
                    end
                case 'SPI'
                    if ~obj.isTerminalSPI(terminal)
                        obj.localizedError('MATLAB:arduinoio:general:invalidPin', obj.Board, [subsystem ' SPI'], obj.validPins(obj.TerminalsSPI));
                    end
                case 'PWM'
                    if ~obj.isTerminalPWM(terminal)
                        obj.localizedError('MATLAB:arduinoio:general:invalidPin', obj.Board, [subsystem ' PWM'], obj.validPins(obj.TerminalsPWM));
                    end
                case 'Servo'
                    if ~obj.isTerminalServo(terminal)
                        obj.localizedError('MATLAB:arduinoio:general:invalidPin', obj.Board, [subsystem ' Servo'], obj.validPins(obj.TerminalsServo));
                    end
                otherwise
                    % Input, Output, Pullup, and Unset are supported by all
                    % Digital pins.
            end
        end
        
        function validateCompatibleTerminalModeConversion(obj, terminal, mode)
            % Digital Pins: I2C, SPI, Input, Pullup, Output, PWM, Servo,
            % Unset
            %
            % Digital I2C, SPI, Input and Pullup modes cannot be converted
            % to any other pin modes.
            %
            % Digital Output, PWM and Servo pin modes are all digital
            % output modes that can be interchanged freely as long as they
            % are all output pins... They cannot be converted to a digital
            % input pin mode.
                        
            % There are no other restrictions on an Unset pin.
            %
            if strcmp(mode, 'Unset')
                return;
            end
            
            switch(obj.getTerminalMode(terminal))
                case {'I2C', 'SPI', 'Input', 'Servo'}
                    if obj.isTerminalAnalog(terminal)
                        obj.localizedError('MATLAB:arduinoio:general:reservedAnalogPin', ...
                            num2str(obj.getAnalogPinsFromTerminals(terminal)), ...
                            obj.getTerminalMode(terminal), ...
                            mode);
                    else
                        obj.localizedError('MATLAB:arduinoio:general:reservedDigitalPin', ...
                            num2str(obj.getDigitalPinsFromTerminals(terminal)), ...
                            obj.getTerminalMode(terminal), ...
                            mode);
                    end
                case {'PWM', 'Output'}
                    if ~ismember(mode, {'PWM', 'Output'}) % Compatible output pins
                        obj.localizedError('MATLAB:arduinoio:general:reservedDigitalPin', ...
                            num2str(obj.getDigitalPinsFromTerminals(terminal)), ...
                            obj.getTerminalMode(terminal), ...
                            mode);
                    end
                case {'Pullup'}
                    if ~ismember(mode, {'Input'}) % Compatible input pins
                        obj.localizedError('MATLAB:arduinoio:general:reservedDigitalPin', ...
                            num2str(obj.getDigitalPinsFromTerminals(terminal)), ...
                            obj.getTerminalMode(terminal), ...
                            mode);
                    end
                case {'Reserved'}
                    % Resource owner needs to handle any compatibility issues
                    %
                otherwise
                    % Unset pins are not reserved
                    %
            end
            
        end
        
        % Terminal conversion rules are hardware limitations that apply
        % regardless of forceConfig flag
        function validateTerminalConversionRules(obj, terminal, mode)
            if strcmp(obj.getTerminalMode(terminal), 'I2C') && ~strcmp(mode, 'I2C')
                if ismember(terminal, obj.TerminalsI2C)
                    bus = ceil(find(obj.TerminalsI2C == terminal)/2)-1;
                    if ismember(terminal, obj.TerminalsAnalog)
                        subsystem = 'analog';
                        sda = ['A' num2str(obj.getAnalogPinsFromTerminals(obj.TerminalsI2C(1+bus)))];
                        scl = ['A' num2str(obj.getAnalogPinsFromTerminals(obj.TerminalsI2C(2+bus)))];
                    else
                        subsystem = 'digital';
                        sda = ['D' num2str(obj.getDigitalPinsFromTerminals(obj.TerminalsI2C(1+bus)))];
                        scl = ['D' num2str(obj.getDigitalPinsFromTerminals(obj.TerminalsI2C(2+bus)))];
                    end
                    
                    obj.localizedError('MATLAB:arduinoio:general:permanentlyReservedI2CPins', ...
                        obj.Board, subsystem, sda, scl);
                end
            end
        end
        
        function applyFilterTerminalModeChange(obj, terminal, resourceOwner, mode, forceConfig)
            % Compatibility has already been verified earlier. Now simply
            % apply the configuration mode changes (except for
            % non-changable modes).
            
            % Example: If the current terminal mode is 'Pullup', reading
            % the terminal should not result in its configuration changing
            % to 'Input'.
            %
            if ~forceConfig
                if strcmp(obj.getTerminalMode(terminal), 'Pullup') && ...
                        strcmp(mode, 'Input')
                    return;
                end
            end
            
            obj.updateResource(terminal, resourceOwner, mode);
        end
        
        function updateResource(obj, terminal, resourceOwner, mode)
            obj.Terminals(terminal+1).Mode = mode;
            obj.Terminals(terminal+1).ResourceOwner = resourceOwner;
            if strcmp(mode, 'Unset')
                obj.Terminals(terminal+1).ResourceOwner = '';
            end
        end
        
        function result = validPins(~, pins)
            if isempty(pins)
                result = '-none-';
                return;
            end
            result = sprintf('%d, ', pins);
            result = result(1:end-2);
        end
        
        function validateResourceOwner(obj, terminal, resourceOwner)
            if strcmp(obj.Terminals(terminal+1).Mode, 'Unset')
                % The only time an object may claim a resource is it that
                % resource is in an unset mode
                obj.Terminals(terminal+1).ResourceOwner = resourceOwner;
                return;
            end
            
            % Throw an error if resource owners don't match
            if ~strcmp(obj.Terminals(terminal+1).ResourceOwner, resourceOwner)
                if obj.isTerminalAnalog(terminal)
                    subsystem = 'Analog';
                    pin = obj.getAnalogPinsFromTerminals(terminal);
                else
                    subsystem = 'Digital';
                    pin = obj.getDigitalPinsFromTerminals(terminal);
                end
                
                resourceOwner = obj.Terminals(terminal+1).ResourceOwner;
                mode = obj.Terminals(terminal+1).Mode;
                
                if strcmp(mode, 'I2C')
                    obj.localizedError('MATLAB:arduinoio:general:permanentlyReservedI2CPins', ...
                        obj.Board, ...
                        subsystem, ...
                        num2str(pin), num2str(pin+1));
                end
                
                if strcmp(resourceOwner, '')
                    if obj.isTerminalAnalog(terminal)
                        obj.localizedError('MATLAB:arduinoio:general:reservedResourceAnalog', subsystem, num2str(pin), mode);
                    else
                        obj.localizedError('MATLAB:arduinoio:general:reservedResourceDigital', subsystem, num2str(pin), mode);
                    end
                else
                    obj.localizedError('MATLAB:arduinoio:general:reservedResource', subsystem, num2str(pin), resourceOwner, mode);
                end
            end
        end
    end
end

