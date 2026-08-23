function assertNear(actual, expected, tolerance)
if nargin < 3, tolerance = 5e-13; end
if isa(actual,'fr'), actual=double(actual); end
if isa(expected,'fr'), expected=double(expected); end
scale = max(1, max(abs(expected(:))));
assert(isequal(size(actual),size(expected)) && all(abs(actual(:)-expected(:)) <= tolerance*scale));
end
