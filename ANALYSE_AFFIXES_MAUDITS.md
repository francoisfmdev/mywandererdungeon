# Analyse - Affixes, objets maudits, identification

## ✅ Implémenté correctement

1. **Interface loot au sol** – S’ouvre à chaque pas sur une case avec objets
2. **Objets maudits (10 %)** – `cursed_affixes.lua` + `loot_generator`
3. **Identification** – Parchemin identifie tout l’équipement/inventaire
4. **Équipement maudit** – Impossible à retirer (`equipment_manager`)
5. **Affichage "Objet inconnu"** – Pour objets non identifiés (`item_display`)
6. **Scroll identify en hub** – Géré dans l’inventaire
7. **Log maudit** – Message quand on tente de retirer un objet maudit

---

## ⚠️ Points à corriger

### 1. **Equipment manager – sauvegarde `identified` / `cursed`**

`_itemToSaveData` ne sauvegarde que `id`, `affixes`, `bonuses`.  
Les champs `identified` et `cursed` sont perdus lors de toute sauvegarde/chargement.

**À faire** : utiliser `ItemInstance.toSaveData` dans `_itemToSaveData`.

---

### 2. **Ground loot – perte d’objet si équipement impossible**

Dans `dungeon_ground_loot.lua`, on appelle `equip()` sans vérifier le retour.  
Si l’équipement échoue (ex. slot bloqué par un objet maudit), l’objet est quand même retiré du sol → perte.

**À faire** : ne retirer l’objet du sol que si `equip()` renvoie `true`.

---

### 3. **Inventaire hub – même risque de perte**

Même logique : `equip()` sans contrôle du résultat, puis `table.remove(inv, _invSel)`.

**À faire** : vérifier le retour de `equip()` et ne supprimer de l’inventaire que si succès.

---

### 4. **Message si slot bloqué par objet maudit**

Quand `equip()` échoue à cause d’un objet maudit dans le slot (`cursed_in_slot`), aucun feedback.

**À faire** : log du type "Objet maudit occupe ce slot" (ou équivalent).

---

### 5. **Log lors du ramassage dans la scène loot**

Avant, le ramassage déclenchait "Vous trouvez {item}".  
Avec la nouvelle interface, on n’ajoute plus de log.

**À faire** : appeler `log_manager.add("loot", ...)` quand l’utilisateur ramasse un objet dans `dungeon_ground_loot`.

---

### 6. **Monstres – loot non identifié (optionnel)**

Les drops des monstres sont tous identifiés (`ItemInstance.create(id)` sans `identified = false`).  
Pour rester cohérent avec les objets au sol, on pourrait ajouter une chance de non-identification.

---

## 📋 Récapitulatif des corrections proposées

| Priorité | Fichier                           | Correction |
|----------|-----------------------------------|------------|
| Haute    | `equipment_manager.lua`           | Utiliser `ItemInstance.toSaveData` dans `_itemToSaveData` |
| Haute    | `dungeon_ground_loot.lua`         | Vérifier le retour de `equip()` avant de retirer l’objet |
| Haute    | `inventory.lua`                   | Vérifier le retour de `equip()` avant de retirer l’objet |
| Moyenne  | `dungeon_ground_loot.lua`         | Ajouter un log quand on ramasse un objet |
| Moyenne  | Locales + `inventory` / `ground_loot` | Message "Slot maudit" pour `cursed_in_slot` |
| Basse    | `death_handler.lua`               | (Optionnel) Loot de monstre parfois non identifié |
