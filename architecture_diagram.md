# Architecture de l'Application Snare Notation

## Vue d'ensemble des couches

```
┌───────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌───────────────────┐  │
│  │   HomeScreen    │  │  StaffScreen    │  │ CreateScoreScreen │  │
│  │                 │  │                 │  │                   │  │
│  │ - Liste scores  │  │ - Édition       │  │ - Nouveau score   │  │
│  │ - Navigation    │  │ - Visualisation │  │ - Métadonnées     │  │
│  └─────────────────┘  └─────────────────┘  └───────────────────┘  │
│                                │                                  │
│  ┌─────────────────────────────┼───────────────────────────────┐  │
│  │                    WIDGETS LAYER                            │  │
│  │  ┌─────────────┐  ┌────────────────┐  ┌─────────────────┐   │  │
│  │  │ StaffView   │  │DurationControls│  │ UnifiedPalette  │   │  │
│  │  │             │  │                │  │                 │   │  │
│  │  │ - Rendu     │  │ - Contrôles    │  │ - Sélection     │   │  │
│  │  │ - Portée    │  │ - Actions      │  │ - Symboles      │   │  │
│  │  └─────────────┘  └────────────────┘  └─────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                       CONTROLLER LAYER                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              StaffScreenController                      │    │
│  │                                                         │    │
│  │ • Gestion de l'état de l'interface utilisateur          │    │
│  │ • Coordination des interactions utilisateur             │    │
│  │ • Gestion de la sélection (notes, symboles, durées)     │    │
│  │ • Orchestration des opérations d'édition                │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │         ScoreWithMetadataController             │    │    │
│  │  │                                                 │    │    │
│  │  │ • Gestion des données de la partition           │    │    │
│  │  │ • Opérations CRUD sur les partitions            │    │    │
│  │  │ • Gestion des métadonnées                       │    │    │
│  │  │ • Intégrité des données musicales               │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                        SERVICE LAYER                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ StorageService  │  │  Layout Engines │  │  Render Engines │  │
│  │                 │  │                 │  │                 │  │
│  │ - Persistance   │  │ • PageEngine    │  │ • StaffPainter  │  │
│  │ - Sérialisation │  │ • BeamEngine    │  │ • BeamPainter   │  │
│  │ - Fichiers JSON │  │ • SpacingEngine │  │ • GlyphPainter  │  │
│  │ - Métadonnées   │  │ • StemEngine    │  │ • RollPainter   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                         MODEL LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │    Score    │  │   Measure   │  │  NoteEvent  │  │ Metadata│ │
│  │             │  │             │  │             │  │         │ │
│  │ - Partition │  │ - Mesure    │  │ - Note/Sil. │  │ - Infos │ │
│  │ - Mesures   │  │ - Événements│  │ - Durée     │  │ - Dates │ │
│  │ - Config    │  │ - Signature │  │ - Ornements │  │ - Titre │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                         UTILS LAYER                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ MeasureEditor   │  │ DurationConverter│  │ MusicSymbols    │  │
│  │ SelectionUtils  │  │ MeasureHelper   │  │ Constants       │  │
│  │ NoteEventHelper │  │ RestFiller      │  │ ErrorHandler    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Rôle détaillé de chaque Controller

### 1. StaffScreenController
**Responsabilité principale :** Contrôleur de l'interface utilisateur pour l'écran d'édition

**Fonctions clés :**
- **Gestion de l'état UI :** Maintient l'état de chargement, sélections actives
- **Coordination des interactions :** Orchestre les actions utilisateur (clics, sélections)
- **Gestion de la sélection :**
  - Symbole sélectionné (droite, gauche, silence, triolet)
  - Durée sélectionnée (noire, croche, etc.)
  - Note/événement sélectionné dans la partition
- **Opérations d'édition :**
  - Ajout de notes à une position donnée
  - Modification des notes existantes (accents, ornements)
  - Remplacement de notes
  - Gestion de la sélection automatique après édition

**Relations :**
- Utilise `ScoreWithMetadataController` pour les opérations sur les données
- Notifie les widgets via `ChangeNotifier`
- Reçoit les événements des widgets (StaffView, StaffControls, UnifiedPalette)

### 2. ScoreWithMetadataController
**Responsabilité principale :** Gestion des données de partition et métadonnées

**Fonctions clés :**
- **Gestion des données :**
  - Chargement/sauvegarde des partitions
  - Création de nouvelles partitions
  - Gestion de l'intégrité des données
- **Opérations CRUD :**
  - Ajout/modification/suppression de notes
  - Gestion des mesures (ajout, suppression)
  - Configuration de la partition (mesures par ligne)
- **Gestion des métadonnées :**
  - Titre, dates de création/modification
  - ID unique de la partition
- **Logique métier musicale :**
  - Création de triolets
  - Validation des durées
  - Normalisation des numéros de mesures

**Relations :**
- Utilise `StorageService` pour la persistance
- Utilise `MeasureEditor` pour les opérations sur les mesures
- Fournit les données à `StaffScreenController`

## Flux de données

### Ajout d'une note :
```
1. Utilisateur clique sur la portée (StaffView)
   ↓
2. StaffView.resolveTapTarget() calcule la position
   ↓
3. StaffView → StaffScreen.onBeatSelected()
   ↓
4. StaffScreen → StaffScreenController.addNoteAtBeat()
   ↓
5. StaffScreenController → ScoreWithMetadataController.addNoteAtBeat()
   ↓
6. ScoreWithMetadataController utilise MeasureEditor pour modifier les données
   ↓
7. ScoreWithMetadataController → StorageService.saveScore()
   ↓
8. StaffScreenController.notifyListeners() → Mise à jour UI
   ↓
9. StaffView utilise PageEngine pour recalculer le layout
   ↓
10. StaffPainter redessine la portée
```

### Sélection d'un symbole :
```
1. Utilisateur clique sur UnifiedPalette
   ↓
2. UnifiedPalette → StaffScreen._handleSymbolSelected()
   ↓
3. StaffScreen → StaffScreenController.setSelectedSymbol() ou replaceSelectedNote()
   ↓
4. StaffScreenController.notifyListeners() → Mise à jour UI
```

### Rendu de la portée :
```
1. StaffView utilise LayoutBuilder pour obtenir les contraintes
   ↓
2. PageEngine.layoutPage() calcule le positionnement des éléments
   ↓
3. StaffPainter utilise le PageLayoutResult pour dessiner
   ↓
4. Les différents painters (BeamPainter, GlyphPainter, etc.) dessinent leurs éléments
```

## Avantages de cette architecture

1. **Séparation des responsabilités :** Chaque couche a un rôle bien défini
2. **Testabilité :** Les controllers peuvent être testés indépendamment
3. **Réutilisabilité :** Les services peuvent être utilisés par différents controllers
4. **Maintenabilité :** Modifications localisées selon les couches
5. **Évolutivité :** Facile d'ajouter de nouvelles fonctionnalités

## Patterns utilisés

- **MVC (Model-View-Controller)** : Séparation claire des responsabilités
- **Observer Pattern** : Via `ChangeNotifier` pour la réactivité
- **Repository Pattern** : `StorageService` abstrait la persistance
- **Service Layer** : Services métier réutilisables
- **Immutable Data** : Modèles immutables avec `copyWith()`
