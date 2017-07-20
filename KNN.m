clear all;
close all;
clc;

%%第一个类数据和标号
mu1=[0 0];  %均值
S1=[0.3 0;0 0.35];  %协方差
data1=mvnrnd(mu1,S1,100);   %产生高斯分布数据
plot(data1(:,1),data1(:,2),'+');
label1=ones(100,1);
hold on;

%%第二个类数据和标号
mu2=[1.25 1.25];
S2=[0.3 0;0 0.35];
data2=mvnrnd(mu2,S2,100);
plot(data2(:,1),data2(:,2),'ro');
label2=label1+1;

data=[data1;data2];
label=[label1;label2];

K=11;   %两个类，K取奇数才能够区分测试数据属于那个类
%测试数据，KNN算法看这个数属于哪个类
for ii=-3:0.1:3
    for jj=-3:0.1:3
        test_data=[ii jj];  %测试数据
        label=[label1;label2];
        %%下面开始KNN算法，显然这里是11NN。
        %求测试数据和类中每个数据的距离，欧式距离（或马氏距离） 
        distance=zeros(200,1);
        for i=1:200
            distance(i)=sqrt((test_data(1)-data(i,1)).^2+(test_data(2)-data(i,2)).^2);
        end

        %选择排序法，只找出最小的前K个数据,对数据和标号都进行排序
        for i=1:K
            ma=distance(i);
            for j=i+1:200
                if distance(j)<ma
                    ma=distance(j);
                    label_ma=label(j);
                    tmp=j;
                end
            end
            distance(tmp)=distance(i);  %排数据
            distance(i)=ma;

            label(tmp)=label(i);        %排标号，主要使用标号
            label(i)=label_ma;
        end

        cls1=0; %统计类1中距离测试数据最近的个数
        for i=1:K
           if label(i)==1
               cls1=cls1+1;
           end
        end
        cls2=K-cls1;    %类2中距离测试数据最近的个数
        
        if cls1>cls2    
           plot(ii,jj);     %属于类1的数据画小黑点
        end
        
    end
end