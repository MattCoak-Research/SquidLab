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

classdef DipoleBasisSet < squidlab.fit.BasisSet
    % DIPOLEBASISSET  Computes dipole and multipole basis vectors, for a
    % given SQUID coil geometry.
    
    properties(SetAccess = protected)
        % CoilRadius (scalar double)
        % Radius of the SQUID coils, in the same units as your z-data.
        CoilRadius = 8.5
        
        % CoilSeparation (scalar double)
        % Separation between the counterwound SQUID coils, in the same
        % units as your z-data.
        CoilSeparation = 8
        
        % SampleOffset (scalar double)
        % Position of the sample centre, in the same units as your z-data.
        SampleOffset = 0;
        
        % DipoleRescaleFactor (scalar double)
        % Factor to rescale the computed dipole and multipole terms by.
        DipoleRescaleFactor = 1;
        
        % DeltaZ (scalar double)
        % Increment between each z-value.
        DeltaZ = 1;
        
        % SmoothingWindow (scalar int)
        % Number of points used to:
        % - Smooth higher-order terms, to avoid introducing noise due to
        %   numeric differentiation.
        % - Extrapolate from the last few values of higher-order terms so
        %   we can ensure all terms contain the same number of points,
        %   despite doing numeric differentiation (which loses us points).
        SmoothingWindow = 5
    end
    
    methods
        function this = DipoleBasisSet(coilRadius, coilSeparation, sampleOffset, dipoleRescaleFactor)
            
            this.CoilRadius = coilRadius;
            this.CoilSeparation = coilSeparation;
            this.SampleOffset = sampleOffset;
            this.DipoleRescaleFactor = dipoleRescaleFactor;
        end
        
        function values = computeFirstTerm(this, z, ~)
            % Computes the first term, by directly computing the expected
            % V(z) for a sample in counterwound SQUID coils.
            
            fixedParameters = [this.CoilRadius, this.CoilSeparation];
            
            % Assume that the dipole has a fixed (known) size, and a fixed
            % offset.
            freeParameterFixes = [this.DipoleRescaleFactor, this.SampleOffset];
            
            this.DeltaZ = z(2) - z(1);
            
            % Dipole term can just be directly computed from the equation.
            values = squidlab.fit.dipoleEquation(fixedParameters,...
                freeParameterFixes, z);
            
            % Rescale by the maximum value, so first term is of order 1.
            values = values / max (abs(values));
        end
    end
    
    methods(Access = protected)
        function values = computeNextTerm(this, z, previousValues, ~)
            % Computes the next term, by differentiating the previous term.
            
            % Directly do numerical differentiation. This will lose us the
            % last point...
            values = diff(previousValues) ./...
                diff(z);
            
            % ...which we need to try and replace in a sensible way. Do so
            % by fitting a cubic spline to the last few points, then
            % extrapolating to the z-value we just removed, to estimate the
            % value there.
            endWindow = 5;
            
            % We need the data to remain moderately smooth, otherwise after
            % a few terms the numeric differentation introduces loads of
            % noise.
            values = smooth(values, endWindow);
            
            % We've lost a point, extrapolate using smoothing spline to get
            % it back. Note that at this point values has one less element
            % than z.
            lastZ = z(end-endWindow:end-1);
            lastValues = values(end+1-endWindow:end);
            values(end+1) = interp1(lastZ, lastValues, z(end), 'pchip', 'extrap');
        end
    end
    
    
end