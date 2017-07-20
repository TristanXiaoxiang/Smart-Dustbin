function  output = BinaryToASCII(input)
% CONVERTTOASCII - Converts the input uint8 data to a column of ASCII numbers 
% by leaving the highest bit to zero and concatenating the 8 bits of the
% data to fill in the rest 7 bits.
% Example:
% input = uint8([200 220)]; or input = bin2dec({'11001000', '11011100'});
% output = bin2dec({'0 1001000', '0 0111001', '0 0000011'})

%   Copyright 2014 The MathWorks, Inc.
    
numBytes = numel(input);

output = [];
% newASCII stores one ASCII number derived from input and always has the
% first element or highest bit set to 0
newASCII = '00000000';
isNewASCIIReady = false;
for ii = 1:numBytes
    % convert data into binary string
    dataInBin = dec2bin(input(ii),8);
    
    % calculate the starting bit in newASCII to fill in with new data
    startBit = mod(ii, 7);
    
    % if startBit is 0, meaning all upper bits will form a complete ASCII
    if startBit == 0
        startBit = 7;
        isNewASCIIReady = true;
    end
    lowerBits = dataInBin(end:-1:startBit+1);
    upperBits = dataInBin(startBit:-1:1);
    newASCII(end-startBit+1:-1:2) = lowerBits;
    output = [output; bin2dec(newASCII)]; %#ok<AGROW>
    
    newASCII = '00000000';
    newASCII(end:-1:end-startBit+1) = upperBits;
    % if the newASCII is completed filled in, recreate empty bit mask
    if isNewASCIIReady
        output = [output; bin2dec(newASCII)]; %#ok<AGROW>
        newASCII = '00000000';
        isNewASCIIReady = false;
    end
end
output = [output; bin2dec(newASCII)];
