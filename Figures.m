
rng(1);
clc
close all
clearvars
addpath('src');

load 'worspaces tries'\m3ns.mat  
load("data\input\EQNF_subset_filtered.mat")

%% M3 figures for thesis

fs = 18;
lw = 1.2;

% === Plot 1: Stations' PGA ===
figure
gs1 = geoscatter(station_data.latitude, station_data.longitude, 80, station_data.pga, 'o', 'filled');
gs1.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic stations' PGA", 'FontWeight', 'bold')
ax = gca;
ax.FontSize = fs;
ax.LineWidth = lw;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
colormap('winter');
cb = colorbar(gca, 'Location', 'eastoutside');  % attach to last axes
cb.Label.String = 'g';
cb.Label.FontSize = 10;
cb.Label.FontWeight = 'bold';
cb.TickLabelInterpreter = 'tex';
set(gcf, 'Position', [100 100 800 700]);


% === Plot 2: Smartphones' PSmA ===
figure
gs2 = geoscatter(EQN_data_subset.latitude, EQN_data_subset.longitude, 80, EQN_data_subset.max_acc, 'o', 'filled');
gs2.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Smartphones' PSA", 'FontWeight', 'bold')
colormap('winter');
ax = gca;
ax.FontSize = fs;
ax.LineWidth = lw;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
cb = colorbar(gca, 'Location', 'eastoutside');  % attach to last axes
cb.Label.String = 'g';
cb.Label.FontSize = 10;
cb.Label.FontWeight = 'bold';
cb.TickLabelInterpreter = 'tex';
set(gcf, 'Position', [100 100 800 700]);

% === Plot 3: User Reports' CFI ===
figure
gs3 = geoscatter(EQNF_subset_filtered.latitude, EQNF_subset_filtered.longitude, 80, EQNF_subset_filtered.PSfA, 'o', 'filled');
gs3.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 350, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', [1 0.8 0], 'LineWidth', 1.2);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("User felt reports' CPGA", 'FontWeight', 'bold')
colormap('winter');
ax = gca;
ax.FontSize = fs;
ax.LineWidth = lw;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
cb = colorbar(gca, 'Location', 'eastoutside');  % attach to last axes
cb.Label.String = 'g';
cb.Label.FontSize = 10;
cb.Label.FontWeight = 'bold';
cb.TickLabelInterpreter = 'tex';
set(gcf, 'Position', [100 100 800 700]);

