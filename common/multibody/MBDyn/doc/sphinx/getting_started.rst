***************
Getting Started
***************

The MBDyn solver takes as input a text-based description of the 
multibody dynamics problem which uses a custom input format. The 
MBDyn Toolbox can be used to generate these input files for MBDdyn 
using on normal Matlab code to more easily integrate MBDyn 
simulations into a Matlab program. The toolbox also has methods to 
then run the simulation, and load and post-process the results all 
from Matlab. In addition, co-simulation, where forces are sent to 
MBDyn from Matlab and motion data sent to Matlab from MBDyn on each 
time step is also possible.

Use of the toolbox requires an intermedate knowledge of Matlab. To 
understand in what knowledge is required, read 
:ref:`required-knowledge`.

The MBDyn pre-processing tools which generate the files are based on
an object oriented appoach, elements of the problem are represented as 
classes and a special system class acts as a container for the entire 
collection of input data, conceptually this is shown in 
:numref:`mbdyn_basic_object_diagram`.

.. _mbdyn_basic_object_diagram:

.. figure:: /images/mbdyn_basic_object_diagram.png
	:align: center

	MBDyn Matlab Toolbox object model.

Problems
========

Although :numref:`mbdyn_basic_object_diagram` shows multiple problem 
classes, there is currently only one type of problem available, the 
initial-value problem. This is a problem type for solving the motion 
of the multibody system over time.

Nodes
=====

Nodes come in various types, the most commonly used being structural 
nodes which can have 6 degrees of freedom (position and 
orientation), and therefore describe the kinematics of rigid-body 
motion in space, or 3 degrees of freedom (position) and thus 
describe the kinematics of point mass motion in space. All the 
available node types in MBDyn are:

* abstract
* electric
* hydraulic
* parameter
* structural
* thermal

Not all of these node types are currently implemented in this 
toolbox. Those which are are represented as Matlab classes, all 
ultimately derived from the `mbdyn.pre.node` class.

Elements
========

Elements are things such as forces, couples, mechanical joints and 
bodies which are attached to structural nodes. However, there are 
also a wide range of other element types avaialable in MBDyn. The 
full list of elements available in MBDyn is shown below:

* structural elements:
   * automatic structural
   * beam
   * body
   * couple
   * gravity
   * joint
   * joint regularization
   * plate
* aerodynamic elements:
   * aerodynamic beam2
   * aerodynamic beam3
   * aerodynamic body
   * aeromodal
   * aircraft instruments
   * air properties
   * induced velocity
* electric elements:
   * electric
* hydraulic elements:
   * hydraulic
* output elements:
   * RTAI output
   * stream output
   * stream motion output
* generic elements:
   * bind
   * bulk
   * force
   * genel
   * loadable
   * user defined
* miscellaneous element cards

Again, not every element is yet available in the Matlab toolbox. As 
with the nodes, those which are are represented as Matlab classes, 
all ultimately derived from the ``mbdyn.pre.element`` class.

Drivers
=======

Drivers are special objects which can be required for certain 
configurations (see the MBDyn manual for more information). There is 
currently limited support for these drivers.

Control Data
============

Unlike the parts discussed above, control data does not refer to a 
class, instead this refers to general settings for the problem. These 
settings are accessed though properties and methods of the system 
class.

Example Matlab Script
=====================

The following example sets up and runs a simulation of a double 
pendulum. It also loads results from MBDyn output files, and plots 
some of them. The system to be simulated is shown in 
:numref:`double_pend_diag`. This example does not demonstrate 
cosimulation, where forces are exchanged during simulation between 
Matlab and MBDyn. An example of this can be found later in this 
documentation.

.. _double_pend_diag:

.. figure:: http://www.sky-engin.jp/en/MBDynExamples/ex03/plan_double_rigid_pendulum.png
    :alt: my-picture1

    Double pendulum example geometry.

The pendulum consists of two bodies. One body is attached by a pin to 
a fixed location. The other body is attached to the first by a 
hinge. A script to describe and run the problem is shown in the 
heavily commented listing below.

.. literalinclude:: /examples/example_double_pendulum.m
   :linenos:

When run, the script ultimately produces six figures shown below. 
:numref:`example_d_pen_1` shows the system with it's initial setup, 
produced using the `mbdyn.pre.system.draw ()` method. The remaining 
fgures, :numref:`example_d_pen_2`, :numref:`example_d_pen_3`, 
:numref:`example_d_pen_4`, :numref:`example_d_pen_5`, and 
:numref:`example_d_pen_6` all show results from the simulation and 
produced using the ``mbdyn.postproc`` class.

.. _example_d_pen_1:

.. figure:: /images/example_double_pendulum_1.png
	:align: center

	Double pendulum initial setup.


.. _example_d_pen_2:

.. figure:: /images/example_double_pendulum_2.png
	:align: center

	Double pendulum result plot.
	
	
.. _example_d_pen_3:

.. figure:: /images/example_double_pendulum_3.png
	:align: center

	Double pendulum result plot.
	
	
.. _example_d_pen_4:

.. figure:: /images/example_double_pendulum_4.png
	:align: center

	Double pendulum result plot.
	
	
.. _example_d_pen_5:

.. figure:: /images/example_double_pendulum_5.png
	:align: center

	Double pendulum result plot.


.. _example_d_pen_6:

.. figure:: /images/example_double_pendulum_6.png
	:align: center

	Double pendulum result plot.

The final command in the example, i.e. 

.. literalinclude:: /examples/example_double_pendulum.m
   :start-at: % Animate the entire simulation, saving it in an avi file
   
Animates the simulation in a figure and saves the animation to an 
avi file, the video can be seen below:

.. youtube:: https://www.youtube.com/watch?v=DdoBRinQrEk

Getting Help
============

In general the mbdyn toolbox classes are documented (although this 
is an ongoing project), so to learn more about a class one can use 
the matlab built-in ``help`` and ``doc`` commands. e.g.::

   help mbdyn.pre.reference
   
An API reference containing the same information (actually generated 
from the help for the classes) is provided with this docuement.
 


