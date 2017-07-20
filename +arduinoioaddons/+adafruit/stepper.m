classdef stepper < arduinoio.MotorBase & matlab.mixin.CustomDisplay
%STEPPER Create a stepper motor device object.
    
% Copyright 2014 The MathWorks, Inc.
    
    properties(SetAccess = immutable)
        StepsPerRevolution
    end
    
    properties(Access = public)
        RPM = 0
    end
    
    properties (SetAccess = immutable)
        StepType
    end
    
    properties(Access = private)
        ResourceMode
        ResourceOwner
        MaxStepperMotors
        MaxStepsPerRevolution
    end
    
    properties(Access = private, Constant = true)
        CREATE_STEPPER     = hex2dec('06')
        RELEASE_STEPPER    = hex2dec('07')
        MOVE_STEPPER       = hex2dec('08')
        SET_SPEED_STEPPER  = hex2dec('09')
    end
    
	%% Constructor
    methods(Hidden, Access = public)
        function obj = stepper(parentObj, motorNumber, stepsPerRevolution, varargin)
            obj.Pins = [];
            obj.MaxStepperMotors = 2;
            obj.MaxStepsPerRevolution = 2^15-1;
            obj.Parent = parentObj;
            arduinoObj = parentObj.Parent;
            
            obj.ResourceOwner = 'AdafruitMotorShieldV2\Stepper';
            obj.ResourceMode = 'AdafruitMotorShieldV2\Stepper';
            motorNumber = arduinoio.internal.validateIntParameterRanged(...
                [obj.ResourceOwner 'MotorNumber'], ...
                motorNumber, ...
                1, obj.MaxStepperMotors);
            
            stepsPerRevolution = arduinoio.internal.validateIntParameterRanged(...
                [obj.ResourceOwner 'StepsPerRevolution'], ...
                stepsPerRevolution, ...
                1, obj.MaxStepsPerRevolution);
            obj.StepsPerRevolution = stepsPerRevolution;
            
            steppers = getResourceProperty(arduinoObj, obj.ResourceOwner, 'steppers');
            if isempty(steppers)
                locStepper = 1;
                steppers = [parentObj.I2CAddress zeros(1, obj.MaxStepperMotors)];
            else
                shieldStepperAddresses = steppers(:, 1);
                [~, locStepper] = ismember(parentObj.I2CAddress, shieldStepperAddresses);
                if locStepper == 0
                    steppers = [steppers; parentObj.I2CAddress zeros(1, obj.MaxStepperMotors)];
                    locStepper = size(steppers, 1);
                end
                
                % Check for resource conflict with Stepper Motors
                if steppers(locStepper, motorNumber+1)
                    obj.localizedError('MATLAB:arduinoio:general:conflictStepperMotor', num2str(motorNumber));
                end
            end

            % Check for resource conflict with DC Motors
            dcmotorResource = 'AdafruitMotorShieldV2\DCMotor';
            dcmotors = getResourceProperty(arduinoObj, dcmotorResource, 'dcmotors');
            if ~isempty(dcmotors)
                shieldDCMotorAddresses = dcmotors(:, 1);
                [~, locDC] = ismember(parentObj.I2CAddress, shieldDCMotorAddresses);
                if locDC ~= 0
                    possibleConflictingDCMotorNumber = [floor((motorNumber-1)*2)+1, floor((motorNumber-1)*2)+2];
                    if any(dcmotors(possibleConflictingDCMotorNumber+1))
                        obj.localizedError('MATLAB:arduinoio:general:conflictStepperTerminals', ...
                            num2str(possibleConflictingDCMotorNumber(1)),...
                            num2str(possibleConflictingDCMotorNumber(2)),...
                            num2str(motorNumber));
                    end
                end
            end

            % No clonflicts
            steppers(locStepper, motorNumber+1) = 1;
            setResourceProperty(arduinoObj, obj.ResourceOwner, 'steppers', steppers);
            obj.MotorNumber = motorNumber;
            
            try
                p = inputParser;
                addParameter(p, 'RPM', 0);
                addParameter(p, 'StepType', 'Single');
                parse(p, varargin{:});
            catch
                obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyName',...
                    obj.ResourceOwner, ...
                    arduinoio.internal.renderCellArrayOfStringsToString(p.Parameters, ', '));
            end
            
            stepTypeValues = {'Single', 'Double', 'Interleave', 'Microstep'};
            try
                obj.StepType = validatestring(p.Results.StepType, stepTypeValues);
            catch
                obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyValue',...
                    obj.ResourceOwner, ...
                    'StepType', ...
                    arduinoio.internal.renderCellArrayOfStringsToString(stepTypeValues, ', '));
            end
            
            createStepper(obj);
            obj.RPM = p.Results.RPM;
        end
    end
    
    %% Public methods
    methods 
        function move(obj, steps)
            %   Move the stepper motor in the specified number of steps.
            %
            %   Syntax:
            %   move(dev, steps)
            %
            %   Description:
            %   Step the stepper motor for the specified number of steps
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       sm = stepper(shield,1,200,'RPM',10);
            %       move(sm, 10);
            %
            %   Input Arguments:
            %   dev       - DC motor device 
            %   steps     - The number of steps to move
            %
			%   See also release
            
            try
                maxSteps = 2^15-1;
                steps = arduinoio.internal.validateIntParameterRanged(...
                    'AdafruitMotorShieldV2\Stepper Steps', steps, -maxSteps, maxSteps);
                
                if obj.RPM > 0
                    timeout = abs(steps)*60/(obj.RPM*obj.StepsPerRevolution);
                    moveStepper(obj, steps, timeout);
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        function release(obj)
            %   Stop the stepper motor
            %
            %   Syntax:
            %   release(dev)
            %
            %   Description:
            %   Release the stepper motor to spin freely
            %
            %   Example:
            %       a = arduino('COM7', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
            %       shield = addon(a, 'Adafruit/MotorShieldV2');
            %       sm = stepper(shield,1,200,'RPM',10);
            %       move(sm, 10);
            %       release(sm);
            %
            %   Input Arguments:
            %   dev       - stepper motor device 
            %
			%   See also move
            
            try
                releaseStepper(obj);
            catch e
                throwAsCaller(e);
            end
        end
        
        function set.RPM(obj, rpm)
            try
                maxRPM = 2^15-1;
                rpm = arduinoio.internal.validateIntParameterRanged(...
                    'Stepper RPM', rpm, 0, maxRPM);
                
                setSpeedStepper(obj, rpm);
                obj.RPM = rpm;
            catch e
                throwAsCaller(e);
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
                
                % Clear the Stepper Motor
                steppers = getResourceProperty(arduinoObj, obj.ResourceOwner, 'steppers');
                shieldDCAddresses = steppers(:, 1);
                [~, locStepper] = ismember(parentObj.I2CAddress, shieldDCAddresses);
                steppers(locStepper, obj.MotorNumber+1) = 0;
                setResourceProperty(arduinoObj, obj.ResourceOwner, 'steppers', steppers);
                
                releaseStepper(obj);
            catch
                % Do not throw errors on destroy.
                % This may result from an incomplete construction.
            end
            warning(orig_state.state, 'MATLAB:class:DestructorError');
        end
    end
    
    %% Private methods
    methods (Access = private)
        function createStepper(obj)
            commandID = obj.CREATE_STEPPER;
            try
                sprev = typecast(uint16(obj.StepsPerRevolution),'uint8');
                rpm = typecast(uint16(obj.RPM),'uint8');
                cmd = [...
                       arduinoio.BinaryToASCII(sprev);...
                       arduinoio.BinaryToASCII(rpm)...
                       ];
                sendCommand(obj, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
        
        function moveStepper(obj, steps, timeout)
            commandID = obj.MOVE_STEPPER;
            try
                if steps > 0
                    direction = 1;
                else
                    direction = 2;
                end
                
                switch obj.StepType
                    case 'Single'
                        stepType = 1;
                    case 'Double'
                        stepType = 2;
                    case 'Interleave'
                        stepType = 3;
                    case 'Microstep'
                        stepType = 4;
                    otherwise
                end
                steps = typecast(uint16(abs(steps)),'uint8');
                cmd = [...
                    arduinoio.BinaryToASCII(steps); ...
                    direction; ...
                    stepType];
                sendCommand(obj, commandID, cmd, timeout);
            catch e
                throwAsCaller(e);
            end
        end
        
        function releaseStepper(obj)
            commandID = obj.RELEASE_STEPPER;
            try
                cmd = [];
                sendCommand(obj, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
        
        function setSpeedStepper(obj, speed)
            commandID = obj.SET_SPEED_STEPPER;
            try
                speed = typecast(uint16(speed),'uint8');
                cmd = arduinoio.BinaryToASCII(speed);
                sendCommand(obj, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function output = sendCommand(obj, commandID, cmd, timeout)
            cmd = [obj.MotorNumber - 1; cmd];
            if nargin < 4
                output = sendShieldCommand(obj.Parent, commandID, cmd);
            else
                output = sendShieldCommand(obj.Parent, commandID, cmd, timeout);
            end
        end
    end
        
    %% Protected methods
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            header = arduinoio.internal.insertHelpLinkInDisplay(header);
            disp(header);
            
            % Display main options
            fprintf('           MotorNumber: %-15d\n', obj.MotorNumber);
            fprintf('    StepsPerRevolution: %-15d\n', obj.StepsPerRevolution);
            fprintf('                   RPM: %-15d\n', obj.RPM);  
            fprintf('              StepType: %s (''Single'', ''Double'', ''Interleave'', ''Microstep'')\n', obj.StepType);
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end