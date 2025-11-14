clc
clearvars
close all

load data/red_zone/EQN_users_coordinates.mat
load data/red_zone/campania_region_polygon.mat
load data/red_zone/red_zone_polygon.mat
load data/red_zone/red_zone_polygon_highres.mat
load data/red_zone/red_zone_northern_limit.mat
load data/red_zone/INGV_stations.mat

load data/input/event_list.mat

load data/output/anomaly_smartphones0_stations1.mat
anomaly_stations_only=anomaly;
load data/output/anomaly_smartphones1_stations0.mat
anomaly_smartphones_only=anomaly;
load data/output/anomaly_smartphones1_stations1.mat
load data/output/anomaly_input_data.mat
load data/output/pga_spatial_prediction.mat
load data/output/pga_model.mat

load figures/colormaps.mat
load figures/mask_pga_map.mat
load figures/mask_anomaly_map.mat

%% Data preparation
station_pga = exp(pga_model.stem_data.stem_varset_p.Y{1});

flag_compute_pga_mask=0;
flag_compute_anomaly_mask=0;

event_idx=1;

eq_latitude = event_list.latitude(event_idx);
eq_longitude = event_list.longitude(event_idx);
eq_depth = event_list.depth(event_idx);
eq_date = event_list.date(event_idx);
eq_magnitude = event_list.magnitude(event_idx);

LAT_pga = pga_spatial_prediction.stem_grid.coordinate(:,1);
LON_pga = pga_spatial_prediction.stem_grid.coordinate(:,2);
LAT_pga = reshape(LAT_pga,pga_spatial_prediction.stem_grid.grid_size);
LON_pga = reshape(LON_pga,pga_spatial_prediction.stem_grid.grid_size);

LON_anomaly=anomaly.LON;
LAT_anomaly=anomaly.LAT;

%% EQN users
in = isinterior(red_zone_polygon_highres,EQN_users_coordinates.lat,EQN_users_coordinates.lon);

figure
geoplot([red_zone_polygon_highres.Vertices(:,1);red_zone_polygon_highres.Vertices(1,1)],[red_zone_polygon_highres.Vertices(:,2);red_zone_polygon_highres.Vertices(1,2)],'k','LineWidth',1.5);
hold on
geoplot(EQN_users_coordinates.lat(in),EQN_users_coordinates.lon(in),'o','LineStyle','none','MarkerFaceColor','r','MarkerEdgeColor','k','MarkerSize',5,'LineWidth',0.75);
geoplot(INGV_stations(:,1),INGV_stations(:,2),'^','MarkerFaceColor','y','MarkerEdgeColor','k','LineWidth',1.5,'MarkerSize',18);
geobasemap('topographic');
geotickformat("-dd")
legend({'Red zone area','EQN user','INGV station'})
set(gca,'FontSize',22)
set(gca,'LineWidth',2)

%% EQN and INGV data used to estimate the anomaly map
figure
titles={'a','b','c','d'};
counter_plot=1;
for i=1:length(anomaly_input_data)

    if (anomaly_input_data{i}.eventid==38381891 || anomaly_input_data{i}.eventid==38762031 || anomaly_input_data{i}.eventid==38797691 || anomaly_input_data{i}.eventid==39089101)
        subplot(2,2,counter_plot);

        geoplot([red_zone_polygon_highres.Vertices(:,1);red_zone_polygon_highres.Vertices(1,1)],[red_zone_polygon_highres.Vertices(:,2);red_zone_polygon_highres.Vertices(1,2)],'k','LineWidth',1.5);
        hold on
        geoplot(anomaly_input_data{i}.EQN_data.latitude,anomaly_input_data{i}.EQN_data.longitude,'o','MarkerFaceColor','r','MarkerEdgeColor','k','LineWidth',1.5,'MarkerSize',7);
        geoplot(anomaly_input_data{i}.INGV_data.latitude,anomaly_input_data{i}.INGV_data.longitude,'^','MarkerFaceColor','y','MarkerEdgeColor','k','LineWidth',1.5,'MarkerSize',12);
        geobasemap topographic

        geoplot(anomaly_input_data{i}.eq_latitude,anomaly_input_data{i}.eq_longitude,'p','MarkerFaceColor',[0.4660 0.8740 0.3880],'MarkerEdgeColor','k','LineWidth',1.5,'MarkerSize',20)
        set(gca,'FontSize',20)
        set(gca,'LineWidth',2)
        [a,b]=geolimits;
        %geolimits([40.7861   40.8884],[13.9996   14.2619]);
        geolimits([40.7747   40.9066],[14.0192   14.2620]);
        title(titles{counter_plot});
        geotickformat("-dd")

        counter_plot=counter_plot+1;
    end
