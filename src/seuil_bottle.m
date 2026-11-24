function [seuil, calibre, reference] = seuil_bottle(dossierProjet)
    seuil = NaN;
    calibre = false;
    reference = [];
    modele = dir(fullfile(dossierProjet, 'netCAE.mat'));

    if isempty(modele)
        return
    end

    % La carte de référence et son seuil sont enregistrés ensemble.
    % Avec deux sorties, retourner le seuil compatible avec le score précédent.
    if nargout >= 3
        fichier = fullfile(dossierProjet, 'calibrationBottleReference.mat');
        mesure = dir(fichier);
        if ~isempty(mesure) && mesure.datenum >= modele.datenum
            valeurs = load(fichier, 'seuil', 'reference');
            if isfield(valeurs, 'reference') && isequal(size(valeurs.reference), [128 128]) ...
                    && all(isfinite(valeurs.reference(:))) && seuilValide(valeurs)
                seuil = valeurs.seuil;
                reference = valeurs.reference;
                calibre = true;
                return
            end
        end
    end

    % Ancienne calibration, utilisable avant d'exécuter la nouvelle validation.
    fichier = fullfile(dossierProjet, 'seuilBottleLocal.mat');
    mesure = dir(fichier);
    if ~isempty(mesure) && mesure.datenum >= modele.datenum
        valeurs = load(fichier, 'seuil');
        if seuilValide(valeurs)
            seuil = valeurs.seuil;
            calibre = true;
        end
    end
end

function valide = seuilValide(valeurs)
    valide = isfield(valeurs, 'seuil') && isscalar(valeurs.seuil) ...
        && isfinite(valeurs.seuil) && valeurs.seuil >= 0;
end
