# Matlab_bitscope_micro
This is an example of how to interface BitScope (http://www.bitscope.com/) Micro (http://www.bitscope.com/product/BS05/)
to matlab using python. It was developed as a minor project in an introductory MatLab course at Chalmers Technology University (http://www.chalmers.se/en/Pages/default.aspx).

It uses a modfied version of machine_scope and utlities that Bruce Tulloch developed
in the bitbucket PiLab Project (https://bitbucket.org/bitscope/pilab/src/9eefac861818?at=default).
Thanks to Bruce Tulloch for providing the PiLab. As no license could be found, more than it is open source this is 
also open source. I take NO RESPOSIBILITES using this code.

It has been tested on Linux Mint 18 and Macbook (OS X). 

Dependencies: Python 2.7, pyserial, MATLAB (2016b).

The main.m matlab script provides means to start the wave generator in the bitscope and take 1024 samples and displaying the result in a gui window via channel A or B if connected to the wave generator output via probes. It has rudimentary functions such as save the samples to a file, to MatLabs workspace and make a few calclations on the sampled signals. It has limited functions regarding ranges, trigger, et.c..

main.m - Load the python library, test that bitscope is connected and the call the matlab gui scope.
scope.m - The gui event functions.
scope.fig - used by the gui.
scope.py - wrapper to machine_scope import machine.py and machines and utlities.
machines - The home of machine_scope.py state machine that communicates with the BitScope Virtual Machine
utlilties - The home of serial_tools.py and tools.py support functions to machine_scope.py

screenshot.jpg - A screenshot of the gui.

To execute:
Connect  channel probe A to the wave generator outputs or the BitScope micro.
Start MatLab and change to the directory of the main.m and load it and execute it.

/Klas