end

%% Anomaly map
figure
h=geoshow(LAT_anomaly,LON_anomaly,anomaly.mean_anomaly.*anomaly_mask,'DisplayType','texturemap');
set(h,'FaceColor','flat');
colormap(colormap_anomaly);
hold on

sign=anomaly.mean_anomaly_significant.*anomaly_mask;
sign(isnan(sign))=0;
sign(sign==-1)=0;
B=bwboundaries(sign);
for i=1:length(B)
    plot(LON_anomaly(1,B{i}(:,2)),LAT_anomaly(B{i}(:,1),1),'-r','LineWidth',2);
end

sign=anomaly.mean_anomaly_significant.*anomaly_mask;
sign(isnan(sign))=0;
sign(sign==1)=0;
B=bwboundaries(sign);
for i=1:length(B)
    plot(LON_anomaly(1,B{i}(:,2)),LAT_anomaly(B{i}(:,1),1),'-b','LineWidth',2);
end

plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',2,'Color','k');
plot(red_zone_northern_limit(:,2),red_zone_northern_limit(:,1),"LineWidth",2,'Color','k')

xlim([min(LON_anomaly(:))+0.018,max(LON_anomaly(:))+0.002])
ylim([min(LAT_anomaly(:))+0.0015,max(LAT_anomaly(:))])

c=colorbar;
c.Label.FontSize=16;
c.LineWidth=2;
clim([-1.5,1.5]);
set(c,'XTick',[-1.5 -0.97 -0.527 0 0.527 0.97 1.5]);
set(c,'XTickLabel',{'-1.5','-1.0','-0.5','0.0','0.5','1.0','1.5'});
set(gca,'LineWidth',3);
set(gca,'FontSize',20);
set(gca,'Layer','top');
xlabel('Longitude')
ylabel('Latitude')

xticks(14:0.05:14.25);
xticklabels({'14.00','14.05','14.10','14.15','14.20','14.25'});

yticks(40.78:0.02:40.90);
yticklabels({'40.78','40.80','40.82','40.84','40.86','40.88','40.90'});

box on
mean_lon = mean(LON_anomaly(:));
mean_lat = mean(LAT_anomaly(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])

%% Anomaly map standard deviation
figure
anomaly.std(1,1)=0.8;
anomaly.std(1,2)=0.2;
h=geoshow(LAT_anomaly,LON_anomaly,anomaly.mean_anomaly_std.*anomaly_mask,'DisplayType','texturemap');
set(h,'FaceColor','flat');
colormap(colormap_std_anomaly);
hold on
plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',2,'Color','k');
plot(red_zone_northern_limit(:,2),red_zone_northern_limit(:,1),"LineWidth",2,'Color','k')

xlim([min(LON_anomaly(:))+0.018,max(LON_anomaly(:))+0.002])
ylim([min(LAT_anomaly(:))+0.0015,max(LAT_anomaly(:))])

c=colorbar;
c.Label.FontSize=16;
c.LineWidth=2;
clim([0.2,0.8]);
set(c,'XTick',[0.2 0.3 0.4 0.5 0.6 0.7 0.8]);
set(gca,'LineWidth',3);
set(gca,'FontSize',22);
set(gca,'Layer','top');
xlabel('Longitude')
ylabel('Latitude')

xticks(14:0.05:14.25);
xticklabels({'14.00','14.05','14.10','14.15','14.20','14.25'});

