matlabVersion = "R2025b";

GHoptions = setupGitHubOptions(matlabVersion);
genPipeline = padv.pipeline.generatePipeline(GHoptions);
disp(genPipeline.GeneratedPipelineFiles)

GLoptions = setupGitLabOptions(matlabVersion);
genPipeline = padv.pipeline.generatePipeline(GLoptions);
disp(genPipeline.GeneratedPipelineFiles)

ADOoptions = setupAzureOptions(matlabVersion);
genPipeline = padv.pipeline.generatePipeline(ADOoptions);
disp(genPipeline.GeneratedPipelineFiles)



function options = setupAzureOptions(matlabVersion)
    options = padv.pipeline.AzureDevOpsOptions(GeneratorVersion=1);
    
    options.MatlabInstallationLocation = strcat("/opt/matlab/", matlabVersion);
    options.ShellEnvironment = "bash";
    options.UseMatlabPlugin = true;
    
    % Wont be used but still specify in case you deice to change the runner to
    % self-hosted
    options.MatlabLaunchCmd = strcat ("matlab-batch");
    options.AddBatchStartupOption = false;
    
    options.StopOnStageFailure = true;
    options.PipelineArchitecture = padv.pipeline.Architecture.SerialStagesGroupPerTask;
    options.EnablePipelineCaching = true;
    
    % Use the padv.pipeline.RunProcessOptions object to specify how your generated pipeline files invoke the runprocess function. 
    pAdvoptions = setRunProcessOptns();
    options.RunprocessCommandOptions = pAdvoptions;
    
    
    options.EnableArtifactCollection = "always";
    options.ArtifactZipFileName = "mbd_pipeline_artifacts";
    
    options.GenerateReport = true;
    options.ReportFormat = "pdf";
    
    % Consider Enabling this in future!
    options.EnableOpenTelemetry = false;
    
    options.GeneratedYMLFileName = "simulink_pipeline_AzureDevOps";
end


function options = setupGitHubOptions(matlabVersion)
    options = padv.pipeline.GitHubOptions(GeneratorVersion=1);
    
    options.MatlabInstallationLocation = strcat("/opt/matlab/", matlabVersion);
    options.RunnerLabels = 'ubuntu-latest';
    options.ShellEnvironment = "bash";
    
    options.UseMatlabPlugin = true; % Setup to use matlab-actions/run-build@v2
    
    % Wont be used but still specify in case you deice to change the runner to
    % self-hosted
    options.MatlabLaunchCmd = "matlab-batch";
    options.AddBatchStartupOption = false;
    
    options.StopOnStageFailure = true;
    options.PipelineArchitecture = padv.pipeline.Architecture.SerialStagesGroupPerTask;
    options.EnablePipelineCaching = true;
    
    % Use the padv.pipeline.RunProcessOptions object to specify how your generated pipeline files invoke the runprocess function. 
    pAdvoptions = setRunProcessOptns();
    options.RunprocessCommandOptions = pAdvoptions;
    
    options.EnableArtifactCollection = "always";
    options.ArtifactZipFileName = "mbd_pipeline_artifacts";
    options.RetentionDays = "90";
    
    options.GenerateReport = true;
    options.ReportFormat = "pdf";
    
    % Consider Enabling this in future!
    options.EnableOpenTelemetry = false;
    
    options.GeneratedYMLFileName = "simulink_pipeline_GitHubActions";
end


function options = setupGitLabOptions(matlabVersion)
    options = padv.pipeline.GitLabOptions(GeneratorVersion=1);
    
    options.MatlabInstallationLocation = strcat("/opt/matlab/", matlabVersion);
    options.Tags = 'on-prem';
    
    % Wont be used but still specify in case you deice to change the runner to
    % self-hosted
    options.MatlabLaunchCmd = strcat ("mw -using B", matlabVersion,"d matlab");
    options.AddBatchStartupOption = true;
    
    options.StopOnStageFailure = true;
    options.PipelineArchitecture = padv.pipeline.Architecture.SerialStagesGroupPerTask;
    options.EnablePipelineCaching = true;
    
    % Use the padv.pipeline.RunProcessOptions object to specify how your generated pipeline files invoke the runprocess function. 
    pAdvoptions = setRunProcessOptns();
    options.RunprocessCommandOptions = pAdvoptions;
    
    options.EnableArtifactCollection = "always";
    options.ArtifactZipFileName = "mbd_pipeline_artifacts";
    options.ArtifactsExpireIn = "90 days";
    
    options.GenerateReport = true;
    options.ReportFormat = "pdf";
    
    % Consider Enabling this in future!
    options.EnableOpenTelemetry = false;
    
    options.GeneratedYMLFileName = "simulink_pipeline_GitLab-ci";
end


function pAdvoptions = setRunProcessOptns()
pAdvoptions = padv.pipeline.RunProcessOptions();
pAdvoptions.DryRun = false;
pAdvoptions.EnableTaskLogging = true;
pAdvoptions.Force = false;
pAdvoptions.RunWithoutSaving = false;
pAdvoptions.RerunErroredTasks = true;
pAdvoptions.RerunFailedTasks = true;
pAdvoptions.GenerateJUnitForProcess = true;
pAdvoptions.GenerateReport = false;
end