%% Setup
rng(1);
clc
close all
clearvars
addpath('src');

load data/input/EQN_data.mat                            % g acceleration detections -> smarthphones
load data/input/EQN_felt.mat                            % scalar acceleration detections -> smarthphones
load data/input/mask_pga_shakemap.mat                   % mask for kriging 

% Information about the analyzed earthquake
event_info.date = datetime('2025-03-13 00:25:02');      % date of the earthquake
event_info.latitude = 40.82;                            % latitude of the earthquake
event_info.longitude = 14.15;                           % longitude of the earthquake
event_info.depth = 2.5;                                 % depth of the earthquake
event_info.magnitude = 4.4;                             % magnitude of the earthquake

R = 6371;                                               % Earth radius (don't take data that are too far from our area)
data_radius = 10;                                       % km


% Settings for graphs
FontSize = 22;
widthLinesGraphs = 2;


%% INGV stationlist file reading:
% filtering the specific detections associated to our selected event_idx
% from a json file based on the date we have collected before

file_name = ['data/input/stationlist', '.json'];
txt = fileread(file_name);

% create the matlab structure of the station_data file
stationlist = jsondecode(txt);
station_data.latitude = [];
station_data.longitude = [];
station_data.pga = [];                          % response variable im interested into
counter = 1;
for i = 1 : length(stationlist.features)
    pga = stationlist.features(i).properties.pga;
    epi_distance = stationlist.features(i).properties.distance;

    % filtering the accelerations that are about a threshold
    if isnumeric(pga)
        if pga > 0.01
            station_data.pga(counter,1) = pga / 100;                                                    % pga: peak graound acceleration [g] from cm/s^2 to m/s^2 100 factor
            station_data.epi_separation(counter,1) = stationlist.features(i).properties.distance;       % distance from epicenter
            station_data.latitude(counter,1) = stationlist.features(i).geometry.coordinates(2);         % latitude of the station
            station_data.longitude(counter,1) = stationlist.features(i).geometry.coordinates(1);        % longitude of the station
            counter = counter + 1;
        end
    end
end

%% EQN data filtering:
% filtering on: window time, distance, maximum acceleration, on a zone capture inside a squared area

% filtering on window time
L = EQN_shake_sub.data > event_info.date & EQN_shake_sub.data < event_info.date + seconds(10);
EQN_data_subset = EQN_shake_sub(L,:);

% filtering on distance
d = distdim(distance(event_info.latitude, event_info.longitude, EQN_data_subset.latitude, EQN_data_subset.longitude), 'deg', 'km');
L = d < data_radius;
EQN_data_subset = EQN_data_subset(L,:);

% filtering on the maximum acceleration
L = EQN_data_subset.max_acc < 5;
EQN_data_subset = EQN_data_subset(L,:);

% filtering on the zone
L = EQN_data_subset.longitude > 14 & EQN_data_subset.longitude < 14.21 & EQN_data_subset.latitude < 40.88;  % filtering on the zone
EQN_data_subset = EQN_data_subset(L,:);

% Remove duplicate latitude-longitude pairs
[~, uniqueIdx] = unique([EQN_data_subset.latitude, EQN_data_subset.longitude], 'rows');
EQN_data_subset = EQN_data_subset(uniqueIdx, :);

% Change name to PSA (peak smartphone accelearation) is already in [g]
EQN_data_subset.PSA = EQN_data_subset.max_acc;

%% EQN felt filtering:

% filtering on distance
d = distdim(distance(event_info.latitude, event_info.longitude, EQN_felt.latitude, EQN_felt.longitude), 'deg', 'km');
L = d < data_radius;
EQN_felt_subset = EQN_felt(L,:);

% filtering on the maximum intensity -> scalar value
L = EQN_felt_subset.intensity <= 12;
EQN_felt_subset = EQN_felt_subset(L,:);

% filtering on the zone
L = EQN_felt_subset.longitude > 14 & EQN_felt_subset.longitude < 14.21 & EQN_felt_subset.latitude < 40.88;  % filtering on the zone
EQN_felt_subset = EQN_felt_subset(L,:);

% Remove duplicate latitude-longitude pairs
[~, uniqueIdx] = unique([EQN_felt_subset.latitude, EQN_felt_subset.longitude], 'rows');
EQN_felt_subset = EQN_felt_subset(uniqueIdx, :);

% Calcolo della PGA in g secondo Faenza & Michelini (2010) [g]
EQN_felt_subset.PSfA = 10.^((EQN_felt_subset.intensity - 1.68) / 2.58) / 100;  % [g] dividing /100 ottengo m/s^2


%% INGV data filtering
% filtering only on the radius
% stations have accurate accelerations

L = station_data.epi_separation <= data_radius;
station_data.latitude = station_data.latitude(L);
station_data.longitude = station_data.longitude(L);
station_data.pga = station_data.pga(L);
station_data.epi_separation = station_data.epi_separation(L);

%% After filtering the data

% Compute global latitude and longitude limits
all_lat = [station_data.latitude; EQN_data_subset.latitude; EQN_felt_subset.latitude; event_info.latitude];
all_lon = [station_data.longitude; EQN_data_subset.longitude; EQN_felt_subset.longitude; event_info.longitude];

lat_margin = 0 * (max(all_lat) - min(all_lat)); % 10% margin
lon_margin = 0.1 * (max(all_lon) - min(all_lon)); % 10% margin

lat_limits = [min(all_lat) - lat_margin, max(all_lat) + lat_margin];
lon_limits = [min(all_lon) - lon_margin, max(all_lon) + lon_margin];

cl1_lan = [station_data.latitude(9), station_data.latitude(22), station_data.latitude(23), station_data.latitude(7), station_data.latitude(20)];
cl2_lan = [station_data.latitude(4), station_data.latitude(3), station_data.latitude(19)];
cl3_lan = [station_data.latitude(29), station_data.latitude(8), station_data.latitude(28), station_data.latitude(16), station_data.latitude(33)];
cl4_lan = [station_data.latitude(1), station_data.latitude(5), station_data.latitude(6), station_data.latitude(11), ...
       station_data.latitude(12), station_data.latitude(14), station_data.latitude(15), station_data.latitude(17), ...
       station_data.latitude(30), station_data.latitude(31), station_data.latitude(32)];
cl5_lan = [station_data.latitude(18), station_data.latitude(2), station_data.latitude(34), station_data.latitude(24)];
cl6_lan = [station_data.latitude(27), station_data.latitude(10), station_data.latitude(25), station_data.latitude(21), station_data.latitude(26)];
cl7_lan = [station_data.latitude(13)];


cl1_lon = [station_data.longitude(9), station_data.longitude(22), station_data.longitude(23), station_data.longitude(7), station_data.longitude(20)];
cl2_lon = [station_data.longitude(4), station_data.longitude(3), station_data.longitude(19)];
cl3_lon = [station_data.longitude(29), station_data.longitude(8), station_data.longitude(28), station_data.longitude(16), station_data.longitude(33)];
cl4_lon = [station_data.longitude(1), station_data.longitude(5), station_data.longitude(6), station_data.longitude(11), ...
           station_data.longitude(12), station_data.longitude(14), station_data.longitude(15), station_data.longitude(17), ...
           station_data.longitude(30), station_data.longitude(31), station_data.longitude(32)];
cl5_lon = [station_data.longitude(18), station_data.longitude(2), station_data.longitude(34), station_data.longitude(24)];
cl6_lon = [station_data.longitude(27), station_data.longitude(10), station_data.longitude(25), station_data.longitude(21), station_data.longitude(26)];
cl7_lon = [station_data.longitude(13)];


% Define unique colors for each cluster
colors = [
    0.85 0 0;    % Red for cluster 1
    0 0.85 0;    % Green for cluster 2
    0 0 0.85;    % Blue for cluster 3
    0.85 0.85 0; % Yellow for cluster 4
    0.85 0.5 0;  % Orange for cluster 5
    0.5 0 0.5;   % Purple for cluster 6
    0.5 0.5 0;   % Olive for cluster 7
];

% Plot each cluster with a different color
figure
geoscatter(cl1_lan, cl1_lon, 80, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(1, :), 'LineWidth', 1.5); % Red triangles
hold on
geoscatter(cl2_lan, cl2_lon, 80, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(2, :), 'LineWidth', 1.5); % Green triangles
hold on
geoscatter(cl3_lan, cl3_lon, 80, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(3, :), 'LineWidth', 1.5); % Blue triangles
hold on
geoscatter(cl4_lan, cl4_lon, 80, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(4, :), 'LineWidth', 1.5); % Yellow triangles
hold on
geoscatter(cl5_lan, cl5_lon, 80, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(5, :), 'LineWidth', 1.5); % Orange triangles
hold on
geoscatter(cl6_lan, cl6_lon, 80, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(6, :), 'LineWidth', 1.5); % Purple triangles
hold on
geoscatter(cl7_lan, cl7_lon, 80, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(7, :), 'LineWidth', 1.5); % Olive triangles
hold on
geolimits(lat_limits, lon_limits)
ax = gca;
ax.TickLabelFormat = 'dd';
ax.FontSize = FontSize;
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1); % Gold pentagon
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic station locations - clusters", 'FontWeight', 'bold')
ax = gca;
ax.TickLabelFormat = 'dd';
% ax.FontWeight = 'bold';  
ax.FontSize = FontSize;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Position', [0, 0, 1080, 1080])
geoscatter(station_data.latitude, station_data.longitude, 200, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5); % Red triangles
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1); % Gold pentagon
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic station locations (PGA)", 'FontWeight', 'bold')
% lgd = legend(["Seismic stations", "Epicenter"], 'Location', 'southoutside', 'Orientation', 'horizontal')
% lgd.FontSize = 20; 
% lgd.ItemTokenSize = [50, 50]; % adjust this to enlarge legend markers
ax = gca;
ax.TickLabelFormat = 'dd';
ax.LineWidth = widthLinesGraphs;
% ax.FontWeight = 'bold';  
ax.FontSize = FontSize;
% Remove latitude/longitude labels
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';


