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

classdef(Abstract) Logger < handle
    
    properties(Access = public)
       LogEvery = 0.05; 
    end
    
    properties(Access = protected)
       LastLoggedFraction = 0; 
    end
    
    methods(Abstract, Access = protected)
       doLog(this, fraction, varargin)
       
       doFinished(this, varargin)
    end
    
    methods(Access = public)
        function log(this, fraction, varargin)
            if fraction - this.LastLoggedFraction >= this.LogEvery
               this.doLog(fraction, varargin{:});
               this.LastLoggedFraction = fraction;
            end
        end
        
        function finished(this, varargin)
           this.LastLoggedFraction = 0;
           this.doFinished(varargin{:});
        end
    end
end