classdef GenInteractiveCompareRprt < padv.builtin.task.GenerateModelComparison
    % Generate and package options files to run Polyspace analysis on code
    % generated from Simulink model.

    properties(Access=private)
        WarningCount = 0;
    end
    methods

        function obj = GenInteractiveCompareRprt(options)
            arguments
                options.Name (1,1) string  = 'processLibrary.diffRprtTask.GenInteractiveCompareRprt';
                options.Title = "Genereate Interactive Diff Report";
                % artifacts the task iterates over
                options.IterationQuery (1,1)  = "padv.builtin.query.FindModels";
                % input artifacts for the task
                    % options.InputQueries = "padv.builtin.query.GetIterationArtifact";
                % For each input, find dependencies that impact if the
                % task results are up-to-date
                    % options.InputDependencyQuery = padv.builtin.query.GetDependentArtifacts;
                % where the task outputs artifacts
                    % options.OutputDirectory = Simulink.fileGenControl('get', 'CodeGenFolder');
            end

            % Built of of existing task, so calling and modifying existing task
            obj@padv.builtin.task.GenerateModelComparison(Name = options.Name);
            obj.Title = options.Title;
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

            % filter the modified files for the MATLAB binary file extensions
            visdiffFileTypes = {'slx'}; % restricting to only SLX compare for now.
            modifiedFiles = modifiedFiles(startsWith(modifiedFiles,['M' char(9)]));
            fileList = modifiedFiles(endsWith(modifiedFiles,visdiffFileTypes));
            fileList = regexprep(fileList,['^M' char(9)],'');

            if isempty(fileList)
                disp('No modified binary files to compare.')
                taskResult.ResultValues.Warn = 1;
                return
            end

            % Generate a comparison report
            for i = 1:numel(fileList)
                diffToAncestor(workDir,string(fileList(i)),currentCommit, prevCommit,reportPath,reportName);
            end


            % Set task result
            taskResult.OutputPaths = file;
            taskResult.Status = padv.TaskStatus.Pass;
            taskResult.ResultValues.Pass = 1;
            
            % Clean up
            iterationArtifact.close();
            % Close models loaded by this task
            padv.util.closeModelsLoadedByTask(PreviouslyLoadedModels=loadedModels);

        end

    end


    methods(Access = private)

        function report = diffToAncestor(tempdir,fileName,branch,target,reportPath,reportName)

            revision = getRevision(tempdir,fileName,branch);
            ancestor = getRevision(tempdir,fileName,target);
            if isempty(revision) || isempty(ancestor)
                report = [];
                return;
            end
            [~, ~, ext] = fileparts(fileName);
            % relpath = strrep(filepath,rootFolder,'');
        
            % Compare models and publish results in a printable report
            % Specify the format using 'pdf', 'html', or 'docx'
                    % name = strrep(strcat(name,ext,'_diff'),'.','_');
            name = reportName;
                    % outputFolder = fullfile(rootFolder,'diffreports',relpath);
            outputFolder = reportPath;
            disp("*** Reporting on " + string(fileName) + " ***");
            switch ext
                case {'.slx','.mdl','.mldatx','.slmx','.slreqx','.mlapp','.m','.ssc'}
                    comp = visdiff(ancestor, revision);
                    filter(comp, 'unfiltered');
                    diffReport = publish(comp,format="html",Name=name,...
                        OutputFolder=outputFolder);
                    diffReport = strrep(diffReport,outputFolder,'');
                    if strcmp(ext,'.slx') || strcmp(ext,'.mdl')
                        [leftHighlightWindow, rightHighlightWindow] = highlightModels(comp);
                        webReport = generateWebview(outputFolder,revision);
                        webReport = strrep(webReport,outputFolder,'');
                        ancestorWebReport = generateWebview(outputFolder,ancestor);
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