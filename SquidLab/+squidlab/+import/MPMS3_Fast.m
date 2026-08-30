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

classdef MPMS3_Fast < squidlab.import.ImportPipeline
    
    properties(Constant)
        % MinHeaderLines (scalar integer)
        % The MINIMUM number of header lines we expect an MPMS3 datafile to
        % have. This should definitely be less than the actual number of
        % lines the files really have. This number is used to provide a
        % heuristic which makes it faster to parse the header, because we
        % can just skip most of it.
        MinHeaderLines = 20
        
        % ScanMetaLineStartMarker (scalar string)
        % Marker at the start of metadata lines.
        ScanMetaLineStartMarker = ";"
    end
    
    properties
              
    end
    
    methods
              
        function [results, info] = process(this, fileName, rescaleFactor)
            
            this.Logger.setBusy("import");
            t = tic();
            
            fileAsString = this.readFileToData(fileName);
            data = this.extractDataFromString(fileAsString);
            
            [temperatures, fields, range, scanData] = ...
                this.separateScanMetaDataAndScanData(data);
            
            % We don't know exactly how many points there are per scan -
            % the number may vary between cryostats. Work it out, based on
            % how many scan datapoints we have compared to how many
            % temperature points we have.
            numScanPoints = size(scanData, 1);
            numPointsPerScan = numScanPoints / length(temperatures);
            numScans = length(temperatures);
            
            % Throw if we've gone wrong somewhere and don't have an integer
            % number of points per scan.
            if mod(numPointsPerScan, 1) ~= 0
               this.Logger.throwError(...
                   sprintf("Estimated %.2f z-points per scan, when this value should be integer. File is probably corrupted.", numPointsPerScan), ....
                   "squidlab:import:InvalidPointsPerScan");
            end
            
            this.Logger.logInfo(sprintf("Reshaping %i scan data points to %i scans" + ...
                " assuming %i z-points per scan.", numScanPoints, numScans, numPointsPerScan));
            
            % Reshape the [NumScans*ZPointsPerScan x 2] array into a
            % [ZPointsPerScan x 2 x NumScans] array. For every scan, rescale
            % by the appropriate factor for range and rescaleFactor.
            %
            % It's surely possible to do this with reshape + permute, and
            % that's probably faster.
            scanResults = zeros(numPointsPerScan, 2, numScans);
            for i=1:numScans
                idx = (1 + (i-1)*numPointsPerScan):(i*numPointsPerScan);
                scanResults(:,:,i) = scanData(idx, :);
                
                % Take into account the range.
                scanResults(:,2,i) = scanResults(:,2,i) * range(i) * rescaleFactor;
            end
            
            time = toc(t);
            this.finalize(range, numScans, time);
            
            % Prepare results and info to return
            results = struct("Temperatures", temperatures, ...
                "Fields", fields, ...
                "ScanData", scanResults);
            
            info = struct("Filename", fileName, ...
                "NumScans", length(temperatures), ...
                "TimeInSeconds", time, ...
                "Meta", this.getMetaData);
            
            this.Logger.setFinished("Import");
        end
    end
    
    methods(Access = protected)
        function meta = getMetaData(~)
            meta.XVar = 'T';
            meta.CalibrationFactor = -5.966e-7;
            meta.CoilRadius = 8.5;
            meta.CoilSeparation = 8.0;
            meta.CryostatInfo = 'MPMS3, standard format';
        end
        
        function dataAsCell = readFileToData(this, fileName)
            % Reads a text file into a cellstr array, and removes the
            % header so only data remains. The header is stored in
            % this.Header.
            
            % Catch a common error with bad paths.
            if ~exist(fileName, 'file')
                this.Logger.logError(sprintf("Couldn't find file %s - might be a relative path issue.",...
                    fileName));
            end
            
            dataAsCell = this.readFileToString(fileName);
        end
        
        function fileAsCell = readFileToString(~, fileName)
            % Read a file into a string array, with one line per string
            % array element.
            
            fid = fopen(fileName);
            data = textscan(fid,'%s','Delimiter','\n');
            
            % Using textscan like this gives us a 1x1 cell array with a
            % cell containing the actual cell array we want.
            fileAsCell = string(data{1});
            
            % Close open file handles.
            fclose(fid);
        end
        
        function [temperature, field, range] = parseScanMetadataLines(~, scanStartLines)
            % String parse strings corresponding to the start of scans, to
            % extract the temperature and field.
            
            % Parse for average temperature.
            temperature = double(scanStartLines.extractBetween("avg. temp = ", " K"));
            
            % Parse for average field (the datafile doesn't expose this
            % easily for us).
            lowFields = double(scanStartLines.extractBetween("low field = ", " Oe"));
            highFields = double(scanStartLines.extractBetween("high field = ", " Oe"));
            field = 0.5*(lowFields + highFields);
            
            % Parse for 'squid range'.
            range = double(scanStartLines.extractBetween("squid range = ", ";"));
        end
        
        function scanData = parseScanDataLines(~, dataLines)
            
            % Some scans contain more data, because they're the MPMS3 fits,
            % not the raw data. Those lines have multiple consecutive
            % commas (which anyway break the call to string.split later).
            % We don't want to include that data.
            isMPMS3FitLine = dataLines.contains(",,,");
            dataLines = dataLines(~isMPMS3FitLine);
            
            % Columns 3 and 5 are z and V.
            s = dataLines.split(",");
            scanData = double(s(:, [3 5]));
        end
        
        function data = extractDataFromString(this, fileAsString)
            % Given an array of strings, each element being one line in the
            % file, return only the data as a string array. Remove the
            % header.
            
            % Take the first MinHeaderLines and assume those are header.
            % Use that as the initial estimate of the header.
            data = fileAsString(this.MinHeaderLines:end);
            
            % Iterate through data, and find the first line which starts
            % with scanMetaMarker, which denotes the start of the first scan
            % and the end of the header.
            offset = 1;
            while ~data(offset).startsWith(this.ScanMetaLineStartMarker)
                offset = offset + 1;
            end
            
            % We now have an accurate value for the start of the data.
            data = fileAsString(this.MinHeaderLines + offset - 1:end);
        end
        
        function [temperatures, fields, range, scanData] = separateScanMetaDataAndScanData(this, data)
            % Work out which lines correspond to metadata. Parse metadata to
            % numeric values for temperature, field and range.
            %
            % Doing this in one pass is (~20x) faster than parsing the
            % file by line.
            isMetadataLine = data.startsWith(this.ScanMetaLineStartMarker);
            [temperatures, fields, range] = this.parseScanMetadataLines(data(isMetadataLine));
            
            % Parse the actual data corresponding to each scan.
            dataLines = data(~isMetadataLine);
            scanData = this.parseScanDataLines(dataLines);
        end
        
        function finalize(this, range, numScans, time)
            % Warn if ranges are 1000
            if all(range == 1000)
                this.Logger.logWarning(iAllRanges1000Warning(), "squidlad:import:AllRanges1000");
            elseif any(range == 1000)
                this.Logger.logWarning(iSomeRanges1000Warning(), "squidlad:import:SomeRanges1000");
            end
            
            this.Logger.logInfo(sprintf("Imported %i scans in %.2f s.", numScans, time));
        end
    end
    
