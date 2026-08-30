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

classdef LinearDriftSubtract < squidlab.postprocess.PostProcessPipe
     % LINEARDRIFTSUBTRACT  PostProcessPipe for subtracting a linear SQUID
     % drift.
     %
     % This process works by looking at the first and last
     % driftSubtractionRange points of each scan, and fitting a straight
     % line between those points. This straight line is then subtracted
     % from the signal, to eliminate the effect of linear SQUID drift.
    
    methods
        
        function [outputScans, temperatures] = process(~, inputScans, temperatures, driftSubtractionRange)
            % Subtracts from the signal a straight line obtained by fitting
            % the first and last few [position signal] points.
            %
            % Set the number of points to fit at each with the scalar int
            % driftSubtractionRange. If this is 0, no subtraction will be
            % performed.
            
            % Just return if there's no need to subtract.
            if driftSubtractionRange == 0
               outputScans = inputScans;
               return;
            end
            
            outputScans = inputScans;
            nFit = driftSubtractionRange;  % Shorter for indexing.

            for i=1:size(outputScans, 3)
                % Non-optimal repeat call to polyfit.
                %
                % Fit a straight to line to first and last nFit points.
                predictedSignal = polyval(polyfit(...
                    outputScans([1:nFit end-nFit:end],1,i),...
                    outputScans([1:nFit end-nFit:end],2,i), 1),...
                    outputScans(:,1,i));
                
                % Subtract this from the data.
                outputScans(:,2,i) = outputScans(:,2,i) - predictedSignal;
            end
            
        end
        
    end
    
end