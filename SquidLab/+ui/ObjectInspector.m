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

classdef ObjectInspector < handle
    %Inspect and edit values of an object
    properties
        Object
        Container
        
        Margin = [2 1];
        WidgetHeight = 20;
        LabelFraction = 0.6;
        ExposeSubclassProperties logical = false;
    end
    
    properties(Access = protected)
       PropertyList
       Widgets
       TooltipButton
    end
    
    methods
        function this = ObjectInspector(object, container)

            % Warn if the container already has children, as they'll get
            % deleted when this is.
            if ~isempty(container.Children)
               warning("Target container already has children." + ... 
               " These will be lost when this object is deleted." + ...
               " You should create an ObjectInspector using an empty container.");
            end
            
            this.Object = object;
            this.Container = container;
            this.PropertyList = this.computePropertyList();
            
            this.createWidgets();
        end
        
        function setProperties(this)
            for i=1:length(this.PropertyList)
               thisProp = this.PropertyList(i);
               value = this.Widgets.(thisProp).Edit.Value;
               
               if ischar(value) || isstring(value)
                  value = ui.fromString(value);
               end
               this.Object.(thisProp) = value;
            end
        end
        
        function delete(this)
            % We need to override delete so that this correctly cleans up
            % its widgets when it's deleted.
            
            if isvalid(this.Container)
                delete(this.Container.Children);
            end
        end
    end
    
    methods(Access = protected)
        function propertyList = computePropertyList(this)
            % Returns a string array of the properties to show.
           
            objectClass = string(class(this.Object));
            
            % If we're exposing subclass properties this is trivial.
            if this.ExposeSubclassProperties
                propertyList = properties(this.Object);
            else
                % If we only want to expose properties defined in this
                % class, and not its subclasses, it's more complicated. We
                % can use the metaclass, but be wary of exposing private or
                % hidden properties.
                propertyList = string.empty(0);
                metaClass = metaclass(this.Object);
                
                for i=1:length(metaClass.PropertyList)
                    thisProp = metaClass.PropertyList(i);
                    
                    % Add to the list only non-hidden publicly settable
                    % properties defined in this class.
                    if( thisProp.SetAccess == "public" && ...
                        thisProp.DefiningClass.Name == objectClass && ...
                        ~thisProp.Hidden)
                    
                        propertyList(end+1, 1) = thisProp.Name;
                    end
                end
            end
            
        end
        
        function createWidgets(this)
            
            % Cache units of the container so we can revert them later.
            unitsCache = this.Container.Units;
            
            this.Container.Units = 'pixels';
            
            containerHeight = this.Container.Position(4);
            
            labelX = this.Margin(1);
            labelWidth = this.Container.Position(3) * this.LabelFraction - 2 * this.Margin(1);
            editX = labelWidth + 2 * this.Margin(1);
            editWidth = this.Container.Position(3) * (1-this.LabelFraction) - 2 * this.Margin(1);
            
            % In R2017b we can't set tooltips on uifigure controls, so we
            % have to show help in a dialog. Trap the comment for each
            % property as it comes by, so we can use it later.
            tooltipStrings = string.empty();
            
            % Note that, rather dangerously, the scope of i is not only
            % this loop. We're going to use it again outside the loop.
            for i=1:length(this.PropertyList)
                propertyName = this.PropertyList(i);
                propertyValue = this.Object.(propertyName);

                %No 'help' function in deployed code, handle this and
                %branch the code here
                if isdeployed
                    %This could be improved..
                    tooltipStrings(end+1,1) = strtrim((string(class(this.Object)) +  "." + propertyName));
                else
                    %#exclude help
                    tooltipStrings(end+1,1) = strtrim(string(help(string(...
                        class(this.Object)) +  "." + propertyName)));
                end
                
                y = containerHeight - i * (this.WidgetHeight + 2*this.Margin(2)) + this.Margin(2);
                pos = [labelX + this.Margin(1) y labelWidth this.WidgetHeight];
                
                % Label widget
                labelWidget = uilabel(this.Container, ...
                    'Position', pos,...
                    'Text', this.PropertyList(i));
                
                % Post-R2017b, we can add tooltips to uicontrols
                if isprop(labelWidget, "Tooltip")
                    labelWidget.Tooltip = tooltipStrings(end);
                end
                this.Widgets.(propertyName).Label = labelWidget;
                
                % We want to create the right type of widget to render a given
                % property.
                %
                % In R2017b we can't use meta.property's meta.Validation, which
                % is a shame as this would do exactly what we want. Instead we
                % have to use the variable's class.
                this.Widgets.(propertyName).Edit = ...
                    iCreateWidgetByPropertyType(propertyValue, ...
                    this.Container, ...
                    [editX + this.Margin(1) y editWidth this.WidgetHeight], ...
                    tooltipStrings(end));
            end
            
            % Create the button for showing help.
            i = i+1;
            y = containerHeight - i * (this.WidgetHeight + 2*this.Margin(2)) + this.Margin(2);
            pos = [labelX + this.Margin(1)...
                y this.Container.Position(3) - 2.* this.Margin(1) ...
                this.WidgetHeight];
            fullTooltip = tooltipStrings.join(sprintf("\n\n"));

            this.TooltipButton = uibutton(this.Container, 'Position', pos, ...
                'Text', 'Show help',...
                'ButtonPushedFcn', @(~,~)msgbox(char(fullTooltip), class(this.Object)));
            
            % Revert container units.
            this.Container.Units = unitsCache;
        end
        
    end
end

function widget = iCreateWidgetByPropertyType(value, parent, position, tooltipString)
% Choose a type of widget to use based on the class of the object's
% property value.

if isnumeric(value) && isscalar(value)
    widget = uieditfield(parent, 'numeric', 'Position', position, 'Value', value, 'HorizontalAlignment', 'center');
elseif islogical(value)
    widget = uicheckbox(parent, 'Position', position, 'Value', value, 'Text', '');
elseif class(value) == "function_handle"
    value = func2str(value);
    widget = uieditfield(parent, 'Position', position, 'Value', string(value), 'HorizontalAlignment', 'center');
else
    widget = uieditfield(parent, 'Position', position, 'Value', iScalarString(value), 'HorizontalAlignment', 'center');
end

% Post-R2017b, we can add tooltips to uicontrols
if isprop(widget, "Tooltip")
    widget.Tooltip = tooltipString;
end

end

function str = iScalarString(value)
% Returns a scalar string from something which might be a char array, or a
% numeric multi-element vector.
str = string(value);

if ~ismatrix(value)
   error("Value isn't a scalar or vector so it's a high-dimensional array," + ...
    " that's probably bad news.") ;
end

if ~isscalar(str)
    str = join(str, " ");
end
end

