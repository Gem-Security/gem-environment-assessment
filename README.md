# Cloud Resource Assessment Scripts
This GitHub repository contains shell scripts that can be used to assess cloud environment workload.

## Usage
The scripts are designed to be run from the command line. They will output a log file containing the results of the assessment.

### AWS
```bash
./aws.sh | tee aws.log
```

#### Requirements
AWS assessment script requires the AWS CLI to gather information about the environment.
AWS CLI v2 must be installed and configured. The script will use the default profile unless a different one is specified.

#### Choosing a profile
The `-p` flag can be used to specify a profile to use for the AWS CLI. This is useful if you have multiple AWS accounts configured.

```bash
./aws.sh -p my-profile | tee aws.log
```
