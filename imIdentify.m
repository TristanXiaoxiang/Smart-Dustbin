function [ object , similarity ] = imIdentify(  net,inputn,inputps,outputn,outputps  )
%%image identification
%input a binary image
%output the object identified from the image and the degree of similarity among 0 and 1.

    imTest  = imread(strcat('imTest.jpg'));
    imTest = imresize(imTest,[100,100]);
    imGRAY   = rgb2gray(imTest);%转化为灰度图像
    threshold = graythresh(imGRAY);%阈值
    imBinary = im2bw(imGRAY, threshold);%转化为二值图像
    [imRow,imCol] = size(imBinary);
    
    %将Matrix变成Vector
    %for k = 1:imRow
    %    input_train(numberOfTrainCases-i,(1+imCol*(k-1)):(imCol*k)) = imBinary(k,1:imCol);
        
    %end
    input_test = real(eig(double(imBinary)));
 
%testing
    %inputn_test = mapminmax(input_test);
inputn_test = mapminmax('apply', input_test, inputps)
%inputn_test = input_test;
an = sim(net, inputn_test)
BPoutput = mapminmax('reverse', an, outputps);
%BPoutput = an;
    %[num1(1001:1010), num2(1001:1010),num3(1001:1010),BPoutput']

%[W2,WB2] = Classify('C:\\MATLAB\\SupportPackages\\R2014a\\arduinoio\\imModel.jpg');
%similarity = corr2(inputBiImage,WB2);
%similarity = BPoutput;
[MinValue,MaxValue] = [min(BPoutput),max(BPoutput)];
if MaxValue > 0.5
    if MaxValue == BPoutput(1)
        object = 1; %Cokecola metal cans
    elseif MaxValue == BPoutput(2)
        object = 2; %Plastic
    else
        object = 3; %Paper Box
    end   
    similarity = MaxValue;
else
    object = 0; %Nothing being indentified
    similarity = MaxValue;
end