figure('Position', [0, 0, 1080, 1080])
geoscatter(station_data.latitude, station_data.longitude, 200, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5); % Red triangles
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
hold on
geoscatter(EQN_data_subset.latitude, EQN_data_subset.longitude, 100, 'o', ...
    'MarkerEdgeColor', [0 0.4 1], 'MarkerFaceColor', [0.4 0.7 1], 'LineWidth', 1.2); % Light blue circles
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Stations and smartphone detections (PSA)", 'FontWeight', 'bold')
ax = gca;
ax.TickLabelFormat = 'dd';
ax.LineWidth = widthLinesGraphs;
ax.FontSize = FontSize;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';


figure('Position', [0, 0, 1080, 2000])
geoscatter(station_data.latitude, station_data.longitude, 200, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5); % Red triangles
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
hold on
geoscatter(EQN_felt_subset.latitude, EQN_felt_subset.longitude, 100, 's', ...
    'MarkerEdgeColor', [0.2 0.6 0], 'MarkerFaceColor', [0.5 0.8 0.5], 'LineWidth', 1.2); % Green squares
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Stations and user felt reports (CPGA)", 'FontWeight', 'bold')
ax = gca;
ax.TickLabelFormat = 'dd';
ax.LineWidth = widthLinesGraphs;
ax.FontSize = FontSize;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';



