function output = insertHelpLinkInDisplay(header)
% INSERTHELPLINKINDISPLAY - Replace the standard helpPopup classname with
% link to open the PDF doc.

%   Copyright 2014 The MathWorks, Inc.

searchStr = '<a.*">'; 
linkStr = '<a href="matlab: open(fullfile(arduinoio.SPPKGRoot, ''arduinoio_ug_book.pdf''))">';
% Example, 
% input string is <a href="matlab:helpPopup arduino" style="font-weight:bold">arduino<...
% output string is <a href="matlab: open(fullfile(arduinoio.SPPKGRoot, arduinoio_ug_book.pdf'))">arduino<...
output = regexprep(header, searchStr, linkStr);

end