end

function s = iAllRanges1000Warning()
s = "All 'squid range' values are reported as 1000. This can be due to a bug in MultiVu. Consider checking that 'squid range' correspond in the data file and the raw file. If they differ, use the scaleFactor argument to compensate.";
end

function s = iSomeRanges1000Warning()
s = "Some, but not all, 'squid range' values are reported as 1000. This can be due to a bug in MultiVu. Consider checking that 'squid range' correspond in the data file and the raw file. If they differ, use the scaleFactor argument to compensate.";
end

% function scanResults = iReshapeScanData(scanData, numPointsPerScan, numScans)
% % Reshape the [NumScans*ZPointsPerScan x 2] array into a
% % [ZPointsPerScan x 2 x NumScans] array. For every scan, rescale
% % by the appropriate factor for range and rescaleFactor.
% %
% % It's surely possible to do this with reshape + permute, and
% % that's probably faster.
% 
% scanResults = zeros(numPointsPerScan, 2, numScans);
% for i=1:numScans
%     idx = (1 + (i-1)*numPointsPerScan):(i*numPointsPerScan);
%     scanResults(:,:,i) = scanData(idx, :);
% 
%     % Take into account the range.
%     scanResults(:,2,i) = scanResults(:,2,i) * range(i) * rescaleFactor;
% end
%end