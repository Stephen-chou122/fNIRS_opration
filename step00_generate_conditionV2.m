% file name: generate_condition.m
%
% [Info]
%   [basic info]
%   The script is aim to get conditions file for NIRS_SPM or SPM_FNIRS
%   analysis. You need to prepare all subjects' Behavioral date file 
%   (e.g. allSub.txt) that need to marged in E-Merge, and everysubjects'
%   fNIRS TXT files (e.g. sub01.TXT, sub02.TXT... in same folder).
% 
%   [User Guide]
%   Define global variables below. 
%   Mixed Design is same as Event Design
% 
%   [updata info]
%   GC-V0 Date: 2023.07.29  Author: Zhou.M    Basic frame
%   GC-V1 Date: 2023.08.26  Author: Zhou.M    add block for get fnirs star
%   time point
% 
%   [warning]
%   matlab version at least 2013b and above.

%% step.01 parameter setting
clc; clear;
global dir_behav fn_behav dir_fnirs savePath starMark 
% path & file name
dir_behav = 'C:\Users\zhou\Desktop\20230816Demo\beha\BD';
fn_behav  = 'allSubFilter.txt';
dir_fnirs = 'C:\Users\zhou\Desktop\20230816Demo\fnirs\BD';
savePath  = 'C:\Users\zhou\Desktop\20230816Demo\conditions\BD';

if ~exist(savePath)
    mkdir(savePath);
end

exp.isEventDesign   = 0; % 1, if event design(ED); 0, if not ED.

exp.rowStartTime    = 3;
exp.trialOnsetTime  = 5;
exp.rowCondition    = 7;
exp.trialNum4block  = 60; % 1, if ED

%% steo.02 Time Align
folderNum = dir(fullfile(dir_fnirs,'sub*'));
startTime = zeros(length(folderNum),1);
starMark = 11; %%%%% 定义mark的数�?

for j = 1:length(folderNum) % every sub
    file = dir(fullfile(dir_fnirs,folderNum(j).name,'*.txt'));


    fid4fnirs = fopen(fullfile(dir_fnirs,folderNum(j).name,file.name));
    C = textscan(fid4fnirs,'%s','Delimiter','\n');
    C = [C{1,1}];
    c=0;

    for ii=37:(size(C,1))
        c=c+1;
        Data(c,:)=(str2num(C{ii,:}));
    end


    rowST = find(Data(:, 2) == starMark);
    if isempty(rowST)
        rowST = find(Data(:, 2) ~= 0);
    end
    startTime(j) = Data(rowST(1),1);%%%%%%%%%%%%%%%%

end
%% step.03
fid = readtable(fullfile(dir_behav,fn_behav));
subList = unique(fid.Subject);

for i = 1:length(subList)
    % find subject-i's rows 
    trialscscr = find(fid.Subject == subList(i));
    onsetscscr = table2array(fid(trialscscr(1:end), exp.trialOnsetTime)) - table2array(fid(trialscscr(1:end), exp.rowStartTime));
    onsetscscr = (onsetscscr - onsetscscr(1))/1000;
    onsetscscr = onsetscscr + startTime(i);

    names_events = fid(trialscscr(1:exp.trialNum4block:end), exp.rowCondition);
    names_events = table2array(names_events);
    onsets_events = onsetscscr(1:exp.trialNum4block:end);
    names_unique = unique(names_events);

    names       = cell(1);
    onsets      = cell(1);
    durations   = cell(1);

    for k = 1:size(names_unique,1)
        names{k} = names_unique{k};
        % 找到第k个条件的对应行数
        indextemp = find(strcmp(names_events,names_unique{k}));
        onsets{k} = onsets_events(indextemp);
        if exp.isEventDesign == 0 % block design
            durations{k} = (onsetscscr(exp.trialNum4block)-onsets{1,1}(1))*ones(size(indextemp,1),1);%%%%%%%%%
        else % event relevent design
            durations{k} = zeros(size(indextemp,1),1);
        end
    end

    save_fn = fullfile(savePath,['sub',sprintf('%02d',(subList(i))),'.mat']);
    save(save_fn,'names','onsets','durations')
end
msgbox('computer Done...')