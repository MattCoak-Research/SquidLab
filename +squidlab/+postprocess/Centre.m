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

classdef Centre < squidlab.postprocess.PostProcessPipe
    % CENTRE  PostProcessPipe for centring scans around 0.
    
    methods
        
        function [outputScans, temperatures] = process(~, inputScans, temperatures, shouldCentre, centreDimension)
            % Centres one dimension of a scan around 0, by subtracting that
            % dimension's mean.
            %
            % For centring to occur, shouldCentre must be true.
            % Pass centreDimension as a scalar int, which sets which
            % dimension of a single scan to centre (1 = position, 2 =
            % signal).
            
            % Just return if there's no need to centre.
            if ~shouldCentre
               outputScans = inputScans;
               return;
            end
            
            outputScans = inputScans;
            
            % Surely this can be vectorised, but I spent some time trying
            % and couldn't get the subscripts to match properly.
            for i=1:size(outputScans, 3)
               centre = mean(outputScans(:, centreDimension, i));
               outputScans(:,centreDimension,i) = outputScans(:,centreDimension,i) - centre;
            end
        end
        
    end
    
end