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

classdef(Abstract) ScanSet < handle
    % SCANSET  Interface for ScanSets.
    % 
    % ScanSets hold sets of scans from a single field sweep. They provide a
    % convenient way to store the scan and temperature data, and provide a
    % number of convenient methods to:
    % - plot the scans.
    % - get only a restricted number of scans.
    % - get scans at different temperatures, e.g. with interpolation
    %  (necessary for background subtraction).
    %
    % This class is ABSTRACT, which means it can't be instantiated
    % directly. Instead, make a RawScanSet (which holds raw data), or a
    % PostProcessedScanSet (which holds a RawScanSet, and provides methods
    % to smooth, subtract a linear SQUID drift, etc.)
    %
    % Example usage of implementations:
    %   % Create an instance
    %   ss = MyScanSet(temperatures, fields, scans);
    %
    %   % Plot the scans
    %   plot(ss);
    %
    %   % Plot only a subset.
    %   ss.UseEvery = 10;  % Only show every 10th scan.
    %   ss.TemperatureRange = [50 100];  % In Kelvin
    %   plot(ss);
    %
    %   % Reset to using all.
    %   ss.useAll();
    %
    %   % Get scans at 5,10,15 K...
    %   % Using interpolation.
    %   scans = ss.getScansAt([5 10 15]);
    %   
    %   % Using the nearest measured scans.
    %   scans = ss.getScansAt([5 10 15], "nearest");
    
    properties(Access = public)
        % TemperatureRange ([1 x 2] double)
        % Sets which scans will be included in plots etc. - only scans with
        % a temperature in this range will be included.
        %Coak Feb 2019 - Set this to -Inf Inf to accomodate idiot hack of
        %MvH using temeprature to describe field
        TemperatureRange = [-Inf Inf]
        
        
        % ZRange ([1 x 2] double)
        % Sets which z-values will be included in plots etc. - only
        % z-values within these limits will be included.
        ZRange = [-Inf Inf]
        
        % ScanRange ([1 x 2] double)
        % Sets which scans will be included in plots etc. - only
        % scans within these indices will be included, if in Scans plot mode that is.
        ScanRange = [-Inf Inf];
        
        % UseEvery (scalar int)
        % Sets how many scans will be included in plots etc. - only every
        % UseEvery scan will be included. Set this to e.g. 5 to show only
        % every 5th scan, which will improve the appearance of plots etc.
        UseEvery = 1;
        
        % Plotter (squidlab.scanset.ScanPlotter)
        % Used when plot() is called. Contains many settings for changing
        % the appearance of plots. See the documentation for 
        % squidlab.scanset.ScanPlotter for more details.
        Plotter = squidlab.scanset.ScanPlotter();
        
        %Stores metadata like x axis units, SQUID coil radius etc. This
        %used to be stored centrally in the application, but in v2.9 it's
        %moved to be here, per-scan, instead.
        Meta;
    end
    
    properties(SetAccess = protected)
        % Temperatures ([NumScans x 1] double)
        % List of the temperatures each scan was taken at, in kelvin.
        Temperatures;
        
        % Field (scalar double)
        % The magnetic field this set of scans was taken at.
        Field;
        
        % ScanData ([NumPointsPerScan x 2 x NumScans] double)
        % Actual data in the scans. ScanData(:,:,3) is data for the 3rd
        % scan, and will be a NumPointsPerScan x 2 array of [position
        % signal].
        ScanData;
    end
    
    properties(Dependent, SetAccess = protected)
        % SelectedScans ([NumPointsPerScan x 2 x N] double])
        % Returns every UseEveryth scan that has a temperature within 
        % TemperatureRange. 
        SelectedScans
        
        % SelectedTemperatures ([N x 1] double)
        % Returns every UseEveryth temperature within TemperatureRange.
        SelectedTemperatures
        
        % NumScans (scalar int)
        % Returns the number of scans.
        NumScans
    end
    
    methods(Access = public)
        
        function this = ScanSet(temperatures, fields, scanData)
            % Construct an instance.
            %
            % Pass temperatures as a [NumScans x 1] array, fields as either
            % a scalar or an array of fields (which will be checked to
            % ensure all fields are identical), and scanData as a
            % [NumPointsPerScan x 2 x NumScans]
