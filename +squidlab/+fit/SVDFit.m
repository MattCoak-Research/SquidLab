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

classdef SVDFit < squidlab.fit.Fit
    % SVDFIT  Fits data using singular value decomposition.
    %
    % The fit method of this object implements the singular value
    % decomposition linear least-squares algorithm.
    
    methods
        function [parameters, prediction] = fit(~, data, basis)
            % Fits a set of data with singular value decomposition.
            %
            % Pass data as an Nx2 array of [x, y] points.
            %
            % Pass basis as an NxM array, for M basis vectors. Each column
            % corresponds to a single basis vector; basis(i, j) corresponds
            % to the calculated value of the jth basis vector evaluated at
            % x(i).
            
            numBasis = size(basis, 2);
            
            %Decompose F into its singular values
            [U, S, V] = svd(basis, 0);
            
            %Restrict size of S so it's diagonal.
            S = S(1:numBasis, 1:numBasis);
            
            %Estimate the coefficients.
            parameters = V * (S \ U') * data(:,2);
            parameters = parameters';
            
            % Predicted value is a sum over the coefficients of each basis
            % vector.
            prediction = sum(parameters .* basis, 2);
        end
    end
end