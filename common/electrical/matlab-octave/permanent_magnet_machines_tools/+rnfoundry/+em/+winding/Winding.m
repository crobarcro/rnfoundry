classdef Winding
    properties
        PhaseCount=NaN; PoleCount=NaN; LayerCount=1; CoilCount=NaN
        BasicCoilCount=NaN; BasicPoleCount=NaN; BasicWindingRepetitions=NaN
        SlotCount=NaN; BasicSlotCount=NaN; CoilPitchSlots=NaN
        qcn=NaN; qcd=NaN; ypn=NaN; ypd=NaN
        ParallelBranches=1; Layout=struct(); TurnsPerCoil=NaN
        PackingFactor=NaN; Conductor=[]; CoilGeometry=[]
    end
    properties (Dependent)
        qc; yp; SlotsPerPole; CoilsPerPhase; CoilsPerBranch
        MeanTurnLength; TurnPathLengthPerCoil; TotalTurnPathLength
        TotalStrandLength; CopperVolume; CopperFillFactor; ReferenceDCCoilResistance
    end
    methods
        function obj=Winding(s)
            if nargin==0, return; end
            names=fieldnames(s); allowed={'PhaseCount','PoleCount','LayerCount','CoilCount','BasicCoilCount','BasicPoleCount','BasicWindingRepetitions','SlotCount','BasicSlotCount','CoilPitchSlots','qcn','qcd','ypn','ypd','ParallelBranches','Layout','TurnsPerCoil','PackingFactor','Conductor','CoilGeometry'}; for k=1:numel(names), if any(strcmp(names{k},allowed)), obj.(names{k})=s.(names{k}); end; end
        end
        function v=get.qc(obj), v=obj.qcn/obj.qcd; end
        function v=get.yp(obj), v=obj.ypn/obj.ypd; end
        function v=get.SlotsPerPole(obj), v=obj.SlotCount/obj.PoleCount; end
        function v=get.CoilsPerPhase(obj), v=obj.CoilCount/obj.PhaseCount; end
        function v=get.CoilsPerBranch(obj), v=obj.CoilsPerPhase/obj.ParallelBranches; end
        function v=get.MeanTurnLength(obj), v=obj.CoilGeometry.MeanTurnLength; end
        function v=get.TurnPathLengthPerCoil(obj), v=obj.TurnsPerCoil*obj.MeanTurnLength; end
        function v=get.TotalTurnPathLength(obj), v=obj.CoilCount*obj.TurnPathLengthPerCoil; end
        function v=get.TotalStrandLength(obj), v=obj.Conductor.StrandCount*obj.TotalTurnPathLength; end
        function v=get.CopperVolume(obj), v=obj.TotalTurnPathLength*obj.Conductor.CopperAreaPerTurn; end
        function v=get.CopperFillFactor(obj), v=obj.TurnsPerCoil*obj.Conductor.CopperAreaPerTurn/obj.CoilGeometry.PackArea; end
        function v=get.ReferenceDCCoilResistance(obj), v=obj.Conductor.dcResistancePerLength()*obj.TurnPathLengthPerCoil; end
        function validate(obj)
            nums=[obj.PhaseCount obj.PoleCount obj.LayerCount obj.CoilCount obj.SlotCount obj.TurnsPerCoil obj.ParallelBranches];
            if any(~isfinite(nums))||any(nums<=0)||any(nums~=fix(nums)), error('rnfoundry:em:InvalidWinding','Winding counts must be positive integers.'); end
            if ~any(obj.LayerCount==[1 2]), error('rnfoundry:em:InvalidLayers','LayerCount must be one or two.'); end
            if obj.CoilsPerPhase~=fix(obj.CoilsPerPhase)||obj.CoilsPerBranch~=fix(obj.CoilsPerBranch), error('rnfoundry:em:InvalidCombinatorics','Coils must divide phases and branches.'); end
            obj.Conductor.validate(); obj.CoilGeometry.validate();
            if obj.PackingFactor<=0||obj.PackingFactor>1||obj.TurnsPerCoil*obj.Conductor.OccupiedAreaPerTurn>obj.CoilGeometry.PackArea*(obj.PackingFactor+1e-12), error('rnfoundry:em:InvalidPacking','Conductor construction does not fit the requested packing factor.'); end
        end
        function s=toStruct(obj)
            s=struct('Type','Winding','PhaseCount',obj.PhaseCount,'PoleCount',obj.PoleCount,'LayerCount',obj.LayerCount,'CoilCount',obj.CoilCount,'BasicCoilCount',obj.BasicCoilCount,'BasicPoleCount',obj.BasicPoleCount,'BasicWindingRepetitions',obj.BasicWindingRepetitions,'SlotCount',obj.SlotCount,'BasicSlotCount',obj.BasicSlotCount,'CoilPitchSlots',obj.CoilPitchSlots,'qcn',obj.qcn,'qcd',obj.qcd,'ypn',obj.ypn,'ypd',obj.ypd,'ParallelBranches',obj.ParallelBranches,'Layout',obj.Layout,'TurnsPerCoil',obj.TurnsPerCoil,'PackingFactor',obj.PackingFactor,'Conductor',obj.Conductor.toStruct(),'CoilGeometry',obj.CoilGeometry.toStruct());
        end
    end
    methods (Static)
        function obj=fromStruct(s), s.Conductor=rnfoundry.em.winding.RoundWireConductor.fromStruct(s.Conductor); s.CoilGeometry=rnfoundry.em.winding.RadialSlottedCoilGeometry.fromStruct(s.CoilGeometry); obj=rnfoundry.em.winding.Winding(s); end
    end
end