% Create new figure
figure('Position', [100, 100, 500, 300])
axis off  % remove axes

% Create dummy handles for legend symbols
h1 = plot(nan, nan, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5, 'MarkerSize', 10);
hold on
h2 = plot(nan, nan, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1.2, 'MarkerSize', 10);
h3 = plot(nan, nan, 's', 'MarkerEdgeColor', [0.2 0.6 0], 'MarkerFaceColor', [0.5 0.8 0.5], 'LineWidth', 1.2, 'MarkerSize', 10);
h4 = plot(nan, nan, 'o', 'MarkerEdgeColor', [0 0.4 1], 'MarkerFaceColor', [0.4 0.7 1], 'LineWidth', 1.2, 'MarkerSize', 10);

% Create the legend
lgd = legend([h1, h2, h3, h4], ...
    ["Seismic stations", "Epicenter", "Felt report locations (CPGA)", "Smartphone locations (PSA)"], ...
    'Orientation', 'vertical', 'FontSize', FontSize, 'Box', 'on');

lgd.ItemTokenSize = [25, 25];

% Center the legend manually in the figure
set(lgd, 'Units', 'normalized'); 
lgd.Position = [0.3 0.25 0.4 0.5]; % [x y width height] adjust slightly if needed

axis off
set(gca, 'Position', [0 0 1 1]); % remove padding


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


