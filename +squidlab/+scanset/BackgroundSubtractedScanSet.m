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

classdef BackgroundSubtractedScanSet < squidlab.scanset.ScanSet
    % BACKGROUNDSUBTRACTEDSCANSET  ScanSet for holding
    % background-subtracted scans.
    %
    % Use this to perform background subtraction - create it with ScanSets
    % holding your data and background, and it will hold the
    % background-subtracted result.
    %
    % Example:
    %   bss = BackgroundSubtractedScanSet(dataScanSet, backgroundScanSet, "interp");
    %   bss.plot()
    
   properties(SetAccess = protected)
       % DataScanSet (squidlab.scanset.ScanSet)
       % Stores the ScanSet containing the actual data.
       DataScanSet
       
       % BackgroundScanSet (squidlab.scanset.ScanSet)
       % Stores the ScanSet containing the background.
       BackgroundScanSet
       
       % InterpolationMode ("interp" | "nearest")
       % Sets how interpolation is done to get the background scans at the
       % same temperatures at the data scans.
       % See this.getScansAt().
       InterpolationMode
   end
   
   methods
       function this = BackgroundSubtractedScanSet(data, background, mode)
           % Create an instance.
           %
           % Pass mode as an valid argument to this.getScansAt, e.g.
           % "interp" or "nearest".

           assert(isa(data, 'squidlab.scanset.ScanSet'));
           assert(isa(background, 'squidlab.scanset.ScanSet'));

           % Delegate to parent ctor.
           this@squidlab.scanset.ScanSet(data.Temperatures,...
               data.Field,...
               data.ScanData);

           this.DataScanSet = data;
           this.BackgroundScanSet = background;
           this.InterpolationMode = mode;
           
           this.doBackgroundSubtraction();
       end
   end
   
   methods(Access = protected)
       function doBackgroundSubtraction(this)
           % Actually perform the background subtraction.
           
           zPoints = this.DataScanSet.ScanData(:, 1, 1);
           
           % Interpolate the background scans onto the data scans.
           backgroundScanData = this.BackgroundScanSet.getScansAt(...
               this.DataScanSet.Temperatures, zPoints, this.InterpolationMode);
           
           backsubData = this.DataScanSet.ScanData;
           backsubData(:,2,:) = backsubData(:,2,:) - backgroundScanData(:,2,:);
           
           this.ScanData = backsubData;
           this.Meta = this.DataScanSet.Meta;
       end
   end
    
end