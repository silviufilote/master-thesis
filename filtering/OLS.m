%% Setup 
clc
close all
clearvars

rng(1)

% Load dataset
load("EQNF_subset.mat")

% Extract predictors and response
X = [EQNF_subset.constant, EQNF_subset.distance];
Y = EQNF_subset.PSfA;

%% Step 1: Split into training (80%) and validation (20%)
n = size(X,1);
idx = randperm(n);
train_ratio = 0.8;
n_train = round(train_ratio * n);

X_train = X(idx(1:n_train), :);
Y_train = Y(idx(1:n_train));
X_val   = X(idx(n_train+1:end), :);
Y_val   = Y(idx(n_train+1:end));

%% Step 2: Fit OLS model on training data
mdl = fitlm(X_train, Y_train, 'Linear', 'Intercept', false);

% Compute training residuals and define threshold
resid_train = mdl.Residuals.Raw;
threshold = 3 * std(resid_train);

%% Step 3: Plot histogram of training residuals (before filtering)
figure;
histogram(resid_train, 30, 'FaceColor', [0.4 0.6 0.8]);
hold on;
xline(threshold, 'r--', 'LineWidth', 2);
xline(-threshold, 'r--', 'LineWidth', 2);
title('Training residuals before filtering (with ±3σ thresholds)');
xlabel('Residuals');
ylabel('Frequency');
hold off;

% Identify training outliers beyond ±3σ
outlier_mask_train = abs(resid_train) > threshold;
n_outliers_train = sum(outlier_mask_train);
fprintf('Outliers detected in training: %d (%.2f%%)\n', ...
        n_outliers_train, 100 * n_outliers_train / n_train);

%% Step 4: Compute validation performance (before filtering)
Y_pred_val_before = predict(mdl, X_val);
resid_val_before = Y_val - Y_pred_val_before;

% Validation metrics before filtering
R2_val_before = 1 - sum(resid_val_before.^2) / sum((Y_val - mean(Y_val)).^2);
RMSE_val_before = sqrt(mean(resid_val_before.^2));

% Identify validation outliers beyond ±3σ (same threshold)
outlier_mask_val = abs(resid_val_before) > threshold;
n_outliers_val = sum(outlier_mask_val);
fprintf('Outliers detected in validation: %d (%.2f%%)\n', ...
        n_outliers_val, 100 * n_outliers_val / length(Y_val));

%% Step 5: Compute training metrics before filtering
Y_pred_train_before = predict(mdl, X_train);
resid_train_before = Y_train - Y_pred_train_before;
R2_train_before = 1 - sum(resid_train_before.^2) / sum((Y_train - mean(Y_train)).^2);
RMSE_train_before = sqrt(mean(resid_train_before.^2));

fprintf('\n--- Performance BEFORE filtering ---\n');
fprintf('Training:   R² = %.4f | RMSE = %.4f\n', R2_train_before, RMSE_train_before);
fprintf('Validation: R² = %.4f | RMSE = %.4f\n', R2_val_before, RMSE_val_before);

%% Step 6: Remove outliers from BOTH training and validation sets
X_train_filt = X_train(~outlier_mask_train, :);
Y_train_filt = Y_train(~outlier_mask_train);
X_val_filt = X_val(~outlier_mask_val, :);
Y_val_filt = Y_val(~outlier_mask_val);

%% Step 7: Refit OLS model on filtered training data
mdl_filt = fitlm(X_train_filt, Y_train_filt, 'Linear', 'Intercept', false);

% Predictions on filtered training set
Y_pred_train_after = predict(mdl_filt, X_train_filt);
resid_train_after = Y_train_filt - Y_pred_train_after;
R2_train_after = 1 - sum(resid_train_after.^2) / sum((Y_train_filt - mean(Y_train_filt)).^2);
RMSE_train_after = sqrt(mean(resid_train_after.^2));

% Predictions on filtered validation set
Y_pred_val_after = predict(mdl_filt, X_val_filt);
resid_val_after = Y_val_filt - Y_pred_val_after;
R2_val_after = 1 - sum(resid_val_after.^2) / sum((Y_val_filt - mean(Y_val_filt)).^2);
RMSE_val_after = sqrt(mean(resid_val_after.^2));

fprintf('\n--- Performance AFTER filtering ---\n');
fprintf('Training:   R² = %.4f | RMSE = %.4f\n', R2_train_after, RMSE_train_after);
fprintf('Validation: R² = %.4f | RMSE = %.4f\n', R2_val_after, RMSE_val_after);

%% Step 8: Plot histogram of validation residuals after filtering
figure;
histogram(resid_val_after, 30, 'FaceColor', [0.6 0.8 0.6]);
hold on;
xline(3 * std(resid_val_after), 'r--', 'LineWidth', 2);
xline(-3 * std(resid_val_after), 'r--', 'LineWidth', 2);
title('Validation residuals after filtering and model refit (±3σ)');
xlabel('Residuals');
ylabel('Frequency');
hold off;

%% Step 9: Save filtered dataset (optional)
EQNF_subset_filtered = EQNF_subset(idx(1:n_train), :);
EQNF_subset_filtered = EQNF_subset_filtered(~outlier_mask_train, :);
save("..\data\input\EQNF_subset_filtered.mat", 'EQNF_subset_filtered');
