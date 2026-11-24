
function [precision, recall, f1] = evaluateMetrics(YTrue, YPred)

    % Matrice de confusion
    ordre = categorical(categories(YTrue), categories(YTrue));
    C = confusionmat(YTrue, YPred, 'Order', ordre);

    % Calcul des vrais positifs
    TP = diag(C);

    % Calcul des faux positifs
    FP = sum(C, 1)' - TP;

    % Calcul des faux negatifs
    FN = sum(C, 2) - TP;

    % Calcul des indicateurs
    precision = TP ./ max(TP + FP, 1);
    recall = TP ./ max(TP + FN, 1);

    f1 = 2 * (precision .* recall) ...
        ./ max(precision + recall, eps);

end
