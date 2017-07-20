clear all;
clc;
%case1
can01 = [ 0,0,0,0,0,0;
          0,9,8,8,8,0;
          0,9,4,2,8,0;
          0,8,6,8,9,0;
          0,9,6,7,9,0;
          0,8,8,7,9,0;];
input_train(1,1:6) = eig(can01)';
output_train(1) = 1;

%case2      
noncan01 = [ 0,0,0,0,0,0;
             0,0,8,8,0,0;
             0,7,3,4,7,0;
             0,8,9,7,8,0;
             0,0,9,9,0,0;
             0,0,0,0,0,0;];
input_train(2,1:6) = eig(noncan01)';
output_train(2) = 0.2;

%case3         
noncan02 = [ 0,0,7,7,0,0;
             0,0,8,8,0,0;
             0,9,8,2,9,0;
             6,8,8,5,8,9;
             0,0,6,7,0,0;
             0,0,8,8,0,0;];
input_train(3,1:6) = eig(noncan02)';
output_train(3) = 0.0;

%case4      
can02 = [ 0,7,8,8,8,0;
          0,2,4,6,9,0;
          0,9,4,4,8,0;
          0,9,4,9,5,0;
          0,9,7,7,8,0;
          0,0,0,0,0,0;];
input_train(4,1:6) = eig(can02)';
output_train(4) = 1;
      
%case5      
can03 = [ 2,1,8,5,0,0;
          3,5,9,2,0,0;
          4,9,6,8,0,0;
          7,5,5,7,0,0;
          8,4,9,7,0,0;
          0,0,0,0,0,0;];
input_train(5,1:6) = eig(can03)';
output_train(5) = 0.9;
      
%case6
can04 = [ 0,0,7,8,5,8;
          0,0,4,4,6,9;
          0,0,8,6,2,6;
          0,0,9,3,4,7;
          0,0,5,7,9,8;
          0,0,0,0,0,0;];   
input_train(6,1:6) = eig(can04)';
output_train(6) = 0.9;
      
%case7
noncan03 = [ 0,8,8,9,0,0;
             0,8,7,5,0,0;
             0,9,4,9,0,0;
             0,6,7,8,0,0;
             0,8,9,8,0,0;
             0,4,8,9,0,0;];
input_train(7,1:6) = eig(noncan03)';
output_train(7) = 0.3;

%case8
noncan04 = [ 9,0,0,0,0,0;
             5,9,0,0,0,0;
             5,8,6,0,0,0;
             8,9,4,8,0,0;
             9,7,6,8,9,0;
             9,6,8,7,8,9;];
input_train(8,1:6) = eig(noncan04)'; 
output_train(8) = 0.0;

%case9
can05 = [ 0,0,0,0,0,0;
          0,0,8,8,8,8;
          0,0,9,7,7,9;
          0,0,7,8,9,5;
          0,0,8,9,8,8;
          0,0,8,6,9,8;];
input_train(9,1:6) = eig(can05)';
output_train(9) = 0.9;

%case10
can06 = [ 0,0,8,9,8,0;
          0,0,3,4,7,8;
          0,0,9,6,7,9;
          0,0,8,6,8,9;
          0,0,5,9,8,7;
          0,0,0,0,0,0;];   
input_train(10,1:6) = eig(can06)';
output_train(10) = 0.8;

%test1
can_test_01 = [ 0,0,2,8,8,6;
                0,0,6,9,7,0;
                0,0,6,6,9,9;
                0,0,8,8,7,8;
                0,0,4,7,8,6;
                0,0,0,0,0,0;];   
input_test(1,1:6) = eig(can_test_01)';

can_test_02 = [ 0,0,8,8,7,7;
                0,5,8,3,8,8;
                4,9,8,9,6,0;
                6,7,7,2,0,0;
                8,9,8,0,0,0;
                8,6,0,0,0,0;]; 
input_test(2,1:6) = eig(can_test_02)';

can_test_03 = [ 0,0,9,8,9,7;
                0,7,8,0,0,0;
                6,9,0,0,0,0;
                7,8,0,0,0,0;
                0,8,6,0,0,0;
                0,0,8,7,9,8;]; 
input_test(3,1:6) = eig(can_test_03)';




%num1 = (10*random('Normal',0,1,1,1010))';
%num2 = (25*random('Normal',0,1,1,1010))';
%num3 = num1+num2+100; %output



%input_train = [num1(1:1000), num2(1:1000)]';
%output_train = num3(1:1000)';
%input_test = [num1(1001:1010),num2(1001:1010)]';
%input_train = input_train';
input_train = real([input_train;input_train;input_train;input_train;input_train;input_train]');
%output_train = output_train;
output_train = real([output_train,output_train,output_train,output_train,output_train,output_train]);
%input_test = input_test';
input_test = real(input_test');

[inputn,inputps] = mapminmax(input_train);
[outputn,outputps] = mapminmax(output_train);

net = newff(inputn, outputn, 5);

net.trainParam.epochs = 100; % Iteration
net.trainParam.lr = 0.1; % rate of learning
net.trainParam.goal = 0.00001; %target value

%training
net = train(net, inputn, outputn); % net training

%testing
%inputn_test = mapminmax(input_test);
inputn_test = mapminmax('apply', input_test, inputps);
an = sim(net, inputn_test);
BPoutput = mapminmax('reverse', an, outputps)
%[num1(1001:1010), num2(1001:1010),num3(1001:1010),BPoutput']





