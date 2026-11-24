
function [label, score, errMap] = inspectImage(img, netTL, netCAE, typeImage)

    % Initialisation des resultats
    label = 'Non applicable';
    score = NaN;
    errMap = [];

    %% Classification supervisee - Base NEU

    if strcmp(typeImage, 'NEU')

        % Redimensionnement pour ResNet-18
        img224 = imresize(img, [224 224]);

        % Conversion en 3 canaux si necessaire
        if size(img224, 3) == 1
            img224 = repmat(img224, [1 1 3]);
        end

        % Classification
        label = char(classify(netTL, img224));

    %% Detection d'anomalies - Base Bottle

    elseif strcmp(typeImage, 'bottle')

        % Preparation de l'image
        img128 = im2single(imresize(img, [128 128]));

        % Conversion en 3 canaux si necessaire
        if size(img128, 3) == 1
            img128 = repmat(img128, [1 1 3]);
        end

        % Reconstruction
        Xrec = predict(netCAE, img128);

        % Calcul de la carte d'erreur
        errMap = mean((img128 - Xrec).^2, 3);

        % Calcul du score d'anomalie
        score = mean(errMap(:));

    end

end
