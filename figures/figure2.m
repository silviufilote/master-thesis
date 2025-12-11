
rng(1);
clc
close all
clearvars
addpath('src');

load ..\worspaces\m3.mat

%% M3 figures for thesis

fs = 22;
lw = 2;

% === Plot 1: Stations' PGA ===
figure
gs1 = geoscatter(station_data.latitude, station_data.longitude, 80, log(station_data.pga), 'o', 'filled');
gs1.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'LineWidth', 1.5);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic stations' log(PGA)", 'FontWeight', 'bold')
ax = gca;
ax.FontSize = fs;
ax.LineWidth = lw;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
colormap('parula');
cb = colorbar(gca, 'Location', 'eastoutside');  % attach to last axes
cb.Label.String = 'log(%g)';
cb.Label.FontSize = 10;
cb.LineWidth = lw;  
cb.Label.FontWeight = 'bold';
cb.TickLabelInterpreter = 'tex';
set(gcf, 'Position', [100 100 800 700]);


% === Plot 2: Smartphones' PSA ===
figure
gs2 = geoscatter(PSA_filtered.latitude, PSA_filtered.longitude, 80, log(PSA_filtered.PSA), 'o', 'filled');
gs2.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'LineWidth', 1.5);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Smartphones' log(PSA)", 'FontWeight', 'bold')
colormap('parula');
ax = gca;
ax.FontSize = fs;
ax.LineWidth = lw;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
cb = colorbar(gca, 'Location', 'eastoutside');  % attach to last axes
cb.Label.String = 'log(%g)';
cb.Label.FontSize = 10;
cb.LineWidth = lw;
cb.Label.FontWeight = 'bold';
cb.TickLabelInterpreter = 'tex';
set(gcf, 'Position', [100 100 800 700]);

% === Plot 3: User Reports' CGPA ===
figure
gs3 = geoscatter(CPGA_filtered.latitude, CPGA_filtered.longitude, 80, log(CPGA_filtered.CPGA), 'o', 'filled');
gs3.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'LineWidth', 1.5);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("User felt reports' log(CPGA)", 'FontWeight', 'bold')
colormap('parula');
ax = gca;
ax.FontSize = fs;
ax.LineWidth = lw;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
cb = colorbar(gca, 'Location', 'eastoutside');  % attach to last axes
cb.Label.String = 'log(%g)';
cb.Label.FontSize = 10;
cb.LineWidth = lw;
cb.Label.FontWeight = 'bold';
cb.TickLabelInterpreter = 'tex';
set(gcf, 'Position', [100 100 800 700]);

