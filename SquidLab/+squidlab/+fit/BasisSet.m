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

classdef(Abstract) BasisSet < handle
    % BASISSET  Interface for basis set generators.
    %
    % A BasisSet provides a way to compute N basis vectors, where N is the
    % order.
    %
    % Example use of implementations
    %   bs = myBasisSet();
    %
    %   % Get up to the 5th-order basis vector.
    %   vectors = bs.getBasisVectors(z, 5);
    %   
    %   % vectors is a (length(z)) x 5 array.

    methods(Abstract, Access = public)
       values = computeFirstTerm(this, z)
       % computeFirstTerm
       % Given a set of z-points to evaluate at, computes the first (order
       % 1) term in the set of basis vectors.
    end
    
    methods(Abstract, Access = protected)
        values = computeNextTerm(this, z, previousValues)
        % computeNextTerm
        % Given a set of z-points to evaluate at, and the previous basis
        % vector, returns the next basis vector.
    end
    
   methods
       function values = getBasisVectors(this, z, order)
           % Returns basis vectors from 1 to order.
           %
           % Pass z as a [NumPoints x 1] array of points to compute the
           % basis vector at, and order as a scalar int.
           
           z = z(:);
           values = nan(length(z), order);
           
           values(:,1) = this.computeFirstTerm(z, order);
           for i=2:order
              values(:,i) = this.computeNextTerm(z, values(:,i-1), order);
           end
           
       end
   end
    
end