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

classdef(Abstract) LineReadingImportPipeline < squidlab.import.ImportPipeline
    % IMPORTPIPELINE  Interface for importing data from a file on disk line-by-line
    %
    % Subclass this and implement its protected methods to provide a way to
    % import data for a particular cryostat datafile type. Then use the
    % subclass to read data into scans.
    %
    % Example:
    %   fileName = 'mydata.dat';
    %   pipeline = MyImportPipeline();
    %   % I've correctly implemented abstract properties and methods.
    %   [results, info] = pipeline.process(fileName);
    %   % results in a struct with fields:
    %   %   Temperatures: [1 x NScans]
    %   %   Fields: [1 x NScans]
    %   %   Scans:  [NPointsPerScan x 2 x NScans]
    %
    % %%%%%% LIMITATIONS %%%%%%%%%
    % - You must be able to read the whole file into memory. This is not
    %   guaranteed to hold for very large numbers of scans. In that case, you
    %   should subclass this and re-use the general approach with
    %   out-of-memory methods.
    % - This class uses a very naive continuous reallocation of the scan data
    %   array and various others at every line of the file. This array will
    %   become quite large, and reallocating it in every step of a for loop
    %   like this is quite horrible - it will fragment your MATLAB memory
    %   all over the place, and be quite slow. This is ripe for
    %   optimization.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % USERS MUST IMPLEMENT EVERYTHING MARKED ABSTRACT IN DERIVED CLASSES
    properties(Abstract)
        % HeaderLines (scalar int)
        % Number of lines in the file that need to be ignored because
        % they're just the file header, and contain no data.
        %
        % Example: 31
        HeaderLines
    end
    
    methods(Abstract, Access = protected)
        
        tf = isScanMetaDataLine(this, line)
        % isScanMetaDataLine
        % Returns true when a line is classed as ScanMetaData.
        %
        % Called for every line of the file; line will be passed as a char
        % vector, corresponding to a single line of the file.
        % Implementations should return true if, for their file type, that
        % line is a ScanMetaData line, and otherwise return false.
        %
        % To decide the line type, you should use methods which look at the
        % whole line but don't split it; strsplit() is quite slow, and this
        % method will be called on every line of your file. It's preferable
        % to e.g. look at the first character or count the number of a
        % given type of character in the line.
        
        tf = isScanDataLine(this, line)
        % isScanDataLine
        % Returns true when a line is classed as ScanData.
        %
        % Called for every line of the file; line will be passed as a char
        % vector, corresponding to a single line of the file.
        % Implementations should return true if, for their file type, that
        % line is a ScanData line, and otherwise return false.
        %
        % To decide the line type, you should use methods which look at the
        % whole line but don't split it; strsplit() is quite slow, and this
        % method will be called on every line of your file. It's preferable
        % to e.g. look at the first character or count the number of a
        % given type of character in the line.
        
        [temperature, field] = processScanMetaDataLine(this, line);
        % processScanMetaDataLine
        % Returns the temperature and field for a given ScanMetaDataLine.
        %
        % Called for every line of the file classed as ScanMetaData; line
        % will be passed as a char vector. Implementations should parse
        % this line in the way required for their datafiles, and return
        % temperature and field as scalar doubles.
        
        [position, signal] = processScanDataLine(this, line);
        % processScanDataLine
        % Returns the temperature and field for a given ScanDataLine.
        %
        % Called for every line of the file classed as ScanData; line
        % will be passed as a char vector. Implementations should parse
        % this line in the way required for their datafiles, and return
        % position and signal as scalar doubles.
        
        [meta] = GetMetaData(this);
        %GetMetaData - Return a struct specific to each import type with
        %data information and paramters in that the programme might use. eg
        %Meta.XVar = 'H' to detial that the x units are field not
        %temperature.
    end
    
    % BELOW IS PROTECTED - USERS MAY OVERRIDE IF NEEDED IN DERIVED CLASSES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties
        
    end
    
    
    properties(SetAccess = protected)
        % FileName (char vector)
        % Name of the file to import.
        FileName = '';
        
        % Header (string array)
        % Holds the header data for the file (anything in lines
        % 1:HeaderLines).
        Header;

        RescaleFactor = 1;
    end
    
    properties
       % StopAtLine (scalar int)
       % Set this to a finite value to only read a certain number of lines
       % of a file, rather than all of them.
       %
       % If this is the default, inf, the entire file will be read.
       % Otherwise, reading will continue until file line StopAtLine, then
       % it will stop.
       StopAtLine = inf;
    end
    
    methods
        
        function [results, info] = process(this, fileName, scaleFactor)
            % Reads the data in the file this.FileName, and returns a
            % struct of scans, temperatures and fields, and a struct of
            % additional diagnostic.
            
            %Log progress
            this.Logger.setBusy("Importing");
            drawnow;
            
            timer = tic();
            this.FileName = fileName;
            dataAsCell = this.readFileToData();
            
            % Which scan we're currently reading.
            scanIndex = 0;
            
            % Which datapoint in the scan we're currently at.
            positionIndex = 0;
            
            % Allocate a 3D array to store data. This array will
            % eventually be [NumDataPointsPerScan x 2 x NumScans].
            % For every scan, there are NumDataPointsPerScan [position,
            % signal] pairs.
            %
            % This array, and others, are continuously reallocated. This is
            % certainly quite slow. A sensible optimization might be to
            % reallocate in blocks of NaNs if needed, and remove NaNs at
            % the end. This should use a clever buffering approach (e.g.
            % double the array size every time reallocation is required).
            %
            % A nice alternative would be to use the fact that, once we've
            % completed one scan, all other scans are probably the same
            % size. This lets us roughly estimate the size of the arrays
            % needed early in the process based on the number of lines in
            % dataAsCell, so we'd only have to reallocate a couple of
            % times.
            scanData = nan(1,1,3);
            
            % Sanity check: we expect the same number of [position, signal]
            % pairs in every scan. We'll track this and make sure this is
            % actually what we do get, then error out afterwards if not.
            pointsInScan = [];
            
            temperatures = [];
            fields = [];
            
            % Check if we're reading the whole file.
            lastLine = this.computeLastLineNumber(dataAsCell);    

            %Temp variable to track if a block is valid
            blockValid = true;
            
            for i=1:lastLine
                
                line = dataAsCell{i,1};
                
                % We need to distinguish between the 2 types of line:
                % - a ScanMetaDataLine
                % - a ScanDataLine
                if this.isScanMetaDataLine(line)
                    [temperatures(end+1), fields(end+1), range] = this.processScanMetaDataLine(line);
                    
                    % Store the number of points in the previous scan, to
                    % check they're all the same at the end.
                    if scanIndex > 0
                        pointsInScan(scanIndex) = positionIndex;
                    end
                    
                    % Reset positionIndex (we're in a new scan), and
                    % increment scanIndex.

                    if(blockValid) %Only move to next block if the previous block was valid - otherwise we want to overwrite the block we just took
                        scanIndex = scanIndex + 1;
                    else
                        %Warn the user this is happening
                        this.Logger.showWarning("Parsing a data line has failed, NaNs were returned.\nThis scan will be skipped from the import, a datapoint will be missing. Reccomended to check datafile if this is happening more than once in a single file.\n\nThe line was: \n" + line, "Data line failed to parse");
                        this.Logger.logWarning("Data line failed to parse");
                   
                        %Clear temperature and field values for that
                        %invalid block
                        temperatures(end) = [];
                        fields(end) = [];
                    end
                    positionIndex = 0;

                    blockValid = true;

                elseif this.isScanDataLine(line)
                    
                    [z, V] = this.processScanDataLine(line, range);

                    if(isnan(z) || isnan(V))
                        blockValid = false; %This flag will be reset once we hit a metadata line and move to the next scan
                    end

                    if(blockValid)
                        % If there is an issue parsing this line, we assume
                        % there were a couple of NaNs or missing values
                        % somewhere in the midst of the data file (.raw)
                        % but it is otherwise ok. We used to just error
                        % out, but now let's try to drop this one scan and
                        % use all the others
    
                        %No issue with parsing the line, import normally
                        %and add to array
                        positionIndex = positionIndex + 1;

                        scanData(positionIndex, 1, scanIndex) = z;
                        scanData(positionIndex, 2, scanIndex) = V * this.RescaleFactor * scaleFactor;
                    end
                end
            end
            
            
            this.Logger.setFinished("Importing");
            
            %If range is 1000 (ofc we are just looking at the last point
            %here) - this could be a bug where the MPMS puts 1000 as the
            %squid range in the Raw file, but not the standard data file.
            %1000 is the default value and will not be correct. Warn the
            %user.
            if(range == 1000)
                if(~this.Logger.SuppressSquidRangeWarning)
                    this.Logger.showWarning("The Squid Range is reported as 1000 - this can be due to a bug in MultiVu. Consider checking that Range corresponds in the Data file and the Raw file. If they differ, use the ScaleFactor to compensate.", "Squid Range Warning");
                end
            end
            
            % Check read worked correctly.       
            this.Logger.setBusy("Validating");
            this.validateProcess(temperatures, scanData, pointsInScan, positionIndex);            
            this.Logger.setFinished("Validating");
            
            % Results to return.
            results.Temperatures = temperatures(:);
            results.Fields = fields(:);
            results.ScanData = scanData;
            
            % Diagnostics to return.
            info.FileName = this.FileName;
            info.NumScans = length(temperatures);
            info.TimeInSeconds = toc(timer);
            info.Meta = this.GetMetaData();
        end
        
    end
    
    methods(Access = protected)
        function dataAsCell = readFileToData(this)
            % Reads a text file into a cellstr array, and removes the
            % header so only data remains. The header is stored in
            % this.Header.
            
            % Catch a common error with bad paths.
            if ~exist(this.FileName, 'file')
               error("Couldn't find file %s - might be a relative path issue.",...
                   this.FileName);
            end
            
            fileAsCell = this.readFileToCell(this.FileName);
            this.Header = fileAsCell(1:this.HeaderLines);
            dataAsCell = fileAsCell(this.HeaderLines + 1:end);
        end
        
        function fileAsCell = readFileToCell(~, fileName)
            % Read a file into a cellstr array, with one line per cell.
            
            fid = fopen(fileName);
            data = textscan(fid,'%s','Delimiter','\n');
            
            % Using textscan like this gives us a 1x1 cell array with a
            % cell containing the actual cell array we want.
            fileAsCell = data{1};
            fclose(fid);
        end
        
        function values = splitLineAndPickCells(~, line, splitDelimiter, idx, extractBetweenDelimiters)
            % Splits a line of text using strsplit, then converts text in
            % each cells to numbers, and returns the desired numbers.
            %
            % Pass line as a char array, splitDelimiter (which sets how the
            % text is split) as a char, and idx as an int vector of cells
            % you want to pick out. 
            %
            % Values are returned as a row vector of doubles.
            %
            % If you need to additionally preprocess
            % text within a cell, provide the additional 5th arg
            % extractBetweenDelimiters as a 1x2 string vector, denoting
            % where to extract text before and after.
            %
            % Example:
            %   % Extract comma-delimited data.
            %   line = '10,20,30,40';
            %   splitDelimited = ','; % Data is comma-delimited
            %   idx = [2 4]; % Get the 2nd and 4th values.
            %   values = splitLineAndPickCells(line, splitDelimiter, idx);
            %   % values == [20, 40];
            %
            %   % Extract comma-delimited data which has some extra
            %   % formatting in each column.
            %   line = 'a=10.,b=20.,c=30.,d=40.';
            %   splitDelimited = ','; % Data is comma-delimited
            %   idx = [2 4]; % Get the 2nd and 4th values.
            %   extractBetweenDelimiters = ["=", "."]; % We want to remove these.
            %   values = splitLineAndPickCells(line, splitDelimiter, idx, extractBetweenDelimiters);
            %   % values == [20, 40];
            % Can return NaN if cells of data are empty or invalid -
            % pipeline should handle this case. Did previously just error
            % here, but often we only have one scan that is a mess and we
            % could just drop that scan.
            
            splitLine = strsplit(line, splitDelimiter);
           
            % Pick out the relevant quantities
            for i=1:length(idx)
                
                valueAsString = splitLine{idx(i)};
                
                % If extractBetweenDelimiters was provided, we need to
                % additionally process the string before trying to do
                % conversion to double.
                if nargin > 4
                    valueAsString = extractBetween(string(valueAsString),...
                        extractBetweenDelimiters(1),...
                        extractBetweenDelimiters(2));
                end
                
                values(i) =  str2double(valueAsString);
            end
        end
        
        function lastLine = computeLastLineNumber(this, dataAsCell)
            % Returns the index of the line to stop at.
            %
            % If this.StopAtLine is infinite, the last line is just the
            % length of the file. If not, then we need to calculate the
            % stop point. Note that we need to take because we've removed
            % the file header, so the line to stop at in the file (which is
            % StopAtLine) isn't the same is lastLine.
            
            if isinf(this.StopAtLine)
                lastLine = length(dataAsCell);
            else
                % Deal with the stop point.
                
                % Make sure it's sane.
                validateattributes(this.StopAtLine, {'numeric'},...
                    {'scalar', 'positive', 'integer'});
                
                lastLine = this.StopAtLine - this.HeaderLines;
            end
        end
        
        function validateProcess(~, temperatures, scanData, pointsInScan, positionIndex)
           % Verifies that processing the data worked as expected and the
           % resulting scanData is sensible.
                      
           % Make sure we have a temperature and field for every scan or
            % we're in trouble.
            assert(length(temperatures) == size(scanData, 3),...
                "%i scans but %i temperatures; these values should match.",...
                size(scanData, 3), length(temperatures));
            
            % Make sure all our scans had the same length. We can't just
            % check the actual scanData, because that will auto-expand to
            % be the right size, filling with zeros. First, we can try
            % checking pointsInScan to make sure it's always the same
            % (cunningly, this doesn't depend on the size of scanData)...
       %     assert( length(unique(pointsInScan)) == 1,...
             %   "There should only be one unique value for the number of points in a scan, but there were %i.", length(unique(pointsInScan)));
            
            % ...But if we stopped part-way through a scan - the most
            % likely failure mode - we won't have updated pointsInScan yet.
            % Therefore check the length of the last scan against the
            % length of the first one.
        %    assert(pointsInScan(1) == positionIndex,...
         %       "All scans should have the same number of points, but the first scan had %i points and the final one %i points.",...
        %        pointsInScan(1), positionIndex);
            
        end
    end

end