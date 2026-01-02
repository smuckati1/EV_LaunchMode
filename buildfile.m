function plan = buildfile

    % Define a MATLAB Build Tool plan with a target that unzips Pack-N-Go and runs Polyspace.
    import matlab.buildtool.*;
    %plan = Plan;
    
    plan = buildplan(localfunctions);
    
    % Make the "polyspacePackNGoAnalyze" task the default task in the plan
    plan.DefaultTasks = "polyspacePackNGoAnalysis";
end

function polyspacePackNGoAnalysisTask(~)
% Define the task for the Polyspace Pack-N-Go analysis

    % Parameters (adjust to your project)
    codeGenFile = Simulink.fileGenControl('get', 'CodeGenFolder');
    zipName   = fullfile(codeGenFile, 'VCU_Software.zip');                 % Code archive name produced by codegen + packNGo
    resultsDir= fullfile("PA_Results","polyspace_results"); % Where to store Polyspace results
    polyspaceBin = "";
    runPolyspacePackNGo(zipName, resultsDir, polyspaceBin);

end