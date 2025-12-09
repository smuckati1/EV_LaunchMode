function genCCode()
% This script is to automate the codeGeneration of models contained in this project

% clean out older shared utils
    scrubSharedUtils();
    
% List names of all models for which code is being generated
    mdlName_C = {'BMS_Software'};
    mdlName_CPP = {'VCU_Software'};

% Get handle to project
    prj = matlab.project.currentProject;
    disp(' ')
    disp("Project: " + prj.Name)
    disp('Generating C/C++ Code...')

% Generate C/C++ Code
    mex -setup C
    slbuild(mdlName_C) 

    mex -setup C++
    slbuild(mdlName_CPP) 
    % Saved in currentProject().SimulinkCodeGenFolder

    mex -setup C % Restoring base setting to C

% Cleanup
    disp('Code Generation complete.')