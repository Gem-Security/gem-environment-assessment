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

AWS permissions required for the script to run:
- `dynamodb:ListTables`
- `ec2:DescribeInstances`
- `ec2:DescribeVpcs`
- `eks:ListClusters`
- `elasticloadbalancing:DescribeLoadBalancers`
- `lambda:ListFunctions`
- `rds:DescribeDBClusters`
- `rds:DescribeDBInstances`
- `redshift:DescribeClusters`
- `s3:ListBuckets`
- `wafv2:ListWebACLs`
- `organizations:ListAccounts` - If using the `-o` flag for scanning an entire organization
- `ec2:DescribeRegions` - Unless using the `-r` flag to scan specific regions

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

### Azure
```bash
./azure.sh | tee azure.log
```

#### Requirements
Azure assessment script requires the Azure CLI to gather information about the environment.
Azure CLI must be installed and configured.

JQ is also required to parse the JSON output from the Azure CLI.

The assessment script uses Azure Resource Graph to query the environment.
User must have read access to all resources in the relevant subscriptions in order to gather information about them.
Resource Graph uses the subscriptions available to a principal during login. To see resources of a new subscription added during an active session, the principal must refresh the context. This action happens automatically when logging out and back in.

#### Limiting the scope of the assessment for certain subscriptions
The `-s` flag can be used to scan certain subscriptions.
Note that the flag can be used multiple times to scan multiple subscriptions.

```bash
./aws.sh -s 11111111-1111-1111-1111-111111111111 -s 22222222-2222-2222-2222-222222222222 | tee azure.log
```

#### Limiting the scope of the assessment for certain management groups
The `-m` flag can be used to scan certain management groups.
Note that the flag can be used multiple times to scan multiple management groups.

```bash
./aws.sh -m aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa -m bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb | tee azure.log
```