figure
tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

% === Plot 1: Seismic Station Locations ===
nexttile
geoscatter(station_data.latitude, station_data.longitude, 60, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5); % Red triangles
hold on
geoscatter(event_info.latitude, event_info.longitude, 150, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1); % Gold pentagon
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic station locations (PGA)", 'FontWeight', 'bold')
legend(["Seismic stations", "Epicenter"], 'Location', 'southoutside', 'Orientation', 'horizontal')
ax = gca;
ax.TickLabelFormat = 'dd';
% ax.FontWeight = 'bold';  
ax.FontSize = FontSize;


% === Plot 2: Seismic Stations and Smartphones (PSA) ===
nexttile
geoscatter(station_data.latitude, station_data.longitude, 60, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5); % Red triangles
hold on
geoscatter(event_info.latitude, event_info.longitude, 150, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
hold on
geoscatter(EQN_data_subset.latitude, EQN_data_subset.longitude, 30, 'o', ...
    'MarkerEdgeColor', [0 0.4 1], 'MarkerFaceColor', [0.4 0.7 1], 'LineWidth', 1.2); % Light blue circles
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Stations and smartphone detections (PSA)", 'FontWeight', 'bold')
legend(["Seismic stations", "Epicenter", "Smartphone locations (PSA)"], ...
    'Location', 'southoutside', 'Orientation', 'horizontal')
ax = gca;
ax.TickLabelFormat = 'dd';
% ax.FontWeight = 'bold';  
ax.FontSize = FontSize;

% === Plot 3: Seismic Stations and Felt Reports (PSfA) ===
nexttile
geoscatter(station_data.latitude, station_data.longitude, 60, '^', ...
    'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5); % Red triangles
hold on
geoscatter(event_info.latitude, event_info.longitude, 150, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
hold on
geoscatter(EQN_felt_subset.latitude, EQN_felt_subset.longitude, 30, 's', ...
    'MarkerEdgeColor', [0.2 0.6 0], 'MarkerFaceColor', [0.5 0.8 0.5], 'LineWidth', 1.2); % Green squares
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Stations and user felt reports (CPGA)", 'FontWeight', 'bold')
legend(["Seismic stations", "Epicenter", "Felt report locations (CPGA)"], ...
    'Location', 'southoutside', 'Orientation', 'horizontal')
ax = gca;
ax.TickLabelFormat = 'dd';
% ax.FontWeight = 'bold';  
ax.FontSize = FontSize;



%%%%%%%%%%%%%%%%%
figure
tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% === Plot 1: Stations' PGA ===
nexttile
gs1 = geoscatter(station_data.latitude, station_data.longitude, 50, log10(station_data.pga), 'o', 'filled');
gs1.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 150, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1); % Gold pentagon
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic stations' log_{10}(PGA)", 'FontWeight', 'bold')
cb1 = colorbar;
colormap('winter');
cb1.Label.String = "log_{10}(PGA)";
cb1.Label.FontSize = 10;    
cb1.Label.FontWeight = 'bold'; 
cb1.TickLabelInterpreter = 'tex';
ax = gca;
ax.TickLabelFormat = 'dd';
% ax.FontWeight = 'bold';  
ax.FontSize = FontSize;  

% === Plot 2: Smartphones' PGA ===
nexttile
gs2 = geoscatter(EQN_data_subset.latitude, EQN_data_subset.longitude, 50, log10(EQN_data_subset.max_acc), 'o', 'filled');
gs2.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 150, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Smartphones' log_{10}(PSA)", 'FontWeight', 'bold')
cb2 = colorbar;
colormap('winter');
cb2.Label.String = "log_{10}(PSA)";
cb2.Label.FontSize = 10;    
cb2.Label.FontWeight = 'bold'; 
cb2.TickLabelInterpreter = 'tex';
ax = gca;
ax.TickLabelFormat = 'dd';
% ax.FontWeight = 'bold';  
ax.FontSize = FontSize;  

% === Plot 3: Smartphones' Felt PGA ===
nexttile
gs3 = geoscatter(EQN_felt_subset.latitude, EQN_felt_subset.longitude, 50, log10(EQN_felt_subset.PSfA), 'o', 'filled');
gs3.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 150, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("User felt reoports' log_{10}(PSfA)", 'FontWeight', 'bold')
cb3 = colorbar;
colormap('winter');
cb3.Label.String = "log_{10}(PSfA)";
cb3.Label.FontSize = 10;    
cb3.Label.FontWeight = 'bold'; 
cb3.TickLabelInterpreter = 'tex';
ax = gca;
ax.TickLabelFormat = 'dd';
% ax.FontWeight = 'bold';  
ax.FontSize = FontSize;  


%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% Compute common color limits
all_vals = [log10(station_data.pga); log10(EQN_data_subset.max_acc); log10(EQN_felt_subset.PSfA)];
vmin = min(all_vals);
vmax = max(all_vals);

% === Plot 1: Stations' PGA ===
nexttile
gs1 = geoscatter(station_data.latitude, station_data.longitude, 80, log10(station_data.pga), 'o', 'filled');
gs1.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic stations' log_{10}(PGA)", 'FontWeight', 'bold')
colormap('winter');
clim([vmin, vmax])
ax = gca;
ax.TickLabelFormat = 'dd';
ax.FontSize = FontSize;

% === Plot 2: Smartphones' PSmA ===
nexttile
gs2 = geoscatter(EQN_data_subset.latitude, EQN_data_subset.longitude, 80, log10(EQN_data_subset.max_acc), 'o', 'filled');
gs2.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Smartphones' log_{10}(PSmA)", 'FontWeight', 'bold')
colormap('winter');
clim([vmin, vmax])
ax = gca;
ax.TickLabelFormat = 'dd';
ax.FontSize = FontSize;

% === Plot 3: User Reports' CFI ===
nexttile
gs3 = geoscatter(EQN_felt_subset.latitude, EQN_felt_subset.longitude, 80, log10(EQN_felt_subset.PSfA), 'o', 'filled');
gs3.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("User felt reports' log_{10}(CPGA)", 'FontWeight', 'bold')
colormap('winter');
clim([vmin, vmax])
ax = gca;
ax.TickLabelFormat = 'dd';
ax.FontSize = FontSize;

% === Shared Colorbar (Vertical, attached to last plot) ===
cb = colorbar(gca, 'Location', 'eastoutside');  % attach to last axes
cb.Label.String = 'log_{10} acceleration';
cb.Label.FontSize = 10;
cb.Label.FontWeight = 'bold';
cb.TickLabelInterpreter = 'tex';


%% DCM estimation (only spatial)

obj_stem_gridlist_p = stem_gridlist();

%%%% I equation of the DCM model
ground.Y{1} = log10(station_data.pga);                                              % 1st log respose variable
ground.Y_name{1} = 'INGV PGA';
ground.coordinates{1} = [station_data.latitude, station_data.longitude];
ground.X_p{1} = ones(length(ground.Y{1}),1);                                      % costante davanti alla latente => non ho covariate quindi passo matrice di 1
ground.X_p_name{1} = {'constant'};

obj_stem_grid = stem_grid(ground.coordinates{1}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);


% distance from the epicenter, which is based on the depth of the earthquake and
% the distance from the station
x_distance_stations = distdim(distance(event_info.latitude, event_info.longitude, ground.coordinates{1}(:,1), ground.coordinates{1}(:,2)), 'deg', 'km');
x_distance_stations = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_stations/(2*R)).^2);

