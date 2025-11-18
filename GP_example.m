clc
close all
clearvars

% Vettore coordinate
x = 0:1:99;
y = 0:1:99;

% Create a grid of coordinates (X, Y) using 'x' and 'y' vectors.
[X, Y] = meshgrid(x, y);

% Convert the grid coordinates (X, Y) into a 2D array 'coord'.
coord = [X(:) Y(:)];

% Plot the coordinates as points.
% Set the aspect ratio of the plot to be equal.
figure
plot(coord(:,1), coord(:,2), '.');
axis equal

% Set a correlation length parameter.
theta = 2;

% Calculate pairwise Euclidean distances between points.
% distance matrix
dist = pdist2(coord, coord, "euclidean");


% Display the distance matrix as an image.
figure
imagesc(dist);

% Calculate the spatial correlation using the exponential
% correlation function.
sp_corr = exp(-dist/theta);

% Display the spatial correlation matrix as an image.
figure
imagesc(sp_corr);

% GP simulation:
% Generate a sample from a multivariate Gaussian distribution.
v = mvnrnd(zeros(1, size(dist,1)), sp_corr, 1);

% Reshape the sample to match the grid shape.
v = reshape(v, size(X));

% Display the generated GP sample as an image.
imagesc(v)
clim([-3, 3])   % Set the color limit for the plot.
colorbar        % Add a color bar to the plot.
