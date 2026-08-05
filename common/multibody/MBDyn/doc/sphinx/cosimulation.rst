************
Cosimulation
************

The previous examle simply set up a simulation and ran it, with not 
input from Matlab during the solving process. MBDyn is also capable 
of cosimulation with external software. This allows forces to be 
sent to MBDyn based on kinematics sent by MBDyn to the external 
software. The MBDyn Matlab toolbox includes tools to assist with 
connecting to an MBDyn simulation and sending forces as the 
simulation progresses. Here we will demonstrate the use of these 
tools with a simple example.

The cosimulation process is primarily handled by the 
``mbdyn.mint.MBCNodal`` class which manages the communication with 
MBDyn. The ``mbdyn.mint`` namespace holds all of the functions or 
classes specifically related to cosimulation. 
``mbdyn.mint.MBCNodal`` is used to start the mbdyn executeable, set 
up communication to it, and has various methods to then get and send 
appropriate data at each time step between Matlab and MBDyn. It will 
also close communication and quit MBDyn in the event that the 
simulation is to be ended. ``mbdyn.mint.MBCNodal`` is uesed in 
tandem with the ``mbdyn.pre.externalStructuralForce`` element which 
adds an element to the MBDyn input file which tells MBDyn what data 
to expect from Matlab. How this works is best demonstrated with an 
example.

Cosimulation Example
====================

A simple example of cosimulation is presented in the listing below, 
which simulates a small solid sphere, in a gravitational field, which 
has some additional forces applied to it during the simulation which 
are supplied by Matlab. The position and velocity are also read by 
Matlab as the simulation progesses.

.. literalinclude:: /examples/example_basic_cosimulation.m
   :linenos:
   
This produces the plots in :numref:`example_b_cosim_1`, 
:numref:`example_b_cosim_2` and :numref:`example_b_cosim_3`.

.. _example_b_cosim_1:

.. figure:: /images/example_basic_cosimulation_1.png
	:align: center

	Basic cosimulation result plot.

.. _example_b_cosim_2:

.. figure:: /images/example_basic_cosimulation_2.png
	:align: center

	Basic cosimulation result plot.
	
.. _example_b_cosim_3:

.. figure:: /images/example_basic_cosimulation_3.png
	:align: center

	Basic cosimulation result plot.
	
We can take a closer look at the various parts of this example in 
order to fully understand it.
   
The first part of the file sets up the MBDyn problem, which is 
solving the motion of a sphere with some forces applied to it, and 
the first section of this part, shown below, is just setting up some 
things that are all handled internally by MBDyn. That is, the node, 
the body and gravity.

.. literalinclude:: /examples/example_basic_cosimulation.m
   :start-after: %% Problem Definition
   :end-before: % set up the communication methods between MBDyn and Matlab
   
The next part is adding elements which MBDyn uses to communicate 
with Matlab (or any external solver). The 
``externalStructuralForce`` element tells MBDyn about which nodes 
are going to have forces applied by the external solver, and a few 
other things about the nature of those forces. The 
``socketCommunicator`` tells MBDyn how the communication with the 
external solver will be performed, other communication methods are 
possible.

.. literalinclude:: /examples/example_basic_cosimulation.m
   :start-at: % set up the communication methods between MBDyn and Matlab
   :end-before: % set up the initial-value problem
   
The usual problem and system set up follows.

.. literalinclude:: /examples/example_basic_cosimulation.m
   :start-after: % set up the initial-value problem
   :end-before: %% Start MBDyn
   
Following this is a section where the instantiation of the 
``mbdyn.mint.MBCNodal`` object takes place. The MBCNodal class handles 
both the starting up of the MBDyn program, and also the initiation 
of communication between Matlab and MBDyn. If an 
``mbdyn.pre.system`` object is passed to MBCNodal, it will 
discover the details of the chosen communication method and settings 
from this. However, it is not necessary to use an 
``mbdyn.pre.system`` object, and communication can be set up 
manually, if, say, one were using a predefined MBDyn input file, and 
not generating  file using the Matlab preprocessor. However, this 
method ensures a change to the communication method or nodes for 
which forces are to be applied etc. are automatically propogated to 
the MBCNodal object and everything is more easily kept up to 
date if the problem is modified or expanded.

.. literalinclude:: /examples/example_basic_cosimulation.m
   :start-at: %% Start MBDyn
   :end-before: %% Perform Simulation Loop
   
By default MBCNodal searches for the MBDyn executable in some 
standard install locations. If your version of MBDyn is not in these 
locations (e.g. you compiled it yourself) you can poiont MBDyn to a 
specific place. See the help for the ``mbdyn.mint.MBCNodal`` 
constructor to see all the options that can be sued when creating 
the object.

The following part is the main simulation loop. In this loop forces 
and positions are exchanged with MBDyn until the simulation is 
finished. 

.. literalinclude:: /examples/example_basic_cosimulation.m
   :start-at: %% Perform Simulation Loop
   :end-before: %% Perform Post-Processing
   
In this loop we are faking the Matlab solving algorithm's 
convergence by adding in fake iterations. In a real simulation, you 
would use this mechanism to alow then MBDyn solution and force 
calulation to converge together when the calculated forces depended 
on the motion. In the example, they don't, so we could have skipped 
the iterations and just sent the forces. If the forces really don't 
depend very much on the motion, it is also possible to define the 
communication between the solver and MBDyn as 'loose' (rather than 
'tight') when setting up the communicator object for the problem. 
When 'loose' is used, the convergence flag passed in to 
``applyForcesAndMoments`` is ignored, and the MBDyn simulation 
always steps forward using the supplied forces.

The rest of the file, shown below, demonstrates how to use the 
post-processing class to examine the results from output files 
produced by MBDyn. 

.. literalinclude:: /examples/example_basic_cosimulation.m
   :start-at: %% Perform Post-Processing
   
This works in exactly the same way as for the non-cosimulation case, 
however, it is worth noting that since Matlab is able to extract and 
store data from the simulation as it progresses, this might be 
redundant. In this case, one can use the 'DefaultOutput' option of 
the ``mbdyn.pre.system`` class to turn off all output logging to 
files by setting it to 'none'. See the help for the system class for 
more information.


Helper Classes
==================

Two other classes are provided to assist with the application of 
forces, ``mbdyn.mint.twoNodeTranslationalForce`` and 
``mbdyn.mint.twoNodeTorque``. These classes assist with the 
application of forces in the correct frame of reference. For 
instance, ``mbdyn.mint.twoNodeTranslationalForce`` might be used 
when modelling an actuator of some kind which is movng and changing 
orientation in the global frame. 
``mbdyn.mint.twoNodeTranslationalForce`` has methods to calculate 
the relative displacement and velocity of the two nodes to which it 
is linked in a direction parallel to one axis of one of the nodes. 
It can then be used to apply forces to both nodes, also parallel to 
this axis and then transform these forces to forces in the global 
frame suitable for application using the MBDyn external structural 
force element (which expects forces in the global frame). 