yticks(40.78:0.02:40.90);
yticklabels({'40.78','40.80','40.82','40.84','40.86','40.88','40.90'});

box on
mean_lon = mean(LON_pga(:));
mean_lat = mean(LAT_pga(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])

%% Anomaly comparison
figure
subplot(2,2,1)

h=mapshow(anomaly_stations_only.LON,...
        anomaly_stations_only.LAT,...
        anomaly_stations_only.mean_anomaly.*anomaly_mask,...
        'DisplayType','texturemap');
set(h,'FaceColor','flat');
colormap(gca,colormap_anomaly);
hold on

sign=anomaly_stations_only.mean_anomaly_significant.*anomaly_mask;
sign(isnan(sign))=0;
sign(sign==-1)=0;
B=bwboundaries(sign);
for i=1:length(B)
    plot(anomaly.LON(1,B{i}(:,2)),anomaly.LAT(B{i}(:,1),1),'-r','LineWidth',1.5);
end

sign=anomaly_stations_only.mean_anomaly_significant.*anomaly_mask;
sign(isnan(sign))=0;
sign(sign==1)=0;
B=bwboundaries(sign);
for i=1:length(B)
    plot(anomaly.LON(1,B{i}(:,2)),anomaly.LAT(B{i}(:,1),1),'-b','LineWidth',1.5);
end

hold on
plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',1.5,'Color','k');
plot(red_zone_northern_limit(:,2),red_zone_northern_limit(:,1),"LineWidth",1.5,'Color','k')
c=colorbar;
c.LineWidth=2;
set(c,'XTick',[-1.5 -0.97 -0.527 0 0.527 0.97 1.5]);
set(c,'XTickLabel',{'-1.5','-1.0','-0.5','0.0','0.5','1.0','1.5'});
set(gca,'LineWidth',2);
set(gca,'FontSize',18);
set(gca,'Layer','top');
xlim([min(anomaly_stations_only.LON(:))+0.018,max(anomaly_stations_only.LON(:))+0.002])
ylim([min(anomaly_stations_only.LAT(:))+0.0015,max(anomaly_stations_only.LAT(:))])
box on
clim([-1.5,1.5]);
title('a');
xticks(14:0.05:14.25);
xticklabels({'14.00','14.05','14.10','14.15','14.20','14.25'});

yticks(40.78:0.02:40.90);
yticklabels({'40.78','40.80','40.82','40.84','40.86','40.88','40.90'});
xlabel('Longitude');
ylabel('Latitude');

mean_lon = mean(anomaly_stations_only.LON(:));
mean_lat = mean(anomaly_stations_only.LAT(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])

subplot(2,2,2)
anomaly_stations_only.std(1,1)=0.9;
anomaly_stations_only.std(1,2)=0.1;
h=mapshow(anomaly_stations_only.LON,...
        anomaly_stations_only.LAT,...
        anomaly_stations_only.mean_anomaly_std.*anomaly_mask,...
        'DisplayType','texturemap');
set(h,'FaceColor','flat');
colormap(gca,colormap_std_anomaly);
hold on
plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',1.5,'Color','k');
plot(red_zone_northern_limit(:,2),red_zone_northern_limit(:,1),"LineWidth",1.5,'Color','k')
c=colorbar;
c.LineWidth=2;
clim([0.1,0.9]);
set(c,'XTick',[0.1 0.3 0.5 0.7 0.9]);
set(gca,'LineWidth',2);
set(gca,'FontSize',18);
set(gca,'Layer','top');
xlim([min(anomaly_stations_only.LON(:))+0.018,max(anomaly_stations_only.LON(:))+0.002])
ylim([min(anomaly_stations_only.LAT(:))+0.0015,max(anomaly_stations_only.LAT(:))])
box on

title('b');
xticks(14:0.05:14.25);
xticklabels({'14.00','14.05','14.10','14.15','14.20','14.25'});

yticks(40.78:0.02:40.90);
yticklabels({'40.78','40.80','40.82','40.84','40.86','40.88','40.90'});

xlabel('Longitude');
ylabel('Latitude');


