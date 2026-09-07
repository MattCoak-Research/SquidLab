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

classdef RemoveZeroes < squidlab.postprocess.PostProcessPipe
    % REMOVEZEROES  PostProcessPipe for removing data that have y=0 -
    % assuming that these are empty or invalid data points
    
    methods
        
        function [outputScans, temperatures] = process(~, inputScans, temperatures, shouldRemove)
            % Smooths the scans with a moving average, using smooth().
            %
            % smoothingSpan is a scalar int which sets the size of the
            % averaging window. If this is 0, no smoothing will be done.
            
            % Just return if there's no need to remove
            if shouldRemove == 0
               outputScans = inputScans;
               return;
            end
            
            outputScans = inputScans;
           
            % Loop over the last (3rd) dimension - the temperature/fields
            for k = 1:size(inputScans, 3)
                for j = 1 :size(inputScans, 2)
                    % logical index of rows where first column is exactly zero
                    zeroRows = inputScans(:,j,k) == 0;

                    % set both columns of those rows to NaN in output
                    if any(zeroRows)
                        outputScans(zeroRows, j, k) = NaN;
                    end
                end
                
            end
        end
        
    end
    
end