% covariate: costant, distance from the epicenter, aplification of the wave
ground.X_beta{1} = [ones(length(ground.Y{1}),1) x_distance_stations];
ground.X_beta_name{1} = {'constant', 'distance'};


%%%% II equation of the DCM model:
ground.Y{2} = log10(EQN_data_subset.PSA);        % 2nd log respose varible: smarthphones acceleration
ground.Y_name{2} = 'EQN PSA';
ground.coordinates{2} = [EQN_data_subset.latitude, EQN_data_subset.longitude];

ground.X_p{2} = ones(length(ground.Y{2}),1);    % covariate davanti alla latente costante
ground.X_p_name{2} = {'constant'};

obj_stem_grid = stem_grid(ground.coordinates{2}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);

x_distance_smartphones = distdim(distance(event_info.latitude, event_info.longitude,ground.coordinates{2}(:,1), ground.coordinates{2}(:,2)), 'deg', 'km');
x_distance_smartphones = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_smartphones/(2*R)).^2);

% distance from the epicenter
ground.X_beta{2} = [ones(length(ground.Y{2}),1) x_distance_smartphones];        % covariates
ground.X_beta_name{2} = {'constant', 'distance'};


%%%% III equation of the DCM model:
ground.Y{3} = log10(EQN_felt_subset.PSfA);        % 2nd log respose varible: smarthphones acceleration
ground.Y_name{3} = 'EQN PSA felt';
ground.coordinates{3} = [EQN_felt_subset.latitude, EQN_felt_subset.longitude];