mean_lon = mean(anomaly_stations_only.LON(:));
mean_lat = mean(anomaly_stations_only.LAT(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])

%second row
subplot(2,2,3)
h=mapshow(anomaly_smartphones_only.LON,...
        anomaly_smartphones_only.LAT,...
        anomaly_smartphones_only.mean_anomaly.*anomaly_mask,...
        'DisplayType','texturemap');
set(h,'FaceColor','flat');
colormap(gca,colormap_anomaly);
hold on

sign=anomaly_smartphones_only.mean_anomaly_significant.*anomaly_mask;
sign(isnan(sign))=0;
sign(sign==-1)=0;
B=bwboundaries(sign);
for i=1:length(B)
    plot(anomaly.LON(1,B{i}(:,2)),anomaly.LAT(B{i}(:,1),1),'-r','LineWidth',1.5);
end

sign=anomaly_smartphones_only.mean_anomaly_significant.*anomaly_mask;
sign(isnan(sign))=0;
sign(sign==1)=0;
B=bwboundaries(sign);
for i=1:length(B)
    plot(anomaly.LON(1,B{i}(:,2)),anomaly.LAT(B{i}(:,1),1),'-b','LineWidth',1.5);
end

plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',1.5,'Color','k');
plot(red_zone_northern_limit(:,2),red_zone_northern_limit(:,1),"LineWidth",1.5,'Color','k')
c=colorbar;
c.LineWidth=2;
set(c,'XTick',[-1.5 -0.97 -0.527 0 0.527 0.97 1.5]);
set(c,'XTickLabel',{'-1.5','-1.0','-0.5','0.0','0.5','1.0','1.5'});
set(gca,'LineWidth',2);
set(gca,'FontSize',18);
set(gca,'Layer','top');
xlim([min(anomaly_stations_only.LON(:))+0.018,max(anomaly_stations_only.LON(:))+0.002])
ylim([min(anomaly_stations_only.LAT(:))+0.0015,max(anomaly_stations_only.LAT(:))])
box on
clim([-1.5,1.5]);
title('c');
xticks(14:0.05:14.25);
xticklabels({'14.00','14.05','14.10','14.15','14.20','14.25'});

yticks(40.78:0.02:40.90);
yticklabels({'40.78','40.80','40.82','40.84','40.86','40.88','40.90'});

xlabel('Longitude');
ylabel('Latitude');

mean_lon = mean(anomaly_smartphones_only.LON(:));
mean_lat = mean(anomaly_smartphones_only.LAT(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])

subplot(2,2,4)
anomaly_smartphones_only.std(1,1)=0.9;
anomaly_smartphones_only.std(1,2)=0.1;
h=mapshow(anomaly_smartphones_only.LON,...
        anomaly_smartphones_only.LAT,...
        anomaly_smartphones_only.mean_anomaly_std.*anomaly_mask,...
        'DisplayType','texturemap');
set(h,'FaceColor','flat');
colormap(gca,colormap_std_anomaly);
hold on
plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',1.5,'Color','k');
plot(red_zone_northern_limit(:,2),red_zone_northern_limit(:,1),"LineWidth",1.5,'Color','k')
c=colorbar;
c.LineWidth=2;
clim([0.1,0.9]);
set(c,'XTick',[0.1 0.3 0.5 0.7 0.9]);
set(gca,'LineWidth',2);
set(gca,'FontSize',18);
set(gca,'Layer','top');
xlim([min(anomaly_stations_only.LON(:))+0.018,max(anomaly_stations_only.LON(:))+0.002])
ylim([min(anomaly_stations_only.LAT(:))+0.0015,max(anomaly_stations_only.LAT(:))])
box on
title('d');

xticks(14:0.05:14.25);
xticklabels({'14.00','14.05','14.10','14.15','14.20','14.25'});

yticks(40.78:0.02:40.90);
yticklabels({'40.78','40.80','40.82','40.84','40.86','40.88','40.90'});

xlabel('Longitude');
ylabel('Latitude');

mean_lon = mean(anomaly_stations_only.LON(:));
mean_lat = mean(anomaly_stations_only.LAT(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])

