# tidybee-scripts
## Set up TidyBee repositories
### frontend repository
```
git clone git@github.com:TidyBee/tidybee-frontend.git
(cd tidybee-frontend && git checkout 40-dev-dockerfile-for-tidybee-scripts)
```

### hub repository
```
git clone git@github.com:TidyBee/tidybee-hub.git
(cd tidybee-hub && git checkout 12-dev-dockerfile-for-tidybee-scripts)
```

### agent repository
```
git clone git@github.com:TidyBee/tidybee-agent.git
(cd tidybee-agent && git checkout 79-improve-the-agents-dockerfile-and-add-docs-on-how-to-run-it)
```

### scripts repository
```
git clone git@github.com:TidyBee/tidybee-scripts.git
cp tidybee-scripts/docker-compose-local.yml .
```

Now you should have this file structure:
```
.
├── docker-compose-local.yml
├── tidybee-agent/
├── tidybee-frontend/
├── tidybee-hub/
└── tidybee-scripts/
```

## Run TidyBee containers
### Create and start containers
```
docker compose -f docker-compose-local.yml up [SERVICE...]
```

### Stop and remove containers
```
docker compose -f docker-compose-local.yml down [SERVICE...]
```
