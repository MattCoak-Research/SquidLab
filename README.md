# SquidLab - A user-friendly program for background subtraction and fitting of magnetization data 

SquidLab is an open-source program free to download for academic use with a full user-friendly graphical interface for performing flexible and robust background subtraction and dipole fitting on magnetization data.

This is a data analysis tool for scientists or engineers investigating the the magnetic properties of materials, liquids, even living cells.

For magnetic samples with small moment sizes or sample environments with large or asymmetric magnetic backgrounds, it can become necessary to separate background and sample contributions to each measured raw voltage measurement before fitting the dipole signal to extract magnetic moments. Originally designed for use with pressure cells on a Quantum Design MPMS3 SQUID magnetometer, SquidLab is a modular object-oriented platform implemented in Matlab with a range of importers for different widely available magnetometer systems (including MPMS, MPMS-XL, MPMS-IQuantum, MPMS3, and S700X models) and has been tested with a broad variety of background and signal types.

<img width="400" alt="image" src="https://github.com/user-attachments/assets/f035032f-076c-4465-bec1-0c6a1b2b6a7a" />


The software allows background subtraction of baseline signals, signal preprocessing, and performing fits to dipole data using Levenberg–Marquardt non-linear least squares or a singular value decomposition linear algebra algorithm that excels at picking out noisy or weak dipole signals. A plugin system allows users to easily extend the built-in functionality with their own importers, processes, or fitting algorithms.

A full description can be found in [Matthew Coak et al., Review of Scientific Instruments 91, 023901 (2020)](https://doi.org/10.1063/1.5137820), and in the accompanying [SciLight article](https://doi.org/10.1063/10.0000720) for a general audience.

<img width="700" alt="image" src="https://github.com/user-attachments/assets/362781a2-7b8f-4f7e-ad4b-d415c928f9a9" />


## Documentation
Click here to download the [manual](SquidLab/doc/SquidLabManual.pdf). The installation comes with Example Data, which the manual talks through the steps of analysing.

> [!TIP]
> Note that in addition to the Graphical User Interface provided, SquidLab comes with two levels of API for batch scripting or more bespoke data processing if required. The manual has some examples, and if you have any issues or questions you are encouraged to contact m.j.coak@bham.ac.uk.


## Installation
There are multiple options below for installing and running SquidLab, both with or without a MATLAB licence, listed roughly easiest-first for each. If you experience any issues you are encouraged to contact m.j.coak@bham.ac.uk.

- - - -

### With a MATLAB Licence

#### MATLAB Online
Click below to run SquidLab in your browser using MATLAB online (login required):

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=MattCoak-Research/SquidLab&file=SquidLab.mlapp&focus=true)

#### Toolbox installation
##### Automatic
SquidLab can be installed within MATLAB (and will be updated automatically), by searching for it in the list of AddOns:

<img width="250" alt="image" src="https://github.com/user-attachments/assets/6e318fe6-8550-4c52-85bb-dba7cfc64cfd" />
<img width="600" alt="image" src="https://github.com/user-attachments/assets/942a694d-93b3-446a-b472-f319e8b90266" />

##### Manual
Alternatively, download the [toolbox file](https://github.com/MattCoak-Research/SquidLab/releases/latest/download/SquidLab.mltbx) and run it (will open MATLAB). 

After either installation, type 'SquidLab;' in the MATLAB command window and hit enter to run. Note that Toolbox installation essentially just copies the source code to a local folder managed by MATLAB; this can be viewed and edited by choosing 'Add-Ons -> Manage Add-Ons', finding SquidLab, expanding the ... button and browsing files. This means the Toolbox version can be edited and extended by the user, open source. The manual explains how new plugins and importers can be created.

#### Source code download

> [!TIP]
> Note that Toolbox installation essentially does this, as noted above. 

To install, download the source code above, add to your MATLAB path then type 'SquidLab;' in the MATLAB command window and hit enter (manual has more details).

- - - -

### Without a MATLAB Licence

Download and run one of the installers below. The MATLAB Runtime (which does not require a paid MATLAB licence) is required to run the installed files, see below. Note that you will not be able to edit or extend the code in these versions.

#### Runtime included (web installer)
(Not currently implemented) - download and run. The installer will download and install the MATLAB Runtime automatically.

#### No Runtime (standalone installer)
Download the [standalone installer](https://github.com/MattCoak-Research/SquidLab/releases/latest/download/SquidLab.Installer.-.No.Runtime.exe
) - download and run. The MATLAB Runtime must be installed on your computer for the programme to then launch, it can be downloaded from Mathworks [here](https://uk.mathworks.com/products/compiler/matlab-runtime.html)

- - - -
