classdef SerialHostTransportLayer < arduinoio.internal.TransportLayerBase

%   Copyright 2014 The MathWorks, Inc.
    
    properties (Access = private, Constant = true)
        DT      = 0.005
    end
    
    properties (Access = private)
        TIMEOUT	= 5
    end
    
    %% Constructor
    methods (Access = public)
        function obj = SerialHostTransportLayer(connectionObj, debug)
            obj.connectionObject = connectionObj;
            obj.Debug = debug;
        end
    end
    
    %% Destructor
    methods (Access=protected)
        function delete(obj)
            if isvalid(obj.connectionObject) && strcmp(obj.connectionObject.Status, 'open')
                closeConnection(obj);
            end
        end
    end
    
    %% Public methods
    methods (Access = public)
        function value = sendMessage(obj, msg, timeout)
            if nargin < 3
                obj.TIMEOUT = 5;
            else
                obj.TIMEOUT = timeout;
            end
            
            writeMessage(obj, msg);
            
            [debugStr, value] = readMessage(obj);
            
            % print out received strings
            if obj.Debug
                fprintf('%s', debugStr);
				fprintf('%s\n', value);
            end
        end
        
        function openConnection(obj)
            try 
                fopen(obj.connectionObject);
            catch e
                throwAsCaller(e);
            end
            orig_state = warning;
            warning('off','MATLAB:serial:fread:unsuccessfulRead');
            data = fread(obj.connectionObject, 56); % special characters received at the initialization of server code
            if isempty(data) || isempty(strfind(char(data'), ['I', char(0), 'O', char(0)])) 
            % fails if do not receive expected number of characters or incorrect characters
                arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidServerInitResponse') % TODO
            end
            warning(orig_state);
        end
        
        function closeConnection(obj)
            fclose(obj.connectionObject);
        end
    end
    
    %%
    methods(Access = protected)
        function writeMessage(obj, msg)
            try 
                % flush the serial line before sending any command
                if obj.connectionObject.BytesAvailable
                    fread(obj.connectionObject, obj.connectionObject.BytesAvailable);
                end
                fwrite(obj.connectionObject, msg);
            catch e
                if strcmp(e.identifier, 'MATLAB:serial:fwrite:opfailed')
                    id = 'MATLAB:arduinoio:general:connectionIsLost';
                    e = MException(id, getString(message(id)));
                    fclose(obj.connectionObject);
                end
                throwAsCaller(e);
            end
        end
        
        function [debugStr, value] = readMessage(obj)
            orig_state = warning;
            warning('off','MATLAB:serial:fread:unsuccessfulRead');
            warning('off','MATLAB:serial:fscanf:unsuccessfulRead');
            
            debugStr = [];
            value = [];
            elapsedTime = 0;
            while elapsedTime < obj.TIMEOUT
                while obj.connectionObject.BytesAvailable > 0
                    firstByte = fread(obj.connectionObject, 1);
                    if firstByte == 0 % MW message starts with 0
                        msgID = fread(obj.connectionObject, 1);
                        if msgID == 0 % non debug message starts with 0
                            header = fread(obj.connectionObject, 3);
                            cmdID = header(1);
                            payLoad = header(2:end);
                            valueSize = bitshift(payLoad(1), 8) + payLoad(2);
                            if valueSize
                                value = [cmdID; payLoad; fread(obj.connectionObject, valueSize)];
                            else
                                value = [cmdID; payLoad];
                            end
                            break;
                        else
                            count = fread(obj.connectionObject, 1);
                            debugStr = [debugStr; fread(obj.connectionObject, count)]; %#ok<AGROW>
                        end
                    else
                        fscanf(obj.connectionObject);
                    end
                end
                if ~isempty(value)
                    break;
                end
                pause(obj.DT);
                elapsedTime = elapsedTime + obj.DT;
                %if obj.Debug
                %    fprintf('.');
                %end
            end
            
            warning(orig_state);
        end
    end
end