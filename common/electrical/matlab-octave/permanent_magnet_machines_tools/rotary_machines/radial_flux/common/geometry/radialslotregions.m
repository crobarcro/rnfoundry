function geom=radialslotregions(varargin)
%RADIALSLOTREGIONS Analyze exact physical regions in RADIALSLOTGEOMETRY.
%   Face tracing and label classification are intentionally separate from the
%   authoritative drawing kernel so FEMM construction cannot fail because of
%   an area-analysis diagnostic.
geom=radialslotgeometry(varargin{:});
geom=analyzeRadialSlotRegions(geom);
end
