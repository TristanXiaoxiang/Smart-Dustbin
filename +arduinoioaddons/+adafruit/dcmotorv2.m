classdef dcmotorv2 < arduinoio.MotorBase & matlab.mixin.CustomDisplay
    %DCMOTORV2 Create a DC motor device object.
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties
        Speed = 0
    end
    
    properties (Dependent = true, Access = private)
        ConvertedSpeed
    end
    
    properties (SetAccess = private)
        IsRunning = false;
    end
    
    properties(Access = private)
        ResourceMode
        ResourceOwner
        MaxDCMotors
    end
    
    properties(Access = private, Constant = true)
        CREATE_DC_MOTOR     = hex2dec('02')
        START_DC_MOTOR      = hex2dec('03')
        STOP_DC_MOTOR       = hex2dec('04')
        SET_SPEED_DC_MOTOR  = hex2dec('05')
    end
    
    %% Constructor
    methods(Hidden, Access = public)
        function obj = dcmotorv2(parentObj, motorNumber, varargin)
            obj.Pins = [];
            obj.MaxDCMotors = 4;
            obj.Parent = parentObj;
            arduinoObj = parentObj.Parent;
            
            obj.ResourceOwner = 'AdafruitMotorShieldV2\DCMotor';
            obj.ResourceMode = 'AdafruitMotorShieldV2\DCMotor';
            motorNumber = arduinoio.internal.validateIntParameterRanged(...
                [obj.ResourceOwner 'MotorNumber'], ...
                motorNumber, ...
                1, obj.MaxDCMotors);
            
            dcmotors = getResourceProperty(arduinoObj, obj.ResourceOwner, 'dcmotors');
            if isempty(dcmotors)
                locDC = 1;
                dcmotors = [parentObj.I2CAddress zeros(1, obj.MaxDCMotors)];
            else
                shieldDCAddresses = dcmotors(:, 1);
                [~, locDC] = ismember(parentObj.I2CAddress, shieldDCAddresses);
                if locDC == 0
                    dcmotors = [dcmotors; parentObj.I2CAddress zeros(1, obj.MaxDCMotors)];
                    locDC = size(dcmotors, 1);
                end
                
                % Check for resource conflict with DC Motors
                if dcmotors(locDC, motorNumber+1)
                    obj.localizedError('MATLAB:arduinoio:general:conflictDCMotor', num2str(motorNumber));
                end
            end

            % Check for resource conflict with Steppers
            steppersResource = 'AdafruitMotorShieldV2\Stepper';
            steppers = getResourceProperty(arduinoObj, steppersResource, 'steppers');
            if ~isempty(steppers)
                shieldStepperAddresses = steppers(:, 1);
                [~, locStepper] = ismember(parentObj.I2CAddress, shieldStepperAddresses);
                if locStepper ~= 0
                    possibleConflictingStepperMotorNumber = floor((motorNumber-1)/2)+1;
                    dcMotorNumbers = [(possibleConflictingStepperMotorNumber-1)*2+1, (possibleConflictingStepperMotorNumber-1)*2+2];
                    if steppers(locStepper, possibleConflictingStepperMotorNumber+1)
                        obj.localizedError('MATLAB:arduinoio:general:conflictDCMotorTerminals', ...
                            num2str(dcMotorNumbers(1)),...
                            num2str(dcMotorNumbers(2)),...
                            num2str(possibleConflictingStepperMotorNumber));
                    end
                end
            end

            % No clonflicts
            dcmotors(locDC, motorNumber+1) = 1;
            setResourceProperty(arduinoObj, obj.ResourceOwner, 'dcmotors', dcmotors);
            obj.MotorNumber = motorNumber;
            
            try
                p = inputParser;
                addParameter(p, 'Speed', 0);
                parse(p, varargin{:});
            catch
                obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyName',...
                    obj.ResourceOwner, ...
                    arduinoio.internal.renderCellArrayOfStringsToString(p.Parameters, ', '));
            end
            
            obj.Speed = p.Results.Speed;
            
            createDCMotor(obj);
        end
    end
    
    %%
    methods
        function start(obj)
            %   Start the DC motor.
            %
            %   Syntax:
            %   start(dev)
            %
            %   Description:
            %   Start the DC motor so that it can rotate if Speed is non-zero
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       dcm = dcmotor(shield,1,'Speed',0.3);
            %       start(dcm);
			%
            %   Input Arguments:
            %   dev       - DC motor device 
            %
			%   See also stop
            
            try
                if obj.IsRunning == false
                    if obj.Speed ~= 0
                        startDCMotor(obj);
                    end
                    obj.IsRunning = true;
                else
                    obj.localizedWarning('MATLAB:arduinoio:general:dcmotorAlreadyRunning', num2str(obj.MotorNumber));
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        function stop(obj)
            %   Stop the DC motor.
            %
            %   Syntax:
            %   stop(dev)
            %
            %   Description:
            %   Stop the DC motor if it has been started
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       dcm = dcmotor(shield,1,'Speed',0.3);
            %       start(dcm);
            %       stop(dcm);
			%
            %   Input Arguments:
            %   dev       - DC motor device 
            %
			%   See also start
            
            try
                if obj.IsRunning == true
                    stopDCMotor(obj);
                    obj.IsRunning = false;
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        function set.Speed(obj, speed)
            % Valid speed range is -1 to 1
            try
                speed = arduinoio.internal.validateDoubleParameterRanged(...
                    'AdafruitMotorShieldV2\DCMotor Speed', speed, -1, 1);
                
                if speed == -0
                    speed = 0;
                end
                
                if obj.IsRunning == true %#ok<MCSUP>
                    if speed > 0
                        convertedSpeed = floor(abs(speed)*255);
                    else
                        convertedSpeed = -1*floor(abs(speed)*255);
                    end
                    setSpeedDCMotor(obj, convertedSpeed);
                end
                obj.Speed = speed;
            catch e
                throwAsCaller(e);
            end
        end
        
        function out = get.ConvertedSpeed(obj)
            if obj.Speed > 0
                out = floor(abs(obj.Speed)*255);
            else
                out = -1*floor(abs(obj.Speed)*255);
            end
        end
    end
    
	%% Destructor
    methods (Access=protected)
        function delete(obj)
            orig_state = warning('off','MATLAB:class:DestructorError');
            try
                parentObj = obj.Parent;
                arduinoObj = parentObj.Parent;
                
                % Clear the DC Motor
                dcmotors = getResourceProperty(arduinoObj, obj.ResourceOwner, 'dcmotors');
                shieldDCAddresses = dcmotors(:, 1);
                [~, locDC] = ismember(parentObj.I2CAddress, shieldDCAddresses);
                dcmotors(locDC, obj.MotorNumber+1) = 0;
                setResourceProperty(arduinoObj, obj.ResourceOwner, 'dcmotors', dcmotors);
                
                stopDCMotor(obj);
            catch
                % Do not throw errors on destroy.
                % This may result from an incomplete construction.
            end
            warning(orig_state.state, 'MATLAB:class:DestructorError');
        end
    end
    
    %% Private methods
    methods (Access = private)
        function createDCMotor(obj)
             commandID = obj.CREATE_DC_MOTOR;
            try
                cmd = [];
                sendCommand(obj, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
        
        function startDCMotor(obj)
            commandID = obj.START_DC_MOTOR;
            try
                if obj.ConvertedSpeed > 0 
                    direction = 1;
                else
                    direction = 2;
                end
                speed = uint8(abs(obj.ConvertedSpeed));
                cmd = [...
                       arduinoio.BinaryToASCII(speed);
                       direction ...
                       ];
                sendCommand(obj, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
        
        function stopDCMotor(obj)
            commandID = obj.STOP_DC_MOTOR;
            try
                cmd = [];
                sendCommand(obj, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
        
        function setSpeedDCMotor(obj, speed)
            commandID = obj.SET_SPEED_DC_MOTOR;
            try
                if speed > 0
                    direction = 1;
                else
                    direction = 2;
                end
                speed = uint8(abs(speed));
                cmd = [...
                       arduinoio.BinaryToASCII(speed);
                       direction ...
                       ];
                sendCommand(obj, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    
    %% Protected methods
    methods(Access = protected)    
        function output = sendCommand(obj, commandID, cmd)
            cmd = [obj.MotorNumber - 1; cmd]; 
            output = sendShieldCommand(obj.Parent, commandID, cmd);
        end
    end
        
    %% Protected methods
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            header = arduinoio.internal.insertHelpLinkInDisplay(header);
            disp(header);
            
            % Display main options
            fprintf('    MotorNumber: %d (M%d)\n', obj.MotorNumber, obj.MotorNumber);
            fprintf('          Speed: %-15.2f\n', obj.Speed);
            fprintf('      IsRunning: %-15d\n', obj.IsRunning);  
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end