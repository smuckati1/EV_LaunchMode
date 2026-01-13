classdef GenInteractiveCompareRprt < padv.Task
    % Generate and package options files to run Polyspace analysis on code
    % generated from Simulink model.

    properties
        % Filter the comparison result.
        %    'unfiltered' - Removes all filtering from the comparison
        %    'default'    - Default filtering strategy for comparison. Hide
        %                   nonfunctional changes.
        Filter (1,1) string {mustBeMember(Filter, {'unfiltered', 'default'})} = "default";

        % Name of the generated comparison report.
        ReportName (1,1) string = "$ITERATIONARTIFACT$_Model_Comparison";

        % Path to the generated comparison report.
        ReportPath (1,1) string = fullfile('$DEFAULTOUTPUTDIR$', '$ITERATIONARTIFACT$','model_comparison');

        % Format of the generated comparison report. Must be either pdf, docx, or html.
        ReportFormat (1,1) string {mustBeMember(ReportFormat,{'HTML','PDF', 'DOCX'})} = "HTML";

        % Name of the git branch used for comparison.
        % The report shows the model source on the left and current model
        % on the right.
        MainBranch (1,1) string = "main";
    end

    properties(Access=private)
        WarningCount = 0;
    end
    methods

        function obj = GenInteractiveCompareRprt(options)
            arguments
                % Configurable name, iteration and inputs with their default
                % values
                options.Name (1,1) string  = 'processLibrary.diffRprtTask.GenInteractiveCompareRprt';
                options.Title = "Genereate Interactive Diff Report";
                % artifacts the task iterates over
                options.IterationQuery (1,1)  = "padv.builtin.query.FindModels";

                options.InputQueries = string.empty;
                options.DescriptionText = message('padv_spkg:builtin_text:GenerateModelComparisonDescription').getString();
                options.Instruction = padv.internal.util.getDescription("GenerateModelComparison");
                options.InputDependencyQuery = padv.builtin.query.GetDependentArtifacts;
                options.Licenses = {};
                options.LaunchToolAction = @launchToolAction;
                options.LaunchToolText = message('padv_spkg:text:LaunchToolTextGenerateModelComparison').getString();
            end

            iterationType = "sl_model_file";
            inputQueries = ["padv.builtin.query.GetIterationArtifact", options.InputQueries];
            obj@padv.Task(options.Name, ...
                Title = options.Title, ...
                RequiredIterationArtifactType = iterationType, ...
                IterationQuery = options.IterationQuery, ...
                InputQueries = inputQueries, ...
                DescriptionText = options.DescriptionText, ...
                Instruction= options.Instruction, ...
                Licenses = options.Licenses,...
                LaunchToolAction = options.LaunchToolAction, ...
                LaunchToolText = options.LaunchToolText, ...
                InputDependencyQuery = options.InputDependencyQuery);
        end

        function taskResult = run(obj, input)

            % Construct task result
            taskResult = padv.TaskResult;
            obj.WarningCount = 0;

            % Validate the inputs and throw appropriate errors
            [iterationArtifact, modelFile] = obj.validateInputArtifacts(input);
            
            % Get list of currently loaded models
            iterationArtifact.load();
            loadedModels = get_param(Simulink.allBlockDiagrams(), 'Name');

            % Resolve tokens and get absolute report name and path
            reportPath = convertStringsToChars(obj.resolvePath(obj.ReportPath));
            reportName = convertStringsToChars(obj.resolvePath(obj.ReportName));

            if ~exist(reportPath, 'dir')
                mkdir(reportPath);
            end

            % Restore original directory when done
            currentFolder = pwd;
            c1 = onCleanup(@()(cd(currentFolder)));

            % Create a temporary folder to store the ancestors of the modified models
            workDir = tempname(tempdir);
            mkdir(workDir);
            c2 = onCleanup(@()rmdir(workDir,'s'));

            cp = padv.util.getCurrentProject;
            cd(cp.RootFolder);

            % Get the hash for the current and previous commit
            [~, currentCommit] = system('git rev-parse HEAD');
            currentCommit = strtrim(currentCommit);
            [~, prevCommit] = system('git rev-parse HEAD~1');
            prevCommit = strtrim(prevCommit);

            gitCommand = sprintf('git --no-pager diff --name-status %s %s', currentCommit, prevCommit);
            [status,modifiedFiles] = system(gitCommand);
            if status ~= 0
                error(['git diff failed: ''' gitCommand ''' returned ''' modifiedFiles '''']);
            end
            modifiedFiles = split(modifiedFiles,{char(13),newline});
            modifiedFiles(end) = []; % Removing last element because it is empty

            % filter the modified files for the Input file
            modifiedFiles = modifiedFiles(startsWith(modifiedFiles,['M' char(9)]));
            fileList = modifiedFiles(endsWith(modifiedFiles,modelFile));
            fileList = regexprep(fileList,['^M' char(9)],'');

            if isempty(fileList)
                disp('Artifact was not modified.')
                return
            end

            % Generate a comparison report
            for i = 1:numel(fileList)
                file = obj.diffToAncestor(workDir,string(fileList(i)),currentCommit, prevCommit,reportPath,reportName);
                disp(file)
            end


            % Set task result
            taskResult.OutputPaths = [...
                string(fullfile(reportPath,[reportName '.html'])) ...
                string(fullfile(reportPath,['Unified_' reportName '.html'])) ];
            taskResult.Status = padv.TaskStatus.Pass;
            taskResult.ResultValues.Pass = 1;
            
            % Clean up
            iterationArtifact.close();
            % Close models loaded by this task
            padv.util.closeModelsLoadedByTask(PreviouslyLoadedModels=loadedModels);

        end

        function taskResult = dryRun(obj, input)
            taskResult = padv.TaskResult;

            % Validate the inputs and throw appropriate errors
            obj.validateInputArtifacts(input);

            % Specify outputs
            reportPath = convertStringsToChars(obj.resolvePath(obj.ReportPath));
            reportName = convertStringsToChars(obj.resolvePath(obj.ReportName));
            taskResult.OutputPaths=string(fullfile(reportPath,...
                [reportName, '.', convertStringsToChars(obj.ReportFormat)]));
        end

        function result = launchToolAction(obj, artifact)
            % This function specifies how the Process Advisor app will launch/open
            % the app.  To launch the tool from the
            % Process Advisor app, click the ellipsis(...) for the task,
            % then select 'Compare to Ancestor'

            result = struct('ToolLaunched', false);
            if isempty(artifact)
                result.message = message('padv_spkg:diagnostic:NoArtifactFound').getString();
                return;
            end

            % Check for a git client
            if ~padv.internal.tools.hasGit
                error(message('padv_spkg:builtin_diagnostic:GitClientNotDetected', class(obj)))
            end

            % Restore original directory when done
            currentFolder = pwd;
            c3 = onCleanup(@()(cd(currentFolder)));

            % Get the model name for iteration artifact
            fileName = artifact.ArtifactAddress.getFileAddress;
            modelName = padv.internal.util.getModelNameFromAddress(fileName);

            % Check to see if the model is open.  Only load the tool if the
            % model open.
            if isempty(modelName)
                throw(MException( ...
                    'padv:launchTool', ...
                    message('padv_spkg:diagnostic:NoModelAssociate') ...
                    ));
            end

            % Get environment data needed comparison functions.
            cp = padv.util.getCurrentProject;
            cd(cp.RootFolder);
            workDir = tempname(tempdir);
            mkdir(workDir);

            ancestor = obj.getAncestor(workDir, fileName);

            % Run Comparison
            visdiff(ancestor, fileName);

            result.ToolLaunched = true;
        end

    end

    methods(Access=protected)

        function outputDir = getOutputDirectory(obj)
            outputDir = convertCharsToStrings(obj.ReportPath);
        end

        function setOutputDirectory(obj, value)
            newOutputDir = convertCharsToStrings(value);
            obj.ReportPath = newOutputDir;
        end

    end


    methods(Access = private)

        function report = diffToAncestor(obj,tempdir,fileName,branch,target,reportPath,reportName)

            revision = obj.getRevision(tempdir,fileName,branch);
            ancestor = obj.getRevision(tempdir,fileName,target);
            if isempty(revision) || isempty(ancestor)
                report = [];
                return;
            end
            [~, ~, ext] = fileparts(fileName);
            
            name = reportName;
            outputFolder = reportPath;

            disp("#### Generating Diff for " + string(fileName) + " ####");
            switch ext
                case {'.slx','.mdl','.mldatx','.slmx','.slreqx','.mlapp','.m','.ssc'}
                    comp = visdiff(ancestor, revision);
                    filter(comp, 'unfiltered');
                    diffReport = publish(comp,format="html",Name=name,...
                        OutputFolder=outputFolder);
                    diffReport = strrep(diffReport,outputFolder,'');
                    if strcmp(ext,'.slx') || strcmp(ext,'.mdl')
                        [leftHighlightWindow, rightHighlightWindow] = highlightModels(comp);
                        webReport = obj.generateWebview(outputFolder,revision);
                        webReport = strrep(webReport,outputFolder,'');
                        ancestorWebReport = obj.generateWebview(outputFolder,ancestor);
                        ancestorWebReport = strrep(ancestorWebReport,outputFolder,'');
                        if ~isempty(leftHighlightWindow)
                            delete(leftHighlightWindow);
                        end
                        if ~isempty(rightHighlightWindow)
                            delete(rightHighlightWindow);
                        end
                        generateUnifDiff(outputFolder, diffReport, webReport, ancestorWebReport);
                        bdclose([name '_' matlab.lang.makeValidName(branch)]);
                        bdclose([name '_' matlab.lang.makeValidName(target)]);
                        delete(comp);
                        report = strcat("Unified_", name,'.html');
                    end
                case {'.mat','.fig'}
                    htmlString = matdiff(ancestor,revision);
                    report = fopen(fullfile(outputFolder,strcat(name,'.html')),'w');
                    fwrite(report,htmlString);
                    fclose(report);
                case '.sldd'
                    htmlString = dictdiff(ancestor,revision,'');
                    report = fopen(fullfile(outputFolder,strcat(name,'.html')),'w');
                    fwrite(report,htmlString);
                    fclose(report);
                otherwise
                    warning('Unsupported file type')
            end
            disp("#### Completed Report for " + string(fileName) + " ####");
        end


        function [iterationArtifact, modelFile] = validateInputArtifacts(obj,input)
            % Task needs exactly one model as input. This function
            % validates the same

            % Check for a git client
            if ~padv.internal.tools.hasGit
                error(message('padv_spkg:builtin_diagnostic:GitClientNotDetected', class(obj)))
            end

            % User can give any number of queries to the task for tracking.
            % Removing the upper limit bound on input queries
            if length(input)<1
                error(message('padv_spkg:builtin_diagnostic:inputQueryCount',obj.Name,'1'))
            end

            % Iteration Artifact is always the first input, task opeartes on iteration
            % artifact
            iterationArtifact = input{1};
            [~, cache] = iterationArtifact.inDigitalThread;
            artifactTypes = [iterationArtifact.Type, cache.Type];
            if ~ismember('sl_model_file', artifactTypes) && ~ismember('zc_file', artifactTypes)
                error(message('padv_spkg:builtin_diagnostic:defaultQueriesOverwritten',obj.Name))
            else
                modelFile = iterationArtifact.ArtifactAddress.getFileAddress();
            end

            % This version of the task requires Git integration.
            cp = padv.util.getCurrentProject;
            if ~strcmpi(string(cp.SourceControlIntegration), ...
                    string(getString(message("shared_cmlink:git:GitAdapterName"))))
                error(message('padv_spkg:builtin_diagnostic:MissingGitIntegration',obj.Name))
            end
        end


        function revision = getRevision(~,tempdir,fileName,target)
    
            if isempty(target)
                if exist(fileName, 'file')
                    revision = fullfile(fileName);
                else
                    revision = [];
                end
                return;
            end
        
            [~, name, ext] = fileparts(fileName);
            revision = fullfile(tempdir, name);
            
            % Replace seperators to work with Git and create ancestor file name
            fileName = strrep(fileName, '\', '/');
            revision = strrep(sprintf('%s_%s%s', revision, matlab.lang.makeValidName(target), ext), '\', '/');
            % Build git command to get ancestor from main
            % git show target:models/modelname.slx > modelscopy/modelname_target.slx
            gitCommand = sprintf('git --no-pager show "%s:%s" > "%s"', target, fileName, revision);
            
            [status, response] = system(gitCommand);
            if status ~= 0
                % new model
                warning(['git show failed, but this is normal for models not found in both branches: ''' gitCommand ''' returned ''' response ''''])
                revision = [];
            end
        end


        function report = generateWebview(~,outputFolder,fileName)
            [~, name, ext] = fileparts(fileName);
            % Create a WebView of the models
            switch ext
                case {'.slx','.mdl'}
                    load_system(fileName);
                    if isMATLABReleaseOlderThan("R2023a")
                        report = slwebview(name,LookUnderMasks="All",FollowLinks="on",ViewFile="off", ...
                            PackageFolder=outputFolder);
                    else
                        report = slwebview(name,LookUnderMasks="All",FollowLinks="on",ViewFile="off", ...
                            IncludeSupportingFunctions="on",PackageFolder=outputFolder);
                    end
                    delete(report);
                    report = (fullfile(outputFolder,name,'webview.html'));
                otherwise
                    % do nothing
                    report = [];
            end
        end

        % function ancestor = getAncestor(obj, workDir, fileName)
        %     % Get the ancestor from git
        % 
        %     [~, name, ext] = fileparts(fileName);
        %     ancestor = fullfile(workDir, name);
        % 
        %     % Replace seperators to work with Git and create ancestor file name
        %     fileName = strrep(fileName, '\', '/');
        %     ancestor = strrep(sprintf('%s%s%s',ancestor, "_ancestor", ext), '\', '/');
        % 
        %     commitIDs = obj.getCommitID(fileName);
        %     hasChanges = obj.isModified(fileName);
        %     compBranch = obj.getComparisonBranch();
        %     if ~hasChanges && isvector(commitIDs)
        %         % model has not changed since initial commit
        %         ancestor = fileName;
        %         return
        %     elseif hasChanges || ~strcmp(obj.getCurrentBranch, compBranch)
        %         % model has changed since last commit or we are comparing a
        %         % version of the model from a feature branch to the last
        %         % commit on the main branch
        %         gitCommand = sprintf('git --no-pager show %s:"./%s" > "%s"', compBranch, fileName, ancestor);
        %     else
        %         % comparing model to the previous version on the main
        %         % branch
        %         gitCommand = sprintf('git --no-pager show %s:"./%s" > "%s"', commitIDs(2), fileName, ancestor);
        %     end
        % 
        %     [status, result] = system(gitCommand);
        %     assert(status==0, result);
        % end
        % 
        % function name = getCurrentBranch(~)
        %     % Get the name of the current git branch
        %     gitCommand = sprintf('git --no-pager branch --show-current');
        %     [status, result] = system(gitCommand);
        %     assert(status==0, result);
        %     name = strtrim(result);
        % end
        % 
        % function name = getComparisonBranch(obj)
        %     % Verify MainBranch exists
        %     gitCommand = sprintf('git --no-pager rev-parse --verify %s', obj.MainBranch);
        %     [status, ~] = system(gitCommand);
        %     if status == 0
        %         name = obj.MainBranch;
        %     else
        %         name = obj.getCurrentBranch();
        %         padv.internal.error.warnWithoutBacktrace(message('padv_spkg:builtin_diagnostic:GitBranchNotFound',obj.MainBranch, obj.Name, name));
        %         obj.WarningCount = obj.WarningCount + 1;
        %     end
        % end
        % 
        % function hash = getCommitID(~, fileName)
        %     % Get a list of commit IDs from git log
        %     gitCommand = "git --no-pager log -s --format='%H' -- " + fileName;
        %     [status, hash] = system(gitCommand);
        %     assert(status==0, hash);
        %     hash = strsplit(hash,'\n');
        %     notEmpty = cellfun(@(x) ~isempty(x), hash);
        %     hash = hash(notEmpty);
        %     hash = string(erase(hash, ''''));
        % end
        % 
        % function is = isModified(~, fileName)
        %     % Check to see if the file has been modified
        %     gitCommand = sprintf('git --no-pager diff --name-only %s', fileName);
        %     [status, result] = system(gitCommand);
        %     assert(status==0, result);
        %     is = ~isempty(result);
        % end
    end
end