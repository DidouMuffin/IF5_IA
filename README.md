# IF5 — Détection de défauts industriels

Projet MATLAB de BUT GEII sur la classification de défauts de surface et la détection d’anomalies dans des images industrielles.

## Fichiers du projet

- `src/` contient les scripts de prétraitement, de classification, d’autoencodage, de validation et l’interface `interface_appli.m`.
- `rapport/notes.mlx` contient le Live Script du projet.
- `netCAE.mat` contient l’autoencodeur entraîné.

## Lancer le projet

Ouvrir la racine du dépôt comme dossier courant dans MATLAB et exécuter `addpath('src')`. Ouvrir `rapport/notes.mlx` et exécuter les sections depuis cette racine, ou lancer `interface_appli` pour ouvrir l’interface.

Pour reconstituer les ressources de l’archive, copier le contenu de `Projet_Defauts/data/` dans `data/` à la racine du dépôt. Les scripts lisent les six classes du jeu NEU dans `data/train/` et les images MVTec dans `data/mvtec/`. Copier aussi `Projet_Defauts/netTL.mat` à la racine pour la classification dans l’interface et la validation.
