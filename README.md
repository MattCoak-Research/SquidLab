**A user-friendly program for background subtraction and fitting of magnetization data**

SquidLab is an open-source program free to download for academic use with a full user-friendly graphical interface for performing flexible and robust background subtraction and dipole fitting on magnetization data.

For magnetic samples with small moment sizes or sample environments with large or asymmetric magnetic backgrounds, it can become necessary to separate background and sample contributions to each measured raw voltage measurement before fitting the dipole signal to extract magnetic moments. Originally designed for use with pressure cells on a Quantum Design MPMS3 SQUID magnetometer, SquidLab is a modular object-oriented platform implemented in Matlab with a range of importers for different widely available magnetometer systems (including MPMS, MPMS-XL, MPMS-IQuantum, MPMS3, and S700X models) and has been tested with a broad variety of background and signal types.

The software allows background subtraction of baseline signals, signal preprocessing, and performing fits to dipole data using Levenberg–Marquardt non-linear least squares or a singular value decomposition linear algebra algorithm that excels at picking out noisy or weak dipole signals. A plugin system allows users to easily extend the built-in functionality with their own importers, processes, or fitting algorithms.

A full description can be found in [Matthew Coak et al., Review of Scientific Instruments 91, 023901 (2020)](https://doi.org/10.1063/1.5137820), and in the accompanying [SciLight article](https://doi.org/10.1063/10.0000720) for a general audience.

See the manual for setup instructions (just download the files and add to your MATLAB path then type 'SquidLab;' in the MATLAB command window and hit enter) or click below to **run SquidLab in your browser using MATLAB online**:

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=MattCoak-Research/SquidLab&file=SquidLab.mlapp&focus=true)
