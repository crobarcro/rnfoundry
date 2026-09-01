function [FemmProblem, outernodes, coillabellocs, slotinfo] = curvedstatorhalf2dfemmproblem(...
    nslots, thetaslot, thetacoil, thetashoegap, ryoke, rcoil, rshoebase, rshoegap, roffset, side, varargin)
% draw internal parts of a slotted stator for a radial flux machine
%
% Syntax
%
% [FemmProblem, outernodes, coillabellocs] = ...
%       curvedstatorhalf2dfemmproblem( nslots, thetaslot, thetacoil, ...
%                                       thetashoegap, ryoke, rcoil, rshoebase, ...
%                                       rshoegap, coillayers, side )
%
%
% [FemmProblem, outernodes, coillabellocs] = ...
%       curvedstatorhalf2dfemmproblem( ..., 'Parameter', Value )
%
% Description
%
% curvedstatorhalf2dfemmproblem creates or adds to an mfemm FemmProblem
% structure, the internal parts of a radial flux slotted stator. The
% 'internal parts' refer to the segments, nodes and labels making up the
% teeth and coils, but not the outer part of the yoke of the machine, i.e.
% the stator drawing is not closed at its edges. It is intended for
% curvedstatorhalf2dfemmproblem to be used by higher level drawing
% functions which are drawing the full radial flux machine geometry. 
% 
%
% Input
%
%  nslots - total number of slots to be drawn
%
%  thetaslot - angular displacement between slots
%
%  thetacoil - coil pitch in radians
%
%  thetashoegap - pitch of space between tooth shoes, i.e. the size of the
%     coil slot opening in the coil pitch direction. Measure in radians.
%
%  ryoke - radial length of the stator yoke on which the slots are mounted
%
%  rcoil - radial length of the coil in the slot, i.e. the slot depth
%
%  rshoebase - radial length of the tooth shoe at the point where it joins
%     the tooth.
%
%  rshoegap - radial length of the tooth shoe at it's tip at the slot
%     opening.
%
%  roffset - radial position of the centre of the stator yoke (radial
%     distance from the centre of the machine).
%
%  In addition, a number of other optional arguments can be supplied as
%  parameter-value pairs. These options and their behaviour are as follows:
%
%  'FemmProblem' - 
%
%  'NWindingLayers'
%
%   'Tol' - tolerance at which to consider various dimensions to be zero,
%     by default this is 1e-5. This is used to prevent meshes occuring with
%     very large numbers of triangles.
%
%  'ShoeGapMaterial' - 
%
%  'ShoeGapRegionMeshSize' - 
%
%  'CoilBaseFraction' - 
%
%   'ShoeCurveControlFrac' - factor controlling the 'curvature' of the 
%     tooth shoe, this is a value between 0 and 1. The exact effect of this
%     number is complex, and depends on the geometry of the slot. However,
%     in general a lower number results in a curve closer to a line draw
%     directly from the shoe base to the shoe gap, while higher numbers
%     aproximate a sharp right angle. Anything in between will produce a
%     smooth curve. Defaults to 0.5.
%
%     N.B. the slot geometry affects this curve in the following way. If
%     the position of the shoe gap node is below the intercept of the line
%     formed by the edge of the slot and a vertical line at the shoe gap
%     node, the resulting curve will bend outward from the inside of the
%     slot. If the intercept is below the shoe gap node, the curve will
%     bend into the slot.
%
%  'SplitSlot' - true/false flag. If there is only two winding layers, the 
%    slot can be split into two in the circumferential direction rather
%    than the radial by setting this flag to true. Defaults to false. If
%    true coil label locations are provided in an anti-clockwise direction.
%
%   'DrawCoilInsulation' = true/false flag indicating whether to draw a
%     layer of coil insulation in the slot
%
%   'CoilInsulationThickness' - scalar value giving the thickness of the
%     coil insulation to draw when DrawCoilInsulation is true. Default is 0
%     if not supplied, so no coil insulation will actually be drawn unless
%     you explicitly set a value greater than zero.
%
% Output
%
% 

    Inputs.NWindingLayers = 1;
    Inputs.FemmProblem = newproblem_mfemm('planar');
    Inputs.ShoeGapMaterial = 1;
    Inputs.ShoeGapRegionMeshSize = -1;
