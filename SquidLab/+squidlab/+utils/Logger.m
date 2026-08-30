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
    % Interface for classes used for logging info, warnings and errors.
    %
    % Subclass this and implement the methods to support e.g. GUI logging,
    % command-line logging, etc.
    
    properties (Access = public)
        %If ticking the box to load corrupted SQUIDrange values from .dat
        %in Import, we don't warn to warn the user about this - they
        %clearly know about it!
       SuppressSquidRangeWarning = false; 
    end
    
    methods(Abstract)
        % setBusy
        % Mark the logger as busy, because e.g. a slow process has started.
        setBusy(this, msg)
        
        % setFinished
        % Mark the logger as having finished the last slow process.
        setFinished(this, msg)
        
        % logInfo
        % Log an information message
        logInfo(this, msg)
        
        % logWarning
        % Log a warning message
        logWarning(this, msg, id)
        
        % logError
        % Log an error message that has already been thrown elsewhere, and
        % continue (or hope the caller handles execution).
        logError(this, msg, id)
        
        % showWarning
        % show a warning dialog popup box to display a message, but do not
        % interrupt execution. parentFig can be null for non-GUI
        % applications
        showWarning(this, msg, title)

        % throwError
        % Throw an error with message msg and ID id, stopping execution.
        throwError(this, msg, id);
    end
end