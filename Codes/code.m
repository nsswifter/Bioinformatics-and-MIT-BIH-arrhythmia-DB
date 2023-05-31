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
lastSample = 2000;
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
    if (UD(index) ~= UD(index + 1))
        index_peak(temp) = index;
        temp = temp + 1;
    end
end

for index = 1: length(index_peak)
        signal4_peak_R = subSignal3(index_peak);
        time4_peak_R = subTime3(index_peak);
end

%% Drawing Peaks
subplot(3, 1, 1)
hold on
plot(time4_peak_R, signal4_peak_R, 'g*', 'LineWidth', 2);

%% Drawing UD
subplot(3, 1, 2)
stairs(subTime3, UD(1 : length(subTime3)), 'LineWidth', 1);
axis([0, 3, -0.5, 1.2]);
xlabel('Time(Sec)');
ylabel('UD');

%% Drawing Token
subplot(3, 1, 3)
token = ones(1, length(subTime3));
stem(subTime3, token, 'LineWidth', 1.4)
axis([0, 3, -0.5, 1.2]);
xlabel('Time(Sec)');
ylabel('Token');

%% Setting Duration
j = 1;
n = 4;
W = 9;

Lower = floor(W / 2);
Upper = floor(W / 2) - n + j;

% Lower = -4; Upper = 2;
dp_Dti(1) = 0;

for index = 1:length(Dti) 
    dp_Dti(index + 1) = dp_Dti(index) + Dti(index);
end

for index = 1:length(index_peak)
    down(index) = max(1, index_peak(index) - Lower);
    up(index) = min(length(dp_Dti), index_peak(index) + Upper);
    duration(index_peak(index)) = dp_Dti(up(index)) - dp_Dti(down(index));
    durationPlus(index) = dp_Dti(up(index)) - dp_Dti(down(index));
end

%% Adaptive Thresholding = TH1
coeff1 = 0.25;
coeff2 = 0.25;

SP(1) = 0.1633;
NP(1) = 0.15;

for index = 1:length(index_peak) 
    SP(index + 1) = SP(index) - (coeff1 * (SP(index) - durationPlus(index)));
    NP(index + 1) = NP(index) - (coeff1 * (NP(index) - durationPlus(index)));
    TH1(index_peak(index)) = SP(index) - (coeff2 * (NP(index) - SP(index)));
    TH1Plus(index) = NP(index) - (coeff2 * (NP(index) - SP(index)));
end

%% Detect R_Peak with TH1
temp = 1;
for index = 1:length(index_peak)
    if TH1(index_peak(index)) > duration(index_peak(index))
        index_R_peak(temp) = index_peak(index);
        temp = temp + 1;
    end
end

for index = 1:length(index_R_peak)
    signal5_R_peak = subSignal3(index_R_peak);
    time5_R_peak = subTime3(index_R_peak);
end

%% Drawing R_Peak
subplot(3, 1, 1)
hold on
plot(time5_R_peak, signal5_R_peak, 'bo', 'LineWidth', 2);


%%


DeltaT_Beat=diff(time5_R_peak);
DeltaT_Beat=[0 DeltaT_Beat];

coeff3=0.125; PoB(1)=1;
for i5=2:length(index_R_peak)
    PoB(i5)=PoB(i5-1) - (coeff3 * (PoB(i5-1) - DeltaT_Beat(i5)));
end
TH2=(sum(PoB)/(length(PoB)))*(0.5);


c7=2;
index_R_peak_TH2(1)=index_R_peak(1);
for i7=1:length(DeltaT_Beat)
    if( DeltaT_Beat(i7) > TH2 )
        index_R_peak_TH2(c7) = index_R_peak(i7);
        c7=c7+1;
    end
end

subplot(3,1,1)
S6_R_peak_TH2=subSignal3(index_R_peak_TH2);
t6_R_peak_TH2=subTime3(index_R_peak_TH2);             
hold on
plot(t6_R_peak_TH2, S6_R_peak_TH2, 'yO', 'LineWidth', 3);

legend('ECG Signal', 'Asynchronous-Signal', 'Peak-Flag', ...
    'R-Peak-Flag with TH1', 'R-peak-Flag with TH2');


[ann, anntype, subtype, chan, num, comments] = rdann(ecgFile, 'atr', 1, lastSample);
ann_starting_index=0;
for i8=1:length(ann)
    if ann(i8) >= firstSample
        ann_starting_index=i8;
        break;
    end
end
ann2=ann(ann_starting_index:length(ann));

input_signal=signal(firstSample:lastSample);
t1=time(firstSample:lastSample);
t_ann=time(ann2(2:length(ann2)));
subplot(3,1,2);
plot(t1, input_signal);
hold on
plot(t_ann, signal(ann2(2:length(ann2))), 'ro', 'LineWidth', 1.3);
% ---------------------------------------------------------------
