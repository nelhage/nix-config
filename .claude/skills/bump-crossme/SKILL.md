---
name: bump-crossme
description: Update the pinned CrossMe revision in this nix config, and/or deploy CrossMe to nelhage.com. Use when asked to bump, update, or deploy crossme (beta.crossme.app), or to test a specific crossme commit on the server.
---

CrossMe is deployed on `hw4` (= nelhage.com) as two docker-compose services,
`crossme-statics` and `crossme-api`, both built directly from a GitHub URL
context pinned to a sha1.

The pin lives in `modules/nelhage-services/config/.env`:

```
CROSSME_V2_REVISION=<sha1>
```

`modules/nelhage-services/config/docker-compose.yaml` interpolates it into the
build contexts (`https://github.com/nelhage/crossme.git#${CROSSME_V2_REVISION-main}`,
and `...:client` for the statics image).

## Bumping the pin

1. Resolve the target revision. For "current main":

   ```
   git ls-remote https://github.com/nelhage/crossme.git main
   ```

   Always pin a full sha1, never a branch name.

2. Edit `CROSSME_V2_REVISION` in `modules/nelhage-services/config/.env`.

3. Commit the change.

## Deploying

These are three *separate* steps. Do not assume one implies another.

**`nixos-rebuild switch` does not deploy the site.** The compose wrapper
(`nelhage.com-docker-compose`) points at a `docker-compose.yaml` and `.env`
baked into the nix store, so a switch only updates which revision the wrapper
*would* build. The running containers are untouched until they are rebuilt.

To actually deploy the pinned revision (run on `hw4`, after switching):

```
nelhage.com-docker-compose up -d --build crossme-statics crossme-api
```

To deploy an arbitrary revision **without** touching or switching the nix
config — useful for testing a commit before pinning it — override the variable
in the environment; a shell env var takes precedence over the store `.env`:

```
CROSSME_V2_REVISION=<sha1> nelhage.com-docker-compose up -d --build crossme-statics crossme-api
```

Note that such a deploy is temporary in the sense that it is not recorded
anywhere: the next unqualified `up --build` will rebuild from whatever the
activated nix config pins.

## Rules

Never run any of these steps unless the user asked for them. In particular do
not run `nixos-rebuild switch` or any `nelhage.com-docker-compose` command on
your own initiative — editing and committing the pin is the default scope. The
user may request any subset (bump only, bump + switch, bump + switch + deploy,
or an ad-hoc revision deploy with no config change); do exactly what was asked
and say plainly which steps you did and did not run.
