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

function value = fromString(input)
% Given an input of string type, returns a value of the correct MATLAB
% type.


% str2num doesn't work on strings (?) so we have to cast to char.
% This will cause issues if input is a string array.
if ~ischar(input)
   input = char(input);
end

% If the first character is '@', we've got a function handle.
if input(1) == '@'
   value = str2func(input);
   return
end

% Try to convert to a number or logical.
%
% Works for: 
% "true" -> logical,
% "25" -> 25
% '[3 4]' -> [3 4]
value = str2num(input);

% If conversion failed, input was hopefully a string already, so just
% return it.
if isempty(value)
   value = input; 
end

end