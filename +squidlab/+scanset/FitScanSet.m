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

classdef(Abstract) FitScanSet < squidlab.scanset.ScanSet
    % FITSCANSETInterface for ScanSets used to fit models to the data.
    %
    % FitScanSets hold an existing ScanSet containing data, and also provide
    % methods to fit the data.
    %
    % This class is ABSTRACT, which means it can't be instantiated
    % directly. Instead, make a LevenbergMarquadtFitScanSet, an
    % SVDFitScanSet, etc.
    %
    % Example usage of implementations:
    %   % Create an instance.
    %   fss = MyFitScanSet(dataScanSet);
    %
    %   % Fit to the data, resistricting the Z-range to include.
    %   fss.ZRange = [-10 10];
    %   fss.fit();
    %   
    %   % Plots will include fit lines, if they exist.
    %   fss.plot();
    %
    %   % Plot the fitted parameter of interest as a function of
    %   temperatures.
    %   s.plotFitResults();
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % USERS MUST IMPLEMENT EVERYTHING MARKED ABSTRACT IN DERIVED CLASSES
    properties(Abstract, Dependent, SetAccess = protected)
        % SignalSize ([NumScans x 1] double)
        % Read-only property which returns the signal as a function of
        % temperature.
        SignalSize
    end
    
    methods(Abstract, Access = public)
        fit(this, varargin)
        % fit
        % Performs a fit to the data.
        % Most implementations will use this approach:
        % - Get data from this.SelectedScans.
        % - Create a squidlab.fit.Fit object, pass any required params to 
        %   the Fit.
        % - For each scan, perform the fit, storing the best fit parameters
        %   in this.FitParameters, and the predicted V(z) for those
        %   parameters in this.FittedScanData.
        
        setMetaData(this, meta)
        %setMetaData
        %pre-set parameters like coil radius, potentially overiding
        %defaults
    end
    
    % BELOW IS PROTECTED - USERS MAY OVERRIDE IF NEEDED IN DERIVED CLASSES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties(SetAccess = protected)
        % UnderlyingScanSet (squidlab.scanset.ScanSet)
        % Stores the ScanSet this FitScanSet takes its data from.
       UnderlyingScanSet 
    end
    
    properties(SetAccess = protected)
        % FittedScanData ([NumPointsPerScan x 2 x NumScans] double)
        % Array of predicted scans, calculated using the best fit
        % parameters.
        FittedScanData
        
        % FitParameters ([NumScans x NumParams] double)
        % Array of best fit parameters.
        % Each row corresponds to parameters for a single fitted scan.
        % Each column corresponds to a single parameter as a function of
        % temperature. The number of parameters, and the meaning of each
        % parameter, will depend on the model being fitted.
        FitParameters
    end
    
    methods
        function this = FitScanSet(scanSet)

            assert(isa(scanSet, 'squidlab.scanset.ScanSet'));
            
            % Delegate to parent ctor.
            this@squidlab.scanset.ScanSet(scanSet.Temperatures,...
                scanSet.Field,...
                scanSet.ScanData);
            
            this.UnderlyingScanSet = scanSet;
            this.Meta = scanSet.Meta;
        end
        
        function lineHandles = plot(this)
            % Plots the scans and, if present, the fits to them.
            % 
            % Example:
            %   % Create a FittedScanSet.
            %   fss = MyFittedScanSet(dataScanSet);
            %   
            %   % Plot the data (no results yet).
            %   fss.plot();
            %
            %   % Perform the fitting, plot again.
            %   fss.fit();            
            %   fss.plot();

            this.Plotter.DataMarkerType = 'o';
            lines = this.Plotter.plotScans(this.SelectedScans,...
                this.SelectedTemperatures);

            % Plot fits, if any.
            if ~isempty(this.FittedScanData)
                lines = this.plotFitLines(lines);
            end

            % Avoid annoying printing of the whole lines array to the
            % command line if caller didn't ask for it.
            if nargout > 0
               lineHandles = lines;
            end
        end
        
        function lineHandles = plotFitResults(this)
            % Plots the fitted signal size as a function of temperature.
            
            assert(~isempty(this.SignalSize),...
                "There aren't any fit results to plot yet - have you called this.fit()?");
            
            xlab = this.Plotter.getResultsXLabelString(this.Plotter.Meta);
            lines = this.Plotter.plotXY(this.Temperatures,...
                this.SignalSize, 'Fitted Signal',...
                {xlab, 'Moment (emu)'});
            
            % Avoid annoying printing of the whole lines array to the
            % command line if caller didn't ask for it.
            if nargout > 0
                lineHandles = lines;
            end
        end
    end
    
    methods(Access = protected)
        function lines = plotFitLines(this, lines)
            % Plots the best fits to the data, re-using the existing axes
            % so the data is also kept.
            
            % Store old values we're going to change on the Plotter so user
            % doesn't see the changes.
            %
            % This may break if using the debugger, as Plotter is a handle
            % so iRestorePlotterProperties may not happen. This can be
            % extremely confusing.
            propsToCache = ...
                ["NewFigure", "ShowLegend", "LineWidth", "Colormap"];
            valueCache = iCachePlotterProperties(this.Plotter, propsToCache);
            
            % Change Plotter values to plot the fit lines.
            this.Plotter.NewFigure = false;
            this.Plotter.ShowLegend = false;
            this.Plotter.MarkerTypeToUse = "FitMarkerType";
            this.Plotter.LineWidth = 2;
            this.Plotter.Colormap = {'k', 'k'};
            
            % Plot with the fitted data. Pass third arg to plotScans so we
            % don't clear the existing data in the axes.
            fitScans = this.FittedScanData(:,:,this.getSelectedRangeIdx());
            fitLines = this.Plotter.plotScans(fitScans,...
                this.SelectedTemperatures, false);
            lines = [lines, fitLines];
            
            % Restore old values.
            this.Plotter.MarkerTypeToUse = "DataMarkerType";
            iRestorePlotterProperties(this.Plotter, valueCache);
        end
        
        function value = getFitParameter(idx)
           value = this.FitParameters(:, idx); 
        end
    end
    
end

function valueCache = iCachePlotterProperties(plotter, propsToCache)
% Caches the values of any properties of plotter named in propsToCache in a
% struct.

for i=1:length(propsToCache)
    valueCache.(propsToCache(i)) = plotter.(propsToCache(i));
end
end

function iRestorePlotterProperties(plotter, valueCache)
% Sets all the properties on plotter given by the fields of the struct
% valueCache to their corresponding value.

propsToCache = string(fields(valueCache));

for i=1:length(propsToCache)
    plotter.(propsToCache(i)) = valueCache.(propsToCache(i));
end
end