function results = runProjectTests_MiL(arg1, varargin)
% Run this function execute all the Model-in-loop (MiL) tests contained in this project. 
% The first argument indicates which model tests are to be run. Possible
% input arguments are 'batt','vcu', 'sysStudy' or 'all'.
% An optional input is to include the Name-value argument of "IncludeCov","true"
% (both inputs as strings) in order to generate coverage reports as a part of the test
% (disabled by default). Examples of executing this function:
% >> runProjectTests_MiL('all')
% >> runProjectTests_MiL('batt',"IncludeCov","true")


genCompareReport = false;
if nargin == 3
    if strcmp(varargin{1},"IncludeCov")
        if strcmp(varargin{2},"true")
            genCompareReport = true;
        end
    else
        error(['Invalid {Name, Value} argument pair provided.' ...
            ' Please provide the necessary inputs for this function. ' ...
            'Refer to the help section for this function for more details ("help runProjectTests_MiL")']);
    end
end

% List names of all test files
    switch arg1
        case 'batt'
            testsName = {'BMS_Tests'};
        case 'vcu'
            testsName = {'EV2M_VCU_MiLtests'};
        case 'sysStudy'
            testsName = {'EV_SysLevel_MiL'};
        case 'all'
            testsName = {'BMS_Tests','EV2M_VCU_MiLtests','EV_SysLevel_MiL'};
        otherwise
            testsName = {'BMS_Tests','EV2M_VCU_MiLtests','EV_SysLevel_MiL'};
    end
    level = 'mil';
    results = [];

% Get handle to project
    prj = matlab.project.currentProject;
    disp(' ')
    disp("Project: " + prj.Name)

% Create directory to save the test results
    fldrloc = fullfile(prj.RootFolder, 'GeneratedArtifacts','TestResults',level);
    if isfolder(fldrloc)
    else
        mkdir(fldrloc)
    end

for i = 1:length(testsName)
    
    disp(['Running Model Tests from: ' testsName{i}])
    % Load test file and setup plugins to generate usable test reports    
        sltest.testmanager.load([testsName{i} '.mldatx']);
    
        import matlab.unittest.TestSuite
        suite = testsuite([testsName{i} '.mldatx']);
        
        import matlab.unittest.TestRunner
        myrunner = TestRunner.withNoPlugins;
    
        % Publish Results as MLDATX
            import sltest.plugins.TestManagerResultsPlugin
            mldatxFileName = fullfile(prj.RootFolder,...
                'GeneratedArtifacts','TestResults',level,[testsName{i} '_Results.mldatx']);
            tmr = TestManagerResultsPlugin('ExportToFile',mldatxFileName); 
            addPlugin(myrunner,tmr)

        % Publish Results as PDF
            import matlab.unittest.plugins.TestReportPlugin
            pdfFile = fullfile(prj.RootFolder,'GeneratedArtifacts','TestResults',level,[testsName{i} '.pdf']);
            trp = TestReportPlugin.producingPDF(pdfFile);
            addPlugin(myrunner,trp)

        % Publish Results as TAP Report and JUnitFormat
            import matlab.unittest.plugins.TAPPlugin
            import matlab.unittest.plugins.XMLPlugin
            import matlab.unittest.plugins.ToFile

            tapFile = fullfile(prj.RootFolder,'GeneratedArtifacts','TestResults',level,[testsName{i} '.tap']);
            tap = TAPPlugin.producingVersion13(ToFile(tapFile));
            addPlugin(myrunner,tap)

            xmlFile = fullfile(prj.RootFolder,'GeneratedArtifacts','TestResults',level,[testsName{i} '_results.xml']);
            p = XMLPlugin.producingJUnitFormat(xmlFile);
            addPlugin(myrunner,p)

        % Publish Coverage Report
        if genCompareReport == true
            import sltest.plugins.coverage.CoverageMetrics
            cmet = CoverageMetrics('Decision',true,'Condition',true,'MCDC',true);

            import sltest.plugins.coverage.ModelCoverageReport
            import matlab.unittest.plugins.codecoverage.CoberturaFormat

            rptfile = fullfile(prj.RootFolder,'GeneratedArtifacts','TestResults',level,[testsName{i} '_cov.xml']);
            rpt = CoberturaFormat(rptfile);

            import sltest.plugins.ModelCoveragePlugin
            mcp = ModelCoveragePlugin('Collecting',cmet,'Producing',rpt);

            addPlugin(myrunner,mcp)
                % Turn off command line warnings:
                warning off Stateflow:cdr:VerifyDangerousComparison
                warning off Stateflow:Runtime:TestVerificationFailed
        end

    % Run the tests
        result = run(myrunner,suite);
        results = [results result];

end

disp('Tests complete.')

% Generate baseline CSVs of tests of full components
    % writeCSV_BMS()
    % writeCSV_VCU()
    
% Cleanup
    sltest.testmanager.clearResults
    sltest.testmanager.clear