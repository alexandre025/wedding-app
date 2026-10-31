# Wedding app

The invitation site for Chloé & Alexandre — 1–2 July 2028, Domaine de la Ferme
au Moulin, Pont-Saint-Mard.

Rails 8.1 with Hotwire (Turbo + Stimulus), Propshaft, import maps and Tailwind
CSS. HTML+ERB templates are linted and formatted with [Herb](https://herb-tools.dev).
Every word on screen is French; routes, actions, templates and locale keys are
English. All copy lives in `config/locales/fr.yml`.

## Pages

| Path | Screen |
|---|---|
| `/` | Accueil — the invitation itself |
| `/schedule` | Programme & infos pratiques |
| `/rsvp` | Réponse — the invitation email gate |

The couple's admin screens live under `/admin`, behind HTTP Basic. The RSVP form
is not built yet. The gate's "invitation retrouvée" state is client-side only:
it checks the shape of the address, not a guest list, so it must be replaced by
a real lookup before the site goes live.

## Getting started

Ruby 4.0.6 (see `.ruby-version`) and Node 24 (see `.node-version`) are needed —
Node only for the Herb linter and formatter, never for the asset build.

```sh
docker compose up -d   # PostgreSQL for development and test
bin/setup              # installs dependencies, prepares the database, starts the server
```

`bin/dev` starts Puma with the Tailwind watcher attached (see the
`plugin :tailwindcss` line in `config/puma.rb`), so a single process rebuilds
`app/assets/builds/tailwind.css` as you edit.

Design tokens — the palette and the three typefaces — live in the `@theme`
block of `app/assets/tailwind/application.css`.

## Checks

```sh
bin/ci
```

runs the whole suite: RuboCop, `herb-lint`, `herb-format --check`, the gem and
import map audits, Brakeman, the specs, the seeds file and the production asset
build. Individually:

```sh
bin/rubocop
npm run herb:lint
npm run herb:format
bundle exec rspec
```

GitHub Actions runs the same checks as six jobs — `scan_ruby`, `scan_js`,
`lint`, `lint_erb`, `test` and `build` — on every pull request and every push to
`main`. All six must be green before a pull request can be merged; `main` takes
no direct pushes.
