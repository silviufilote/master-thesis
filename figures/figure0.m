
rng(1);
clc
close all
clearvars
addpath('src');

load ..\worspaces\m3.mat

%% M3 figures for thesis

fs = 22;
lw = 2;



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
    0 0.85 0.85;  % Cyan for cluster 4
    0.85 0.5 0;  % Orange for cluster 5
    0.5 0 0.5;   % Purple for cluster 6
    0.5 0.5 0;   % Olive for cluster 7
];

% Plot each cluster with a different color
figure('Position', [0, 0, 1080, 1080])
geoscatter(cl1_lan, cl1_lon, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(1, :), 'LineWidth', lw); % Red triangles
hold on
geoscatter(cl2_lan, cl2_lon, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(2, :), 'LineWidth', lw); % Green triangles
hold on
geoscatter(cl3_lan, cl3_lon, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(3, :), 'LineWidth', lw); % Blue triangles
hold on
geoscatter(cl4_lan, cl4_lon, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(4, :), 'LineWidth', lw); % Cyan triangles
hold on
geoscatter(cl5_lan, cl5_lon, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(5, :), 'LineWidth', lw); % Orange triangles
hold on
geoscatter(cl6_lan, cl6_lon, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(6, :), 'LineWidth', lw); % Purple triangles
hold on
geoscatter(cl7_lan, cl7_lon, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', colors(7, :), 'LineWidth', lw); % Olive triangles
hold on
geolimits(lat_limits, lon_limits)
ax = gca;
ax.TickLabelFormat = 'dd';
ax.FontSize = fs;
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 2); % Gold pentagon
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic station locations - clusters", 'FontWeight', 'bold')
ax = gca;
ax.TickLabelFormat = 'dd';
ax.LineWidth = lw; 
ax.FontSize = fs;