%% Amplification map
figure
amplification=exp(anomaly.mean_anomaly);
h=geoshow(LAT_anomaly,LON_anomaly,amplification.*anomaly_mask,'DisplayType','texturemap');
set(h,'FaceColor','flat');
colormap(colormap_amplification);
hold on
plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',2,'Color','k');
plot(red_zone_northern_limit(:,2),red_zone_northern_limit(:,1),"LineWidth",2,'Color','k')

xlim([min(LON_anomaly(:))+0.018,max(LON_anomaly(:))+0.002])
ylim([min(LAT_anomaly(:))+0.0015,max(LAT_anomaly(:))])

[C,h] = contour(LON_anomaly,LAT_anomaly,amplification,'LevelList',[0.25,0.5,0.75,1,1.25,1.5,1.75,2,2.25,2.5]);
h.EdgeColor=[0.3 0.3 0.3];
h.LineWidth=1.5;
clabel(C,h,[0.25,0.5,0.75,1,1.25,1.5,1.75,2,2.25,2.5],'Color','k','FontSize',9);

c=colorbar;
c.Label.FontSize=16;
c.LineWidth=2;
clim([0.25,2.5]);
c.Ticks=[0.25,0.50,0.75,1.00,1.25,1.5,1.75,2.0,2.25,2.5];
c.TickLabels={'0.25','0.50','0.75','1.00','1.25','1.50','1.75','2.00','2.25','2.50'};
set(gca,'LineWidth',3);
set(gca,'FontSize',22);
set(gca,'Layer','top');
xlabel('Longitude')
ylabel('Latitude')

xticks(14:0.05:14.25);
xticklabels({'14.00','14.05','14.10','14.15','14.20','14.25'});

yticks(40.78:0.02:40.90);
yticklabels({'40.78','40.80','40.82','40.84','40.86','40.88','40.90'});

box on
mean_lon = mean(LON_pga(:));
mean_lat = mean(LAT_pga(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])

%% EQN user amplification exposure
in = inpolygon(EQN_users_coordinates.lat,EQN_users_coordinates.lon,red_zone_polygon.lat,red_zone_polygon.lon);
EQN_users_coordinates=EQN_users_coordinates(in,:);

lat=LAT_anomaly(:,1);
lon=LON_anomaly(1,:);
exposure_amplification=zeros(height(EQN_users_coordinates),1);
for i=1:height(EQN_users_coordinates)
    [~,idx_lat]=min(abs(lat-EQN_users_coordinates.lat(i)));
    [~,idx_lon]=min(abs(lon-EQN_users_coordinates.lon(i)));
    exposure_amplification(i,1)=amplification(idx_lat,idx_lon);
end

figure
[f,x]=ecdf(exposure_amplification);
yyaxis left
histogram(exposure_amplification,'Normalization','Percentage');
xlabel('Site amplification factor');
ylabel('EQN users frequency (%)');

yyaxis right
plot(x,100-f*100,'r-','LineWidth',2)
ylabel('Cumulative distribution (%)');
grid on
set(gca,'FontSize',22);
set(gca,'LineWidth',2);

%% PGA map
pga_hat = pga_spatial_prediction.y_hat;
var_pga_hat = pga_spatial_prediction.diag_Var_y_hat;

pga_hat_corrected = exp(pga_hat+var_pga_hat/2);
var_pga_hat_corrected = (exp(var_pga_hat)-1).*exp(2*pga_hat+var_pga_hat);

figure
geoshow(LAT_pga,LON_pga,pga_hat_corrected.*pga_mask,'DisplayType','texturemap');
hold on
plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',2,'Color','k');
colormap(colormap_pga);

xlim([14.10,14.22])
ylim([40.79,40.85])

levels=[0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18];
[C,h] = contour(LON_pga,LAT_pga,pga_hat_corrected,levels,'-');
h.EdgeColor=[0.3 0.3 0.3];
h.LineWidth=1;
clabel(C,h,levels,'FontSize',9);

