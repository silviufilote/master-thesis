clc
close all
clearvars

theta = 2;                    % correlation length
gridSides = [50 100];       % 100x100 and 1000x1000
nCases    = numel(gridSides);

% Prealloc per i tempi
tDist   = NaN(nCases,1);      % tempo per pdist2
tCorr   = NaN(nCases,1);      % tempo per exp(-dist/theta)
tSample = NaN(nCases,1);      % tempo per mvnrnd
tTotal  = NaN(nCases,1);      % tempo totale se vuoi

for k = 1:nCases
    n = gridSides(k);
    nPoints = n^2;
    fprintf('\n=== Grid %dx%d (nPoints = %d) ===\n', n, n, nPoints);

    try
        % Coordinate su griglia regolare
        x = 0:n-1;
        y = 0:n-1;
        [X, Y] = meshgrid(x, y);
        coord = [X(:) Y(:)];

        % Timer complessivo
        tStartTotal = tic;

        % 1) Distanze
        tStart = tic;
        dist   = pdist2(coord, coord, "euclidean");
        tDist(k) = toc(tStart);
        fprintf('Time dist (pdist2):            %.3f s\n', tDist(k));

        % 2) Correlazione
        tStart = tic;
        sp_corr = exp(-dist/theta);
        tCorr(k) = toc(tStart);
        fprintf('Time corr (exp(-dist/theta)):  %.3f s\n', tCorr(k));

        % 3) Simulazione GP (Cholesky + estrazione)
        tStart = tic;
        v = mvnrnd(zeros(1, size(dist,1)), sp_corr, 1);
        tSample(k) = toc(tStart);
        fprintf('Time sample (mvnrnd):          %.3f s\n', tSample(k));

        tTotal(k) = toc(tStartTotal);
        fprintf('Total time:                    %.3f s\n', tTotal(k));

        % Reshape per eventuale visualizzazione (solo se non troppo grande)
        if n <= 100
            vGrid = reshape(v, size(X));
            figure;
            imagesc(vGrid);
            clim([-3 3]);
            colorbar;
            axis equal tight;
            title(sprintf('GP sample on %dx%d grid', n, n));
        end

    catch ME
        % Se finisci la memoria, lo segnaliamo e lasciamo NaN nei tempi
        if strcmp(ME.identifier, 'MATLAB:nomem')
            fprintf('Out of memory for %dx%d grid. Skipping timings.\n', n, n);
        else
            rethrow(ME);
        end
    end
end

% Costruisci e stampa la tabella riassuntiva
NumPoints = gridSides'.^2;
TimingTable = table(gridSides', NumPoints, tDist, tCorr, tSample, tTotal, ...
    'VariableNames', {'GridSide', 'NumPoints', 'TimeDist', 'TimeCorr', 'TimeSample', 'TimeTotal'});

fprintf('\n=== Summary table ===\n');
disp(TimingTable);
