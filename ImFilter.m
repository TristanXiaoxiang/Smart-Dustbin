function [ outputImage ] = ImFilter( Image1,Image2 )
%ImFilter Summary of this function goes here
%   Detailed explanation goes here
tolerateError = 20;
[col,row,n] = size(Image1);
for i = 1: col
    for j = 1:row
        if (abs(Image1(i,j)-Image2(i,j))<=tolerateError)
            outputImage(i,j)=0;
        else
            outputImage(i,j)=Image1(i,j);
        end
    end
end

figure
imshow(outputImage);




end

