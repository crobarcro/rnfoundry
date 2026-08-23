function fullDiameter = insulatedWireDiameter(copperDiameter)
%INSULATEDWIREDIAMETER Legacy enamel outside-diameter correlation.
d = copperDiameter .* 1000;
fullDiameter = NaN(size(d));
i = d < 1.6;
fullDiameter(i) = d(i) .* (1 + (-0.1135.*d(i).^5 + 1.6055.*d(i).^4 - 8.5416.*d(i).^3 + 21.481.*d(i).^2 - 27.039.*d(i) + 18.561)./100);
fullDiameter(~i) = d(~i) .* (1 + 5.9131.*d(~i).^(-0.6559)./100);
fullDiameter = fullDiameter ./ 1000;
end
