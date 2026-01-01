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

        function taskResult = run(~, input)

            % Generate TaskResult object to save results
            taskResult = padv.TaskResult;

            % Load the model for this task
            modelArtifact = input{1};
            mdlName     = string(erase(modelArtifact.Alias, ".slx"));
            load_system(mdlName);

            % Ensure codegen settings are setup to create a ZIP file
            % chkZipEnabled = obj.ensurePackagingEnabled(mdlName);

            % Assumes codegen settings are setup to create a ZIP file
            chkZipEnabled = true;

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
                else
                    taskResult.Status = padv.TaskStatus.Fail;
                end
            
            
            else
                taskResult.Status = padv.TaskStatus.Fail;
                error('Task not possible; please update the configuration to enable packaging of artifacts.');
           
            end
                
        end

    end

    % methods(Access=private)
    % 
    %     function chkZipEnabled = ensurePackagingEnabled(mdl)
    %     % ENSUREPACKAGINGENABLED Verifies PackageGeneratedCodeAndArtifacts is 'on'
    %     % on the active configuration (handles both local ConfigSet and ConfigSetRef).
    %     %
    %     % Usage:
    %     %   ensurePackagingEnabled('myModel')
    % 
    % 
    %         % --- Normalize input to a model name string that Simulink accepts ---
    %             if isa(mdl, 'string')
    %                 mdlName = char(mdl);            % convert MATLAB string -> char
    %             elseif ischar(mdl)
    %                 mdlName = mdl;                  % already char
    %             elseif ishghandle(mdl) || ishandle(mdl)
    %                 mdlName = get_param(mdl, 'Name'); % model/block diagram handle
    %             else
    %                 error('Invalid model identifier. Pass a model name (string/char) or handle.');
    %             end
    % 
    %             % Ensure the model is loaded
    %             if ~bdIsLoaded(mdlName)
    %                 load_system(mdlName);
    %             end
    % 
    % 
    %         % Get the active configuration (could be ConfigSet or ConfigSetRef)
    %         csActive = getActiveConfigSet(mdlName);
    % 
    %         % Resolve reference to the actual Simulink.ConfigSet if needed
    %         if isa(csActive, 'Simulink.ConfigSetRef')
    %             csReal = getRefConfigSet(csActive);
    %         else
    %             csReal = csActive;
    %         end
    % 
    %         % Read the parameter value
    %         val = get_param(csReal, 'PackageGeneratedCodeAndArtifacts');
    % 
    %         % Normalize to logical "isOn"
    %         if ischar(val) && strcmpi(val, 'on')
    %             chkZipEnabled = true;
    %         else
    %             chkZipEnabled = false;
    %         end
    %     end
    % 
    % end
   
end