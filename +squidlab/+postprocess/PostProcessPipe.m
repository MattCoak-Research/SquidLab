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

classdef(Abstract) PostProcessPipe
    % POSTPROCESSPIPE  Interface for PostProcessPipes used in
    % post-processing scans.
    %
    % Subclass this and implement the process method, with the correct
    % signature, to have your custom pipes easily included in
    % PostProcessedScanSet's postProcess() method.
    %
    % For details of why you might want to do this, see
    % squidlab.ScanSet.PostProcessedScanSet.
    
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % USERS MUST IMPLEMENT EVERYTHING MARKED ABSTRACT IN DERIVED CLASSES
    methods(Abstract)
        
        [outputScans, temperatures] = process(this, inputScans, temperatures, varargin)
        % process
        % Returns scans and temperatures after performing a given
        % post-processing on them.
        %
        % Pass inputScans as a [NumPointsPerScan x 2 x NumScans] array,
        % temperatures as a [NumScans x 1] array.
        %
        % Return outputScans as a [NumPointsPerScan x 2 x NewNumScans], and
        % temperatures as a [NewNumScans x 1] array. NewNumScans may be
        % different to NumScans, i.e. you may change the number of scans.
        %
        % You MUST accept and return temperatures (even though, in many
        % cases, you won't use them in your implementation), as some pipes
        % do require modifying the temperatures.
        %
        % Define any additional input arguments (like settings or
        % modes) in implementations, in place of varargin.
        
    end
    
    
end