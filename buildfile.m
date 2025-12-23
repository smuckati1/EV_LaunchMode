
% buildfile.m
function plan = buildfile
% Define a MATLAB Build Tool plan with a target that unzips Pack-N-Go and runs Polyspace.

import matlab.buildtool.*;
plan = Plan;

% Parameters (adjust to your project)
zipName   = "genCodeArchive.zip";                 % Code archive name produced by codegen + packNGo
resultsDir= fullfile("PA_Results","polyspace_results"); % Where to store Polyspace results
polyspaceBin = "";                                % If needed, set Polyspace bin dir (e.g., Windows path)

plan("polyspacePackNGoAnalyze") = task( ...
    Dependencies=[], ...
    Actions=@() runPolyspacePackNGo(zipName, resultsDir, polyspaceBin));
