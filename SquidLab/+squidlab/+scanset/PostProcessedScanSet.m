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

classdef PostProcessedScanSet < squidlab.scanset.ScanSet
    % POSTPROCESSEDSCANSET  ScanSet that allows processing of RawScanSets.
    %
    % This post-processing can include subtracting linear SQUID drift,
    % smoothing, or even replacing the raw data with a spline.
    
    properties(Access = public)
        % SmoothingSpan (scalar odd int)
        % Sets the size of the moving average window used by smooth() to
        % smooth data (a larger value will mean more smoothing).
        % Value of 0 will leave data unchanged.
        SmoothingSpan = 0;
        
        % DriftSubtractionRange (scalar int)
        % Sets how many points are used at the start and end of a scan to
        % subtract a linear drift. If this is 5, a straight line will be
        % fitted to the first 5 and last 5 points, and this straight line
        % will be subtracted from the signal.
        % Value of 0 will leave data unchanged.
        DriftSubtractionRange = 1;
        
        % CentreX (bool)
        % Sets whether the mean value of the position will be subtracted
        % from each scan, shifting its centre to zero.
        CentreX logical = false;
        
        % CentreY (bool)
        % Sets whether the mean value of the signal will be subtracted from
        % each sweep, shifting its centre to zero.
        CentreY logical = true;
        
        % FitMethod ("none" | "pchipinterp" | some other valid option for fit())
        % Sets how the scan is fitted and replaced. Use this to improve
        % smoothing. If this is "none", no replacement will be done. If
        % this is e.g. "pchipinterp", the sweep will be replaced with a
        % cubic interpolating spline. See options for fit().
        FitMethod = "pchipinterp";
        
        % AverageConsecutive (bool)
        % Sets whether every pair of scans is averaged. You want this if
        % the import process splits up and down scans. In this case, you
        % want to average these two together - This is for certain MPMS3 files, try this if you have unexplained duplicate data points.
        AverageConsecutive logical = false;
        
        % ZTrimRange ([1x2] double)
        % Sets what z-values are included in the post-processed results.
        % Use this to remove problematic points at the edges of a sweep.
        ZTrimRange = [-Inf Inf];
        
        % ShiftZ ([1x1] double)
        % Will shift a ScanSet along z - note that this clearly conflicts
        % with CentreX! Be careful with ZTrim too.
        ShiftZ = 0;

        % TDepShift ([1x2] double)
        % ADVANCED ONLY - defines a slope and offset (like y=mx+c) for a
        % temperature-dependent sideways shift of the data. First element
        % of length 2 array is gradient, in mm/K, second is a mm offset.
        % This function uses circshift to cycle the data, pushing values
        % off the right of the graph and bringing them in again on the
        % right to preserve the quantity and position of data values - this
        % will give wierd anomalous and cusps! It is intended that you will
        % then trim the outer edges of teh data where this happens and keep
        % the centre only.
        TDepShift = [0 0];

        RemoveZeroes logical = false;
    end
    
    properties(Hidden)        
        % PipelineDefinition (cell vector)
        % %%% For advanced users only. %%%
        %
        % Sets which pipes are used to do post-processing.
        % 
        % This is a cell vector of pairs of values. Each pair defines a
        % pipe and its arguments. When postProcess() is called, scans and
        % temperatures will be passed through these pipes, from first to
        % last, in sequence.
        %
        % The first cell of each pair refers to the
        % squidlab.postprocess.PostProcessPipe object to instantiate.
        %
        % The second cell is a cell array, which determines which arguments
        % will be given to that pipe as additional arguments after the
        % scans and temperatures. If any of these arguments is a valid
        % public property of this PostProcessedScanSet, that argument will
        % be replaced with the current value of the property just before
        % pipe.process() is called. Use this to easily interface your
        % custom pipes with the user-visbile properties of this object.
        PipelineDefinition =...
            {'TrimZ', {'ZTrimRange'},...
            'SimpleSmooth', {'SmoothingSpan'},...
            'Centre', {'CentreX', 1},...
            'Centre', {'CentreY', 2},...
            'AverageUpDown', {'AverageConsecutive'},...
            'LinearDriftSubtract', {'DriftSubtractionRange'},...
            'FitReplace', {'FitMethod'},...
            'Shift', {'ShiftZ'},...
            'TDependent_Shift', {'TDepShift'},...
            'RemoveZeroes' {'RemoveZeroes'}};
        
        % CustomPipelineDefinition (cell vector)
        % %%% For advanced users only. %%%
        % 
        % Define custom pipes here dynamically, if you don't want to edit
        % this classdef to put them in PipelineDefinition. You can set them
        % directly here, or you can provide them as arguments to
        % addCustomPipeline().
        %
        % These pipes will be treated identically to those in
        % PipelineDefinition, but will be called afterwards. This means
        % that, if you want to insert your own pipes earlier in the
        % process, you should instead ignore this property and directly set
        % PipelineDefinition.
        %
        % Example:
        %   % You've correctly created a squidlab.postprocess.MyPipe class
        %   % implementing squidlab.postprocess.PostProcessPipe.
        %
        %   ppss = PostProcessedScanSet(rawScanSet);
        %   ppss.CustomPipelineDefinition = {'MyPipe',...
        %   {'AverageConsecutive', 3}};
        %
        %   % In postProcess, after data has gone through all pipes in 
        %   % PipelineDefinition, it'll be passed to your MyPipe.process()
        %   % method. Additional arguments will be the current value of 
        %   % this.AverageConsecutive, and 3, which your process() method 
        %   % may take as additional args. 
        CustomPipelineDefinition = {};
        
        % DebugPipeline (logical)
        % If this is true, information will be printed to the command line
        % after each pipe is processed. This can make it much easier to
        % work out e.g. why your data is ending up as size [1x0].
        DebugPipeline = false;
    end
    
    properties(SetAccess = protected)
        % RawScanSet (squidlab.scanset.RawScanSet)
        % Returns the RawScanSet this wraps.
        RawScanSet
    end
    
    properties(Dependent, SetAccess = protected)
        % RawScanData ([NumPointsPerScan x 2 x NumScans] double)
        % Returns the ScanData of the RawScanSet this wraps.
        RawScanData
    end
    
    methods
        function value = get.RawScanData(this)
            % Pass-through to get the RawScanSet's data.
            value = this.RawScanSet.ScanData;
        end
    end
    
    methods
        function this = PostProcessedScanSet(rawScanSet)
            % Construct an instance.
            % Provide a RawScanSet to get data from.
            
            assert(isa(rawScanSet, 'squidlab.scanset.ScanSet'));
            
            % Delegate to parent ctor.
            this@squidlab.scanset.ScanSet(rawScanSet.Temperatures,...
                rawScanSet.Field,...
                rawScanSet.ScanData);
            
            this.RawScanSet = rawScanSet;   
            this.Meta = rawScanSet.Meta;
        end
        
        function postProcess(this, varargin)
            % Perform post-processing on the data.
            %
            % Data in this ScanSet will have a variety of post-processing
            % done on it, depending on the settings.
            %
            % If you wish to set properties on this before processing,
            % provide them an additional arguments.
            %
            % Examples:
            %   this.postProcess();
            %   this.postProcess('AverageConsecutive', false);
            
            set(this, varargin{:});
            this.doPostProcess();
        end
        
        function addCustomPipeline(this, pipelineName, pipelineParams)
            % Add a new squidlab.postprocess.pipe object to the
            % post-processing pipeline.
            %
            % Pass pipelineName as a string referring to the class name of
            % the new pipe, and pipeLineParams as a cell array of arguments
            % to the new pipe's constructor.
            %
            % If an element of pipelineParams is a string which refers to
            % a public property of this object, the value of that property
            % will be substituted when process() is called. Use this to
            % provide access to settings in this class for custom pipes.            
            
            this.CustomPipelineDefinition(end+1:end+2) = {pipelineName, pipelineParams};
        end
    end
    
    
    methods(Access = protected)
        
        function doPostProcess(this)
            % Actually performs post-processing, constructing the
            % PostProcessPipes and passing the data through them.
            
            % Get starting data.
            scans = this.RawScanData;
            temperatures = this.RawScanSet.Temperatures;
            
            % Get full pipeline definition, including custom ones user has
            % added.
            pipelineDefinition = this.getFullPipeLine();
            
            % Do processing.
            for i=1:2:length(pipelineDefinition)
                [scans, temperatures] = this.doPipeProcess(pipelineDefinition{i}, pipelineDefinition{i+1}, scans, temperatures);
                
                if this.DebugPipeline
                    fprintf("After pipe %i (%s) scan size is [%ix%ix%i].\n", ...
                        (i+1)/2,pipelineDefinition{i}, size(scans, 1),...
                        size(scans, 2), size(scans, 3));
                end
            end
            
            % Store results.
            this.ScanData = scans;
            this.Temperatures = temperatures;           
        end
        
    end
    
    methods(Access = protected)
        function pipelineDefinition = getFullPipeLine(this)
            % Returns the full definition of the post-process pipeline.
            %
            % Have this as a method, not a getter, as we aren't yet sure of
            % the API for adding user-defined pipes so we likely want to
            % improve this.
            
            pipelineDefinition = [this.PipelineDefinition this.CustomPipelineDefinition];
        end
        
        function [scans, temperatures] = doPipeProcess(this, pipeName, pipeParams, scans, temperatures)
            % Does processing for a single pipe.
            %
            % This involves constructing the right pipe, giving it the
            % right arguments (which may involve looking up the value of
            % those arguments from the properties of this), and calling
            % pipe.process.
            
            % Replace any params that refer to a property of this with their
            % value.
            for i=1:length(pipeParams)
                if isprop(this, pipeParams{i})
                    pipeParams{i} = this.(pipeParams{i});
                end
            end
            
            % Construct this pipe and process with it.
            pipe = squidlab.postprocess.(pipeName)();
            [scans, temperatures] = pipe.process(scans, temperatures, pipeParams{:});
        end
    end
    
end