# Analyse des fonctionnalités de base – The Wanderer Eternal Dungeons

Tour d’horizon des manques et des améliorations à prévoir pour un roguelike Love2D fonctionnel.

---

## Critiques – À corriger en priorité

### 1. Pas de victoire / sortie du donjon
La sortie existe (`gameState.exit`) et est générée à la dernière salle, mais :
- Elle est posée comme un simple `floor` (pas de tuile spéciale).
- **Aucune logique ne détecte quand le joueur marche dessus.**
- Le joueur ne peut donc jamais "gagner" un étage ni sortir du donjon en atteignant la sortie.

**À faire :** Dans `action_resolver.lua` (après le déplacement), vérifier si `(nx, ny) == (gameState.exit.x, gameState.exit.y)` pour le joueur → déclencher une victoire (retour au hub avec succès, conservation de l’équipement, etc.).

---

### 2. Pas de sauvegarde réelle
- `save.lua` enregistre seulement `last_save` (timestamp) via `config`.
- `save.save()` **n’est jamais appelé** dans le projet.
- `player_data`, `game_state`, inventaire et or ne sont jamais persistés.
- "Continuer" au menu principal remplace la scène par `hub_main` sans charger aucune donnée.

**À faire :**
- Choisir quand sauvegarder : fin de donjon réussie, pause, maison, banque, etc.
- Implémenter `save.save()` qui sérialise : personnage, or, banque, inventaire.
- Implémenter `save.load()` et brancher "Continuer" dessus.

---

### 3. Sortie non identifiée visuellement
- La sortie est une tuile `floor` comme les autres.
- La minimap ne la distingue pas.
- Le joueur ne peut pas savoir où aller.

**À faire :**
- Tuile dédiée (ex. `exit`) ou sprite différent.
- Rendu spécial sur la minimap (ex. échelle descendante / portail).

---

## Moyens – À traiter ensuite

### 4. Entrée "Sauvegarde" dans le menu
- Les clés `dungeon.menu.save`, `save_action`, `saved` existent en i18n.
- Le menu contexte et le menu pause n’ont pas d’option "Sauvegarder".
- Aucun bouton ne déclenche `save.save()`.

**À faire :** Ajouter "Sauvegarder" au menu pause (donjon) ou au menu contexte, et appeler `save.save()` puis afficher un message de confirmation.

---

### 5. Continue au démarrage
- "Continuer" n’apparaît que si `save.has_save()` est vrai.
- Comme `save.save()` n’est jamais appelé, `last_save` reste `nil` et "Continuer" n’apparaît jamais.

**À faire :** Une fois la sauvegarde implémentée, le flux Continue → `save.load()` → hub sera cohérent.

---

### 6. Touche "Retour" dans le donjon
- `input.consume("back")` à la ligne 423 de `dungeon_run.lua` fait `replace:hub_main` et `clear`.
- `back` et `pause` sont tous deux mappés sur `escape`.
- Comme `pause` est consommé avant, ce bloc "back" ne s’exécute jamais en pratique.

**À faire :** Soit le supprimer s’il est inutile, soit ajouter une touche dédiée pour quitter directement le donjon (par ex. Alt+Échap).

---

### 7. Équilibrage de la pénalité de mort
- `applyDeathPenalty` : personnage reset niveau 1, or = 0, inventaire vidé.
- Très brutal pour un roguelike classique.

**À faire :** Réfléchir à une pénalité plus nuancée (or perdu, inventaire partiel, équipement conservé, etc.) selon le design voulu.

---

## Mineurs – Finitions

### 8. i18n
- Les clés `log.*` utilisées dans le code sont en grande partie couvertes en `fr.lua` et `en.lua`.
- À vérifier : `log.effect.<effectId>` (empoisonnement, brûlure, etc.) et les effets dynamiques.
- `item.cursed_unequip` est utilisé (inventaire) : à confirmer dans les deux locales.

---

### 9. État initial du joueur
- `player_data.reset()` : or = 100, inventaire vide, banque vide.
- `game_state.reset()` : personnage niveau 1.
- Cohérent pour un "New Game", mais à valider avec la boucle de progression souhaitée.

---

### 10. Un seul donjon
- Seul "Les Ruines" est disponible via la carte du monde.
- Le système supporte plusieurs donjons (data-driven), mais un seul est connecté.

**À faire (optionnel) :** Ajouter d’autres donjons une fois la boucle de base (entrée → combat → loot → sortie) validée.

---

## Déjà en place

- Journal : ouverture, défilement, log des actions.
- Combat : attaque, critique, sorts, résolution des dégâts.
- Loot : au sol et sur monstres, avec affixes et niveaux.
- Pièges : déclenchement et résolution.
- Effets : poison, brûlure, ralentissement, etc.
- Inventaire, équipement, objets maudits (déséquipement bloqué).
- Hub : boutique, banque, taverne, maison, carte du monde.
- Options : langue, résolution, plein écran.
- Menu pause : reprendre, options, retour au hub, quitter.

---

## Synthèse des priorités

| Priorité | Élément | Impact |
|----------|---------|--------|
| **P0** | Condition de victoire (marcher sur la sortie) | Boucle de donjon complète |
| **P0** | Sauvegarde / chargement réels | Progression persistante |
| **P1** | Affichage visuel de la sortie | Lisibilité et objectif clair |
| **P1** | Bouton Sauvegarder + appel à `save.save()` | Sauvegarde utilisable |
| **P2** | Pénalité de mort ajustée | Expérience de jeu |
| **P2** | Nettoyage du bloc `back` donjon | Cohérence du code |

---

*Analyse réalisée le 18/02/2025.*
