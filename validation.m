clc
clearvars

load data/input/soil.mat
load data/output/anomaly_smartphones1_stations1.mat

anomaly_soil=[];
for i=1:height(soil)
    [min_lat,idx_lat]=min(abs(soil.lat(i)-anomaly.LAT(:,1)));
    [min_lon,idx_lon]=min(abs(soil.lon(i)-anomaly.LON(1,:)));
    
    if (min_lat<0.00015 && min_lon<0.00015)
        anomaly_soil(i,1)=anomaly.mean_anomaly(idx_lat,idx_lon);
    else
        anomaly_soil(i,1)=NaN;
    end
end
  
soil.anomaly=anomaly_soil;

figure
geoscatter(soil.lat,soil.lon,80,anomaly_soil,"filled")

figure 
hold on
for i=1:11
    idx=find(soil.geo_idx==i);
    labels{i}=char(soil.geo(idx(1)));
end
for i=1:11
    L=soil.geo_idx==i;
    plot(i,soil.anomaly(L),'.b');
    plot(i,nanmean(soil.anomaly(L)),'sr','LineWidth',2);
    xticks(1:11);
    xticklabels(labels);
end
xlim([1,11]);
xlabel('Soil');
ylabel('Anomaly')
grid on
box on
set(gca,'FontSize',16)

