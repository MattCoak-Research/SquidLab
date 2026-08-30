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

classdef RawScanSet < squidlab.scanset.ScanSet
    % RAWSCANSET  Implementation of the ScanSet which only contains the
    % raw data.
    %
    % Currently, this class is probably pointless, because it just calls
    % its parent. That's likely to change in the future.
    
    methods
        
        function this = RawScanSet(temperatures, fields, scanData)
            
            % Just delegate to parent ctor.
            this@squidlab.scanset.ScanSet(temperatures, fields, scanData);
        end
        
    end

end