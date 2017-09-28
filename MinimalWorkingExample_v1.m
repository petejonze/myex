%% Matlab binding for the Tobii EyeX eye-tracker, by Pete R Jones <petejonze@gmail.com>
%
% Instructions for compiling "myex.c"
% -------------------------------
% Compiling is needed to turn "myex.c" into "myex.mexw32" (or myex.mexw64).
% When compiling, the compiler needs to be able to see the .dll and .lib
% file, and the .h files contained within "./eyex/". When running, the .mex
% file will still need to be able to see the .dll and .lib file (e.g., put
% them in the same local directory).
%
% - Compiling only needs to be done once, on first usage.
% - Must be run in a directory containing:
%       ./eyex (subdirectory containing EyeX.h, EyeXActions.h, etc.)
%       myex.c
%       Tobii.EyeX.Client.dll
%       Tobii.EyeX.Client.lib
% - Note that the .dll and .lib file are found inside the Tobii EyeX SDK
%   E.g., inside: TobiiEyeXSdk-Cpp-0.23.325\lib\x64
%       - Remember that you must use the appropriate .dll/.lib files (x64
%         if compiling for 64bit Matlab, x86 if compiling for 32bit Matlab
%         [even on a  64bit machine])
%       - Remember that the EyeX SDK is not the same as the Tobii SDK for
%         their other ('research grade') eye-trackers.
%
% 32 vs 64 bit
% -------------------------------
% - Note for 32-bit Matlab users:
%       This compiler *did* work: Microsoft Software Development Kit (SDK) 7.1 in C:\Program Files (x86)\Microsoft Visual Studio 10.0
%       The default compiler did *not* work: Lcc-win32 C 2.4.1 in C:\PROGRA~2\MATLAB\R2012b\sys\lcc 
%       (this is because the lcc compiler does not permit variable definition/initialisation on same line)
%       - You can change compiler using mex -setup
%       - You can download the visual studio compiler as part of the
%         Microsoft .Net dev kit (if my memory serves)
% - Note for 64-bit Matlab users:
%       If when you compile you get an error like this:
%           myex.obj : error LNK2019: unresolved external symbol __imp_txFormatObjectAsText referenced in function __txDbgObject 
%       Then you are trying to compile against the 32bit .dll/.lib files.
%       Replace these with the appropriate versions from the x64 SDK
%       directory (see above).
%
% Tobii EyeX engine number
% -------------------------------
% Both the Tobii EyeX Engine and the SDK are regularly updated. This can
% lead to various errors. For example, if you update the EyeX Engine, you
% may start to get this error:
%
%   The connection state is now SERVER_VERSION_TOO_HIGH: this application requires an older version of the EyeX Engine to run.
%
% Or if you try to compile "myex.c" against newer/older-than-expected
% versions of the SDK, you may get various "undeclared identifier errors".
% For example, between SDK_0.23 and SDK_1.3 the following things changed:
%
%   All variables starting "TX_INTERACTIONBEHAVIORTYPE_" now start "TX_BEHAVIORTYPE_"
%   "txInitializeSystem" => "txInitializeEyeX"
%   "TX_SYSTEMCOMPONENTOVERRIDEFLAG_NONE" => "TX_EYEXCOMPONENTOVERRIDEFLAG_NONE"
%
% In the "__precompiled_versions/" directory I include versions compiled
% using the following setups:
%
%   Tobii EyeX Engine (0.8.17.1196), Tobii EyeX Cpp SDK (0.23.325)
%   Tobii EyeX Engine (1.2.0.4583),  Tobii EyeX Cpp SDK (1.3.443)
%
% But as Tobii update their software, you may have to update "myex.c" and
% recompile it accordingly
%
% Version Info
% -------------------------------
%   v0.1 PJ 13/01/2015 -- initial prototype
%   v0.2 PJ 26/09/2016 -- misc tweeks
%   v0.3 PJ 09/05/2017 -- fixed crashes due to memory allocation conflicts
%   v1.0 PJ 09/05/2017 -- JORS version. Removed dependency on psychtoolbox,
%                         improved commenting
%
% --------------------------------------------------
% Copyright 2017: Pete R Jones <petejonze@gmail.com> 
% --------------------------------------------------
%

%% 0. init ----------------------------------------------------------------
clear all %#ok
close all
clc
forceRecompile = false; % set TRUE to recompile the source code

%% 1. run checks ----------------------------------------------------------
switch lower(computer())
        case 'pcwin'
            fprintf('Windows 32 bit detected.\n\nNB: If this is the first time you have run this script, remember to replace the following files with the equivalent files in the ./_precompiled/x86/ directory:\n  myex.mexw64\n  Tobii.EyeX.Client.dll\n  Tobii.EyeX.Client.lib\n\n');
        case 'pcwin64'
            fprintf('Windows 64 bit detected. Good\n\n');
        otherwise
            error('Unsupported architecture');
end
    
