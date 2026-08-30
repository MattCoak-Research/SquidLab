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

classdef AverageUpDown < squidlab.postprocess.PostProcessPipe
     % AVERAGEUPDOWN  PostProcessPipe for averaging consecutive scans which
     % are really just the up and down sweeps of a single scan.
    
    methods
        
        function [outputScans, temperatures] = process(~, inputScans, temperatures, shouldAverage)
            % Averages up and down scans.
            %
            % This uses quite a naive approach, in which we assume:
            % - All scans have the same NumPointsInScan.
            % - Scan i+1 should be matched with scan i.
            % - For each pair of scans, either the scans were taken with
            %   the stepper going in the same direction, or the opposite
            %   direction (This method will attempt to work out which of
            %   those is the case). That is, we don't care about the actual
            %   positions of each scan, and can instead just do clever
            %   things with indices. This is probably true - the most
            %   likely case is that every position index in a scan
            %   corresponds to the same position, at least approximately.
            %
            % For anything more complex (e.g. the range of the stepper was
            % changed between consecutive scans, which seems unlikely) we'd
            % have to something clever involving interpolating the signal
            % in the second scan onto the positions of the first scan, so
            % we can do the subtraction. This method doesn't support that.
            %
            % Pass shouldAverage as a bool which sets whether to actually
            % do anything.
            
            % Just return if there's no need to average.
            if ~shouldAverage
               outputScans = inputScans;
               return;
            end
            
            %Throw a warning if there is an odd number of scans, and return
            %without doing anything
            if(mod(length(temperatures), 2) ~= 0)
                warndlg('Specified to average consecutive scans, but it looks like there is an odd number of scans. This step will be skipped.', 'Warning');
                outputScans = inputScans;
                return;
            end
            
            % We only need every other temperature.
            temperatures = mean([temperatures(1:2:end) temperatures(2:2:end)], 2);
            
            % Split scans into 2 sets.
            splitScans(:,:,:,1) = inputScans(:,:,1:2:end);
            splitScans(:,:,:,2) = inputScans(:,:,2:2:end);
            
            % For the second set, see if we get better agreement with the
            % position variable if we keep as-is, or if we reverse the
            % direction of the position variable.
            if iShouldFlipSecondPosition(splitScans)
                % Flip position and signal.
                %
                % Extremely non-optimal implementation - this should be
                % vectorised. Trying to do so tends to introduce loads of
                % confusing bugs. It should be possible with flip(). 
                for i=1:size(splitScans, 3)
                    splitScans(:,1,i,2) = flipud(splitScans(:,1,i,2));
                    splitScans(:,2,i,2) = flipud(splitScans(:,2,i,2));
                end
            end
            
            % Cunningly take mean along 4th dimension which is equivalent
            % to averaging every other scan under the assumptions detailed
            % above.
            outputScans = mean(splitScans, 4);
        end
        
    end
    
end

function tf = iShouldFlipSecondPosition(splitScans)
% Returns true if the positions between consecutive scans match better
% having flipped the positions of every second scan.
%
% This will likely be true if the scan is taking by first moving the
% stepper up, then moving it down (but these are split into separate
% scans). In this case, scan i and scan i+1 have their position going in
% opposite directions; if we just average them, we will get poor results.

% Assume no need to flip.
tf = false;

% Too confusing to stay working in 4D, so convert to a [NumPointsPerScan x
% NumScans] array of positions.
positions1 = squeeze(splitScans(:,1,:,1));
positions2 = squeeze(splitScans(:,1,:,2));

% Compare positions between scan i and scan i+1, without and with a flip.
positionDifferenceNoChange = positions2 - positions1;
positionDifferenceWithFlip = positions2 - flipud(positions1);

% See how much disagreement there is between the positions of the scans if:
% 1 - we don't try to change the direction of position.
% 2 - we flip the direction of position.
totalNoChange = sum(abs(positionDifferenceNoChange(:)));
totalWithFlip = sum(abs(positionDifferenceWithFlip(:)));

% Smaller value for totalWithFlip implies we should flip the scan
% directions.
if totalWithFlip < totalNoChange
    tf = true;
end

end