ground.X_p{3} = ones(length(ground.Y{3}),1);    % covariate davanti alla latente costante
ground.X_p_name{3} = {'constant'};

x_distance_smartphones_felt = distdim(distance(event_info.latitude, event_info.longitude,ground.coordinates{3}(:,1), ground.coordinates{3}(:,2)), 'deg', 'km');
x_distance_smartphones_felt = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_smartphones_felt/(2*R)).^2);

% distance from the epicenter
ground.X_beta{3} = [ones(length(ground.Y{3}),1) x_distance_smartphones_felt];        % covariates
ground.X_beta_name{3} = {'constant', 'distance'};

%% Save subsets

EQNF_subset = EQN_felt_subset;
EQNF_subset.constant = ones(length(ground.Y{3}), 1);
EQNF_subset.distance = x_distance_smartphones_felt;
save('filtering/EQNF_subset.mat', 'EQNF_subset');
clear EQNS_subset EQNF_subset

%% load filtered subset

load("data\input\EQNF_subset_filtered.mat")

%%%% III equation of the DCM model:
ground.Y{3} = log10(EQNF_subset_filtered.PSfA);
ground.Y_name{3} = 'EQN PSA felt';
ground.coordinates{3} = [EQNF_subset_filtered.latitude, EQNF_subset_filtered.longitude];

ground.X_p{3} = EQNF_subset_filtered.constant;
ground.X_p_name{3} = {'constant'};

obj_stem_grid = stem_grid(ground.coordinates{3}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);

% distance from the epicenter
ground.X_beta{3} = [EQNF_subset_filtered.constant EQNF_subset_filtered.distance];        % covariates
ground.X_beta_name{3} = {'constant', 'distance'};


%% EDA 
eda.Y = {station_data.pga, EQN_data_subset.PSA, EQN_felt_subset.PSfA};
% Basic descriptive statistics
varNames = {'PGA', 'PSA', 'CPGA'};

for i = 1:3
    data = eda.Y{i};
    fprintf('\n--- Descriptive stats for %s ---\n', varNames{i});
    fprintf('Mean: %.4f\n', mean(data, 'omitnan'));
    fprintf('Std: %.4f\n', std(data, 'omitnan'));
    fprintf('Median: %.4f\n', median(data, 'omitnan'));
    fprintf('Min: %.4f\n', min(data));
    fprintf('Max: %.4f\n', max(data));
end

% Histograms with kernel density overlays
figure('Position',[0 0 1920 600])
for i = 1:3
    subplot(1,3,i)
    histogram(eda.Y{i}, 30, 'Normalization', 'pdf', 'FaceColor', [0.4 0.6 0.8])
    hold on
    [f, xi] = ksdensity(eda.Y{i});
    plot(xi, f, 'r-', 'LineWidth', 1.5)
    title(sprintf('Distribution of %s', varNames{i}))
    xlabel('Value'); ylabel('Density')
    grid on
end
sgtitle('Distribution of ground motion variables')




%% Model

