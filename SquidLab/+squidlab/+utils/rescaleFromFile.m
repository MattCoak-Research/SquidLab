%-------------------------------------Licensing and fair use notice---------------------------------------
%---------------------------------------------------------------------------------------------------------
%This code file forms part of the SquidLab software, University of Warwick and University of Cambridge
%SquidLab remains the intellectual property of the Universities of Warwick and Cambridge, but is freely
%distributed under an Academic Use license for non-commercial use. The license file is included with the
%code files when downloaded, and must always be kept with them if distributed. Please also credit the
%authors if the software contributes to any research results. Please read and make sure you agree with
%the points in the (short) license document. In brief, you may use and also modify any of the code files
%for non-commerical purposes, and should contact Warwick Ventures at the University of Warwick with any
%questions as to potential commercial or profit-making use.
%And remember, we can't guarantee that the software is bug or error free! Make sure to check any results.
%---------------------------------------------------------------------------------------------------------

%Standalone function for correcting the SquidRange=1000 bug in some MPMS3 multivu installations. Loads in the associated .dat to read the correct ranges, and rescales the scansets 
function results = rescaleFromFile(results)
% Jarvis, Feb 2020
scanData = results.ScanData;

% Get the associated .dat file for the same run as the raw data file,
% currently using a popup. Presently using an importer auto generated from
% MATLAB detailed at the bottom of file.
datFile = uigetfile('*.dat');
datOut = importdat(datFile);

% Read ranges column. There SHOULD be either the same amount or half as
% many range values depending on if the system measured up and down scans
% (c.f. average consecutive). Note this will ONLY work if your raw data
% file has 1000 range for all points.
ranges = datOut.Range./1000;

% If they match, simply apply the corresponding range to the data.
if length(ranges) == size(scanData, 3)
    
    scanData(:,2,:) = scanData(:,2,:).*ranges;
    
    
elseif length(ranges) == size(scanData, 3)/2
    %     If it's doubled, duplicate the necessary ranges and apply.
    ranges = [ranges'; ranges'];
    for i = 1:size(scanData, 3)
        
        scanData(:,2,i) = scanData(:,2,i).*ranges(i);
        
    end
    
else
    %     If neither case is true, error.
    error('Number of scans and range values do not concur.')
end

results.ScanData = scanData;

end

function datOut = importdat(filename, dataLines)
% Generated from MATLAB's automatic import functionality.

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [27, Inf];
end

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 69);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Comment", "TimeStampsec", "TemperatureK",...
    "MagneticFieldOe", "Momentemu", "MStdErremu", "TransportAction",...
    "AveragingTimesec", "FrequencyHz", "PeakAmplitudemm", "CenterPositionmm",...
    "LockinSignalV", "LockinSignalV1", "Range", "MQuadSignalemu",...
    "MinTemperatureK", "MaxTemperatureK", "MinFieldOe", "MaxFieldOe",...
    "Massgrams", "MotorLagdeg", "PressureTorr", "MeasureCount",...
    "MeasurementNumber", "SQUIDStatuscode", "MotorStatuscode",...
    "MeasureStatuscode", "MotorCurrentamps", "MotorTempC", "TempStatuscode",...
    "FieldStatuscode", "ChamberStatuscode", "ChamberTempK",...
    "RedirectionState", "EvercoolStatus", "AverageTempK",...
    "RotationAngledeg", "Rotatorstate", "DCMomentFixedCtremu",...
    "DCMomentErrFixedCtremu", "DCMomentFreeCtremu", "DCMomentErrFreeCtremu",...
    "DCFixedFit", "DCFreeFit", "DCCalculatedCentermm", "DCCalculatedCenterErrmm",...
    "DCScanLengthmm", "DCScanTimes", "DCNumberofPoints", "DCSquidDrift",...
    "DCMinVV", "DCMaxVV", "DCScansperMeasure", "Map01", "Map02", "Map03",...
    "Map04", "Map05", "Map06", "Map07", "Map08", "Map09", "Map10",...
    "Map11", "Map12", "Map13", "Map14", "Map15", "Map16"];
opts.VariableTypes = ["categorical", "double", "double", "double",...
    "string", "string", "double", "string", "string", "string", "double",...
    "string", "string", "double", "double", "double", "double", "double",...
    "double", "double", "string", "double", "double", "double", "double",...
    "double", "double", "double", "double", "double", "double", "double",...
    "double", "double", "double", "double", "string", "string", "double",...
    "double", "double", "double", "double", "double", "double", "double",...
    "double", "double", "double", "double", "double", "double", "double",...
    "double", "double", "double", "double", "double", "double", "double",...
    "double", "double", "double", "double", "double", "double", "double",...
    "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "error";
opts.EmptyLineRule = "error";

% Specify variable properties
opts = setvaropts(opts, ["Momentemu", "MStdErremu", "AveragingTimesec", "FrequencyHz", "PeakAmplitudemm", "LockinSignalV", "LockinSignalV1", "MotorLagdeg", "RotationAngledeg", "Rotatorstate"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Comment", "Momentemu", "MStdErremu", "AveragingTimesec", "FrequencyHz", "PeakAmplitudemm", "LockinSignalV", "LockinSignalV1", "MotorLagdeg", "RotationAngledeg", "Rotatorstate"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["MQuadSignalemu", "Massgrams", "Map01", "Map02", "Map03", "Map04", "Map05", "Map06", "Map07", "Map08", "Map09", "Map10", "Map11", "Map12", "Map13", "Map14", "Map15", "Map16"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["MQuadSignalemu", "Massgrams", "Map01", "Map02", "Map03", "Map04", "Map05", "Map06", "Map07", "Map08", "Map09", "Map10", "Map11", "Map12", "Map13", "Map14", "Map15", "Map16"], "ThousandsSeparator", ",");

% Import the data
datOut = readtable(filename, opts);

end