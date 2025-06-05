# Clicker Idle Game (Godot 4)

Jednoduchá idle/clicker hra vytvořená v enginu **Godot 4** jako semestrální projekt.

## 🎮 Jak hrát

- Kliknutím na **tlačítko s obrázkem** získáváš body.
- Za body můžeš kupovat **roboty (generátory)**, které ti přidávají body automaticky.
- Každý robot má:
  - **Základní cenu**
  - **Zisk bodů za sekundu**
  - Možnost vylepšení za **prestige body**
  - **Vylepšit za X prestige** = výměna prestige bodů za trvalé zlepšení efektivity konkrétního typu robota.

- **Prestige**:
  - Jakmile získáš **1000 bodů**, můžeš použít tlačítko `Prestige (reset za bonus)`
  - Resetuje body a generátory, ale přidá ti **prestige body**
  - Každý prestige bod zvyšuje zisky o +10 %

- **Prestige Shop**:
  - Umožňuje výběr z 3 náhodných vylepšení za prestige body:
	- `+1 klik` – přidává bonus k ručnímu kliku
	- `+10 % idle` – zvyšuje idle příjem
	- `Zlevnění robotů` – snižuje ceny robotů
	- `+1 auto-click/s` – automatické klikání
	- `+5 % celkový příjem` – zvyšuje všechny zisky

## 🏆 Achievementy

Ve hře je 10+ achievementů, které se odemykají za splnění různých úkolů (např. první klik, nákup 100 robotů, 10 prestige bodů apod.). Odměna je zatím symbolická (zobrazení okna).

## 💾 Ukládání a načítání

- Hra se automaticky ukládá při ukončení (`savegame.cfg` v `user://`)
- Při načtení se počítá také offline idle zisk (kolik by sis vydělal od posledního hraní)

---

Enjoy clicking! 🖱️🤖💸