%             
%             % Currently, we only support T sweeps at a single field, so
%             % error if we're not going to get that.
%             if length(fields) > 1
%                 assert(~any(diff(fields)),...
%                     "All fields must be identical.");
%             end
            
            this.Field = fields(1);
            this.Temperatures = temperatures;
            this.ScanData = scanData;
        end
        
        function removeScans(this, scanIndices)
            %Removes the Scans given by scanIndices from this ScanSet - eg
            %remove the 6th and 7th temperatures if they have jumps in etc
            this.Temperatures(scanIndices) = [];
            this.ScanData(:, :, scanIndices) = [];
        end
        
        function lineHandles = plot(this)
            % Plots the selected scans in this ScanSet.
            %
            % If too many scans are being plotted, try changing UseEvery or
            % TemperatureRange.
            %
            % Examples:
            %   % this.plot();
            %   
            %   % Plot only every 10th scan.
            %   this.UseEvery = 10;
            %   this.plot();
            %
            %   % Customise the plot appearance
            %   this.Plotter.FontSize = 19;
            %   this.Plotter.DefaultFigureArgs = {'Position', [200 200 1000 800], 'Color', 'green'};
            %   this.Plotter.Colormap = {'g', 'k'};
            %   this.plot();
            
            
            this.Plotter.DataMarkerType = '-';
            lines = this.Plotter.plotScans(this.SelectedScans, this.SelectedTemperatures);
            
            % Avoid annoying printing of the whole lines array to the
            % command line if caller didn't ask for it.
            if nargout > 0
               lineHandles = lines;
            end
        end
        
        function useAll(this)
            % Convenience method to reset TemperatureRange to [0 Inf] and
            % UseEvery to 1.
            
            this.UseEvery = 1;
            this.TemperatureRange = [-Inf Inf];
            this.ScanRange = [-Inf Inf];
        end
        
        function useEvery(this, n)
            % Convenience method to reset TemperatureRange to [0 Inf] and
            % UseEvery to n.
            
            this.UseEvery = n;
            this.TemperatureRange = [-Inf Inf];
            this.ScanRange = [-Inf Inf];
        end
        
        function UseScanRange(this, scanFrom, scanTo)
           %Set temperature range to all, useEvery to 1, and set the scan numbers to plot only          
           
            this.UseEvery = 1;
            this.TemperatureRange = [-Inf Inf];
            this.ScanRange = [scanFrom scanTo];
        end
        
        function scans = getScansAt(this, temperatures, zPoints, mode, varargin)
            % Returns an array of scans (of size [NumPointsPerScan x 2 x
            % length(temperatures)]) at the requested temperatures.
            %
            % Pass temperatures as a vector of double temperature values.
            %
            % The optional argument mode can be one of:
            % - "interp": first, a 2D scatteredInterpolant will be
            %   constructed, with columns [Position Temperature Signal].
            %   Then, this interpolant will be used to interpolate at a scan
            %   at exactly the specified temperature. This is the default.
            %   Any additional arguments after mode will be passed straight
            %   to scatteredInterpolant.
            % - "nearest": for each temperature, the actual scan taken
            %   nearest to that temperature will be returned.
            %
            % Examples:
            %   % Get scans using interpolation.
            %   scans = this.getScansAt([50 60 70]);
            %
            %   % Get scans with the "nearest" mode.
            %   scans = this.getScansAt([100 110], "nearest");
            
            % Default.
            if nargin < 3
                mode = "interp" ;
            end
            
            switch mode
                case "interp"
                    % Make a scatteredInterpolant then query it at the
                    % requested temps.
                    scans = this.interpolateScansAtTemperature(temperatures, zPoints, varargin{:});
                case "nearest"
                    % Just get the actual scans nearest to the request
                    % temperatures.
                    scans = this.findScansNearTemperature(temperatures);
                otherwise
                    error("Mode '%s' not supported", mode);
            end
        end
        
        function backgroundSubtractedScans = getBackgroundSubtractedScanSet(this, backgroundScanSet, mode)
            
           if nargin < 3
              mode = "interp"; 
           end
           
           backgroundSubtractedScans = squidlab.scanset.BackgroundSubtractedScanSet(this, backgroundScanSet, mode);
        end
    end
    
    % Getters and setters
    methods
        
        function value = get.SelectedScans(this)
            % Returns every this.UseEveryth scan within the temperature range
            % this.TemperatureRange.
            
            value = this.ScanData(this.getSelectedZRangeIdx(),:, this.getSelectedRangeIdx());
        end
        
        function value = get.SelectedTemperatures(this)
            % Returns every this.UseEveryth temperature within the
            % temperature range this.TemperatureRange.
            
            value = this.Temperatures(this.getSelectedRangeIdx());
        end
        
        function value = get.NumScans(this)
            % Returns the number of scans.
            
            value = size(this.ScanData, 3);
        end
        
    end
    
    methods(Access = protected)
        
        function idx = getSelectedRangeIdx(this)
            % Gets the indices of every this.UseEveryth scan within
            % this.TemperatureRange.
            
            % May not want to use all temperatures.
            idx = find(...
                this.Temperatures >= this.TemperatureRange(1) &...
                this.Temperatures <= this.TemperatureRange(2));
            
            %Clamp to within ScanRange
            idx =find(idx >= this.ScanRange(1) & idx <= this.ScanRange(2));
            
            % May not want to use every scan.
            idx = idx(1:this.UseEvery:end);
            
        end
        
                
        function idx = getSelectedZRangeIdx(this)
            % Gets the indices of the z-indices with this.ZRange.
            
            % Get only required z-points.
            idx = find(...
                this.ScanData(:,1,1) >= this.ZRange(1) &...
                this.ScanData(:,1,1) <= this.ZRange(2));
        end
        
        function scans = findScansNearTemperature(this, temperatures)
            % Returns the nearest actual scans to the query temperatures.
            
            for i=1:length(temperatures)
                [~, idx] = min(abs(this.Temperatures - temperatures(i)));
                scans(:,:,i) = this.ScanData(:,:,idx);
            end
        end
        
        function scans = interpolateScansAtTemperature(this, temperatures, zPoints, varargin)
            % Constructs a scatteredInterpolant, and uses that to estimate
            % scans at the query temperatures.
            %
            % Use varargin to pass any additional args to
            % scans2interpolant and therefore scatteredInterpolant.
            
            % Make scatteredInterpolant.
            si = squidlab.utils.scans2interpolant(this.ScanData,...
                this.Temperatures, varargin{:});
            
            examplePositions = zPoints;
            
            % Evaluate it.
            for i=1:length(temperatures)
                scans(:,1,i) = examplePositions;
                scans(:,2,i) = si(examplePositions,...
                    ones(size(examplePositions))*temperatures(i));
            end
        end
        
        function set(this, varargin)
            % Pushes properties provided as name-value pairs onto this
            % object.
            
            % Set multiple props without exposing private ones.
            for i=1:2:length(varargin)
                if isprop(this, varargin{i})  % Nice try getting at my privates
                    this.(varargin{i}) = varargin{i+1};
                else
                    error("Unrecognised public property %s.\n",...
                        varargin{i});
                end
            end
        end
        
    end
    
end