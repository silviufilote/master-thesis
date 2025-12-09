

rng(1);
clc
close all
clearvars
addpath('src');

load ..\worspaces\m3.mat

%% M3 figures for thesis

fs = 22;
lw = 1.2;

% Figura unica con 3 pannelli (1 x 3)
figure
t = tiledlayout(1,3);
t.TileSpacing = 'compact';
t.Padding = 'compact';
set(gcf, 'Position', [100 100 1400 500]);  % finestra larga orizzontale

% === Plot 1: Stations' PGA ===
nexttile;
gs1 = geoscatter(station_data.latitude, station_data.longitude, 80, station_data.pga, 'o', 'filled');
gs1.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic stations' PGA", 'FontWeight', 'bold')
ax = gca;
ax.FontSize = fs;
ax.LineWidth = lw;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
colormap(ax, 'winter');
cb1 = colorbar(ax, 'Location', 'eastoutside');
cb1.Label.String = '%g';
cb1.Label.FontSize = 10;
cb1.Label.FontWeight = 'bold';
cb1.TickLabelInterpreter = 'tex';

% === Plot 2: Smartphones' PSA ===
nexttile;
gs2 = geoscatter(PSA_filtered.latitude, PSA_filtered.longitude, 80, PSA_filtered.PSA, 'o', 'filled');
gs2.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Smartphones' PSA", 'FontWeight', 'bold')
ax = gca;
ax.FontSize = fs;
ax.LineWidth = lw;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
colormap(ax, 'winter');
cb2 = colorbar(ax, 'Location', 'eastoutside');
cb2.Label.String = '%g';
cb2.Label.FontSize = 10;
cb2.Label.FontWeight = 'bold';
cb2.TickLabelInterpreter = 'tex';

% === Plot 3: User reports' CPGA ===
nexttile;
gs3 = geoscatter(CPGA_filtered.latitude, CPGA_filtered.longitude, 80, CPGA_filtered.CPGA, 'o', 'filled');
gs3.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1.2);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("User felt reports' CPGA", 'FontWeight', 'bold')
ax = gca;
ax.FontSize = fs;
ax.LineWidth = lw;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
colormap(ax, 'winter');
cb3 = colorbar(ax, 'Location', 'eastoutside');
cb3.Label.String = '%g';
cb3.Label.FontSize = 10;
cb3.Label.FontWeight = 'bold';
cb3.TickLabelInterpreter = 'tex';