levels=[0.20 0.50];
[C,h] = contour(LON_pga,LAT_pga,pga_hat_corrected,levels,'-');
h.EdgeColor=[0.3 0.3 0.3];
h.LineWidth=1;
clabel(C,h,levels,'FontSize',9,'LabelSpacing',100);

levels=[0.22 0.50];
[C,h] = contour(LON_pga,LAT_pga,pga_hat_corrected,levels,'-');
h.EdgeColor=[0.3 0.3 0.3];
h.LineWidth=1;
clabel(C,h,levels,'FontSize',9,'LabelSpacing',50);

p3=geoshow(pga_model.stem_data.stem_gridlist_p.grid{2}.coordinate(:,1),pga_model.stem_data.stem_gridlist_p.grid{2}.coordinate(:,2),'DisplayType','point','Marker','o','MarkerEdgeColor','k','MarkerFaceColor',[244/255 0 0],'MarkerSize',8,'LineWidth',1);
p1=geoshow(eq_latitude,eq_longitude,'DisplayType','point','Marker','p','MarkerEdgeColor','w','MarkerFaceColor','m','MarkerSize',24,'LineWidth',2);
for i=1:length(station_pga)
    idx_color = round(station_pga(i)/0.32*size(colormap_pga,1));
    if i==1
        p2=geoshow(pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,1),pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,2),'DisplayType','point','Marker','^','MarkerEdgeColor','w','MarkerFaceColor',colormap_pga(idx_color,:),'MarkerSize',13,'LineWidth',2);
    else
        geoshow(pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,1),pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,2),'DisplayType','point','Marker','^','MarkerEdgeColor','w','MarkerFaceColor',colormap_pga(idx_color,:),'MarkerSize',13,'LineWidth',2);
    end
end

c=colorbar;
c.Label.FontSize=20;
c.LineWidth=2;
clim([0,0.32]);
c.Ticks=0:0.04:0.32;
c.TickLabels={'0.00','0.04','0.08','0.12','0.16','0.20','0.24','0.28','PGA (g)'};
set(gca,'LineWidth',3);
set(gca,'FontSize',22);
set(gca,'Layer','top');
xlabel('Longitude')
ylabel('Latitude')

xticks(14.10:0.02:14.22);
xticklabels({'14.10','14.12','14.14','14.16','14.18','14.20','14.22'});

yticks(40.79:0.01:40.85);
yticklabels({'40.79','40.80','40.81','40.82','40.83','40.84','40.85'});

box on
mean_lon = mean(LON_pga(:));
mean_lat = mean(LAT_pga(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])
l=legend([p1,p2,p3],{'Epicentre','INGV station','EQN smartphone'},'Location','southwest','FontSize',18,'Orientation','vertical');
l.LineWidth=2;
l.BoxFace.ColorType='truecoloralpha';
l.BoxFace.ColorData=uint8(255*[0.85 0.85 0.85 1]');

%% PGA map low extreme
figure

pga_hat_low=pga_hat_corrected-sqrt(var_pga_hat_corrected);
pga_hat_low(pga_hat_low<0)=0;
geoshow(LAT_pga,LON_pga,pga_hat_low.*pga_mask,'DisplayType','texturemap');
hold on
plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',2,'Color','k');
colormap(colormap_pga);

xlim([14.10,14.22])
ylim([40.79,40.85])

levels=[0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16];
[C,h] = contour(LON_pga,LAT_pga,pga_hat_low,levels,'-');
h.EdgeColor=[0.3 0.3 0.3];
h.LineWidth=1;
clabel(C,h,levels,'FontSize',9);

p3=geoshow(pga_model.stem_data.stem_gridlist_p.grid{2}.coordinate(:,1),pga_model.stem_data.stem_gridlist_p.grid{2}.coordinate(:,2),'DisplayType','point','Marker','o','MarkerEdgeColor','k','MarkerFaceColor',[244/255 0 0],'MarkerSize',8,'LineWidth',1);
p1=geoshow(eq_latitude,eq_longitude,'DisplayType','point','Marker','p','MarkerEdgeColor','w','MarkerFaceColor','m','MarkerSize',24,'LineWidth',2);
for i=1:length(station_pga)
    idx_color = round(station_pga(i)/0.32*size(colormap_pga,1));
    if i==1
        p2=geoshow(pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,1),pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,2),'DisplayType','point','Marker','^','MarkerEdgeColor','w','MarkerFaceColor',colormap_pga(idx_color,:),'MarkerSize',13,'LineWidth',2);
    else
        geoshow(pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,1),pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,2),'DisplayType','point','Marker','^','MarkerEdgeColor','w','MarkerFaceColor',colormap_pga(idx_color,:),'MarkerSize',13,'LineWidth',2);
    end
