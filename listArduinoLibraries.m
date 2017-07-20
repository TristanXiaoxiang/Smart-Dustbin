function allInstalledLibs = listArduinoLibraries()
%Display a list of installed Arduino libraries
%
%Syntax:
%libs = listArduinoLibraries()
%
%Description:
%Creates a list of available Arduino libraries and saves the list to the variable libs.
%
%Output Arguments:
%libs - List of available Arduino libraries (cell array of strings)

%   Copyright 2014 The MathWorks, Inc.

    baseList = internal.findSubClasses('arduinoio', 'arduinoio.LibraryBase', true);
    addonList = internal.findSubClasses('arduinoioaddons', 'arduinoio.LibraryBase', true);
    allList = [baseList; addonList];
    allInstalledLibs = {};
    for libClassCount = 1:length(allList)
        thePropList = allList{libClassCount}.PropertyList;
        for propCount = 1:length(thePropList)
            % check classes that have defined constant LibraryName - e.g
            % those that are library classes
            theProp = thePropList(propCount);
            % If the current property's name is 'LibraryName' and it has a
            % default value, then it defines a new library
            if strcmp(theProp.Name, 'LibraryName') && theProp.HasDefault 
                definingClass = theProp.DefiningClass;
                packageNames = strsplit(definingClass.Name, '.');
                vendorPackageName = packageNames{end-1};
                % check vendor package name to form library name string
                if ~strcmp(vendorPackageName, 'arduinoio')  % class within arduinoioaddons.VENDORNAME
                    if ~isempty(strfind(theProp.DefaultValue, '/'))
                        temp = strsplit(theProp.DefaultValue, '/');
                        if strcmpi(vendorPackageName, temp{1})
                            allInstalledLibs = [allInstalledLibs, theProp.DefaultValue]; %#ok<AGROW>
                        end
                    end
                else
                    allInstalledLibs = [allInstalledLibs, theProp.DefaultValue]; %#ok<AGROW>
                end
            end
        end
    end
    allInstalledLibs = unique(allInstalledLibs');
    
    try
        if isempty(allInstalledLibs)
            arduinoio.internal.localizedError('MATLAB:arduinoio:general:IDENotInstalled');
        end
    catch e
        throwAsCaller(e);
    end
end


