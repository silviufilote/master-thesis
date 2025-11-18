%% 1) Carica lo shapefile
S = shaperead('maps/napoli.shp');

%% 2) Converti tutti i poligoni in polyshape e salvali in una lista
polyList = cell(numel(S),1);
for k = 1:numel(S)
    polyList{k} = polyshape(S(k).X, S(k).Y);
end

%% 3) Crea la griglia
lat = 40.73:(0.001/3):40.91;
lon = 14:(0.002/3):14.26;

[LonGrid, LatGrid] = meshgrid(lon, lat);

% Vettorizza
LonVec = LonGrid(:);
LatVec = LatGrid(:);

%% 4) Calcola mask terra/mare
isLand = false(size(LonVec));

for k = 1:numel(polyList)
    % isinterior richiede vettori della stessa dimensione
    in = isinterior(polyList{k}, LonVec, LatVec);
    isLand = isLand | in;   % un punto è terra se appartiene a qualunque poligono
end

% Ricostruisci la matrice
mask = nan(size(LonGrid));
mask(isLand) = 1;

%% 5) Plot di verifica (non usare geoaxes!)
figure;
imagesc(lon, lat, mask);
set(gca, 'YDir', 'normal');
xlabel('Longitude');
ylabel('Latitude');
title('Mask Campi Flegrei: 1 = Terra, NaN = Mare');
colorbar;
