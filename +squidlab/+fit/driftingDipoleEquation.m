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

function V = driftingDipoleEquation(a, c, z)
% Functional form of the SQUID dipole V(z) including:
% - A constant offset.
% - A linear drift.
%
% The vector a is a set of fixed parameters:
% - a(1) is the longitudinal radius of the SQUID coils.
% - a(2) is the longitudinal coil separation
%
% The vector c is a set of free parameters varied by the fit:
% - c(1) is the constant offset
% - c(2) is the coefficient of the linear drift
% - c(3) is the overall size of the dipole.
% - c(4) is the offset of the sample with respect to z = 0
%
% z is the vector of points at which the voltage V is evaluated.

% Make sure we're using a column vector.
z = z(:);

% Add linear drift and offset to the simple dipole form.
V = c(1) + c(2).*z + ...
    squidlab.fit.dipoleEquation(a, c(3:4), z);
end