# tidybee-scripts

## compose

### Run containers from GHCR (recommended)

The default compose file will pull the images from GitHub Container Registry and run them. Use the following commands to do so:

```
git clone git@github.com:tidybee/tidybee-scripts.git
cd tidybee-scripts/compose
docker compose <COMMAND> [SERVICE...]
```

### Run containers from git repositories

#### Setup SSH agent

[Follow these instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) to generate a new SSH key and add it to the ssh-agent.

Then build, run and stop containers using the following commands:

```
git clone git@github.com:tidybee/tidybee-scripts.git
cd tidybee-scripts/compose
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
docker compose -f docker-compose-local.yml <COMMAND> [SERVICE...]
```

## DB

This repo also contains postgres DB which is used to store all the files & the rules of Tidybee solution.

### Env

Please fulfill that .env file to try locally

```
POSTGRES_DB=db
POSTGRES_USER=user
POSTGRES_PASSWORD=pass
```

### Get started

```bash
cd ./compose
docker compose -f hub-postgres.yml up
```

Connect to db

```bash
psql -h <host> -U <username> -d <db_name>
```

You can now interact with db and use major procedure stored inside and then watch the computed score for each files

```
CALL calculate_every_perished_scores();
CALL calculate_every_misnamed_scores();
CALL calculate_every_duplicated_scores();
CALL calculate_every_global_scores();
```