%% 2. compile - can skip this if the .mex file is already present ---------
if isempty(which('myex')) || forceRecompile
    fprintf('Compiling mex file...');
    switch lower(computer())
        case 'pcwin'
            libraryDirectory = './_precompiled/x86';
        case 'pcwin64'
            libraryDirectory = './_precompiled/x64';
        otherwise
            error('Unsupported architecture');
    end
    % move necessary library files to the master directory
    copyfile(fullfile(libraryDirectory, 'Tobii.EyeX.Client.dll'), './');
    copyfile(fullfile(libraryDirectory, 'Tobii.EyeX.Client.lib'), './');
    % run compiler
    mex myex.c % compile to generate myex.mexw32 / myex.mexw64
    fprintf(' done!\n');
end


%% 3. add the current directory to the path, for future use ---------------
fprintf('Adding current working directory to the path, for ease of future use\n\n');
addpath(pwd());


%% 4. run -----------------------------------------------------------------
% connect to EyeX Engine
myex('connect') 

% open tracking window, set axes to screen size
hFig = figure();
hold on
hTxt = text(0,0,'waiting for data');
hDat = plot(NaN,NaN,'+', 'MarkerSize',14);
set(gca, 'xlim',[0 1920], 'ylim',[0 1080], 'Ydir','reverse'); % fix resolution, since Matlab's ability to detect current resolution is poor at best
hold off

% clear any data in buffer
myex('getdata');

% allow to track until window closed
x_all = [];
while ishandle(hFig) % check if figure still open
	% get data
    x = myex('getdata');
    
    % if data returned
    if ~isempty(x)
        % determine eyeball distance
        z_mm = x(end,[8 11]);
        isvalid = x(end,[4 5])==1;
        isvalid = isvalid & (z_mm>0.001); % defensive (shouldn't be necessary)
        z_mm = z_mm(isvalid);
        z_mm = nanmean(z_mm);
        
        % update plot
        set(hTxt, 'String', sprintf('Distance = %1.2f cm', z_mm/10));
        set(hDat, 'xdata',x(end,1), 'ydata',x(end,2));
        set(gca, 'XLim',[0 max([x(end,1) get(gca,'XLim')])], 'YLim',[0 max([x(end,2) get(gca,'YLim')])] );
        drawnow();
        
        % add data to store
        x_all = [x_all; x]; %#ok<AGROW> This is innefficient memory-allocation, but ok for present purposes
    else 
        set(hTxt, 'String', 'Waiting for data');
    end
    pause(1/50); % run at 50 Hz
end

% disconnect from EyeX Engine
myex('disconnect')


%% 5. display results -----------------------------------------------------

% check any data returned
if isempty(x_all)
    fprintf('No data was returned\n');
    return;
end

% plot gaze-trace in figure
close all
plot(x_all(:,1), x_all(:,2), '-o');

% print data to console (max 100 rows)
fprintf('\n\n-----------------------------\nRaw Output (100 rows max):\n-----------------------------\n');
fprintf('%s   %s   %s   %s %s   %s  %s  %s   %s  %s  %s   %s\n','GazeX_px','GazeY_px','GazeTimestamp','L','R','LeyeX_mm','LeyeY_mm','LeyeZ_mm','ReyeX_mm','ReyeY_mm','ReyeZ_mm','EyePosTimestamp');     
fprintf('%-9.2f  %-9.2f  %-12.2f    %i %i   %-9.2f %-9.2f %-9.2f  %-9.2f %-9.2f %-9.2f  %-12.2f\n',x_all(end-min(100,size(x_all,1)-1):end,:)')

% Example console output:
%     GazeX_px   GazeY_px   GazeTimestamp   L R   LeyeX_mm  LeyeY_mm  LeyeZ_mm   ReyeX_mm  ReyeY_mm  ReyeZ_mm   EyePosTimestamp
%     1805.11    395.96     480730313.62    1 1   -39.35    142.32    643.69     23.09     146.64    644.32     480730300.88
%     1803.39    409.23     480730329.61    1 1   -39.35    142.32    643.69     23.09     146.64    644.32     480730300.88
%     1812.84    420.17     480730343.49    1 1   -39.43    142.25    643.65     23.01     146.56    644.19     480730331.16
%     1820.69    415.02     480730357.13    1 1   -39.41    142.27    643.71     23.01     146.56    644.19     480730345.61
%     1823.01    404.10     480730373.34    1 1   -39.41    142.23    643.68     23.02     146.52    644.08     480730361.09
%     1823.41    401.34     480730389.24    1 1   -39.46    142.22    643.69     22.98     146.45    644.04     480730376.17
%     1825.76    400.97     480730420.11    1 1   -39.36    142.20    643.67     23.05     146.35    643.88     480730407.21
%     1825.00    377.23     480730435.09    1 1   -39.36    142.21    643.72     23.06     146.28    643.81     480730421.24
%     ...

% fps check
fprintf('\nApprox FPS: %1.2f Hz\n', 1./(mean(diff(x_all(:,3)))/1000));