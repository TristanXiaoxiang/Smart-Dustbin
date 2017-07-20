function [ net,input_train,inputps,output_train,outputps ] = Imtrain01()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

numberOfTrainCases = 10;
i = numberOfTrainCases;
%input_train = zeros(numberOfTrainCases,19200);
%output_train = zeros(numberOfTrainCases,1);

while(i)
    i = i - 1;
    imTrain  = imread(strcat('image\\im',num2str(i,'%04d'),'.jpg'));
    imTrain = imresize(imTrain,[100,100]);
    imGRAY   = rgb2gray(imTrain);%转化为灰度图像
    threshold = graythresh(imGRAY);%阈值
    imBinary = im2bw(imGRAY, threshold);%转化为二值图像
    [imRow,imCol] = size(imBinary);
    
    %将Matrix变成Vector
    %for k = 1:imRow
    %    input_train(numberOfTrainCases-i,(1+imCol*(k-1)):(imCol*k)) = imBinary(k,1:imCol);
        
    %end
    input_train(numberOfTrainCases-i,1:imCol) = real(eig(double(imBinary)))';
    output_train(numberOfTrainCases-i,1:3) = [rand(),rand(),rand()];%Output
end

input_train = input_train';
output_train = output_train';

%[inputn,inputps] = mapminmax(input_train);
%[outputn,outputps] = mapminmax(output_train);
[inputn,inputps] = mapminmax(input_train);
[outputn,outputps] = mapminmax(output_train);

net = newff(inputn, outputn, 5);

net.trainParam.epochs = 100; % Iteration
net.trainParam.lr = 0.1; % rate of learning
net.trainParam.goal = 0.00001; %target value

%training
net = train(net, inputn, outputn); % net training

end

