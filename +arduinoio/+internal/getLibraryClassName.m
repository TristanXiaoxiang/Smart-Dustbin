function outstr = getLibraryClassName(libName)
% GETLIBRARYCLASSNAME - Return the name of the class that defines the given
% library. The returning string contains the package names as well.

%   Copyright 2014 The MathWorks, Inc.
outstr = '';

addonList = internal.findSubClasses('arduinoioaddons', 'arduinoio.LibraryBase', true);

for libClassCount = 1:length(addonList)
    theList = addonList{libClassCount};
    thePropList = theList.PropertyList;
    theLibraryName = arduinoio.internal.searchDefaultPropertyValue(thePropList, 'LibraryName');
    if strcmp(libName, theLibraryName)
        outstr = theList.Name;
        break;
    end
end

end