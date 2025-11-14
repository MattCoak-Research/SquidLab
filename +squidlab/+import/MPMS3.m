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

classdef MPMS3 < squidlab.import.LineReadingImportPipeline
    
    properties
        HeaderLines = 31; % We want to ignore this many lines of the file as header.
    end
    
    methods(Access = protected)        
         
        function [meta] = GetMetaData(this)
           meta.XVar = 'T';
           meta.CalibrationFactor = -5.966e-7;
           meta.CoilRadius = 8.5;
           meta.CoilSeparation = 8.0;
           meta.CryostatInfo = 'MPMS3, standard format';
        end  
        
        function tf = isScanMetaDataLine(~, line)
            % MPMS3 ScanMetaDataLines start with a colon.
            tf = line(1) == ';';
        end
        
        function tf = isScanDataLine(~, line)
            % MPMS3 ScanMetaDataLines contain 4 commas. This is much faster
            % and less error-prone than any alternative using e.g.
            % strsplit().
            tf = sum(line == ',') == 4;
        end
        
        function [temperature, field, range] = processScanMetaDataLine(this, line)
            %Hack to deal with the erratic space in 'squid range' unlike
            %all other meta fields.
            line = replace(line, 'squid range', 'squidrange'); 
            
            % MPMS3 ScanMetaDataLines are separated by semicolons. Average
            % temperature is in cell 4. Cells 5 and 6 contain start and end
            % field. Provide an extra argument to splitLineAndPickCells to
            % remove the extra text left in each cell after splitting by
            % semicolons..
            values = this.splitLineAndPickCells(line, ';', [4, 5, 6], ["= ", " "]);
            
            temperature = values(1);
            field = mean([values(2), values(3)]); 
                        
            splitLine = strsplit(line, ';');
            range = str2double( extractAfter(string(splitLine{9}), '= ') );
        end
        
        function [position, signal] = processScanDataLine(this, line, range)
            %Updated 2025-11-13 MJC to allow skipping over isolated corrupt
            %data blocks in a file without crashing the whole import - just
            %added this try-catch. Functions upstream catch the NaN values
            %and disregard the whole data block
            try
                % MPMS3 position and signal are in cells 3 and 5.
                values = this.splitLineAndPickCells(line, ',', [3, 5]);
                position = values(1);
                signal = range * values(2);
            catch err
                warning("Data import failed on a line, data will be set to NaN - " + string(err.message) + " The data in this line reads:" + string(line));
                position = NaN;
                signal = NaN;
            end
        end
    end
    
end