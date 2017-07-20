function value = getDefaultLibraryPropertyValue(libName, propertyName)
% GETDEFAULTLIRARYPROPERTYVALUE - Return the default property value by name
% of the given library string. If not overriden in the library class,
% return empty array

%   Copyright 2014 The MathWorks, Inc.

    baseList = internal.findSubClasses('arduinoio', 'arduinoio.LibraryBase', true);
    addonList = internal.findSubClasses('arduinoioaddons', 'arduinoio.LibraryBase', true);

    if isempty(strfind(libName, '/'))
        value = findMatchingLibraryAndReturnDefaultPropertyValue(baseList, libName, propertyName);
    else
        value = findMatchingLibraryAndReturnDefaultPropertyValue(addonList, libName, propertyName);
    end
end

function value = findMatchingLibraryAndReturnDefaultPropertyValue(allLibList, oldLib, propName)
% Return the input library plus its dependent libs, if any
    
    value = [];
    for libClassCount = 1:length(allLibList)
        % get current class's library name
        thePropList = allLibList{libClassCount}.PropertyList;
        libName = arduinoio.internal.searchDefaultPropertyValue(thePropList, 'LibraryName');
        % check if names match
        if strcmp(libName, oldLib)
            value = arduinoio.internal.searchDefaultPropertyValue(thePropList, propName);
        end
    end
end