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

classdef UILogger < squidlab.utils.Logger
    % UILogger  Logger intended to be embedded in uifigure.
    %
    % Example:
    %   u = uifigure();
    %   pos = [0 0 300 300];
    %   logger = UILogger(u, pos);
    %   logger.logInfo("Some message");
    %   logger.setBusy("starting");
    %   logger.setFinished("done");
    
    properties(Dependent)
        % Tag (string)
        % Tag of the underlying panel
        Tag
    end
    
    properties(Access = private)
        %UIFigureHandle (uifigure)
        %Handle to the root UIFigure that will e.g. throw warnings - so
        %alert dialogue boxes can be shown attached to this figure.
        UIFigureHandle

        % Panel (iipanel)
        % Handle to the main panel holding the controls
        Panel
        
        % MainLayout (uigridlayout)
        % Handle to the main uigridlayout
        MainLayout
        
        % StatusLabel (uilabel)
        % Label holding string showing "Ready" etc.
        StatusLabel
        
        % Lamp (uilamp)
        % Lamp showing current status
        Lamp
        
        %InfoArea (ui control)
        % Control holding logged information
        InfoArea
        
        %%% Performance optimizations
        
        % MessageBuffer (string column vector)
        % Vector of strings to store and render.
        MessageBuffer = string.empty();
        
        % MaxMessages (scalar int)
        % Maximum number of messages to display. If more messages are stored
        % in the buffer, the first messages will be lost.
        MaxMessages = 20;
        
        % LastRedrawerTimer (scalar double)
        % tic() of the last time a drawnow() was called to render.
        LastRedrawTimer
        
        % RedrawEvery (scalar double)
        % Time in seconds between every drawnow call. If less time than this
        % has elapsed, the logger won't redraw.
        RedrawEvery = 0.2;
    end
    
    methods
        function this = UILogger(uiFigHandle, parent, position)

            this.UIFigureHandle = uiFigHandle;

            this.Panel = uipanel('Parent', parent, 'Units', 'pixels', ...
                'Position', position, 'Tag', "uilogger");
            
            this.MainLayout = uigridlayout(this.Panel, 'RowHeight', {'1x'}, ...
                'ColumnWidth', {'0.07x', '0.05x', '0.88x'}, ...
                'Padding', [2 2 2 2]);
            
            this.StatusLabel = uilabel(this.MainLayout, 'Text', 'Ready', ...
                'FontSize', iFontSize());
            this.Lamp = uilamp(this.MainLayout, 'Color', iGreen());
            this.InfoArea = uitextarea(this.MainLayout, 'Value', '', ...
                'FontSize', iFontSize(), ...
                'Editable', true);
        end
        
        function setBusy(this, msg)
            this.StatusLabel.Text = "Busy...";
            this.Lamp.Color = iAmber();
            
            this.recordMsg("Starting "+ msg + "...");
        end

        function setFinished(this, msg)
            this.StatusLabel.Text = "Ready";
            this.Lamp.Color = iGreen();
            
            this.recordMsg(msg + " done.");
            this.ensureUpdated();
        end
        
        function logInfo(this, msg, ~)
           this.recordMsg("Info: " + msg + "...");
        end

        function logWarning(this, msg, ~)
            this.recordMsg("Warning: " + msg);
            this.ensureUpdated();
        end
        
        function logError(this, msg)
            this.StatusLabel.Text = "Error!";
            this.Lamp.Color = iRed();
            this.recordMsg(msg);
        end

        function showWarning(this, msg, title)
            warningText = sprintf(msg);
            uialert(this.UIFigureHandle, warningText, title, "Icon", "warning");
        end
        
        function throwError(this, msg, id)
            this.StatusLabel.Text = "Error!";
            this.Lamp.Color = iRed();
            this.recordMsg(msg);
            
            this.ensureUpdated();
            error(id, msg);
        end
    end
    
    % Setters and getters
    methods
        function set.Tag(this, value)
            this.Panel.Tag = value;
        end
        
        function value = get.Tag(this)
           value = this.Panel.Tag; 
        end
    end
    
    methods(Access = private)
        function recordMsg(this, str)
            % Record a message of some sort.
            %
            % For performance reasons, we don't store every message logged,
            % or update on every message log. We maintain a buffer of the
            % last this.MaxMessages, and only update if more seconds than
            % this.RedrawEvery have passed.
            
            % Set up timer if it doesn't exist yet.
            if isempty(this.LastRedrawTimer)
               this.LastRedrawTimer = tic(); 
            end
            
            % Maintain a maximum message buffer size of this.MaxMessages
            if size(this.MessageBuffer) < this.MaxMessages
                this.MessageBuffer(end+1, 1) = string(str);
            else
                % Put early messages in the bin.
                this.MessageBuffer = [this.MessageBuffer(2:end); string(str)];
            end
            
            % Draw last text at the top.
            this.InfoArea.Value = flipud(this.MessageBuffer);
            
            % drawnow() can incur a big performance hit if it's called
            % inside a tight update loop, so only do it every
            % this.RedrawEvery seconds.
            if toc(this.LastRedrawTimer) > this.RedrawEvery
                drawnow();
                this.LastRedrawTimer = tic();
            end
        end
        
        function ensureUpdated(this)
            % Force a drawnow(). Use this sparingly for important messages.
            drawnow();
            this.LastRedrawTimer = tic();
        end
    end
end

function s = iFontSize()
s = 11;
end

function c = iAmber()
c = [1 1 0];
end

function c = iGreen()
c = [0 1 0];
end

function c = iRed()
c = [1 0 0];
end