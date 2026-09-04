function value=greenareaedge(p,e,direction)
%GREENAREAEDGE Signed Green-theorem area contribution of one exact primitive.
% P contains the stored edge endpoints. DIRECTION is +1 or -1.
if strcmp(e.Type,'arc')
    da=e.ArcAngle*direction; c=e.ArcCenter; r=e.Radius;
    t0=atan2(p(1,2)-c(2),p(1,1)-c(1)); t1=t0+da;
    value=0.5*(r*r*da+r*c(1)*(sin(t1)-sin(t0))-r*c(2)*(cos(t1)-cos(t0)));
else
    value=0.5*(p(1,1)*p(2,2)-p(2,1)*p(1,2));
end
end
