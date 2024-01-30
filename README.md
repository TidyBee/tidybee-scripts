# tidybee-scripts

## compose

### Run tidybee containers
#### Setup SSH agent
[Follow these instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) to generate a new SSH key and add it to the ssh-agent.

Then build, run and stop containers using the following commands:
```
git clone git@github.com:tidybee/tidybee-scripts.git
cd tidybee-scripts/compose
docker compose <COMMAND> [SERVICE...]
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
docker compose -f docker-compose-local.yml <COMMAND> [SERVICE...]
```
