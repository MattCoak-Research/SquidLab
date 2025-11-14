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

classdef MPMS_IQuantum < squidlab.import.ImportPipeline
    %Import pipeline for an old generation MPMS XL datafile, using the He-3 IQuantum option, which doesnt
    %have headed blocks of data throught the raw file, but instead a single
    %table of values. This is completely different to a standard MPMS1 file
    %too!
    
    properties
        HeaderLines = 31; % We want to ignore this many lines of the file as header.
        RescaleFactor = 1;
    end
    
    methods (Access = protected)
        function [meta] = GetMetaData(this)
            meta.XVar = 'T';
            meta.CalibrationFactor = 1.096e-3;
            meta.CoilRadius = 9.7;
            meta.CoilSeparation = 15.19;
            meta.CryostatInfo = 'MPMS IQuantum He-3 option, standard format, MvT';
        end
    end
    
    methods(Access = public)
        
        function [results, info] = process(this, fileName, scaleFactor)
            
            this.Logger.setBusy("import");
            t = tic();
            
            % Reads the data in the file fileName, and returns a
            % struct of scans, temperatures and fields, and a struct of
            % additional diagnostic.
            timer = tic();
            
            % Initialize variables. Open file once to read header first
            metaData = this.LoadHeaderMetaData(fileName);
            pointsInFirstScan = metaData.NumberOfPoints;
            scanLength = metaData.ScanLength * 10;  %in mm now, from cm
            initialCentrePos = metaData.InitialPosition * 10;    %in mm now
            
            %I-Quantum does not record position (???) so let us generate
            %positions equally spaced along the movement length
            for i = 1 : pointsInFirstScan
                positions(i) =  initialCentrePos - 0.5 * scanLength + i * scanLength/pointsInFirstScan;
            end
            
            % Setup the Import Options and import the data
            opts = delimitedTextImportOptions("NumVariables", 9 + pointsInFirstScan);
            
            % Specify range and delimiter
            opts.DataLines = [26, Inf];
            opts.Delimiter = ",";
            
            % Specify column names and types - note that because we don't
            % actually know the number of voltage columns until runtime,
            % need to use the for loop to append N of those.
            VariableNames = ["Time", "TargetFieldOe", "ActualFieldOe", "T_finalK", "Temp_minK", "Temp_maxK", "Temp_meanK", "SQUID_Channel", "Scans_per_meas"];
            VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double"];
            for i = 1 : pointsInFirstScan
                VariableNames = [VariableNames, num2str(i)];
                VariableTypes = [VariableTypes, "double"];
            end
            
            opts.VariableNames = VariableNames;
            opts.VariableTypes = VariableTypes;
            
            % Specify file level properties
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
                        
            % Import the data
            dataTable = readtable(fileName, opts);
            data = table2array(dataTable);
            voltages = data(:, 10:9+pointsInFirstScan);  %This will be a NxpointsInScan array of the voltages
            
            %Number of scans
            numberOfScans = length(dataTable.Temp_meanK);
            
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
                    z = positions(j);
                    V = voltages(i, j);
                    scanData(j, 1, i) = z;
                    scanData(j, 2, i) = V * this.RescaleFactor * scaleFactor;
                end
                
                %Retrieve temperature and field data for this scan
                temperatures(i) = dataTable.Temp_meanK(i);
                fields(i) = dataTable.ActualFieldOe(i);
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
            info.TimeInSeconds = toc(timer);
            info.Meta = this.GetMetaData();
            
            this.Logger.setFinished("Import");
        end
    end
    
    methods(Access = protected)
        
        function meta = LoadHeaderMetaData(~, fileName)
            %% Setup the Import Options and import the data
            opts = delimitedTextImportOptions("NumVariables", 33);
            
            % Specify range and delimiter
            opts.DataLines = [16, 19];
            opts.Delimiter = ",";
            
            % Specify column names and types
            opts.VariableNames = ["Var1", "Var2", "Var3", "T_finalK", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31", "Var32", "Var33"];
            opts.SelectedVariableNames = "T_finalK";
            opts.VariableTypes = ["string", "string", "string", "double", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];
            
            % Specify file level properties
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            
            % Specify variable properties
            opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31", "Var32", "Var33"], "WhitespaceRule", "preserve");
            opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31", "Var32", "Var33"], "EmptyFieldRule", "auto");
            
            % Import the data
            tab = readtable(fileName, opts);
            
            % Convert to array type
            tab = table2array(tab);
            
            %Store values in meta struct
            meta.ScanLength = tab(1,1);
            meta.NumberOfPoints = tab(2,1);
            meta.InitialPosition = tab(3,1);
        end       
    end
    
end