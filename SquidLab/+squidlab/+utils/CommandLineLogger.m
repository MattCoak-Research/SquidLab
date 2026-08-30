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

classdef CommandLineLogger < squidlab.utils.Logger
    % CommandLineLogger  Logs info to the command line
    
    methods
        function setBusy(~, msg)
            fprintf("Starting %s...\n", msg);
        end
        
        function setFinished(~, msg)
            fprintf("%s done.\n", msg);
        end
        
        function logInfo(~, msg)
            fprintf("%s\n", msg);
        end
        
        function logWarning(~, msg, id)
            if nargin < 3
               id = "squidlab:warning:Generic"; 
            end
            
            warning(id, msg);
        end
        
        function logError(~, msg, id)
            if nargin < 3
                id = "squidlab:error:Generic";
            end
            
            fprintf("Error (%s): %s\n", id, msg);
        end
        
        function throwError(~, msg, id)
            if nargin < 3
                id = "squidlab:error:Generic";
            end
            
            error(id, msg);
        end

        function showWarning(~, msg, title)
            warningText = sprintf(msg);
            warndlg(warningText, title);
        end
    end
end