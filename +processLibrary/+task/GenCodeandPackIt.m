classdef GenCodeandPackIt < padv.Task
    % Generate and package options files to run Polyspace analysis on code
    % generated from Simulink model.

    methods

        function obj = GenCodeandPackIt(options)
            arguments
                options.Name (1,1) string  = 'processLibrary.Task.GenCodeandPackIt';
                options.Title = "Zip Up Generated Code and Details";
                % artifacts the task iterates over
                options.IterationQuery (1,1)  = "padv.builtin.query.FindModels";
                % input artifacts for the task
                options.InputQueries = "padv.builtin.query.GetIterationArtifact";
                % For each input, find dependencies that impact if the
                % task results are up-to-date
                options.InputDependencyQuery = padv.builtin.query.GetDependentArtifacts;
                % where the task outputs artifacts
                options.OutputDirectory = Simulink.fileGenControl('get', 'CodeGenFolder');
            end

            % Superclass constructor
            obj@padv.Task( ...
                options.Name, ...
                Title = options.Title, ...
                IterationQuery = options.IterationQuery, ...
                DescriptionText = "Zip Up generated code and information for Polyspace to run it",...
                InputQueries   = "padv.builtin.query.GetIterationArtifact",...
                InputDependencyQuery=options.InputDependencyQuery);

            % Default Output to the CodeGen Folder, same as generated code
            obj.OutputDirectory = options.OutputDirectory;
        end

        function taskResult = run(obj, input)

            % Generate TaskResult object to save results
            taskResult = padv.TaskResult;

            % Load the model for this task
            modelArtifact = input{1};
            mdlName     = string(erase(modelArtifact.Alias, ".slx"));
            load_system(mdlName);

            % Check if the parameter "PackageGeneratedCodeAndArtifacts" is set to "on" in the active configuration
            chkZipEnabled = obj.isPackagingEnabled(mdlName);

            if chkZipEnabled

                % Generaete the code, in case it has not been generated
                % We intentionally re-run slbuild because its needed for
                % polyspacePackNgo function to work properly
                % (Also, bug in oct 25 release pAdv for for AUTOSAR models with modelRefs)
                slbuild(mdlName);

                % Setup the polyspace options
                % Use BugFinder verification mode to focus on bug detection
                psOpt = pslinkoptions(mdlName);
                psOpt.ResultDir = fullfile('results_$ModelName$');
                psOpt.InputRangeMode = 'FullRange';
                psOpt.ParamRangeMode = 'DesignMinMax';
                psOpt.VerificationMode = 'BugFinder';

                % Generate polyspace options
                zipFile = polyspacePackNGo(mdlName,psOpt);

                % close model without saving
                close_system(mdlName, 0);

                % Update Process Advisor Status and Show Results
                if ~isempty(zipFile)
                    taskResult.Status      = padv.TaskStatus.Pass;
                    taskResult.OutputPaths = string(zipFile);
                    taskResult.Values.Pass = 1;
                else
                    taskResult.Status = padv.TaskStatus.Fail;
                    taskResult.Values.Fail = 1;
                end


            else
                taskResult.Status = padv.TaskStatus.Fail;
                error('Task not possible; please update the configuration to enable packaging of artifacts.');

            end

        end

    end


    methods (Access = private)
        function chkZipEnabled = isPackagingEnabled(~,mdlName)
            %ISPACKAGINGENABLED Returns true if the active configuration enables packaging.
            %
            % This checks the active configuration set (or ref configset)
            % and returns true if the parameter 'PackageGeneratedCodeAndArtifacts' is 'on'.

            % Get active config set (resolve references if needed)
            csActive = getActiveConfigSet(mdlName);
            if isa(csActive, 'Simulink.ConfigSetRef')
                csReal = getRefConfigSet(csActive);
            else
                csReal = csActive;
            end

            % Read parameter confirm its seto to 'on'
            val = get_param(csReal, 'PackageGeneratedCodeAndArtifacts');
            chkZipEnabled = ischar(val) && strcmpi(val, 'on');

        end

    end

end