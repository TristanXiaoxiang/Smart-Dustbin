classdef (Abstract)ProtocolBase < arduinoio.internal.BaseClass
    % ProtocolBase
    %
    % Copyright 2014 The MathWorks, Inc.
    
    properties
        TransportLayer
    end
    
    properties(Access = protected)
        SequenceID = uint8(0)
    end
    
    methods
        %% CTOR
        function obj = ProtocolBase(connectionObj, traceOn)
            obj.TransportLayer = createTransportLayer(obj, connectionObj, traceOn);
            openConnection(obj.TransportLayer);
        end
    end
       
    methods (Access=protected)
        function delete(obj)
        end
    end
       
    methods
        % Methods, if not overridden, not supported
        function writeDigitalPin(obj, pin, value) %#ok<*INUSD>
            obj.localizedError('MATLAB:arduinoio:general:notSupportedMethod', ...
                'writeDigitalPin', class(obj));
        end
        
        function value = readDigitalPin(obj, pin) %#ok<*STOUT>
            obj.localizedError('MATLAB:arduinoio:general:notSupportedMethod', ...
                'readDigitalPin', class(obj));
        end
        
        function configureDigitalPin(obj, pin, mode)
            obj.localizedError('MATLAB:arduinoio:general:notSupportedMethod', ...
                'configureDigitalPin', class(obj));
        end
        
        function writePWMVoltage(obj, pin, voltage, aref)
            obj.localizedError('MATLAB:arduinoio:general:notSupportedMethod', ...
                'writePWMVoltage', class(obj));
        end
        
        function writePWMDutyCycle(obj, pin, dutyCycle)
            obj.localizedError('MATLAB:arduinoio:general:notSupportedMethod', ...
                'writePWMDutyCycle', class(obj));
        end
        
        function value = readVoltage(obj, pin, aref)
            obj.localizedError('MATLAB:arduinoio:general:notSupportedMethod', ...
                'readVoltage', class(obj));
        end
        
        function playTone(obj, pin, frequency, duration)
            obj.localizedError('MATLAB:arduinoio:general:notSupportedMethod', ...
                'playTone', class(obj));
        end
        
        function addrs = scanI2CBus(obj, libID, bus)
            obj.localizedError('MATLAB:arduinoio:general:notSupportedMethod', ...
                'scanI2CBus', class(obj));
        end
        
        function value = getAvailableRAM(obj)
            obj.localizedError('MATLAB:arduinoio:general:notSupportedMethod', ...
                'getAvailableRAM', class(obj));
        end
    end
    
    methods(Abstract)
        % methods every protocol must override   
        [getLibSuccessFlag, libnames, libIDs, board, traceOn] = getServerInfo(obj); 
        value = sendCustomMessage(obj, libID, cmd, timeout);
        value = sendMWMessage(obj, cmd, timeout);
    end
    
    methods(Access = private)
        function tlObj = createTransportLayer(obj, connectionObj, traceOn)
            if isa(connectionObj, 'serial')
                tlObj = arduinoio.internal.SerialHostTransportLayer(connectionObj, traceOn);
            elseif isa(connectionObj, 'raspi.internal.serialdev')
                tlObj = arduinoio.internal.SerialRaspiTransportLayer(connectionObj, traceOn);
            end
        end
    end
    
end