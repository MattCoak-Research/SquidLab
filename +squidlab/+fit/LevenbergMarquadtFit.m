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

classdef LevenbergMarquadtFit < squidlab.fit.Fit
    % LEVENBERGMARQUADTFIT  Fits dipoles using nlinfit() via Levenberg-Marquadt.
    %
    % Fits a V(z) scan using nlinfit(), minimizing the difference between
    % the data and the predicted form for a counterwound coil.
    %
    % Note that this fit may hit many warnings like
    % stats:nlinfit:ModelConstantWRTParam (even though the actual fit is
    % good). If it's being used in a loop, these warnings should be
    % disabled first, all the fits conducted, and then the warnings
    % restored afterwards.
    
    properties
        % StartAtLastFit (bool)
        % If this is true, then each fit will use the parameters of the
        % previous fit as its start point, rather than trying to estimate
        % its own start point. If the initial fits are good, this can
        % significantly improve performance and give fewer warnings, but if
        % the fit ever gets trapped in a local minimum it will cause big
        % problems. It's recommended to set this to false.
        StartAtLastFit = false
        
        % DipoleRescaleFactor (scalar double)
        % We need to provide a sensible estimate of the dipole size
        % (the c(3) fit parameter), but this is a function of the SQUID
        % coils. The dipole V(z) is ~c(3) * (R^2 + Lambda^2)^(-3/2),
        % where R is the coil radius and Lambda the coil separation. We
        % can estimate what c(3) should be by measuring the span of
        % V(z), from max to min, and multiplying by a factor (R^2 +
        % Lambda^2)^(3/2).
        DipoleRescaleFactor = 1
        
        % NumEdgePoints (scalar int)
        % Number of points considered at the "edge" of the scan, used to
        % estimate the offset and linear drift.
        NumEdgePoints = 5;
        
        % ParameterCache ([NumParams x 1] double)
        % Array of parameters obtained from the last fit, which may be
        % needed if this.StartAtLastFit == true.
        ParameterCache = []
    end
    
    methods
        function [parameters, prediction] = fit(this, data, equation)
            % Fits the data using nlinfit.
            %
            % equation has 4 free parameters, which we need to estimate
            % sensibly.
            % - c(1) is the constant offset
            % - c(2) is the coefficient of the linear drift
            % - c(3) is the overall size of the dipole.
            % - c(4) is the offset of the sample with respect to z = 0
            
            % Using the last fit as the startpoint may give (much) faster
            % convergence and better results, if the fit hasn't changed
            % much. However, if the fit at some point falls into a poor
            % local minimum, it might just wallow around there.
            %
            % If we don't have start points already (or don't want to use
            % them), we instead need to estimate some vaguely sane start
            % points. Assuming this estimation process is good, this latter
            % approach is favourable.
            if this.StartAtLastFit && ~isempty(this.ParameterCache)
                c0 = this.ParameterCache;
            else
                c0 = iEstimateStartPoints(data, this.DipoleRescaleFactor,...
                    this.NumEdgePoints);
            end

            % Perform fit.
            parameters = nlinfit(data(:,1), data(:,2),...
                equation,c0);
            prediction = equation(parameters, data(:,1));
            
            % We might need these parameters as the start point for the
            % next fit.
            this.ParameterCache = parameters;
        end
    end
end

function c = iEstimateStartPoints(data, rescaleFactor, numEdgePoints)
% Estimates the start points c, where the 4 components are:
% - c1 the constant offset.
% - c2 the linear drift.
% - c3 the size of the dipole.
% - c4 the offset of the dipole cente w.r.t z = 0.

% Fit a straight line to the first and last few points to estimate c(1) and
% c(2).
nFit = numEdgePoints;  % Use this many points at start at end.
p = polyfit(data([1:nFit end-nFit:end],1), data([1:nFit end-nFit:end],2), 1);

% p has gradient first but we need it second.
c(1:2) = fliplr(p);

% Overall size is probably approximately the span of y:
% - divided by 2 to account for the factor of 2 in the actual dipole
%   equation (we don't include this factor of 2, it isn't needed).
% - with the correct sign (getting this wrong severely hurts the fit), i.e.
%   is the dipole pointing up or down?
% - multiplied by rescaleFactor. This arises from the fact that in the
%   dipole equation, the signal is proportional to ~(radius^2 +
%   separation^2).^(-3/2), i.e. it scales with the inverse cube of the coil
%   dimensions. If we don't correct for this factor, the magnitude obtained
%   by just measuring the span may be out by several orders of magnitude,
%   and the fitting process will work very poorly. We therefore need to
%   multiply our value obtained from the span by (radius^2 +
%   separation^2).^(3/2).

% Estimate span
c(3) = max(data(:,2)) - min(data(:,2));

% To get the sign right, subtract the midpoint value from the mean of the
% two ends.
endY = 0.5*(data(1,2) + data(end,2));
midIdx = ceil(size(data, 1)/2);
c(3) = c(3) * sign(data(midIdx, 2) - endY);

% Correct for the fact that the dipole size is inversely proportional to
% the cube of the characteristic coil dimension.
c(3) = c(3) * rescaleFactor;

% Hopefully the signal is approximately centred in the middle of the scan.
% It might seem more sensible to set this to e.g. mean(data(:,1)). In
% practice this works poorly - mean(data(:,1)) might be ~eps, in which case
% we end up with numeric precision problems and lots of warnings from
% nlinfit. It works out much better to just fix it at 0 and let the fit
% move it around.
c(4) = 0;
end