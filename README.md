# myex: a MATLAB interface for the Tobii EyeX eye-tracker

myex is a MATLAB interface for the Tobii EyeX eye-tracker. It allows MATLAB users to receive incoming data from the eye-tracker, by providing a data buffer that can receive data from the EyeX, and be queried by the user on demand. Myex enables MATLAB users to take advantage of low-cost, portable eye-tracking technology, ideal for use in gaze-contingent psychophysical paradigms, or for users looking to develop assistive devices for individuals with impaired mobility.		

### Quick Start: Setting up
1. Download the Zip archive and unzip it into an appropriate directory
2. Run MinimalWorkingExample_v1.m in MATLAB

### System Requirements
**Operating system:**
myex is compatible with Windows 7 and Windows 10 (the only platforms supported by the EyeX eye-tracker).

**Programming language:**
myex is compatible with all known versions of MATLAB.

**Additional system requirements:**
myex is designed to interface with the Tobii EyeX eye-tracker (Tobii Technology, Stockholm, Sweden), which requires a USB 3.0 connection.

**Dependencies:**
myex requires is compatible with all versions of the Tobii EyeX Interaction Engine from v1.2.0 onwards (at the time of writing the latest version is v1.9.4). There are no MATLAB dependencies. However, users wishing to compile Myex from source may need to install an appropriate C/C++ compiler (run “mex -setup” from within MATLAB for more info.

### License
GNU GPL v3.0

### Enjoy!
@petejonze  
28/09/2017