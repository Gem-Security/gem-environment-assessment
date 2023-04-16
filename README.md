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

#### Scanning organizations
The `-o` flag can be used to scan an AWS organization. This should be run from the master account of the organization. The script will then assume the specified role in all other accounts in the organization in order to scan them.
Usually this role is named `OrganizationAccountAccessRole`.

```bash
./aws.sh -o OrganizationAccountAccessRole | tee aws.log
```

#### Scanning specific regions
By default, the script will scan all enabled regions in the account. To scan only specific regions, use the `-r` flag.
Note that the flag can be used multiple times to scan multiple regions.

```bash
./aws.sh -r us-east-1 -r us-east-2 | tee aws.log
```
