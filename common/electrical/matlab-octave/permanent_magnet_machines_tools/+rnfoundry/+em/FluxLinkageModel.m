classdef FluxLinkageModel
    %FLUXLINKAGEMODEL Periodic zero-current PM coil flux-linkage model.
    %   Position is normalized in pole spans.  The waveform period is two.
    properties (SetAccess = private)
        Fit
        FitMethod
        RMS
        CoilPeak
        PhasePeak
        PeakFluxLinkageFEAPosition
    end
    methods
        function obj = FluxLinkageModel(fit, rmsValue, coilPeak, phasePeak, peakPosition)
            if nargin ~= 5 || ~isstruct(fit) || isempty(fit) ...
                    || ~isfield(fit,'period') || abs(fit.period-2) > 100*eps
                error('rnfoundry:em:InvalidFluxLinkageModel', ...
                    'A nonempty periodic two-pole SLM fit is required.');
            end
            values=[rmsValue,coilPeak,phasePeak,peakPosition];
            if any(~isfinite(values)) || rmsValue < 0 || peakPosition < 0 || peakPosition > 1
                error('rnfoundry:em:InvalidFluxLinkageModel', ...
                    'Flux-linkage derived properties are inconsistent.');
            end
            obj.Fit=fit; obj.FitMethod='SLM'; obj.RMS=rmsValue;
            obj.CoilPeak=coilPeak; obj.PhasePeak=phasePeak;
            obj.PeakFluxLinkageFEAPosition=peakPosition;
        end
        function value = evaluate(obj, position)
            if ~isnumeric(position) || any(~isfinite(position(:)))
                error('rnfoundry:em:InvalidModelPosition','position must be finite numeric data.');
            end
            value=periodicslmeval(position,obj.Fit,0,false);
        end
    end
end
