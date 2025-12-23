
function runPolyspacePackNGo(zipName, resultsDir, polyspaceBin)
%RUNPOLYSPACEPACKNGO  Unzip Pack-N-Go archive and run Polyspace using -options-file.
% zipName     : Name or path of the generated code archive (e.g., 'genCodeArchive.zip')
% resultsDir  : Results output folder (will be created if needed)
% polyspaceBin: Optional path to Polyspace bin (e.g., 'C:\Program Files\Polyspace\R2025b\polyspace\bin')

    arguments
        zipName (1,1) string
        resultsDir (1,1) string
        polyspaceBin (1,1) string = ""
    end

    % Resolve paths relative to project root if needed
    if ~isfile(zipName)
        error("Pack-N-Go zip not found: %s", zipName);
    end

    if ~exist(resultsDir, 'dir')
        mkdir(resultsDir);
    end

    % Unzip to a temp folder
    tmpRoot = fullfile(tempdir, "polyspace_packngo_unzipped_" + string(datetime('now','Format','yyyyMMddHHmmss')));
    mkdir(tmpRoot);
    unzip(zipName, tmpRoot);

    % Find 'polyspace' folder
    psDir = findPolyspaceDir(tmpRoot);
    if psDir == ""
        error("Could not find 'polyspace' folder under %s", tmpRoot);
    end

    % Pick an options file
    optFile = pickOptionsFile(psDir);
    if optFile == ""
        error("No options file found in %s", psDir);
    end

    % Compose Polyspace command
    cmd = "polyspace-bug-finder -options-file " + quote(optFile) + " -results-dir " + quote(resultsDir);

    % Prepend Polyspace bin to PATH if provided
    if polyspaceBin ~= ""
        addToPath(polyspaceBin);
    end

    % Run Polyspace
    status = system(cmd);
    if status ~= 0
        error("Polyspace command failed with status %d", status);
    end

    fprintf("Polyspace analysis completed. Results: %s\n", resultsDir);
end

function dirPath = findPolyspaceDir(rootFolder)
    d = dir(fullfile(rootFolder, '**', 'polyspace'));
    if isempty(d)
        dirPath = "";
    else
        dirPath = string(d(1).folder);
    end
end

function optFile = pickOptionsFile(psDir)
    candidates = [ ...
        dir(fullfile(psDir, '*bug*finder*.txt')); ...
        dir(fullfile(psDir, '*bug*finder*.options')); ...
        dir(fullfile(psDir, '*.txt')); ...
        dir(fullfile(psDir, '*.options')) ];
    if isempty(candidates)
        optFile = "";
    else
        optFile = string(fullfile(candidates(1).folder, candidates(1).name));
    end
end

function s = quote(str)
    s = '"' + str + '"';
end

function addToPath(binFolder)
    if ispc
        setenv('PATH', binFolder + ";" + getenv('PATH'));
    else
        setenv('PATH', binFolder + ":" + getenv('PATH'));
    end
end
