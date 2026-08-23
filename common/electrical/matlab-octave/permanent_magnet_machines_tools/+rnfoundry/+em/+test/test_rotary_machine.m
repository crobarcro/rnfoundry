function test_rotary_machine()
m4=rnfoundry.em.RotaryMachine(2*pi/4);
rnfoundry.em.test.assertNear(m4.electricalFrequency(100),100/pi);
m2=rnfoundry.em.RotaryMachine(2*pi/2);
rnfoundry.em.test.assertNear(m2.electricalFrequency(2*pi),1);
m12=rnfoundry.em.RotaryMachine(2*pi/12);
omega=1800*2*pi/60;
rnfoundry.em.test.assertNear(m12.electricalFrequency(omega),180);
rnfoundry.em.test.assertNear(m12.thetap,m12.PoleSpan);
end
