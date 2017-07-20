classdef LibraryBase < arduinoio.internal.BaseClass
% LIBRARYBASE - True library classes and, addon classes that define a
% library shall inherit from this base class to get Parent property and
% other properties and methods.

% Copyright 2014 The MathWorks, Inc.

    properties(Hidden, SetAccess = protected)
        Parent
    end
    
    properties(SetAccess = protected)
        Pins
    end
    
    % Every library class SHALL override all of the following properties
    % with default value
    properties(Abstract = true, Access = protected, Constant = true)
        LibraryName
        DependentLibraries
        
        % All values below SHALL be absolute full path following the
        % rules below:
        % - If no CXX or C file is needed to use this library, assign
        % default value {} to the corresponding properties
        % - To specify non empty values for these properties, use struct
        % with field names that are architectures this library is supported
        % on. See i2cdev for an example
        % - Check source code file to ensure directories of all included
        % header files are added to the IncludeDirectories property of its
        % language
        CXXIncludeDirectories 
        CXXFiles 
        CIncludeDirectories 
        CFiles 
        WrapperClassHeaderFile
        WrapperClassName
    end
    
    methods(Access = protected)
        function count = getAvailableRAM(obj)
            count = getAvailableRAM(obj.Parent);
        end
    end
    
    methods(Abstract = true, Access = protected)
       output = sendCommand(obj, libName, commandID, inputs, timeout)
    end
end
