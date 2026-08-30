function y = periodicslmeval(x, slm, evalmode, checkinputs)
% evaluates an slm object which is fitted to a periodic function, you must
% have explicitly used the 'periodic' options when performing the fit 
%
% Syntax
%
% y = periodicslmeval(x, slm)
% y = periodicslmeval(x, slm, evalmode)
% y = periodicslmeval(x, slm, evalmode, checkinputs)
%
% arguments: (input)
%  x       - array (any shape) of data to be evaluated through model
%
%            All points are assumed to lie inside the range of
%            the knots. Any which fall outside the first or last
%            knot will be assigned the value of the function
%            at the corresponding knot. NO extrapolation is
%            allowed. (If you really need to extrapolate, then
%            you should have done it when you built the model
%            in the first place. An alternative, if I ever write
%            it, is an extrapolator code, that builds a new,
%            extrapolated function.)
%
%  slm     - a shape language model structure, normally constructed
%            by slmfit or slmengine.
%
%            The fields in this struct are:
%            slm.type  = either 'cubic', 'linear', or 'constant'
%
%            slm.knots = a vector of knots (distinct & increasing)
%               There must be at least two knots.
%
%            slm.coef  = an array of coefficients for the hermite
%               function.
%
%            If the function is linear or constant Hermite, then
%            slm.coef will have only one column, composed of the
%            value of the function at each corresponding knot.
%            The 'constant' option uses a function value at x(i)
%            to apply for x(i) <= x < x(i+1).
%
%            If the function is cubic Hermite, then slm.coef
%            will have two columns. The first column will be the
%            value of the function at the corresponding knot,
%            the second column will be the correspodign first
%            derivative.
%
% evalmode - (OPTIONAL) numeric flag - specifies what evaluation
%            is to be done.
%
%            DEFAULT VALUE: 0
%
%            == 0 --> evaluate the function at each point in x.
%            == 1 --> the first derivative at each point in x.
%            == 2 --> the second derivative at each point in x.
%            == 3 --> the third derivative at each point in x.
%            == -1 --> evaluate the inverse of the function at
%             each point in x, thus y is returned such that x=f(y)
%
%            Note 1: Piecewise constant functions will return zero
%            for all order derivatives, since I ignore the delta
%            functions at each knot.
%            The inverse operation is also disabled for constant
%            functions.
%
%            Note 2: Linear hermite functions will return zero
%            for second and higher order derivatives. At a knot
%            point, while technically the derivative is undefined
%            at that location, the slope of the segment to the
%            right of that knot is returned.
%
%            Note 3: Inverse computations will return the
%            LEFTMOST zero (closest to -inf) in the event that
%            more than one solution exists.
%
%            Note 4: Inverse of points which fall above the
%            maximum or below the minimum value of the function
%            will be returned as a NaN.
%            
%
% Arguments: (output)
%  y       - Evaluated result, the predicted value, i.e., f(x)
%            or f'(x), f''(x), f'''(x), or the functional inverse
%            such that x = f(y). y will have the same shape and
%            size as x.
%

% Created by Richard Crozier 2012-2015

    if nargin < 3
        evalmode = 0;
    end
    
    xmod = slm.x(1)+mod(x-slm.x(1), slm.period);

    % slmeval selects the compiled evaluator when it is available and its
    % numerically equivalent m-file implementation otherwise.  Calling the
    % MEX entry point directly made periodic SLMs unusable in clean Octave
    % and MATLAB installations where the optional binary was not built.
    y = slmeval (xmod, slm, evalmode, checkinputs);
    
end
