
rng(1);
clc
close all
clearvars
addpath('src');

load ..\worspaces\m3.mat

%% M3 figures for thesis

fs = 22;
lw = 2;

figure('Position', [0, 0, 1080, 1080])
geoscatter(station_data.latitude, station_data.longitude, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5); % INGV stations
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1); % epicenter
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic station locations (PGA)", 'FontWeight', 'bold')
ax = gca;
ax.TickLabelFormat = 'dd';
ax.LineWidth = lw;
ax.FontSize = fs;
% Remove latitude/longitude labels
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';


figure('Position', [0, 0, 1080, 1080])
geoscatter(station_data.latitude, station_data.longitude, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5); % INGV stations
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1); % epicenter
hold on
geoscatter(PSA_filtered.latitude, PSA_filtered.longitude, 100, 'o', 'MarkerEdgeColor', [0 0.4 1], 'MarkerFaceColor', [0.4 0.7 1], 'LineWidth', 1.2); % smarthphones
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Stations and smartphone detections (PSA)", 'FontWeight', 'bold')
ax = gca;
ax.TickLabelFormat = 'dd';
ax.LineWidth = lw;
ax.FontSize = fs;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';


figure('Position', [0, 0, 1080, 2000])
geoscatter(station_data.latitude, station_data.longitude, 200, '^', 'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0.85 0 0], 'LineWidth', 1.5); 
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
hold on
geoscatter(CPGA_filtered.latitude, CPGA_filtered.longitude, 100, 's', 'MarkerEdgeColor', [0.2 0.6 0], 'MarkerFaceColor', [0.5 0.8 0.5], 'LineWidth', 1.2); 
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Stations and user felt reports (CPGA)", 'FontWeight', 'bold')
ax = gca;
ax.TickLabelFormat = 'dd';
ax.LineWidth = lw;
ax.FontSize = fs;
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
    'Orientation', 'vertical', 'FontSize', fs, 'Box', 'on');

lgd.ItemTokenSize = [25, 25];

% Center the legend manually in the figure
set(lgd, 'Units', 'normalized'); 
lgd.Position = [0.3 0.25 0.4 0.5]; % [x y width height] adjust slightly if needed

axis off
set(gca, 'Position', [0 0 1 1]); % remove padding
