function result = endsWith(str1, str2)

%   Copyright 2014 The MathWorks, Inc.

    result = false;
    
    n1 = length(str1);
    n2 = length(str2);
    
    if n1 < n2
        return;
    end
    
    result = strcmp(str1(end-n2+1:end), str2);
end