end

c=colorbar;
c.Label.FontSize=16;
c.Ticks=0:0.04:0.32;
c.TickLabels={'0.00','0.04','0.08','0.12','0.16','0.20','0.24','0.28','PGA (g)'};
c.LineWidth=2;
clim([0,0.32])

set(gca,'LineWidth',3);
set(gca,'FontSize',22);
set(gca,'Layer','top');
xlabel('Longitude')
ylabel('Latitude')

xticks(14.10:0.02:14.22);
xticklabels({'14.10','14.12','14.14','14.16','14.18','14.20','14.22'});

yticks(40.79:0.01:40.85);
yticklabels({'40.79','40.80','40.81','40.82','40.83','40.84','40.85'});

box on
mean_lon = mean(LON_pga(:));
mean_lat = mean(LAT_pga(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])
l=legend([p1,p2,p3],{'Epicentre','INGV station','EQN smartphone'},'Location','southwest','FontSize',18,'Orientation','vertical');
l.LineWidth=2;
l.BoxFace.ColorType='truecoloralpha';
l.BoxFace.ColorData=uint8(255*[0.75 0.75 0.75 1]');

%% PGA map high extreme
figure
pga_hat_high=pga_hat_corrected+sqrt(var_pga_hat_corrected);
geoshow(LAT_pga,LON_pga,pga_hat_high.*pga_mask,'DisplayType','texturemap');
hold on
plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',2,'Color','k');
colormap(colormap_pga);

xlim([14.10,14.22])
ylim([40.79,40.85])

levels=[0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30];
[C,h] = contour(LON_pga,LAT_pga,pga_hat_high,levels,'-');
h.EdgeColor=[0.3 0.3 0.3];
h.LineWidth=1;
clabel(C,h,levels,'FontSize',9);

p3=geoshow(pga_model.stem_data.stem_gridlist_p.grid{2}.coordinate(:,1),pga_model.stem_data.stem_gridlist_p.grid{2}.coordinate(:,2),'DisplayType','point','Marker','o','MarkerEdgeColor','k','MarkerFaceColor',[244/255 0 0],'MarkerSize',8,'LineWidth',1);
p1=geoshow(eq_latitude,eq_longitude,'DisplayType','point','Marker','p','MarkerEdgeColor','w','MarkerFaceColor','m','MarkerSize',24,'LineWidth',2);
for i=1:length(station_pga)
    idx_color = round(station_pga(i)/0.32*size(colormap_pga,1));
    if i==1
        p2=geoshow(pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,1),pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,2),'DisplayType','point','Marker','^','MarkerEdgeColor','w','MarkerFaceColor',colormap_pga(idx_color,:),'MarkerSize',13,'LineWidth',2);
    else
        geoshow(pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,1),pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,2),'DisplayType','point','Marker','^','MarkerEdgeColor','w','MarkerFaceColor',colormap_pga(idx_color,:),'MarkerSize',13,'LineWidth',2);
    end
end

c=colorbar;
c.Label.FontSize=16;
c.Ticks=0:0.04:0.32;
c.TickLabels={'0.00','0.04','0.08','0.12','0.16','0.20','0.24','0.28','PGA (g)'};
c.LineWidth=2;
clim([0,0.32])

set(gca,'LineWidth',3);
set(gca,'FontSize',22);
set(gca,'Layer','top');
xlabel('Longitude')
ylabel('Latitude')

