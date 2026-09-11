---
name: bump-crossme
description: Update the pinned CrossMe revision in this nix config, and/or deploy CrossMe to nelhage.com. Use when asked to bump, update, or deploy crossme (beta.crossme.app), or to test a specific crossme commit on the server.
---

CrossMe is deployed on `hw4` (= nelhage.com) as two docker-compose services,
`crossme-statics` and `crossme-api`, both built directly from a GitHub URL
context pinned to a sha1.

The pin lives in git in `modules/nelhage-services/config/.env`:

```
CROSSME_V2_REVISION=<sha1>
```

The pin can also be overriden without touching git using `~/Sync/config/nelhage-services.env`.

`modules/nelhage-services/config/docker-compose.yaml` interpolates it into the
build contexts (`https://github.com/nelhage/crossme.git#${CROSSME_V2_REVISION-main}`,
and `...:client` for the statics image).

## Updating and deploying

### To resolve a target revision

`crossme` is located at https://github.com/nelhage/crossme.git ; use `git ls-remote`. e.g. if asked to deploy "current main":

```
git ls-remote https://github.com/nelhage/crossme.git main
```

Always pin a full sha1, never a branch name.

### Updating the configured revision

- If asked to deploy a revision without further specification, use the temporary overrride file (~/Sync/config/nelhage-services.env).
- If asked to update the committed config, or to update git, first **remove** any `CROSSME_V2_REVISION=` override from the path in ~/Sync, and instead edit `modules/nelhage-services/config/.env`

Set `CROSSME_V2_REVISION=<sha1>` in the appropriate file. Use a full sha1, never a branch name.

Commit the change if asked to do so.

### Deploying

Do not assume that a request to update the state in `git` corresponds to a request to do a deploy; only do a deploy if explicitly asked.

If you are using the untracked ~/Sync path, you do not need to interact with nixos.

If you are being asked to deploy a state from the in-git nixos configuration, or are explicitly asked to do a `nixos-switch`, first run `sudo nixos-rebuild switch` at the root of the `nix-config` repository. There is no need to pass `--flake`; the machine is configured such that it will discover the correct configuration.

Then, to actually deploy the service, run:

```
nelhage.com-docker-compose up -d --build crossme-statics crossme-api
```

## Rules

Never run any of these steps unless the user asked for them.

The default scope for a request like "deploy crossme to current main" is to update the override in ~/Sync and run `nelhage.com-docker-compose`. Only touch the state in the repository or `nixos-rebuild` if requested. In any case, state clearly which steps you did run and which files you edited.
