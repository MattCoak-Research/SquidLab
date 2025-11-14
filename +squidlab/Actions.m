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

classdef Actions
    % Actions
    % High-level API for accessing the squidlab libraries.
    
    properties
        % Logger (squidlab.utils.Logger)
        % Handles logging of info, warnings etc. emitted by method calls.
        Logger
    end
    
    methods
        function this = Actions()
            this.Logger = squidlab.utils.CommandLineLogger;
        end
        
        function [results, info] = importData(this, fileName, importerName, scaleFactor)
            % Imports data from a file using a specified importer.
            % Pass fileName as full path to the file.
            % Pass importerName as a fully-qualified package name to a
            % squidlab.import.ImportPipeline.
            %
            % Example:
            %   fileName = "myfile.rw.dat";
            %   importerName = "squidlab.import.MPMS3";
            %   [results, info] = ...
            %       actions.importData(fileName, importerName)
            
            importerFcn = str2func(importerName);
            importer = importerFcn();
            importer.Logger = this.Logger;
            
            [results, info] = importer.process(fileName, scaleFactor);
        end
        
        function rawScanSet = createRawScanset(~, results)
            % Creates a RawScanSet from a struct of results. This must
            % contain:
            % - Temperatures, a [NumScans x 1] vector.
            % - Fields, a [NumScans x 1] vector. However, the fields should
            %   all be the same
            % - ScanData, a [NumZPoints x 2 x NumPoints] array, where
            % ScanData(1,1,3) is the first z-point of the 3rd scan.
            
            rawScanSet = squidlab.scanset.RawScanSet(results.Temperatures, ...
                results.Fields, results.ScanData);
        end
        
        function postProcessedScanSet = postProcess(~, input, varargin)
            % Returns a PostProcessedScanSet, used for smoothing, centring,
            % background subtraction, etc.
            %
            % Pass the first argument as either a ScanSet of some other
            % sort, or a struct in the same form you'd give to
            % createRawScanSet.
            %
            % Pass any additional arguments as name-value pairs after the
            % input.
            %
            % Example:
            %   ppScans = actions.postProcess(rawScans, ...
            %       'AverageConsecutive', false, ...
            %       'SmoothingSpan', 1, ...
            %       'FitMethod', "none");
            
            % If we got a results struct, turn it into a RawScanSet.
            if isstruct(input)
                input = squidlab.scanset.RawScanSet(input.Temperatures, ...
                    input.Fields, input.ScanData);
            end
            
            % Create a PostProcessedScanSet and do processing.
            postProcessedScanSet = squidlab.scanset.PostProcessedScanSet(...
                input);
            postProcessedScanSet.postProcess(varargin{:});
        end
        
        function backsubScanSet = subtractBackground(this, dataScanSet, backgroundScanSet, varargin)
            % Returns a BackgroundSubtractedScanSet from pair of other
            % ScanSets; the first should correspond to the data, and the
            % second to the background.
            %
            % Pass additional arguments as name-value pairs.
            %
            % Options are:
            %   'ShouldPostProcess': logical; set this to true if you want 
            %    to first post-process data and background ScanSets before
            %    doing background subtract.
            %   'PostProcessSettings': cell array of name-value pair
            %    arguments to actions.postProcess. Use this to fine-tune
            %    post-processing at the same time you do background
            %    subtraction.
            %   'BackgroundSubtractionMode': "interp" (default) or
            %    "nearest". Sets how the background is subtracted from the
            %    data. "interp" will do 2D linear interpolation of the
            %    background onto the data; in general this will give the
            %    best results. "nearest" will match each background scan
            %    with the data scan nearest to it in temperature.
            %
            % Example:
            %   backsubScanSet = actions.subtractBackground(...
            %       dataSS, bkgSS, 'ShouldPostProcess', true,...
            %        'PostProcessSettings', ...
            %       {'AverageConsecutive', false, ...
            %       'ZTrimRange', [-10 10]});            
            
            p = inputParser();
            p.addParameter('ShouldPostProcess', false, @islogical);
            p.addParameter('PostProcessSettings', {}, @iscell);
            p.addParameter('BackgroundSubtractionMode', "interp", @(x)mustBeMember(x, ["interp", "nearest"]));
            p.parse(varargin{:});
            
            % Post-process if necessary.
            if p.Results.ShouldPostProcess
                dataScanSet = this.postProcess(dataScanSet, p.Results.PostProcessSettings{:});
                backgroundScanSet = this.postProcess(backgroundScanSet, p.Results.PostProcessSettings{:});
            end
            
            % Do background subtraction.
            backsubScanSet = squidlab.scanset.BackgroundSubtractedScanSet(...
                dataScanSet, backgroundScanSet, ...
                p.Results.BackgroundSubtractionMode);
        end
        
        function fittedScanSet = fitLevenbergMarquadt(~, scanSet, varargin)
            % Returns a fitted LevenbergMarquadtFitScanSet from a ScanSet.
            % Pass as name-value pairs any properties you wish to set on
            % the FitScanSet before doing the fit.
            
            fittedScanSet = squidlab.scanset.LevenbergMarquadtFitScanSet(scanSet);
            fittedScanSet.fit(varargin{:});
        end
        
        function fittedScanSet = fitSVD(~, scanSet)
            % Returns a fitted SVDFitScanSet from a ScanSet.
            % Pass as name-value pairs any properties you wish to set on
            % the FitScanSet before doing the fit.
            
            fittedScanSet = squidlab.scanset.SVDFitScanSet(scanSet);
            fittedScanSet.fit();
        end
        
        function results = rescaleFromFile(~, results)
            %Rescales scansets that have the MPMS3 SquidRange = 1000 bug,
            %by loading the .dat file and reading the ranges
            results = squidlab.utils.rescaleFromFile(results);            
        end
        
        function resultsOut = mirrorData(~, results)
           mirroredResults = results;
           
           %Flip the fields.. yes they are called 'temperatures' - that
           %just means 'independent variable'
           mirroredResults.Temperatures = -mirroredResults.Temperatures;
           
           %Flip the voltages too
           mirroredResults.ScanData(:, 2, :) = -mirroredResults.ScanData(:, 2, :);
           
           resultsOut = results;
           
           resultsOut.ScanData = cat(3, mirroredResults.ScanData, results.ScanData);
           resultsOut.Fields = [mirroredResults.Fields; results.Fields ];
           resultsOut.Temperatures = [mirroredResults.Temperatures; results.Temperatures];
        end
        
    end

end