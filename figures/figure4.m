

rng(1);
clc
close all
clearvars
addpath('src');

load ..\worspaces\m3.mat

%% M3 figures for thesis

fs = 22;
lw = 1.2;
clim = [-6 0];   % limiti comuni colorbar

figure
t = tiledlayout(1,3);
t.TileSpacing = 'compact';
t.Padding = 'compact';
set(gcf, 'Position', [100 100 1400 500]);

colormap(parula)   % colormap unica (default Matlab)

% === Plot 1: Stations' PGA ===
nexttile;
gs1 = geoscatter(station_data.latitude, station_data.longitude, 80, log(station_data.pga), 'o', 'filled');
gs1.MarkerEdgeColor = 'k';
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'LineWidth', 2);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Seismic stations' log(PGA)", 'FontWeight','bold')

ax1 = gca;
ax1.FontSize = fs;
ax1.LineWidth = lw;
caxis(clim)

cb1 = colorbar;
cb1.Label.String = 'log(g)';
cb1.Label.FontSize = 12;
cb1.Label.FontWeight = 'bold';

% === Plot 2: Smartphones' PSA ===
nexttile;
gs2 = geoscatter(PSA_filtered.latitude, PSA_filtered.longitude, 80, log(PSA_filtered.PSA), 'o', 'filled');
gs2.MarkerEdgeColor = 'k';
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'LineWidth', 2);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("Smartphones' log(PSA)", 'FontWeight','bold')

ax2 = gca;
ax2.FontSize = fs;
ax2.LineWidth = lw;
ax2.LatitudeLabel.String  = '';   % ← rimosso
ax2.LongitudeLabel.String = '';
caxis(clim)

cb2 = colorbar;
cb2.Label.String = 'log(g)';
cb2.Label.FontSize = 12;
cb2.Label.FontWeight = 'bold';

% === Plot 3: User reports' CPGA ===
nexttile;
gs3 = geoscatter(CPGA_filtered.latitude, CPGA_filtered.longitude, 80, log(CPGA_filtered.CPGA), 'o', 'filled');
gs3.MarkerEdgeColor = 'k';
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'LineWidth', 2);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits)
title("User felt reports' log(CPGA)", 'FontWeight','bold')

ax3 = gca;
ax3.FontSize = fs;
ax3.LineWidth = lw;
ax3.LatitudeLabel.String  = '';   % ← rimosso
ax3.LongitudeLabel.String = '';
caxis(clim)

cb3 = colorbar;
cb3.Label.String = 'log(g)';
cb3.Label.FontSize = 12;
cb3.Label.FontWeight = 'bold';

