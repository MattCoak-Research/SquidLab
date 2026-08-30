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

classdef FitReplace < squidlab.postprocess.PostProcessPipe
    
    methods
        
        function [outputScans, temperatures] = process(~, inputScans, temperatures, fitMode)
            
            % Just return if there's no need to subtract.
            if fitMode == "none"
               outputScans = inputScans;
               return;
            end
            
            outputScans = inputScans;

            % Perform fit to every scan.
            %
            % Note this can have quite a severe performance impact,
            % particularly for spline fits.
            for i=1:size(outputScans, 3)
                % Cast fitMode as fit() may not support string.
                f = fit(outputScans(:,1,i), outputScans(:,2,i), char(fitMode));
                outputScans(:,2,i) = f(outputScans(:,1,i));
            end
            
        end
        
    end
    
    
end