%     Inputs.ArmatureIronGroup = 1;
    Inputs.Tol = 1e-5;
    Inputs.CoilBaseFraction = 0.05;
    Inputs.ShoeCurveControlFrac = 0.5;
    Inputs.SplitSlot = false;
    Inputs.DrawCoilInsulation = false;
    Inputs.CoilInsulationThickness = 0;
    
    Inputs = parse_pv_pairs(Inputs, varargin);
    
    % copy over the FemmProblem
    FemmProblem = Inputs.FemmProblem;
    
    % remove the old one to save memory
    Inputs = rmfield(Inputs, 'FemmProblem');

    slotpos = linspace(0, (nslots-1)*thetaslot, nslots) + (thetaslot / 2);
    
    elcount = elementcount_mfemm(FemmProblem);
    
    % Build the authoritative single-slot physical geometry without FEMM.
    % radialslotregions applies the same legacy layer placement and radial
    % mapping, and additionally exposes exact physical coil-region areas.
    slotgeom = radialslotgeometry(thetacoil, thetashoegap, ryoke, rcoil, ...
        rshoebase, rshoegap, roffset, side, ...
        'NWindingLayers', Inputs.NWindingLayers, 'Tol', Inputs.Tol, ...
        'CoilBaseFraction', Inputs.CoilBaseFraction, ...
        'ShoeCurveControlFrac', Inputs.ShoeCurveControlFrac, ...
        'SplitSlot', Inputs.SplitSlot, ...
        'DrawCoilInsulation', Inputs.DrawCoilInsulation, ...
        'CoilInsulationThickness', Inputs.CoilInsulationThickness);
    nodes = slotgeom.Nodes;
    links = slotgeom.Links;
    slotinfo = slotgeom.SlotInfo;
    slotinfo.coillabelloc = slotgeom.CoilLabelLocations;
    slotinfo.shoegaplabelloc = slotgeom.ShoeGapLabelLocations;
    slotinfo.inslabelloc = slotgeom.InsulationLabelLocations;
    slotinfo.PhysicalGeometry = slotgeom;
    coillabellocs = [];

    % FEMM arc records require a positive angle and the historical endpoint
    % ordering.  The pure result retains signed direction independently.
    angles = zeros(numel(slotinfo.vertlinkinds),1);
    for k = 1:numel(slotinfo.vertlinkinds)
        li = slotinfo.vertlinkinds(k);
        da = slotgeom.Edges(li).ArcAngle;
        if da > 0, links(li,1:2) = fliplr(links(li,1:2)); end
        angles(k) = abs(rad2deg(da));
    end
    links = [links, ismember(1:size(links,1),slotinfo.vertlinkinds)', ...
                    ismember(1:size(links,1),slotinfo.toothlinkinds)'];

    % store the nodes at the bottom of all the slots
    bottomnodes = slotinfo.cornernodes([4,3]) + elcount.NNodes;  
    lastslotcornernodes = slotinfo.cornernodes + elcount.NNodes;    
    
    % draw the first slot linking it to the bottom of the domain
    thisslotsnodes = nodes;
        
    rotM = [cos(slotpos(1))  sin(slotpos(1)); 
            sin(slotpos(1)) -cos(slotpos(1))];
            
    % move in the y direction to the first slot position
    thisslotsnodes = thisslotsnodes * rotM;
    
    originslabellocs = slotinfo.inslabelloc;
    
    if ~isempty (originslabellocs)
        slotinfo.inslabelloc = originslabellocs * rotM;
    end
    
    if ~isempty(slotinfo.coillabelloc)
        
        thiscoillabellocs = slotinfo.coillabelloc * rotM;
        
        % get the coil label location
        coillabellocs = [ coillabellocs; ...
                          thiscoillabellocs ];

    end
    
    % add a new group number for the stator iron
    if ~isfield (FemmProblem.Groups, 'StatorIronOutline')
        FemmProblem = addgroup_mfemm (FemmProblem, 'StatorIronOutline');
    end
    statorirongp = getgroupnumber_mfemm (FemmProblem, 'StatorIronOutline');

    % TODO: put iron and insulation in different groups
%    ironinds = setdiff(1:size(links,1),inslinkinds);
    thisslotlinks = [links(:,1:2) + numel(FemmProblem.Nodes), links(:,3:end)];
    
    [FemmProblem, ~, ~] = addnodes_mfemm (FemmProblem, thisslotsnodes(:,1), thisslotsnodes(:,2));
    
    vcount = 1;
    for ii = 1:size(thisslotlinks,1)
        
        if thisslotlinks (ii,3)
            % vertical link that must be converted to an arc
            if thisslotlinks (ii,4)
                
               [FemmProblem, ~] = addarcsegments_mfemm (FemmProblem, ...
                                                  thisslotlinks(ii,1), ...
                                                  thisslotlinks(ii,2), ...
                                                  angles(vcount), ...
                                                  'MaxSegDegrees', angles(vcount) ./ max (4, ceil (angles(vcount)/1)), ...
                                                  'InGroup', statorirongp);
            else
               [FemmProblem, ~] = addarcsegments_mfemm (FemmProblem, ...
                                                  thisslotlinks(ii,1), ...
                                                  thisslotlinks(ii,2), ...
                                                  angles(vcount), ...
                                                  'MaxSegDegrees', angles(vcount) ./ max (4, ceil (angles(vcount)/1))); 
            end
            vcount = vcount + 1;
        else
            % horizontal link
            if thisslotlinks (ii,4)
                [FemmProblem, ~] = addsegments_mfemm (FemmProblem, ...
                                                      thisslotlinks(ii,1), ...
                                                      thisslotlinks(ii,2), ...
                                                      'InGroup', statorirongp);
            else
                [FemmProblem, ~] = addsegments_mfemm (FemmProblem, ...
                                                      thisslotlinks(ii,1), ...
                                                      thisslotlinks(ii,2));
            end
        end
        
    end
          
    if ~isempty (slotinfo.shoegaplabelloc)
        
        thisshoegaplabelloc = slotinfo.shoegaplabelloc * rotM;
        
        for ind = 1:size(thisshoegaplabelloc,1)
            FemmProblem = addblocklabel_mfemm (FemmProblem, thisshoegaplabelloc(ind,1), thisshoegaplabelloc(ind,2), ...
                                                'BlockType', FemmProblem.Materials(Inputs.ShoeGapMaterial).Name, ...
                                                'MaxArea', Inputs.ShoeGapRegionMeshSize );
        end
        
    end
    
    % draw the rest of the slots, making copies of the original slot's
    % nodes and links, adding in the labels, and linking them together
    for i = 2:numel(slotpos)
    
        slotinsgp = getgroupnumber_mfemm (FemmProblem, ['StatorSlot_', int2str(i)]);
        
        thisslotsnodes = nodes;
        
        rotM = [cos(slotpos(i))  sin(slotpos(i)); 
                sin(slotpos(i)) -cos(slotpos(i))]; 
        
        thisslotsnodes = thisslotsnodes * rotM;
        
        if ~isempty (slotinfo.inslabelloc)
            slotinfo.inslabelloc = [ slotinfo.inslabelloc; originslabellocs * rotM ];
        end
        
        thisslotlinks = [links(:,1:2) + numel(FemmProblem.Nodes), links(:,3:end)];
        
        thisslotcornernodes = slotinfo.cornernodes + numel(FemmProblem.Nodes);
        
        [FemmProblem] = addnodes_mfemm (FemmProblem, ...
                                        thisslotsnodes(:,1), ...
                                        thisslotsnodes(:,2));
        
        vcount = 1;
        for ii = 1:size(thisslotlinks,1)

            if thisslotlinks (ii,3)
                % vertical link that must be converted to an arc
                if thisslotlinks (ii,4)

                   [FemmProblem, ~] = addarcsegments_mfemm(FemmProblem, ...
                                                      thisslotlinks(ii,1), ...
                                                      thisslotlinks(ii,2), ...
                                                      angles(vcount), ...
                                                      'MaxSegDegrees', angles(vcount) ./ max (4, ceil (angles(vcount)/1)), ...
                                                      'InGroup', statorirongp);
                else
                   [FemmProblem, ~] = addarcsegments_mfemm(FemmProblem, ...
                                                      thisslotlinks(ii,1), ...
                                                      thisslotlinks(ii,2), ...
                                                      angles(vcount), ...
                                                      'MaxSegDegrees', angles(vcount) ./ max (4, ceil (angles(vcount)/1))); 
                end
                vcount = vcount + 1;
            else
                % horizontal link
                if thisslotlinks (ii,4)
                    [FemmProblem, ~] = addsegments_mfemm (FemmProblem, ...
                                                          thisslotlinks(ii,1), ...
                                                          thisslotlinks(ii,2), ...
                                                          'InGroup', statorirongp);
                else
                    [FemmProblem, ~] = addsegments_mfemm (FemmProblem, ...
                                                          thisslotlinks(ii,1), ...
                                                          thisslotlinks(ii,2));
                end
            end

        end                              
        
        if ~isempty(slotinfo.shoegaplabelloc)
            
            thisshoegaplabelloc = slotinfo.shoegaplabelloc * rotM;
            
            for ind = 1:size(thisshoegaplabelloc,1)
                
                FemmProblem = addblocklabel_mfemm(FemmProblem, thisshoegaplabelloc(ind,1), thisshoegaplabelloc(ind,2), ...
                                                'BlockType', FemmProblem.Materials(Inputs.ShoeGapMaterial).Name, ...
                                                'MaxArea', Inputs.ShoeGapRegionMeshSize);

            end
                                        
        end
        
        % now link the slot to the slot below
        if side == 'i'
            
            slotangles = chordpoints2angle(FemmProblem.Nodes(thisslotcornernodes(4)+1).Coords(1), ...
                                       FemmProblem.Nodes(thisslotcornernodes(4)+1).Coords(2), ...
                                       FemmProblem.Nodes(lastslotcornernodes(1)+1).Coords(1), ...
                                       FemmProblem.Nodes(lastslotcornernodes(1)+1).Coords(2) );
                                   
            [FemmProblem, seginds] = ...
                addarcsegments_mfemm( FemmProblem, ...
                                      lastslotcornernodes(1), ...
                                      thisslotcornernodes(4), ...
                                      slotangles, ...
                                      'MaxSegDegrees', slotangles ./ 20, ...
                                      'InGroup', statorirongp );
                                  
        else
            
            slotangles = chordpoints2angle(FemmProblem.Nodes(thisslotcornernodes(3)+1).Coords(1), ...
                                       FemmProblem.Nodes(thisslotcornernodes(3)+1).Coords(2), ...
                                       FemmProblem.Nodes(lastslotcornernodes(2)+1).Coords(1), ...
                                       FemmProblem.Nodes(lastslotcornernodes(2)+1).Coords(2) );
                                   
            [FemmProblem, seginds] = ...
                addarcsegments_mfemm( FemmProblem, ...
                                      lastslotcornernodes(2), ...
                                      thisslotcornernodes(3), ...
                                      slotangles, ...
                                      'MaxSegDegrees', slotangles ./ 20, ...
                                      'InGroup', statorirongp );

        end
        
        % store the top nodes of the slot for the next loop
        lastslotcornernodes = thisslotcornernodes;     
        
        thiscoillabellocs = slotinfo.coillabelloc * rotM;
        
        % get the coil label location
        coillabellocs = [ coillabellocs; ...
                          thiscoillabellocs ];
                           
    end
    
    % we will return the outer corner node ids for later use
    outernodes = [bottomnodes, lastslotcornernodes([2,1])];
    
    
    
    % ---------------    Nested functions   -------------------- %
    
    
%    % nested function for drawing single slots
%    function drawslot ()
%    
%        vcount = 1;
%        for i = 1:size(thisslotlinks,1)
%            
%            if thisslotlinks (i,3)
%                % vertical link that must be converted to an arc
%                if thisslotlinks (i,4)
%                    
%                   [FemmProblem, ~] = addarcsegments_mfemm (FemmProblem, ...
%                                                      thisslotlinks(i,1), ...
%                                                      thisslotlinks(i,2), ...
%                                                      angles(vcount), ...
%                                                      'MaxSegDegrees', angles(vcount) ./ 20, ...
%                                                      'InGroup', statorirongp);
%                else
%                   [FemmProblem, ~] = addarcsegments_mfemm (FemmProblem, ...
%                                                      thisslotlinks(i,1), ...
%                                                      thisslotlinks(i,2), ...
%                                                      angles(vcount), ...
%                                                      'MaxSegDegrees', angles(vcount) ./ 20); 
%                end
%                vcount = vcount + 1;
%            else
%                % horizontal link
%                if thisslotlinks (i,4)
%                    [FemmProblem, ~] = addsegments_mfemm (FemmProblem, ...
%                                                          thisslotlinks(i,1), ...
%                                                          thisslotlinks(i,2), ...
%                                                          'InGroup', statorirongp);
%                else
%                    [FemmProblem, ~] = addsegments_mfemm (FemmProblem, ...
%                                                          thisslotlinks(i,1), ...
%                                                          thisslotlinks(i,2));
%                end
%            end
%            
%        end
%              
%        if ~isempty (slotinfo.shoegaplabelloc)
%            
%            thisshoegaplabelloc = slotinfp.shoegaplabelloc * rotM;
%            
%            for ind = 1:size(thisshoegaplabelloc,1)
%                FemmProblem = addblocklabel_mfemm (FemmProblem, thisshoegaplabelloc(ind,1), thisshoegaplabelloc(ind,2), ...
%                                                    'BlockType', FemmProblem.Materials(Inputs.ShoeGapMaterial).Name, ...
%                                                    'MaxArea', Inputs.ShoeGapRegionMeshSize );
%            end
%            
%        end      
%    
%    end
    
end


function angle = chordpoints2angle(x1,y1,x2,y2)

     chordlen = hypot(x2-x1, y2-y1);
     
     R = magn([x1,y1]);
     
     angle = chordlen/R;
     
     angle = rad2deg(angle);

end

