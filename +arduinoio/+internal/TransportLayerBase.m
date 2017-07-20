
%   Copyright 2014 The MathWorks, Inc.

classdef TransportLayerBase < handle
    % TransportLayerBase
    properties
        connectionObject
        Debug
    end
    
    methods(Abstract)
        value = sendMessage(obj, msg, timeout);
        openConnection(obj);
        closeConnection(obj);
    end
    
    methods(Abstract, Access = protected)
        writeMessage(obj, msg);
        value = readMessage(obj);
    end
end