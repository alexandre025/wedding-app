# Conventions

The README says how to run this app. This file says how to write for it: the
decisions that have been settled, and the reason each one was settled that way.

Reasoning for a *particular* change belongs in its commit message. What lands
here is only what outlives the change — the rules the next screen has to follow.
When a decision is overturned, rewrite the rule here in the same commit that
overturns it.

## Language

Every word on screen is French. Everything a developer types is English: class
names, routes, actions, columns, template names, locale keys, branch names,
commit messages, spec descriptions.

All copy lives in `config/locales/fr.yml` — there is one locale and no plan for
a second. Nothing user-visible is hardcoded in a template, not even a `·`
separator or an `aria-label`.

Translation keys are always written out in full:

```erb
<%= t("admin.families.index.title") %>   <%# yes %>
<%= t(".title") %>                       <%# no %>
```

Lazy lookup hides where a string lives: `t(".title")` only resolves once you
know which template you are in, and nothing finds it from the locale file end.
Full keys are greppable in both directions.

Example data in specs, factories and seeds is French too — `exemple.fr`
addresses, French first names. It keeps the fixtures reading like the real
guest list, accents and apostrophes included.

## Class names

Namespaced classes are declared with their full path, never with a nested
module:

```ruby
class Admin::FamilyForm < ApplicationForm   # yes
module Admin; class FamilyForm; end; end    # no
```

One line tells you what the class is called. Nesting also opens the enclosing
namespace for constant lookup, so an unqualified `Family` inside `module Admin`
can silently resolve to `Admin::Family` if one ever appears.

## Forms own the rules; models own almost nothing

