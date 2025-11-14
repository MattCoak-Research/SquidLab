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

classdef SVDFitScanSet < squidlab.scanset.FitScanSet
    % SVDFITSCANSET Fits scan dipoles using singular value decomposition.
    %
    % Use this class to fit the V(z) scans using a multipole expansion. The
    % coefficient of each multipole term will be found using singular value
    % decomposition.
    %
    % This fit uses an exact linear least squares method, so it doesn't
    % rely on guessing start points. It computes the projection of the data
    % onto the multipole basis. However, it assumes that:
    % - The finite number of multipole basis vectors are sufficient to
    %   describe the data. For very irregular signals, this will not hold.
    % - There's no constant offset of the signal (i.e. the multipole basis
    %   is sufficient to describe the data without a constant term). This
    %   assumption is seldom true in practice.
    % - The sample is centred at the midpoint of the z-values. The sample
    %   position is NOT allowed to vary as a free parameter. If the sample
    %   is not very well-centred, this method can give quite poor results.
    %
    % Example:
    %   svdFit = LevenbergMarquadtFitScanSet(dataScanSet);
    %   svdFit.fit();
    %
    %   % Plot fit and data, only show every 20th scan.
    %   svdFit.UseEvery = 20;
    %   svdFit.plot();
    
    properties
          % CalibrationFactor (scalar double) 
        % Overall factor that scales the resulting moment. Exact value can
        % be found by measuring a palladium reference sample. Values given
        % in manual. For MPMS3 we have found it to be -5.966e-7, but will
        % be slightly different across instruments. For MPMS, this looks to
        % just be the Correction Factor, and a * 1000 units change, so
        % 1.096e-3 - note it is positive in this case. NOTE - seems to give
        % wrong values for MPMS, need to test
        %CalibrationFactor = -5.966e-7;
        CalibrationFactor = 1.096e-3;
        
        % CoilRadius (scalar double)
        % Radius of the SQUID coils, in the same units as your z-data.
        
        %CoilRadius = 8.5
        CoilRadius = 9.7
        
        % CoilSeparation (scalar double)
        % Separation between the counterwound SQUID coils, in the same
        % units as your z-data.
        %CoilSeparation = 8.0
        CoilSeparation = 15.9
        
        % MultipoleOrder (scalar int)
        % Number of multipoles to include in the basis set. Significantly
        % more than 4 will typically cause issues because the higher-order
        % terms will become quite noisy (they're small compared to the
        % dipole).
        MultipoleOrder = 4;
    end
    
    properties(Dependent, SetAccess = protected)
        % SignalSize ([NumScans x 1] double)
        % Returns the fitted signal size as a function of temperature.
        SignalSize
    end
    
    methods
        function this = SVDFitScanSet(scanSet)
            
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
            % Performs a fit to the data using multipole basis functions
            % and singular value decomposition.   
            
            set(this, varargin{:});
            
            data = this.SelectedScans;
            fitter = squidlab.fit.EnhancedSVDFit();
            
            % We need to provide a sensible estimate of the dipole size
            % (the c(3) fit parameter), but this is a function of the SQUID
            % coils. The dipole V(z) is ~c(3) * (R^2 + Lambda^2)^(-3/2),
            % where R is the coil radius and Lambda the coil separation. We
            % can estimate what c(3) should be by measuring the span of
            % V(z), from max to min, and multiplying by a factor (R^2 +
            % Lambda^2)^(3/2).
            dipoleRescaleFactor = (this.CoilRadius.^2 + this.CoilSeparation.^2).^(-3/2);
            
            % We need to provide the midpoint so we compute the correct
            % basis functions.
            %
            % Assume the dipole basis functions (i.e. expected V(z)) are
            % always evaluated at the same z. This means we don't need to
            % compute the basis functions inside the for loop, but can just
            % do it once.
            %
            % This will break if each scan has a different set of z-points.
            z = this.ScanData(:,1,1);
            zMidpoint = mean(z);
            
            basis = squidlab.fit.DipoleBasisSet(this.CoilRadius,...
                this.CoilSeparation, zMidpoint, dipoleRescaleFactor);
            
            % Optimization: assuming each scan has the same z-points, we
            % only need to calculate the basis vectors once, rather than
            % for each scan.
            basisVectors = ...
                basis.getBasisVectors(z, this.MultipoleOrder);
            
            % We get the basis vectors for the full range of the z-data,
            % and then do the restriction afterwards. This is because the
            % final value of each basis vector is dubious due to how
            % DipoleBasisSet calculates the higher-order terms with
            % diff().
            basisVectors = basisVectors(this.getSelectedZRangeIdx(), :);
            
            % Pre-alloc arrays.
            % Note that we also return the offset of the fit, which means
            % we have one more parameter than we have multipoles.
            this.FitParameters = nan(size(data, 3), this.MultipoleOrder + 1);
            this.FittedScanData = data;
            
            % Perform fit.
            for i=1:size(data, 3)
                scan = data(:,:,i);
                [this.FitParameters(i,:), this.FittedScanData(:,2,i)]...
                    = fitter.fit(scan, basisVectors);
            end
            
        end
    end
    
    % Getters and setters
    methods
        function value = get.SignalSize(this)
            % For us, SignalSize is the first FitParameter (the coefficient
            % of the first-order multipole term).
            %No idea what the 1.69 and the 298 is - empirically seems to work? That'a the
            %factor to get my data to agree with LM fit.. but is it
            %different across MPMSs?
            value =  1.69.*298.* this.FitParameters(:, 1) .* this.CalibrationFactor;
        end
    end
    
end