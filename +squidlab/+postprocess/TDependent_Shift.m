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

classdef TDependent_Shift < squidlab.postprocess.PostProcessPipe
    % TDependent_Shift  PostProcessPipe for shifting scans along z by a
    % different amount per temperature. To get the scan z values to still
    % all line up, this actually does a pixelwise circshift - values on the
    % far right of the plot will be 'pushed off' and wrap back round to the
    % far left. This is obviously bad! The anticipation is that these data
    % will be later trimmed off, and the good stuff is all in the centre
    % region which will be ok.
    
    methods
        
        function [outputScans, temperatures] = process(~, inputScans, temperatures, mc)
            % Shifts one dimension of a scan along z
            %m in K/mm
            % c offset in mm
                        
            m = mc(1);
            c= mc(2);
            outputScans = inputScans;
            centreDimension = 2;
            numPts = size(outputScans, 1); %Number of z points
            swingZ = abs(max(outputScans(:,1,1)) - min(outputScans(:,1,1)));    %Range in mm of a full scan's z
            factor = numPts / swingZ;


            % Surely this can be vectorised, but I spent some time trying
            % and couldn't get the subscripts to match properly.
            for i=1:size(outputScans, 3)
                T = temperatures(i);
                numshifts = floor(factor * (T * m + c));    %round down to nearest int as we need to shift by an integer number

               outputScans(:,centreDimension,i) = circshift(outputScans(:,centreDimension,i), numshifts);
            end
        end
        
    end
    
end