Validations and normalization live on the form objects in `app/forms` — built
on [HyperActiveForm](https://github.com/Intrepidd/hyperactiveform) — rather than
on the model, with the single exception named below:

```ruby
class Admin::FamilyMemberForm < ApplicationForm
  proxy_for FamilyMember, :@family_member

  attribute :email
  after_assign_form_attributes :normalize

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
end
```

The forms own the wording and the shape of a submission; the models own nothing
a console session or a seed script can trip over. The database still holds the
line underneath — `null: false` on the columns that must be there, a unique
index where uniqueness matters — so the data stays sound without the model
re-stating it.

A model therefore carries only: associations, constants (`AGE_GROUPS`,
`SEARCH_PREDICATE`), small predicates (`answered?`), and the Ransack
allowlists. No `normalizes`, no callbacks, and no `validates` — with one
exception.

**Uniqueness is the exception.** It lives on the model, because it is a
statement about the table rather than about one submission, and the database
already backs it with a unique index. A nullable unique column needs
`allow_nil: true` or every member without an address collides with the others,
and `case_sensitive: false`, because the model cannot normalize the value first.

Each form implements `setup` (read the record into attributes) and `perform`
(write them back, then save). A form over a model with no validations ends in
`save!` — a falsey return is unreachable, and a constraint violation raises
whichever call you use. A form over a model that *can* fail validation ends in
`save || add_errors_from(record)`, so the failure renders as a field error
instead of a 500: `Admin::FamilyMemberForm` is the one that does, because of the
uniqueness rule above. Controllers call `@form.submit(params)` and branch on the
result.

## The database

**No foreign keys.** Not on any of the app's own tables, not in any migration we
write. `dependent: :destroy` is what clears a family's members; a raw `DELETE`
would leave them behind, and that is accepted. Do not add `foreign_key: true`
to a migration, and do not "fix" `db/schema.rb` by adding one. (Solid Queue's
own `db/queue_schema.rb` keeps the keys Rails ships it with — it is generated,
not ours.)

Everything else leans on Postgres: `null: false` on columns that must be
present, unique indexes where uniqueness matters. A nullable unique column is
the idiom for "optional but unique" — Postgres allows many NULLs under one
index — which is why a blank email normalizes to `nil` rather than `""`.

Search is Ransack with an explicit `ransackable_attributes` allowlist on every
model, and the `i_cont` predicate rather than `cont`: plain `cont` is `LIKE`,
case sensitive on Postgres, and would miss "Melchior" for "melch". The
predicate itself is a model constant so the controller, the view and the specs
all name the same thing.

## Controllers

Plain REST actions, one resource per controller, shallow nesting in the routes.
Members are their own resource with their own form rather than nested fields
inside the parent's.

`before_action` setters and `*_params` go in a `private` section, indented under
the keyword — Omakase RuboCop style:

```ruby
  private
    def set_family
      @family = Family.find(params[:id])
    end
```

Failed submissions `render :new, status: :unprocessable_content`. Successful
ones redirect with a `notice:` read from the locale file.

The admin area sits behind HTTP Basic in `Admin::BaseController`, compared with
`ActiveSupport::SecurityUtils.secure_compare`. Credentials come from
`config.x.admin` so each environment sets its own — development skips the check
entirely, test uses `admin`/`admin`, production reads the environment.

## Views

Every partial declares strict locals on its first line:

```erb
<%# locals: (caption:, value:, emphasis: false) %>
```

Tailwind v4 with the design tokens from the "Mariage — prototype" canvas in the
`@theme` block of `app/assets/tailwind/application.css`. Use the token
(`text-ink-muted`, `border-rule-sage`, `font-display`) — never a raw hex in a
template. A one-off pixel value in brackets (`text-[15px]`) is fine; a one-off
colour is not.

Icons are ERB partials in `app/views/shared/icons`, rendered through the
`icon()` helper, so they inherit `currentColor` and can be sized at the call
site. No icon font, no sprite sheet, no inline SVG in a page template.

HTML+ERB is linted and formatted by [Herb](https://herb-tools.dev) — it sorts
the Tailwind classes and wraps at 120 columns, so write the markup and let
`npm run herb:format` settle the layout.

## JavaScript

Hotwire only. Turbo frames for in-place updates (the families list refreshes
inside `families_results`), Stimulus for behaviour. No build step: import maps
and Propshaft serve the files as they are, and Node is only ever used for the
Herb linter and formatter.

A Stimulus controller stays small enough to read in one screen, declares its
`targets` and `values`, and cleans up after itself in `disconnect`.

## Specs

RSpec and FactoryBot. `spec/` mirrors `app/`.

Request specs over controller specs: they exercise routing, authentication and
rendering together. `assert_select` is kept for assertions about rendered copy —
it decodes entities, and the French copy is full of apostrophes that `include`
would have to match escaped. Assertions read against `I18n.t(...)`, never
against a literal French string.

Factories use sequences for anything unique and traits for the interesting
states (`:answered`, `:with_email`). The suite truncates before it runs, because
`bin/ci` seeds the test database and nothing else clears it.

## Comments

The code carries no comments. The reasoning behind a change goes in the commit
message, where it stays attached to the diff that needs it and does not drift
out of date in place. A comment that survives is a sign the code should be
clearer or the name better.

The exception is a note marking something deliberately unfinished — the RSVP
gate is client-side until there is a guest list to query — which exists to stop
the next reader taking the placeholder for the real thing.

## Git

Branches are prefixed by the area they touch: `admin/families-crud`,
`pages/schedule`.

Commit messages are prose, not bullet lists, and explain *why* in enough detail
that the diff needs no comments. They are the project's decision log.

`main` takes no direct pushes. Every change arrives as a pull request with all
six GitHub Actions jobs green — `scan_ruby`, `scan_js`, `lint`, `lint_erb`,
`test`, `build`. Run `bin/ci` locally first; it runs the same steps.

One gotcha: `bin/ci`'s asset step ends with `assets:clobber assets:precompile`,
which leaves `app/assets/builds/tailwind.css` built for production. Restart
`bin/dev` afterwards or the next page you load will be styled by a stale
stylesheet.

Alexandre reviews and merges every pull request himself.