obj_stem_varset_p = stem_varset(ground.Y, ground.Y_name, [], [], ...
    ground.X_beta, ground.X_beta_name, ...
    [], [], ...
    ground.X_p, ground.X_p_name);

% Validation
val_clustering = {};
val_clustering.choosed = ones(6,2);
val_clustering.cluster_coordinates{1} = [9 22 23 7 20];
val_clustering.cluster_coordinates{2} = [4 3 19];
val_clustering.cluster_coordinates{3} = [29 8 28 16 33];
val_clustering.cluster_coordinates{4} = [1 5 6 11 12 14 15 17 30 31 32];
val_clustering.cluster_coordinates{5} = [18 2 34 24];
val_clustering.cluster_coordinates{6} = [27 10 25 21 26];
val_clustering.cluster_coordinates{7} = [13];    % only one point not going to include it into the validation 
clusters = 7;
S_val_sta = [];

for i = 1:clusters - 1
    cluster = val_clustering.cluster_coordinates{i};
    unique_items = unique(cluster); 
    num_to_select = round(size(cluster , 2)/2) - 1;
    
    if num_to_select > 0
        selected_indices = randperm(length(unique_items), num_to_select);
        selected_items = unique_items(selected_indices);
        S_val_sta = [S_val_sta selected_items];
        for k = 1:length(selected_items)
            idx = selected_items(k);
            val_clustering.choosed(end+1, :) = [station_data.latitude(idx), station_data.longitude(idx)];
        end
    end
end

num_total = height(EQN_data_subset);
S_val_sma = randperm(num_total, 1);

num_total = height(EQNF_subset_filtered);
S_val_felt = randperm(num_total, 1);


% model definition
obj_stem_validation = stem_validation({'INGV PGA', 'EQN PSA', 'EQN PSA felt'}, {S_val_sta, S_val_sma, S_val_felt}, 0, {'point','point','point'});
obj_stem_datestamp = stem_datestamp('01-01-2024 00:00:00', '01-01-2024 00:00:00', 1);   % random date D-STEM wants it
obj_stem_modeltype = stem_modeltype('DCM');                                             % stem_data object creation
obj_stem_data = stem_data(obj_stem_varset_p, obj_stem_gridlist_p, [], [], obj_stem_datestamp, obj_stem_validation, obj_stem_modeltype);

% stem_par object creation
obj_stem_par_constraints = stem_par_constraints();
obj_stem_par = stem_par(obj_stem_data, 'exponential',obj_stem_par_constraints);

% obj_stem_model = SP_model_estimation(obj_stem_data, obj_stem_par);
obj_stem_model = stem_model(obj_stem_data, obj_stem_par);
obj_stem_model.stem_data.standardize;

% Starting values
obj_stem_par.beta = obj_stem_model.get_beta0;
obj_stem_par.theta_p = 0.02;                                      % must be provided in [km] regardless of the unit of measure of the gri
obj_stem_par.v_p = [0.2930, 0.1852, 0.0161;
                    0.1852, 0.3552, 0.1051;
                    0.0161, 0.1051, 0.0388];                 % covariance matrix of the latents variables
obj_stem_par.sigma_eps = diag([0.28 0.40 0.90]);             % error variance one for the stations and one for the smarthphones
obj_stem_model.set_initial_values(obj_stem_par);
obj_stem_EM_options = stem_EM_options();
obj_stem_EM_options.exit_tol_par = 0.002;                          % EM algorithm stops if the maximum relative norm of the model parameters between two consecutive iterations EM is below this value
obj_stem_EM_options.max_iterations = 1000;                            % max iterations EM algorithm
obj_stem_model.EM_estimate(obj_stem_EM_options);            
obj_stem_model.set_varcov;                                         % variance-covariance matrix of the estimated model parameters (std)
obj_stem_model.print()
obj_stem_model.print_par()
% obj_stem_model.set_logL;

corrcov(obj_stem_model.stem_par.v_p)

%% Statistics

statistics_md = {};
statistics_md.sigma_eps = obj_stem_model.stem_EM_result.stem_par.sigma_eps;
statistics_md.v_p = obj_stem_model.stem_EM_result.stem_par.v_p;
statistics_md.theta_p = obj_stem_model.stem_EM_result.stem_par.theta_p;

