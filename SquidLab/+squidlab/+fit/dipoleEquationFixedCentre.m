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

function V = dipoleEquationFixedCentre(a, c, z)
% New functionality added Mar2024 M Coak - modified version of the
% dipole equation with the centre fixed at z=0, rather than
% including a fitted z offset
%
% Functional form of the SQUID dipole V(z), without drift or constant
% offset.
%
% The vector a is a set of fixed parameters:
% - a(1) is the longitudinal radius of the SQUID coils.
% - a(2) is the longitudinal coil separation
%
% The vector c is a set of free parameters varied by the fit:
% - c(1) is the overall size of the dipole.
%
% z is the vector of points at which the voltage V is evaluated.

% Make sure we're using a column vector.
z = z(:);

V = c(1) .* (2.* iPointDipole(a(1), 0, z) - ...
    iPointDipole(a(1), a(2), z) - iPointDipole(a(1), -a(2), z));

end

function v = iPointDipole(radius, separation, z)

v = (radius.^2 + (separation+z).^2).^(-3/2);
end