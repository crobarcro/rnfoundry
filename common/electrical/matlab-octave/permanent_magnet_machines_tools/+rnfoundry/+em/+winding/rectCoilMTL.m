function length = rectCoilMTL(depth,height,thickness)
sidelen = sqrt((height+thickness).^2);
length = 2.*sidelen + 2.*depth + 2.*thickness + pi.*thickness;
end
