%-------------------------------------Licensing and fair use notice---------------------------------------
%---------------------------------------------------------------------------------------------------------
%This code file forms part of the SquidLab software, University of Warwick and Unviersity of Cambridge
%SquidLab remains the intellectual property of the Universities of Warwick and Cambridge, but is freely 
%distributed under an Academic Use license for non-commercial use. The license file is included with the 
%code files when downloaded, and must always be kept with them if distributed. Please also credit the 
%authors if the software contributes to any research results. Please read and make sure you agree with 
%the points in the (short) license document. In brief, you may use and also modify any of the code files 
%for non-commerical purposes, and should contact Warwick Ventures at the University of Warwick with any 
%questions as to potential commercial or profit-making use. 
%And remember, we can't guarantee that the software is bug or error free! Make sure to check any results.
%---------------------------------------------------------------------------------------------------------

classdef(Abstract) ImportPipeline
    % IMPORTPIPELINE  Interface for importing data from a file on disk.
    %
    % Subclass this and implement its protected properties and methods to
    % ensure the ImportLine for your cryostat will work correctly with
    % Squidlab.    
    
    properties(Access = public)
        % Logger (squidlab.utils.Logger)
        % Logs errors and warnings.
        %
        % Your subclass can call this property, which will be instantiated in the constructor, and your process()
        % method should include calls to the squidlab.utils.Logger
        % interface to log updates.
        Logger;
    end
    
    methods(Access = public)
        %Constructor
        function this = ImportPipeline()
           
        end    
    end
    
    methods(Abstract)
        % process
        % Reads the data from a file into a format suitable for Squidlab.
        %
        % Pass fileName as a string corresponding to a file name (assume
        % the full filepath). Pass rescaleFactor as a scalar which will be
        % used to multiple the value of the computed voltage signal.
        %
        % Return results, a struct with fields Temperatures, Fields and
        % ScanData. Temperatures and Fields should be double arrays of size
        % [NumScans x 1], and ScanData should be a double array of size
        % [PointsPerScan x 2 x NumScans], where ScanData(:,1,1) is position
        % and ScanData(:,2,1) is voltage for the first scan.
        %
        % Return info, a struct containing information about the import
        % process.
        [results, info] = process(this, fileName, rescaleFactor)
    end
    
end