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

classdef(Abstract) Fit < handle
    % FIT  Interface for fitters.
    %
    % Implementations should provide a single method, fit(), which takes a
    % set of [x, y] data and a function to fit (in whatever form required),
    % and returns a row vector of best fit parameters, and a [NumPoints x
    % 1] array of the predicted y-values given those parameters.
    
    methods(Abstract)
        [parameters, prediction] = fit(this, data, equation);
    end
    
end