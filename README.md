# IF5 — Détection de défauts industriels

Projet MATLAB de BUT GEII sur la classification des défauts de surface sur le métal (NEU) et la détection d’anomalies sur des bouteilles (MVTec AD).

## Fichiers du projet

- `src/` contient les scripts de prétraitement, d’entraînement, de validation et d’interface.
- `rapport/notes.mlx` contient le Live Script du projet.
- `netCAE.mat` contient l’autoencodeur entraîné.

## Lancer l’inspection

1. Ouvrir la racine du dépôt comme dossier courant dans MATLAB avec Image Processing Toolbox et Deep Learning Toolbox.
2. Pour le mode métal, placer le modèle `netTL.mat` de l’archive du projet à la racine. Il est aussi possible de le générer avec `train_supervise`, avec les images NEU et le module ResNet-18 installés.
3. Depuis la fenêtre de commandes MATLAB, lancer l’interface.

   ```matlab
   addpath('src')
   interface_appli
   ```

La version App Designer utilise `InspectionApp.mlapp` à la racine et `src/construireInspectionApp.m` pour construire l’interface au démarrage.

## Reproduire la calibration et la validation

Copier les dossiers de données de l’archive du projet dans `data/` à la racine.

| Dossier | Contenu |
| --- | --- |
| `data/train/` | Images NEU rangées dans les six dossiers de classes |
| `data/mvtec/bottle/train/good/` | Bouteilles saines pour calculer la carte de référence |
| `data/mvtec/bottle/test/` | Sous-dossiers `good`, `broken_large`, `broken_small` et `contamination` |

Avec `netTL.mat` et `netCAE.mat` à la racine, exécuter `addpath('src')` puis `validation_industrielle`. Le script compare le score local précédent au score avec carte de référence et enregistre la nouvelle calibration dans `calibrationBottleReference.mat`. Placer ce fichier à côté de `netCAE.mat` pour réutiliser la calibration sur un autre poste.
