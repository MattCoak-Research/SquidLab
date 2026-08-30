classdef ErrorHandler
    %Static class to expose methods for Verifying correct matlab
    %installation, toolboxes etc
    
    properties (Constant)       
       DebugMode = false;   %Set to true to rethrow all handled errors and hence have a stack trace to follow in the command window - for debugging/testing purposes 
    end
    
    methods (Static)
        
        %Throw an error if the installed Matlab version is lower than the
        %specified maj.min. eg 9,5 would be version 9.5 (2018b)
        function VerifyMatlabVersion(maj, min)
            if verLessThan('matlab',[num2str(maj) '.' num2str(min)])
                ver = version;
                error(['Unsupported Matlab version, please upgrade to at least version ' num2str(maj) '.' num2str(min) '. This is version ' ver]);
            end
        end
        
        function VerifyToolboxInstalled(toolboxName)
            %% Find the toolbox and give proper output
            v_= ver;
            [installedToolboxes{1:length(v_)}] = deal(v_.Name);
            result = all(ismember(toolboxName,installedToolboxes));
            assert(result,['Error! ' toolboxName ' is not installed!']);
        end
        
        function ErrorMessageBoxHandler(message, err)
            %For now, simply pass through the error message into a dialog
            %box
            warndlg([message, ' : ', err.message]);       
            
            if(ui.ErrorHandler.DebugMode)
               rethrow(err); 
            end
        end
    end
end

