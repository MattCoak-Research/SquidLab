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

classdef EnhancedSVDFit < squidlab.fit.Fit
    % ENHANCEDSVDFIT  Improvement on the basic SVDFit algorithm.
    %
    % %The basic SVDFit can't deal with the constant offset the signal may
    % have. We can't easily include this in the multipole basis (a constant
    % vector isn't orthogonal to the other basis vectors). We therefore
    % include it via an iterative approach:
    % - Use SVD to fit the signal.
    % - Work out the offset between the prediction and data.
    % - Subtract this from the data, perform the fit again, repeat.
    
    properties
        % MaxIterations (scalar int)
        % Number of iterations the fit procedure will run for.
        MaxIterations = 5;
        
        % SVDFit (squidlab.fit.SVDFit)
        % Underlying SVDFit object.
        SVDFit = squidlab.fit.SVDFit();
    end
    
    methods
        function [parameters, prediction] = fit(this, data, basis)
            % Fits using SVD, attempting to correct for the constant offset
            % of the signal w.r.t. the prediction, which the SVD algorithm
            % can't handle.
            
            % Get an estimate at the fit parameters.
            [~, prediction] = this.SVDFit.fit(data, basis);
            
            % This gives us a prediction, but the prediction can't deal
            % with contant offsets. To try and account for this, see what
            % the constant offset off the data wrt the prediction is. Fit
            % with this offset subtracted, and repeat.
            newData = data;
            for i=2:this.MaxIterations
                offset = mean(newData(:,2)) - mean(prediction);
                
                % Try fitting the data again, without that offset.
                newData(:,2) = newData(:,2) - offset;
                [parameters, prediction] = this.SVDFit.fit(data, basis);
            end
            
            
            finalOffset = mean(data(:,2)) - mean(prediction);
            
            % Include the offset in both the prediction and the parameters.
            prediction = prediction + finalOffset;
            parameters(end+1) = finalOffset;
        end
    end
    
    
end