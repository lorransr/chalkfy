# Contributing

## Design

- Keep the behaviour in deep modules: a lot of behaviour behind a small, stable interface. The code that talks to macOS is a thin adapter around them, with no rules of its own.
- Put a new rule behind an interface that exists before you make an interface wider.
- Test through the public interface, so a refactor inside a module keeps the tests green. Do not make a function public, or extract it, only to test it.
- Before you add a type or a file, imagine you delete it. If its complexity then spreads across its callers, it earns its place. If it only passes calls through, do not add it.

## Language

Use the terms in `CONTEXT.md` in code, issues and commits. A new concept gets its term there first.

## Decisions

Record a decision that a future change could undo by mistake as an ADR, in `docs/adr/`: the context, the decision and the reason. Record a rejected design too, so nobody proposes it again.

## Changes

- One issue, one pull request that says `Closes #N`.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).
- The logo and the icons come from the VectorCraft file in `brand/`.
