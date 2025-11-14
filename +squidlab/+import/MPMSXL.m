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

classdef MPMSXL < squidlab.import.ImportPipeline
    %Import pipeline for an old generation MPMS XL datafile, which doesnt
    %have headed blocks of data throught the raw file, but instead a single
    %table of values. Trick is to find out how many points are in a scan,
    %then chop the data into chunks based on that.
        
    methods (Access = protected)
        function [meta] = GetMetaData(this)
            meta.XVar = 'T';
            meta.CalibrationFactor = 1.096e-3;
            meta.CoilRadius = 9.7;
            meta.CoilSeparation = 15.19;
            meta.CryostatInfo = 'MPMS or MPMSXL, standard format, MvT';
        end
    end
    
    methods(Access = public)

        function [results, info] = process(this, fileName, scaleFactor)
            %Tell the logger we are busy importing, and start a diagnostics
            %timer.
            this.Logger.setBusy("import");
            t = tic();
            
            % Reads the data in the file fileName, and returns a
            % struct of scans, temperatures and fields, and a struct of
            % additional diagnostic.
            
            % Initialize variables.
            delimiter = ',';
            startRow = 22;
            endRow = inf;
            
            % Format for each line of text:
            formatSpec = '%f%*s%f%f%f%*s%*s%f%*s%f%*s%*s%*s%*s%*s%*s%f%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%[^\n\r]';
            
            % Open the text file.
            fileID = fopen(fileName,'r');
            
            % Read columns of data according to the format.
            textscan(fileID, '%[^\n\r]', startRow(1)-1, 'WhiteSpace', '', 'ReturnOnError', false);
            dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN, 'ReturnOnError', false, 'EndOfLine', '\r\n');
            for block=2:length(startRow)
                frewind(fileID);
                textscan(fileID, '%[^\n\r]', startRow(block)-1, 'WhiteSpace', '', 'ReturnOnError', false);
                dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN, 'ReturnOnError', false, 'EndOfLine', '\r\n');
                for col=1:length(dataArray)
                    dataArray{col} = [dataArray{col};dataArrayBlock{col}];
                end
            end
            
            % Close the text file.
            fclose(fileID);
            
            % Create table of data. Column vectors accessible from eg
            % dataTable.Time
            dataTable = table(dataArray{1:end-1}, 'VariableNames', {'Time','FieldOe','StartTemperatureK','EndTemperatureK','Positioncm','LongVoltage','LongScaledResponse'});
            
            %Work out how many points are in each scan
            pointsInFirstScan = this.getNumberOfPointsInScan(dataTable.Positioncm);
            
            %Number of scans
            numberOfScans = length(dataTable.Positioncm) / pointsInFirstScan;
            
            % Allocate a 3D array to store data. This array will
            % eventually be [NumDataPointsPerScan x 2 x NumScans].
            % For every scan, there are NumDataPointsPerScan [position,
            % signal] pairs.
            scanData = nan(pointsInFirstScan,2,numberOfScans);
            
            temperatures = nan(numberOfScans, 1);
            fields = nan(numberOfScans, 1);
            
            %Map the tabled data into the expected format in scanData
            for i = 1 : numberOfScans
                for j = 1 : pointsInFirstScan
                    z = dataTable.Positioncm((i-1) * pointsInFirstScan + j);
                    V = dataTable.LongScaledResponse((i-1) * pointsInFirstScan + j);
                    scanData(j, 1, i) = z*10;    %Convert cm to mm
                    scanData(j, 2, i) = V * scaleFactor;
                end
                
                %Retrieve temperature and field data for this scan
                temperatures(i) = mean([dataTable.StartTemperatureK((i-1)* pointsInFirstScan+1), dataTable.EndTemperatureK(i* pointsInFirstScan)]);
                fields(i) = dataTable.FieldOe((i-1)* pointsInFirstScan+1);
            end
            
            time = toc(t);
            this.Logger.logInfo(sprintf("Imported %i scans in %.2f s.", numberOfScans, time));
            
            % Results to return.
            results.Temperatures = temperatures;
            results.Fields = fields;
            results.ScanData = scanData;
            
            % Diagnostics to return.
            info.FileName = fileName;
            info.NumScans = numberOfScans;
            info.TimeInSeconds = time;
            info.Meta = this.GetMetaData();
            
            this.Logger.setFinished("Import");
        end
    end
    
    methods(Access = protected)
        
        function pointsInScan = getNumberOfPointsInScan(~, positionsArray)
            %Position values in a single scan ramp up contiuously, then
            %reset to zero for the next. Look at data and see where they
            %stop increasing - that's the start of a new scan
            deltaP = 1;
            n = 1;
            while(deltaP > 0)
                deltaP = positionsArray(n+1) - positionsArray(n);
                n = n +1;
            end
            pointsInScan = n-1;
        end       
        
    end
    
end