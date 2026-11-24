
function [label, score, errMap, confiance, erreurBrute] = inspectImage(img, netTL, netCAE, typeImage, reference)

    if nargin < 5
        reference = [];
    end

    % Initialisation des resultats
    label = 'Non applicable';
    score = NaN;
    errMap = [];
    erreurBrute = [];
    confiance = NaN;

    %% Classification supervisee - Base NEU

    if strcmpi(typeImage, 'NEU')

        % Redimensionnement pour ResNet-18
        img224 = imresize(img, [224 224]);

        % Conversion en 3 canaux si necessaire
        if size(img224, 3) == 1
            img224 = repmat(img224, [1 1 3]);
        end

        % Classification
        [classe, scores] = classify(netTL, img224);
        label = char(classe);
        confiance = max(scores);

    %% Detection d'anomalies - Base Bottle

    elseif strcmpi(typeImage, 'bottle')

        % Preparation de l'image
        img128 = im2single(imresize(img, [128 128]));

        % Conversion en 3 canaux si necessaire
        if size(img128, 3) == 1
            img128 = repmat(img128, [1 1 3]);
        end

        % Reconstruction
        Xrec = predict(netCAE, img128);

        % Calcul de la carte d'erreur
        erreurBrute = mean((img128 - Xrec).^2, 3);

        [score, errMap] = score_bouteille(erreurBrute, reference);
        label = 'Bottle';

    else
        error('Type inconnu. Choisir NEU ou bottle.');

    end

end