statistics_md.R2_t = obj_stem_model.stem_EM_result.R2;
statistics_md.R2_v = obj_stem_model.stem_validation_result{1}.cv_R2_s;
statistics_md.EM_iterations = obj_stem_model.stem_EM_result.iterations;
statistics_md.res = obj_stem_model.stem_validation_result{1}.res_back;              % measure unit of the problem
statistics_md.RMSE_v = sqrt(mean(statistics_md.res.^2));

%% Residuals analysis
res_sta =  obj_stem_model.stem_validation_result{1}.res;

% Plot residuals
figure;
subplot(2,1,1); autocorr(res_sta); title('ACF of res\_sta');
subplot(2,1,2); plot(res_sta); title('Residuals: res\_sta');

% Autocorrelation test
[h_sta, p_sta] = lbqtest(res_sta);

% Test for ARCH effects (heteroscedasticity)
[h_arch_sta, p_arch_sta] = archtest(res_sta);

% Perform statistical tests
statistics_md.res_test_lbqtest = [h_sta, p_sta];
statistics_md.res_test_archtest = [h_arch_sta, p_arch_sta];

save("worspaces tries\m3ns.mat")

%% PGA mapping
lat = 40.73:(0.001/3):40.91;
lon = 14:(0.002/3):14.26;

[LON,LAT] = meshgrid(lon,lat);
krig_coordinates = [LAT(:) LON(:)];

obj_stem_krig_grid = stem_grid(krig_coordinates, 'deg','regular','pixel',size(LAT),'square', 0.001799/3,0.002376/3);

X_const = ones(length(krig_coordinates),1);
X_distance = distdim(distance(event_info.latitude, event_info.longitude, krig_coordinates(:,1), krig_coordinates(:,2)), 'deg', 'km');
X_distance = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(X_distance/(2*R)).^2);

X_krig = [X_const, X_distance];

obj_stem_krig_data = stem_krig_data(obj_stem_krig_grid, X_krig, {'constant','distance'});
obj_stem_krig = stem_krig(obj_stem_model, obj_stem_krig_data);

obj_stem_krig_options = stem_krig_options();
obj_stem_krig_options.block_size = 500;

obj_stem_krig_result = obj_stem_krig.kriging(obj_stem_krig_options);

%% PGA ShakeMap
pga_spatial_prediction = obj_stem_krig_result{1};
pga = pga_spatial_prediction.y_hat;
var_pga = pga_spatial_prediction.diag_Var_y_hat;

% PGA and its variance (uncertainty) are backtransformed and masked
pga_shakemap.pga = 10.^(pga + var_pga/2);
% pga_shakemap.pga = exp(pga + sqrt(var_pga));
pga_shakemap.var_pga = (10.^(var_pga)-1) .* 10.^(2*pga+var_pga);
pga_shakemap.var_pga_logscale = var_pga;
pga_shakemap.lat = LAT;
pga_shakemap.lon = LON;

% Shapefiles of napoli - use geoplot to create borders
borders = readgeotable("maps\napoli.shp");
italy = borders(strcmp(borders.reg_name, 'Campania'), :);

figure                                             
gs1 = geoscatter(LAT(:), LON(:), 10, pga_shakemap.pga(:));
alpha(0.6); % Transparency so coastlines and borders are visible
geobasemap("streets-light") % Set basemap
colormap('parula');  % Apply cool colormap here
colorbar;
c2 = colorbar;
c2.Label.String = "Estimated PGA (g)"; % Label for the colorb
c2.Label.FontSize = 10;    
c2.Label.FontWeight = 'bold'; 
c2.TickLabelInterpreter = 'tex';
hold on
geoplot(italy, 'k', 'LineWidth', 2);  % 'k' = black line
title("Shakemap employing trivariate spatial model")
geolimits(lat_limits, lon_limits)
hold on
geoscatter(event_info.latitude, event_info.longitude, 100, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', 'LineWidth', 1.5);
ax = gca;
ax.TickLabelFormat = 'dd';
% ax.FontWeight = 'bold';  
ax.FontSize = 12;

save("worspaces tries\m3ns.mat")