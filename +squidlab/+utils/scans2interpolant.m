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

function interpolant = scans2interpolant(scans, temperatures)
% Constructs a scatteredInterpolant from the [NumPointsPerScan x 2 x
% NumScans] array scans and the [NumScans x 1] array temperatures.
%
% Example:
%   interpolant = scans2interpolant(scans, temperatures);
%   
%   % Use the interpolant to get a new scan at 120 K.
%   positionExample = scans(:,1,1);
%   interpolatedSignal = interpolant(positionExample, 120);

scansAsMatrix = [];

% We need to provide scatteredInterpolant data in a
% [NumScans*NumPointsPerScan x 3] array of [Position Temperature Signal]
% points, but we have data in a [NumPoints x 2 x NumScans] array, with
% separate temperatures.
% 
% Converting involves a horrible repeat array reallocation, but this
% basically can't be avoided as we need to include the temperatures and the
% 3D array isn't in the right form for reshape();
numPointsPerScan = size(scans, 1);
for i=1:size(scans, 3)
    scansAsMatrix = [scansAsMatrix; ...
        scans(:,1,i), ones(numPointsPerScan,1) * temperatures(i), scans(:,2,i)];
end

interpolant = scatteredInterpolant(scansAsMatrix(:,1), scansAsMatrix(:,2),...
    scansAsMatrix(:,3));
end