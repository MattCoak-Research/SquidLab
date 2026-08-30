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

classdef LevenbergMarquadtFitScanSet < squidlab.scanset.FitScanSet
    % LEVENBERGMARQUADTFITSCANSET Fits scan dipoles using Levenberg-Marquadt non-linear least squares.
    %
    % Use this class to directly fit the expected V(z), including a linear
    % drift, to the measured V(z), using nlinfit()'s non-linear least
    % squares fitting.
    %
    % This will tend to work well if the measured V(z) closely resembled
    % the theoretical one, in which case this routine should be quite fast
    % and reliable. If the measured V(z) doesn't look much like a dipole,
    % this approach is likely to work poorly, as the fit won't be able to
    % find a good match to the data.
    %
    % The model to fit is the function in this.ModelFunction. By default,
    % this will be the expected dipole signal for a counterwound SQUID
    % coil, with specified coil radius and coil separation, in the presence
    % of linear drift, allowing the sample centre position to vary.. In
    % that case, after fitting, this.FitParameters will contain 4
    % parameters for each scan:
    % - Constant offset
    % - Linear drift
    % - Size of the dipole (this is the one you care about).
    % - Z-position of the dipole.
    %
    % Example:
    %   lmFit = LevenbergMarquadtFitScanSet(dataScanSet);
    %   lmFit.fit();
    %   
    %   % Plot fit and data, only show every 20th scan.
    %   lmFit.UseEvery = 20;
    %   lmFit.plot();
    
    properties
        % CalibrationFactor (scalar double) 
        % Overall factor that scales the resulting moment. Exact value can
        % be found by measuring a palladium reference sample. Values given
        % in manual. For MPMS3 we have found it to be -5.966e-7, but will
        % be slightly different across instruments. For MPMS, this looks to
        % just be the Correction Factor, and a * 1000 units change, so
        % 1.096e-3 - note it is positive in this case.
        %CalibrationFactor = -5.966e-7;
        CalibrationFactor = 1.096e-3;
        
        % CoilRadius (scalar double)
        % Radius of the SQUID coils, in the same units as your z-data. 
        % For an MPMS3 this is typically 8.5 mm, for an older MPMS and MPMS
        % XL this is 9.7.
        %CoilRadius = 8.5
        CoilRadius = 9.7
        
        % CoilSeparation (scalar double)
        % Separation between the counterwound SQUID coils, in the same
        % units as your z-data. For an MPMS3 this is typically 8.0 mm, for an
        % older generation MPMS 15.9 mm
        %CoilSeparation = 8.0
        CoilSeparation = 15.9
        
        % StartAtLastFit (bool)
        % If this is true, then each fit will use the parameters of the
        % previous fit as its start point, rather than trying to estimate
        % its own start point. If the initial fits are good, this can
        % significantly improve performance and give fewer warnings, but if
        % the fit ever gets trapped in a local minimum it will cause big
        % problems. It's recommended to set this to false.
        StartAtLastFit = false;
        
        % ModelFunction (function handle)
        % Handle to the function to fit. This should take 3 parameters:
        % - a vector of fixed parameters a, which is provided by the
        %   implementation of this.fit().
        % - a vector of fit parameters.
        % - a vector of z-points to evaluate the function at.
        ModelFunction = @(a,c,z)squidlab.fit.driftingDipoleEquation(a,c,z);
    end
    
    properties(Dependent, SetAccess = protected)
        % SignalSize ([NumScans x 1] double)
        % Returns the fitted signal size as a function of temperature.
        SignalSize
        
        % FixedParameters ([2 x 1] double)
        % Returns the fixed parameters for this SQUID coil set, i.e. the
        % coil radius and separation.
        FixedParameters
    end
    
    methods
        function this = LevenbergMarquadtFitScanSet(scanSet)
            
            % Delegate to parent ctor.
            this@squidlab.scanset.FitScanSet(scanSet);
        end
    end
    
    methods
        function setMetaData(this, meta)
            if(isfield(meta, 'CalibrationFactor'))
                this.CalibrationFactor = meta.CalibrationFactor;
            end
            if(isfield(meta, 'CoilRadius'))
                this.CoilRadius = meta.CoilRadius;
            end
            if(isfield(meta, 'CoilSeparation'))
                this.CoilSeparation = meta.CoilSeparation;
            end
        end
            
        function fit(this, varargin)
            % Performs a fit to the data using non-linear least squares as
            % implemented by nlinfit().
            
            set(this, varargin{:});
            
            data = this.SelectedScans;
            
            % Suppress warnings like "Some columns of the Jacobian are
            % effectively zero at the solution". Use an onCleanup to
            % ensure these get turned back on regardless of how this
            % function exists.
            warnStates = iSuppressWarnings();
            c = onCleanup(@()iRestoreWarningState(warnStates));
            
            fitter = squidlab.fit.LevenbergMarquadtFit();
            
            % We need to provide a sensible estimate of the dipole size
            % (the c(3) fit parameter), but this is a function of the SQUID
            % coils. The dipole V(z) is ~c(3) * (R^2 + Lambda^2)^(-3/2),
            % where R is the coil radius and Lambda the coil separation. We
            % can estimate what c(3) should be by measuring the span of
            % V(z), from max to min, and multiplying by a factor (R^2 +
            % Lambda^2)^(3/2).
            fitter.DipoleRescaleFactor = (this.CoilRadius.^2 + this.CoilSeparation.^2).^(3/2);
            
            % Set whether we re-use old start points or always try to
            % compute new start points (recommended).
            fitter.StartAtLastFit = this.StartAtLastFit;
            
            fitFunc = @(c,z)this.ModelFunction(this.FixedParameters,c,z);
            
            % Pre-alloc arrays.
            this.FitParameters = nan(size(data, 3), 4);
            this.FittedScanData = data;
            
            % Perform fit.
            for i=1:size(data, 3)
                scan = data(:,:,i);
                [this.FitParameters(i,:), this.FittedScanData(:,2,i)] ...
                    = fitter.fit(scan, fitFunc);
                
                this.FitParameters(i, 3) = this.FitParameters(i, 3) * this.CalibrationFactor;
            end
            
            %Temporary - assign fit parameters into the workspace for
            %inspection
            %For 'driftingDipoleEquation', these are the contents of this
            %array (each row corresponds to a temperature/field)
            % The vector c is a set of free parameters varied by the fit:
            % - c(1) is the constant offset
            % - c(2) is the coefficient of the linear drift
            % - c(3) is the overall size of the dipole.
            % - c(4) is the offset of the sample with respect to z = 0
            %
           % assignin('base', 'fitParams', this.FitParameters);
            %assignin('base', 'TempOrField', this.SelectedTemperatures);
        end
    end
    
    % Getters and setters
    methods
        function value = get.SignalSize(this)
            % For us, SignalSize is the third FitParameter.
            value = this.FitParameters(:, 3);
        end
        
        function value = get.FixedParameters(this)
           value = [this.CoilRadius, this.CoilSeparation];
        end
    end
    
end

function warnStates = iSuppressWarnings()
% Suppress warnings like "Some columns of the Jacobian are effectively zero
% at the solution" and "Warning: Rank deficient".

warnStates = [warning("off", "stats:nlinfit:ModelConstantWRTParam");
    warning("off", "MATLAB:rankDeficientMatrix")];

for i=1:length(warnStates)
    fprintf("Disabling warning: %s.\n", warnStates(i).identifier);
end
end

function iRestoreWarningState(warnStates)
% Turn back on any warnings which have been suppressed.

for i=1:length(warnStates)
    fprintf("Re-enabling warning: %s.\n", warnStates(i).identifier);
    warning("on", warnStates(i).identifier);
end
end