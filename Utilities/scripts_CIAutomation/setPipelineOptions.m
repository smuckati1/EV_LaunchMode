options = padv.pipeline.GitHubOptions(GeneratorVersion=1);

options.MatlabInstallationLocation = "/opt/matlab/R2025b";
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

pAdvoptions = padv.pipeline.RunProcessOptions();
pAdvoptions.DryRun = false;
pAdvoptions.EnableTaskLogging = true;
pAdvoptions.Force = false;
pAdvoptions.RunWithoutSaving = false;
pAdvoptions.GenerateJUnitForProcess = true;
pAdvoptions.GenerateReport = false;

options.RunprocessCommandOptions = pAdvoptions;


options.EnableArtifactCollection = "always";
options.ArtifactZipFileName = "mbd_pipeline_artifacts";
options.RetentionDays = "90";

options.GenerateReport = true;
options.ReportFormat = "pdf";

% Consider Enabling this in future!
options.EnableOpenTelemetry = false;

options.GeneratedYMLFileName = "simulink_pipeline";
generatorResults = padv.pipeline.generatePipeline(options);