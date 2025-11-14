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

classdef ScanPlotter < handle
    % SCANPLOTTER  Used to plot the data in ScanSets.
    %
    % A ScanPlotter provides a number of properties and methods for
    % conveniently visualising SQUID scans.
    %
    % Examples:
    %   scans = scanset.ScanData;
    %
    %   sp = ScanPlotter();
    %
    %   % Plot with defaults. 
    %   sp.plotScans(scans);
    %
    %   % Change plot settings and replot.
    %   sp.Colormap = "jet";
    %   sp.LineWidth = 6;
    %   sp.ShowLegend = false;
    %   sp.plotScans();

    properties(Access = public)
        % Colormap (char vector or 1x2 cell array of colorspecs)
        % Sets how lines are colored in the plot.
        % Either:
        %   - a char vector MATLAB can use to produce a colormap -
        %     e.g. 'lines', 'jet', or 'autumn'. This colormap will be used
        %     to color the lines.
        %   - a cell array of 2 MATLAB colorspecs, like {'r', [1 0 0]} or
        %     {'b', 'r'}. This pair will be used to produce a linear
        %     interpolation between the first and second color, which will
        %     be used to color the lines.
        Colormap = {'b', 'r'};
        
        % NewFigure (bool)
        % If true, all new plots will be in new figures. Otherwise, the
        % current figure will be reused.
        NewFigure = true;
        
        % DataMarkerType ( '-', '-.', etc.)
        % Marker type used for data lines.
        DataMarkerType = '-';
        
        % LineWidth (scalar double)
        % Sets width of lines in the graph
        LineWidth = 2;
        
        % DefaultFigureArgs (cell array of name-value pairs)
        % Additional options passed to figure() for every plot.
        DefaultFigureArgs = {'Position', [200 200 1000 800], 'Color', 'white'};
        
        % ShowLegend (bool)
        % If true, the plot will show a legend.
        ShowLegend = true;
        
        % MaxLegendEntries (scalar int)
        % Sets the maximum number of entries that can be shown in the
        % legend. If you have 200 scans, and try to show all of them in the
        % legend, this will obviously look stupid. If there are more lines
        % to label than this, only a subset of the lines will be labelled.
        MaxLegendEntries = 5;
        
        %Can get copied over from the overall UI to inform optional
        %plotting options
        Meta;
        
        % FontSize (scalar double)
        % Size of font in the graph. No, this can't be provided in
        % DefaultFigureArgs.
        FontSize = 18;
                
        % AxesLabels (1x2 cellstr)
        % Values used to label x and y axes.
        AxesLabels = {'Position (mm)', 'Signal (a.u.)'};

        MarkerTypeToUse = "DataMarkerType"

        FitMarkerType = '-';
        
        Axes;
    end
    
    properties(Access = protected)
        Legend        
    end
    
    methods(Access = public)
        
        function lineHandles = plotScans(this, scans, temperatures, clearAxes)
            % Plots a set of scans.
            % Pass scans as an NumDataPointsPerScan x 2 x NumScans array,
            % and temperatures as a NumScans x 1 array.
            %
            % Provide the optional bool clearAxes to set whether cla() is
            % called to erase anything in the axes before plotting (default
            % is true).
            
            if nargin < 4
                clearAxes = true;
            end
            
            numScans = length(temperatures);
            
            % Set up figure with our settings and get an axes. Clear it if
            % we have to.
            ax = this.provideAxes();
            if clearAxes
                cla(ax);
            end
            
            colors = this.computeColors(length(temperatures));
            
            % Perform plotting.
            hold(ax, 'on');
            lineHandles = [];
            for i=1:numScans
                lineHandles(i) = plot(ax, scans(:,1,i), scans(:,2,i),...
                    this.(this.MarkerTypeToUse), 'LineWidth', this.LineWidth,...
                    'Color', colors(i,:), 'MarkerFaceColor', 'none');
            end
            
            if this.ShowLegend
                this.setUpLegend(ax, lineHandles, temperatures);
            end
            
            % Do this last so it works.
            ax.FontSize = this.FontSize;
        end
        
        function lineHandle = plotXY(this, x, y, titleString, labels)
            
            % Set up figure with our settings and get an axes. Clear it if
            % we have to.
            ax = this.provideAxes();
            cla(ax);
            
            color = this.Colormap{1};
            
            lineHandle = plot(ax, x, y, this.(this.MarkerTypeToUse),...
                'LineWidth', this.LineWidth,...
                'Color', color, 'MarkerFaceColor', color);
            
            title(ax, titleString, 'Interpreter', 'none');
            xlabel(ax, labels(1));
            ylabel(ax, labels(2));
            
            % Do this last so it works.
            ax.FontSize = this.FontSize;
        end
        
        function str = getResultsXLabelString(this, meta)
            if(isfield(meta, 'XVar'))
                switch(meta.XVar)
                    case('T')
                        str = "Temperature (K)";
                    case('H')
                        str = "Magnetic Field (Oe)";
                    otherwise
                        error ('unsupported');
                end
                return;
            end
            
            %Carry on as before, assuming MvT, if no meta found
            str = "Temperature (K)";
        end
        
    end
    
    methods(Access = protected)
        
        function ax = provideAxes(this)
            % Sets up a figure and axes correctly.
            
            if this.NewFigure
                figure(this.DefaultFigureArgs{:});
                ax = gca();
            elseif ~isempty(this.Axes)
                ax = this.Axes;
            else
                f = gcf();
                if isempty(f)
                    f = figure;
                end
                set(f, this.DefaultFigureArgs{:});
                ax = gca();
            end
            
            % Focus the axes if we can. IF we can't, it's probably because
            % we're using a UIAxes from App Designer, so we don't need to
            % focus them anyway.
            if isa(ax, 'matlab.graphics.axis.Axes')
                axes(ax);
                % Fails if ax is a uiaxes.
            end
            
            xlabel(ax, this.AxesLabels{1});
            ylabel(ax, this.AxesLabels{2});
            ax.Box = 'on';
        end
        
        function colors = computeColors(this, numScans)
            % Computes the colors to use in the plot based on the number of
            % scans and the Colormap.
            
            switch class(this.Colormap)
                case {'char', 'string'}
                    colors = this.computeColorsWithFunction(numScans);
                case 'cell'
                    colors = this.computeColorsWithInterpolation(numScans);
            end
        end
        
        function colors = computeColorsWithFunction(this, numScans)
            % Returns color computed for the case when Colormap is a
            % string (hopefully e.g. "lines" or "jet") which can be used to
            % compute colors.            
            
            % Hopefully Colormap is a function MATLAB can produce
            % colors with.
            
            % Not condoning this.
            func = str2func(this.Colormap);
            
            % Actually get colors, or more likely error out because
            % this approach is effective but fragile.
            try
                colors = func(numScans);
            catch err
                error("Couldn't make a valid colormap with '%s'. Failed with error: %s",...
                    this.Colormap, err.message);
            end
            
            % Make sure we got something sane after str2func to avoid
            % propagating problems everywhere.
            validateattributes(colors,...
                {'numeric'}, {'2d', 'nonnegative', '<=', 1});
            assert(size(colors, 1) == numScans && size(colors, 2) == 3,...
                "Colormap '%s' wasn't a valid function for producing colors.",...
                this.Colormap);
            
        end
        
        function colors = computeColorsWithInterpolation(this, numScans)
            % Returns color computed for the case when Colormap is a cell
            % array of 2 colorspecs, in which case do linear interpolation
            % between the 2 colors.
            
            fractions = linspace(0, 1, numScans)';
            
            % Use singleton expansion to get array of the right size.
            colors = this.ensureColor(this.Colormap{1}) .* (1-fractions)...
                + this.ensureColor(this.Colormap{2}) .* fractions;
        end

        
        function setUpLegend(this, ax, lineHandles, temperatures)
            % Set up a legend in the axes. If there are too many lines to
            % sensibly show, include only a subset.
            
            numLines = length(lineHandles);
            
            % Don't show too many entries.
            if numLines > this.MaxLegendEntries
                pickOutEvery = ceil(numLines / this.MaxLegendEntries);
                lineHandles = lineHandles(1:pickOutEvery:end);
                temperatures = temperatures(1:pickOutEvery:end);
            end
            
            delete(this.Legend);
            % Create legend with formatted labels. We don't want it to
            % auto-update, otherwise if fits are also plotted in this axes,
            % they'll be added on.
            this.Legend = legend(ax, lineHandles,...
                compose(this.getLegendFormatString(this.Meta), temperatures),...
                'Box', 'off',...
                'Location', 'best',...
                'AutoUpdate', 'off');
        end
        
        function str = getLegendFormatString(this, meta)
            if(isfield(meta, 'XVar'))
                switch(meta.XVar)
                    case('T')
                        str = "%.1f K";
                    case('H')
                        str = "%.0f Oe";
                    otherwise
                        error ('unsupported');
                end
                return;
            end
            
            %Carry on as before, assuming MvT, if no meta found
            str = "%.1f K";
        end
        
        
        
        function color = ensureColor(~, color)
            % Ensures that the argument color is either an RGB triple or a
            % valid MATLAB colorspec.
            
            if ischar(color)
                % From StackOverflow.
                color = bitget(find('krgybmcw' == color)-1,1:3);
            else
                % Make sure it actually is a color we're going to return.
                assert(isequal(size(color), [1 3]),...
                    "Provide color gradients as a cell array of RGB triples or MATLAB colorspec chars");
            end
        end

    end
    
end