# tidybee-scripts

## compose

Choose one of the 3 solutions below to run the containers (depending on your configurations, you may need to run docker with the root permissions).

### Run containers from GHCR (recommended)

The default compose file will pull the images from GitHub Container Registry and run them. Use the following command to do so:

```
# tidybee-scripts/compose
docker compose <COMMAND> [SERVICE...]
```

### Run containers from git repositories

Build, run and stop containers using the following command:

```
# tidybee-scripts/compose
docker compose -f docker-compose-git.yml <COMMAND> [SERVICE...]
```

### Run tidybee containers (debug)

Clone the repositories:

```
# agent
git clone git@github.com:tidybee/tidybee-agent.git

# hub
git clone git@github.com:tidybee/tidybee-hub.git

# frontend
git clone git@github.com:tidybee/tidybee-frontend.git

# scripts
git clone git@github.com:tidybee/tidybee-scripts.git
ln -s tidybee-scripts/compose/docker-compose-local.yml .
```

Now you should have this file structure:

```
.
├── docker-compose-local.yml -> tidybee-scripts/compose/docker-compose-local.yml
├── tidybee-agent/
├── tidybee-frontend/
├── tidybee-hub/
└── tidybee-scripts/
```

Build, run and stop containers:

```
docker compose -f docker-compose-local.yml --env-file tidybee-scripts/compose/.env <COMMAND> [SERVICE...]
```