xticks(14.10:0.02:14.22);
xticklabels({'14.10','14.12','14.14','14.16','14.18','14.20','14.22'});

yticks(40.79:0.01:40.85);
yticklabels({'40.79','40.80','40.81','40.82','40.83','40.84','40.85'});

box on
mean_lon = mean(LON_pga(:));
mean_lat = mean(LAT_pga(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])
l=legend([p1,p2,p3],{'Epicentre','INGV station','EQN smartphone'},'Location','southwest','FontSize',18,'Orientation','vertical');
l.LineWidth=2;
l.BoxFace.ColorType='truecoloralpha';
l.BoxFace.ColorData=uint8(255*[0.75 0.75 0.75 1]');

%% INGV Shakemap PGA
load data/input/INGV_M42.mat
lon_ingv=INGV_M42.lon;
lat_ingv=INGV_M42.lat;
pga_ingv=INGV_M42.pga;

lon_ingv=reshape(lon_ingv,611,311);
lat_ingv=reshape(lat_ingv,611,311);
pga_ingv=reshape(pga_ingv,611,311);

pga_ingv_highres=griddata(lon_ingv,lat_ingv,pga_ingv,LON_pga,LAT_pga,"cubic");

figure
geoshow(LAT_pga,LON_pga,pga_ingv_highres.*pga_mask,'DisplayType','texturemap');
hold on
plot(campania_region_polygon.lon,campania_region_polygon.lat,'LineWidth',2,'Color','k');
colormap(colormap_pga);

xlim([14.10,14.22])
ylim([40.79,40.85])

levels=[0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.15];
[C,h] = contour(LON_pga,LAT_pga,pga_ingv_highres,levels,'-');
h.EdgeColor=[0.3 0.3 0.3];
h.LineWidth=1;
clabel(C,h,levels,'FontSize',9);

p1=geoshow(eq_latitude,eq_longitude,'DisplayType','point','Marker','p','MarkerEdgeColor','w','MarkerFaceColor','m','MarkerSize',24,'LineWidth',2);

for i=1:length(station_pga)
    idx_color = round(station_pga(i)/0.32*size(colormap_pga,1));
    if i==1
        p2=geoshow(pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,1),pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,2),'DisplayType','point','Marker','^','MarkerEdgeColor','w','MarkerFaceColor',colormap_pga(idx_color,:),'MarkerSize',13,'LineWidth',2);
    else
        geoshow(pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,1),pga_model.stem_data.stem_gridlist_p.grid{1}.coordinate(i,2),'DisplayType','point','Marker','^','MarkerEdgeColor','w','MarkerFaceColor',colormap_pga(idx_color,:),'MarkerSize',13,'LineWidth',2);
    end
end

c=colorbar;
c.Label.FontSize=16;
c.Ticks=0:0.04:0.32;
c.TickLabels={'0.00','0.04','0.08','0.12','0.16','0.20','0.24','0.28','PGA (g)'};
c.LineWidth=2;
clim([0,0.32])

set(gca,'LineWidth',3);
set(gca,'FontSize',22);
set(gca,'Layer','top');
xlabel('Longitude')
ylabel('Latitude')

xticks(14.10:0.02:14.22);
xticklabels({'14.10','14.12','14.14','14.16','14.18','14.20','14.22'});

yticks(40.79:0.01:40.85);
yticklabels({'40.79','40.80','40.81','40.82','40.83','40.84','40.85'});

box on
mean_lon = mean(LON_pga(:));
mean_lat = mean(LAT_pga(:));
d_lat = distdim(distance(mean_lat,mean_lon,mean_lat+0.05,mean_lon),'deg','km');
d_lon = distdim(distance(mean_lat,mean_lon,mean_lat,mean_lon+0.05),'deg','km');
daspect([1,d_lon/d_lat 1])
l=legend([p1,p2],{'Epicentre','INGV station'},'Location','southwest','FontSize',18,'Orientation','vertical');
l.LineWidth=2;
l.BoxFace.ColorType='truecoloralpha';
l.BoxFace.ColorData=uint8(255*[0.75 0.75 0.75 1]');