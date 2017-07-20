function [ object , similarity ] = imKNN2()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

imTest  = imread(strcat('imTest.jpg'));
imTest = imresize(imTest,[50,50]);
imTestGRAY   = double(rgb2gray(imTest));%转化为灰度图像
[imRow,imCol] = size(imTestGRAY);
%将Matrix变成Vector
for k = 1:imRow
    imTestVector((1+imCol*(k-1)):(imCol*k)) = imTestGRAY(k,1:imCol);
end
%threshold = graythresh(imGRAY);%阈值
%imBinary = im2bw(imGRAY, threshold);%转化为二值图像
%[imRow,imCol] = size(imBinary);

%i=1;
%imTest01  = imread(strcat('image\\im',num2str(i,'%04d'),'.jpg'));

%test Obj1
NumberObj1Cases = 200;
for i = 1:(NumberObj1Cases-100)
    imTrainCase  = imread(strcat('image\\',num2str(i-1,'%d'),'.jpg'));
    imTrainCase = imresize(imTrainCase,[50,50]);
    imTrainGRAY   = double(rgb2gray(imTrainCase));%转化为灰度图像
    [imRow,imCol] = size(imTrainGRAY);
    error = imTestGRAY-imTrainGRAY;
    %将Matrix变成Vector
    for k = 1:imRow
        imTrainVector((1+imCol*(k-1)):(imCol*k)) = imTrainGRAY(k,1:imCol);
    end
    %imDelta = zscore(imTrainVector-imTestVector);
    distance =0;
    for ii=1:(imRow*imCol)
        distance=distance+(imTrainVector(ii)-imTestVector(ii)).^2;
    end
    outputObj1(i) = sqrt(distance);
    %outputFanta(i) =pdist(imDelta,'Euclid')%计算欧氏距离
end
outputObj1;
Obj1Relativity = min(outputObj1);


%test Obj2
NumberObj2Cases = 200;
for i = 1:(NumberObj2Cases-100)
    imTrainCase  = imread(strcat('image\\',num2str((i-1+NumberObj1Cases),'%d'),'.jpg'));
    imTrainCase = imresize(imTrainCase,[50,50]);
    imTrainGRAY   = double(rgb2gray(imTrainCase));%转化为灰度图像
    [imRow,imCol] = size(imTrainGRAY);
    error = imTestGRAY-imTrainGRAY;
    %将Matrix变成Vector
    for k = 1:imRow
        imTrainVector((1+imCol*(k-1)):(imCol*k)) = imTrainGRAY(k,1:imCol);
    end
    %imDelta = zscore(imTrainVector-imTestVector);
    distance =0;
    for ii=1:(imRow*imCol)
        distance=distance+(imTrainVector(ii)-imTestVector(ii)).^2;
    end
    outputObj2(i) = sqrt(distance);
    %outputFanta(i) =pdist(imDelta,'Euclid')%计算欧氏距离
end
outputObj2;
Obj2Relativity = min(outputObj2);

%test Waste
NumberWasteCases = 100;
for i = 1:(NumberWasteCases-50)
    imTrainCase  = imread(strcat('image\\',num2str((i-1+NumberObj1Cases+NumberObj2Cases),'%d'),'.jpg'));
    imTrainCase = imresize(imTrainCase,[50,50]);
    imTrainGRAY   = double(rgb2gray(imTrainCase));%转化为灰度图像
    [imRow,imCol] = size(imTrainGRAY);
    error = imTestGRAY-imTrainGRAY;
    %将Matrix变成Vector
    for k = 1:imRow
        imTrainVector((1+imCol*(k-1)):(imCol*k)) = imTrainGRAY(k,1:imCol);
    end
    %imDelta = zscore(imTrainVector-imTestVector);
    distance =0;
    for ii=1:(imRow*imCol)
        distance=distance+(imTrainVector(ii)-imTestVector(ii)).^2;
    end
    outputWaste(i) = sqrt(distance);
    %outputFanta(i) =pdist(imDelta,'Euclid')%计算欧氏距离
end
outputWaste;
WasteRelativity = min(outputWaste);




KNNoutput=[Obj1Relativity,Obj2Relativity]
MinValue= min(KNNoutput);
%MinValue = 2000;
%SecondValue = 2500;
%for i = 1:length(KNNoutput)
%    if KNNoutput(i) <= MinValue
%        SecondValue = MinValue;
%        MinValue = KNNoutput(i);
%    elseif (KNNoutput(i) > MinValue)&&(KNNoutput(i) < SecondValue)
%        SecondValue = KNNoutput(i);
%    end
%end
    

%if (MinValue < 2000)&&((SecondValue-MinValue)>=200)
if (MinValue < 2000) && (abs(Obj1Relativity-Obj2Relativity)>100)
    if MinValue == KNNoutput(1)
        object = 1; 
    elseif MinValue == KNNoutput(2)
        object = 2; 
    %    ...
    else
        object = 1000;%error output 
    end   
    similarity = MinValue;
else
    object = 0; %Nothing being indentified  //waste
    similarity = 0;
end

if WasteRelativity <= 1300
    object = 0; %Nothing being indentified  //waste
    similarity = 0;
end
    
object
similarity
end

