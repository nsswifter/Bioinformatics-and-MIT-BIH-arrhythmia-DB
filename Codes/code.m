%% Documentation
% Author: Mehdi Karami
% Lesson: Bioinformatics
% Date: 10-May-2023

%% Memory Managment
clc; clear; close all;

%% --------------------------Code-Blocks--------------------------
ecgFile = '100';

[signal, frequency, time] = rdsamp(ecgFile, 1, 650000);

firstSample = 1;
lastSample = 1000;
subTime1 = time(firstSample:lastSample);
subSignal1 = signal(firstSample:lastSample);

% subplot(3, 1, 1);
% plot(subTime1, subSignal1);

%% Setting Interpolation
in = 16;
subTime2 = 0:((time(2) - time(1)) / in):time(lastSample);
subSignal2 = interp1(subTime1, subSignal1, subTime2);

% subplot(3, 1, 2);
% plot(subTime2, subSignal2);

%% Level Crossing ADC
A_FS = 10;
M = 7;

LSB = (2*A_FS)/(2 ^ M);

n = 4;
k = n * LSB;

%% Level Crossing Sampling
Lower_Level = subSignal2(1);
Upper_Level = Lower_Level + k;

temp = 1;
for index = 1:length(subTime2)
    if subSignal2(index) >= Upper_Level
        subSignal3(temp) = Upper_Level;
        subTime3(temp) = subTime2(index);
        
        Lower_Level = Lower_Level + LSB;
        Upper_Level = Upper_Level + LSB;
        
        UD(temp) = 1;
        Dti = subTime3(1, 2:length(subTime3)) - subTime3(1, 1:length(subTime3) - 1);
        
        temp = temp + 1;
        
    elseif subSignal2(index) <= Lower_Level
        subSignal3(temp) = Lower_Level;
        subTime3(temp) = subTime2(index);
        
        Lower_Level = Lower_Level - LSB;
        Upper_Level = Upper_Level - LSB;
        
        UD(temp) = 0;
        Dti = subTime3(1, 2:length(subTime3)) - subTime3(1, 1:length(subTime3) - 1);
        
        temp = temp + 1;
    end
end

%% Drawing (Level Crossing Sampling)
subplot(3, 1, 1);
plot(subTime2, subSignal2, 'LineWidth', 1);
hold on;
plot(subTime3, subSignal3, '*');
title(['Tape Number:', ecgFile]);
xlabel('Time(Sec)');
ylabel('Original Signal-ECG(mv)');

%% Finding Peaks
temp = 1;
for index = 1: length(UD) - 1
    if (UD(index) ~= UD(index + 1));
        index_peak(temp) = index;
        temp = temp + 1;
    end
end

for index = 1: length(index_peak)
        s4_peak_R = subSignal3(index_peak);
        t4_peak_R = subTime3(index_peak);
end
subplot(3, 1, 1)
hold on
plot(t4_peak_R, s4_peak_R, 'g*', 'LineWidth', 2);

%%
subplot(3, 1, 2)
stairs(subTime3, UD(1 : length(subTime3)), 'LineWidth', 1);
axis([0, 3, -0.5, 1.2]);
ylabel('UD');
xlabel('Time*(Sec)');

%%
subplot(3, 1, 3)
token = ones(1, length(subTime3));
stem(subTime3, token, 'LineWidth', 1.4)
axis([0, 3, -0.5, 1.2]);
ylabel('Time*(Sec)');
xlabel('Token');

% ---------------------------------------------------------------
