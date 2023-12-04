# tidybee-scripts
## Run tidybee containers
Build, run and stop containers using the following commands:
```
git clone git@github.com:tidybee/tidybee-scripts.git
cd tidybee-scripts
docker compose -f docker-compose.yml <COMMAND> [SERVICE...]
```

## Run tidybee containers (debug)
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
ln -s tidybee-scripts/docker-compose-local.yml .
```

Now you should have this file structure:
```
.
├── docker-compose-local.yml -> tidybee-scripts/docker-compose-local.yml
├── tidybee-agent/
├── tidybee-frontend/
├── tidybee-hub/
└── tidybee-scripts/
```

Build, run and stop containers:
```
docker compose -f docker-compose-local.yml <COMMAND> [SERVICE...]
```
