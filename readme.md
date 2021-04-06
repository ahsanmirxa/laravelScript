## wpSetup

This script will setup Laravel project based on provided repository

Required parameters are **projectName**, **dbName**, **dbUser**, **dbPassword**, **repositoryUrl** **rootPassword** and **webUrl**

###### Pre-Requisites

If it is a private repository, make sure to add server SSH public key in repository before executing this script

**_projectName_** and **_repositoryName_** must be same

**_targetDirectory_**, **_dbUser_** and **_dbPassword_** must exist

**_webUrl_** must be pointed to the target server already so that SSL can be applied

Do not end **_targetDirectory_** with forward slash
