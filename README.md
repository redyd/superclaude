# superclaude

Stack Claude Code personnelle : Superpowers (méthode), skills ECC (Spring Boot, JPA, Docker,
Postgres, API), Context7 (docs à jour), LSP (TS, Python, Java, C#), claude-mem (mémoire),
ponytail en mode lite (anti sur-engineering), frontend-design, Figma, Playwright.

## Installation

```bash
git clone https://github.com/redyd/superclaude.git ~/superclaude && ~/superclaude/install.sh
```

Le clone doit rester dans `~/superclaude` : la config de `~/.claude` pointe dessus par liens symboliques.

| Action | Commande |
|---|---|
| Ajouter un plugin | l'ajouter dans `claude/settings.json`, relancer `install.sh` |
| Rafraîchir les skills ECC | `./install.sh update-ecc`, puis commit |
| Synchroniser le portable | `git pull && ./install.sh` |

## Démarrer sur un projet

1. `cd` dans le repo, lancer `claude`.
2. `/init` génère un `CLAUDE.md` de projet. Le compléter avec :
   - les commandes de build, de test et de lancement (`./mvnw test`, `dotnet test`, `npm run dev`...) ;
   - l'architecture attendue (couches, conventions de nommage, dossiers) ;
   - ce qui est interdit (lib non validée par l'équipe, modification du schéma sans migration...).
3. Si le repo est partagé et que tu ne veux pas imposer ce fichier à l'équipe, mets tes notes
   personnelles dans `CLAUDE.local.md` et ajoute-le au `.gitignore`.
4. `/context` pour vérifier le coût de départ de la session.

## Workflow d'une fonctionnalité (Superpowers)

Les skills se déclenchent seuls ; il suffit de décrire ce que tu veux.

1. **Brainstorming** : « Je veux ajouter X ». Claude pose des questions, propose des options,
   puis écrit un document de design. Valide-le ou corrige-le avant de continuer.
2. **Worktree** : il crée une branche isolée et vérifie que les tests passent au départ.
3. **Plan** : découpage en petites tâches avec fichiers et étapes de vérification. Relis-le :
   c'est le meilleur moment pour recadrer.
4. **Exécution** : réponds « go ». Les sous-agents implémentent en TDD et se relisent.
5. **Fin** : revue, tests verts, puis merge ou PR avec `gh`.

Pour une petite correction, ce cérémonial est inutile : demande directement, ou passe en
mode plan avec `Shift+Tab`.

## Commandes utiles

| Commande | Usage |
|---|---|
| `Shift+Tab` | Bascule en mode plan (lecture seule, propose avant d'agir) |
| `/clear` | Nouvelle tâche : repart d'un contexte vide |
| `/compact` | Session longue : résume l'historique pour libérer du contexte |
| `/context` | Voir ce qui consomme le contexte |
| `/resume` | Reprendre une session précédente |
| `/model` | Changer de modèle |
| `/plugin`, `/mcp` | Gérer plugins et serveurs MCP |
| `Esc Esc` | Revenir à un message précédent |
| `!commande` | Lancer une commande shell sans passer par Claude |

### Ponytail

| Commande | Usage |
|---|---|
| `/ponytail` | Affiche le niveau actuel (lite par défaut) |
| `/ponytail off` | Le couper, par exemple pour un projet d'école où la structure compte plus que la concision |
| `/ponytail-review` | Chercher du sur-engineering dans le diff courant |
| `/ponytail-audit` | Même chose sur tout le repo |
| `/ponytail-debt` | Lister les raccourcis laissés « pour plus tard » |

### Docs, mémoire, navigateur

- **Context7** : ajouter « vérifie avec context7 » quand la version d'une lib compte
  (Spring Boot 3, .NET, Next.js).
- **claude-mem** : le contexte des sessions passées est injecté automatiquement. Pour
  chercher : « qu'est-ce qu'on avait décidé sur l'auth ? ».
- **Playwright** : « ouvre localhost:3000 et vérifie que le formulaire s'affiche ».

## Bonnes pratiques

- Une session = une tâche. `/clear` entre deux sujets sans rapport.
- Commit avant de lancer une grosse modification : le retour arrière est gratuit.
- Relire le plan plutôt que le code : c'est là que se jouent les erreurs de direction.
- Si Claude fusionne des couches d'architecture, le rappeler au `CLAUDE.md` du projet.
