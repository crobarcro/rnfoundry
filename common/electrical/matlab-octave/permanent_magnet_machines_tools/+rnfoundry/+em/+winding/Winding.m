classdef Winding
    %WINDING Canonical resolved electromagnetic winding definition.
    %   Stored topology includes counts, turns, branches, conductor, coil
    %   geometry, and Layout.Coils/Layout.Phases. PackingFactor preserves
    %   legacy CoilFillFactor insulated-wire occupancy semantics, whereas
    %   CopperFillFactor is actual copper area divided by PackArea.
    %   Length queries distinguish turn path, total path, and strand length.
    properties (SetAccess = private)
        PhaseCount
        PoleCount
        LayerCount
        CoilCount
        BasicCoilCount
        BasicPoleCount
        BasicWindingRepetitions
        SlotCount
        BasicSlotCount
        CoilPitchSlots
        qcn
        qcd
        ypn
        ypd
        ParallelBranches
        Layout
        TurnsPerCoil
        PackingFactor
        Conductor
        CoilGeometry
    end
    properties (Dependent)
        qc
        yp
        SlotsPerPole
        CoilsPerPhase
        CoilsPerBranch
        MeanTurnLength
        TurnPathLengthPerCoil
        TotalTurnPathLength
        TotalStrandLength
        CopperVolume
        CopperFillFactor
        ReferenceDCCoilResistance
    end
    methods
        function obj = Winding(s)
            required = {'PhaseCount','PoleCount','LayerCount','CoilCount', ...
                'BasicCoilCount','BasicPoleCount','BasicWindingRepetitions', ...
                'SlotCount','BasicSlotCount','CoilPitchSlots','qcn','qcd', ...
                'ypn','ypd','ParallelBranches','Layout','TurnsPerCoil', ...
                'PackingFactor','Conductor','CoilGeometry'};
            if nargin < 1
                return;
            end
            for k = 1:numel(required)
                if ~isfield(s, required{k})
                    error('rnfoundry:em:MissingWindingProperty', ...
                          'Missing winding property %s.', required{k});
                end
                obj.(required{k}) = s.(required{k});
            end
            obj.validate();
        end
        function value = get.qc(obj)
            value = obj.qcn ./ obj.qcd;
        end
        function value = get.yp(obj)
            value = obj.ypn ./ obj.ypd;
        end
        function value = get.SlotsPerPole(obj)
            value = obj.SlotCount ./ obj.PoleCount;
        end
        function value = get.CoilsPerPhase(obj)
            value = obj.CoilCount ./ obj.PhaseCount;
        end
        function value = get.CoilsPerBranch(obj)
            value = obj.CoilsPerPhase ./ obj.ParallelBranches;
        end
        function value = get.MeanTurnLength(obj)
            value = obj.CoilGeometry.MeanTurnLength;
        end
        function value = get.TurnPathLengthPerCoil(obj)
            value = obj.TurnsPerCoil .* obj.MeanTurnLength;
        end
        function value = get.TotalTurnPathLength(obj)
            value = obj.CoilCount .* obj.TurnPathLengthPerCoil;
        end
        function value = get.TotalStrandLength(obj)
            value = obj.Conductor.StrandCount .* obj.TotalTurnPathLength;
        end
        function value = get.CopperVolume(obj)
            value = obj.TotalTurnPathLength .* obj.Conductor.CopperAreaPerTurn;
        end
        function value = get.CopperFillFactor(obj)
            value = obj.TurnsPerCoil .* obj.Conductor.CopperAreaPerTurn ./ obj.CoilGeometry.PackArea;
        end
        function value = get.ReferenceDCCoilResistance(obj)
            value = obj.Conductor.dcResistancePerLength() .* obj.TurnPathLengthPerCoil;
        end
        function validate(obj)
            counts = [obj.PhaseCount,obj.PoleCount,obj.LayerCount,obj.CoilCount, ...
                      obj.BasicCoilCount,obj.BasicPoleCount,obj.BasicWindingRepetitions, ...
                      obj.SlotCount,obj.BasicSlotCount,obj.CoilPitchSlots, ...
                      obj.ParallelBranches,obj.TurnsPerCoil];
            if any(~isfinite(counts)) || any(counts <= 0) || any(counts ~= fix(counts))
                error('rnfoundry:em:InvalidWinding', 'Winding counts must be positive integers.');
            end
            if ~(obj.LayerCount == 1 || obj.LayerCount == 2)
                error('rnfoundry:em:InvalidLayers', 'LayerCount must be one or two.');
            end
            expectedSlots = obj.CoilCount;
            expectedBasicSlots = obj.BasicCoilCount;
            if obj.LayerCount == 1
                expectedSlots = 2 .* expectedSlots;
                expectedBasicSlots = 2 .* expectedBasicSlots;
            end
            if obj.SlotCount ~= expectedSlots || obj.BasicSlotCount ~= expectedBasicSlots
                error('rnfoundry:em:InvalidCombinatorics', 'Slot and coil counts disagree with LayerCount.');
            end
            [expectedQcn, expectedQcd] = rat(obj.CoilCount ./ (obj.PoleCount .* obj.PhaseCount));
            [expectedYpn, expectedYpd] = rat(obj.SlotCount ./ obj.PoleCount);
            if obj.qcn ~= expectedQcn || obj.qcd ~= expectedQcd ...
                    || obj.ypn ~= expectedYpn || obj.ypd ~= expectedYpd
                error('rnfoundry:em:InvalidCombinatorics', 'Stored winding fractions disagree with counts.');
            end
            if obj.BasicCoilCount .* obj.BasicWindingRepetitions ~= obj.CoilCount ...
                    || obj.BasicPoleCount .* obj.BasicWindingRepetitions ~= obj.PoleCount
                error('rnfoundry:em:InvalidCombinatorics', 'Basic winding repetitions disagree with total counts.');
            end
            if obj.CoilsPerPhase ~= fix(obj.CoilsPerPhase) ...
                    || obj.CoilsPerBranch ~= fix(obj.CoilsPerBranch)
                error('rnfoundry:em:InvalidCombinatorics', 'Coils must divide phases and branches.');
            end
            if ~isstruct(obj.Layout) || ~isfield(obj.Layout,'Coils') || ~isfield(obj.Layout,'Phases') ...
                    || isempty(obj.Layout.Coils) || isempty(obj.Layout.Phases)
                error('rnfoundry:em:UnresolvedWindingLayout', ...
                      'A canonical winding requires resolved Coils and Phases layout matrices.');
            end
            coils = obj.Layout.Coils;
            phases = obj.Layout.Phases;
            expectedCoilRows = obj.CoilCount ./ obj.PhaseCount;
            if ~isnumeric(coils) || ~ismatrix(coils) ...
                    || size(coils,1) ~= expectedCoilRows ...
                    || size(coils,2) ~= 2 .* obj.PhaseCount ...
                    || any(~isfinite(coils(:))) || any(coils(:) ~= fix(coils(:))) ...
                    || any(coils(:) < 1) || any(coils(:) > obj.SlotCount)
                error('rnfoundry:em:InvalidWindingLayout', ...
                      'Layout.Coils is inconsistent with winding counts and slots.');
            end
            if ~isnumeric(phases) || ~ismatrix(phases)
                error('rnfoundry:em:InvalidWindingLayout', ...
                      'Layout.Phases must be a numeric matrix.');
            end
            populatedPhases = phases(~isnan(phases));
            if size(phases,1) ~= obj.SlotCount ...
                    || size(phases,2) ~= obj.LayerCount ...
                    || any(~isfinite(populatedPhases)) ...
                    || any(populatedPhases ~= fix(populatedPhases)) ...
                    || any(abs(populatedPhases) < 1) ...
                    || any(abs(populatedPhases) > obj.PhaseCount)
                error('rnfoundry:em:InvalidWindingLayout', ...
                      'Layout.Phases is inconsistent with winding phases and layers.');
            end
            if ~(isscalar(obj.PackingFactor) && isfinite(obj.PackingFactor) ...
                    && obj.PackingFactor > 0 && obj.PackingFactor <= 1)
                error('rnfoundry:em:InvalidPacking', 'PackingFactor must be in (0, 1].');
            end
            obj.Conductor.validate();
            obj.CoilGeometry.validate();
            occupied = obj.TurnsPerCoil .* obj.Conductor.OccupiedAreaPerTurn;
            allowance = obj.CoilGeometry.PackArea .* obj.PackingFactor ...
                      + 0.5 .* obj.Conductor.OccupiedAreaPerTurn;
            if occupied > allowance
                error('rnfoundry:em:InvalidPacking', ...
                      'Resolved turns and conductor construction exceed the requested packing.');
            end
        end
        function s = toStruct(obj)
            s = struct('Schema','rnfoundry.em.winding.Winding','SchemaVersion',1,'Type','Winding', ...
                'PhaseCount',obj.PhaseCount,'PoleCount',obj.PoleCount,'LayerCount',obj.LayerCount, ...
                'CoilCount',obj.CoilCount,'BasicCoilCount',obj.BasicCoilCount, ...
                'BasicPoleCount',obj.BasicPoleCount,'BasicWindingRepetitions',obj.BasicWindingRepetitions, ...
                'SlotCount',obj.SlotCount,'BasicSlotCount',obj.BasicSlotCount, ...
                'CoilPitchSlots',obj.CoilPitchSlots,'qcn',obj.qcn,'qcd',obj.qcd, ...
                'ypn',obj.ypn,'ypd',obj.ypd,'ParallelBranches',obj.ParallelBranches, ...
                'Layout',obj.Layout,'TurnsPerCoil',obj.TurnsPerCoil, ...
                'PackingFactor',obj.PackingFactor,'Conductor',obj.Conductor.toStruct(), ...
                'CoilGeometry',obj.CoilGeometry.toStruct());
        end
    end
    methods (Static)
        function obj = fromStruct(s)
            rnfoundry.em.validateStructEnvelope( ...
                s, 'rnfoundry.em.winding.Winding', 'Winding');
            s.Conductor = rnfoundry.em.winding.RoundWireConductor.fromStruct(s.Conductor);
            s.CoilGeometry = rnfoundry.em.winding.RadialSlottedCoilGeometry.fromStruct(s.CoilGeometry);
            obj = rnfoundry.em.winding.Winding(s);
        end
    end
end
