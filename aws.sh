#!/bin/sh
set -euo pipefail

export AWS_RETRY_MODE=standard
export AWS_MAX_ATTEMPTS=5
export AWS_STS_REGIONAL_ENDPOINTS=regional

PROFILE=""

while getopts "hp:" opt; do
  case $opt in
    h)
      echo "Usage: $0 [-p profile]"
      echo "  -p profile  Use the specified AWS profile"
      exit 0
      ;;
    p)
      PROFILE=$OPTARG
      ;;
    \?)
      exit 1
      ;;
    :)
      exit 1
      ;;
  esac
done

if ! aws --version | grep -Eq 'aws-cli/2'; then
  echo "This script requires aws-cli version 2"
  exit 1
fi

profile_flag=""
if [ -n "$PROFILE" ]; then
  profile_flag="--profile $PROFILE"
fi

_aws() {
  aws --no-cli-pager ${profile_flag} $@
}

aws_count() {
  local service="${1}"; shift
  local command="${1}"; shift
  local query="${1}"; shift

  _aws --region ${REGION} --output json "${service}" "${command}" --query "length(${query})" $@ 2>/dev/null || echo "unknown"
}

echo_count() {
  local display_name="${1}"; shift
  local count="${1}"; shift

  echo "        * ${display_name} - ${count}"
}

scan_account_region() {
  REGION="${1}"
  local count=0
  echo "    [+] Scanning region ${REGION}"

  count=$(aws_count rds describe-db-clusters 'DBClusters')
  echo_count "AWS::RDS::DBClusters" "${count}"
  [ "${count}" != "unknown" ] && rds_db_clusters=$((rds_db_clusters + count))

  count=$(aws_count rds describe-db-instances 'DBInstances')
  echo_count "AWS::RDS::DBInstance" "${count}"
  [ "${count}" != "unknown" ] && rds_db_instances=$((rds_db_instances + count))

  count=$(aws_count dynamodb list-tables 'TableNames')
  echo_count "AWS::DynamoDB::Table" "${count}"
  [ "${count}" != "unknown" ] && dynamo_db_tables=$((dynamo_db_tables + count))

  count=$(aws_count docdb describe-db-clusters 'DBClusters')
  echo_count "AWS::DocumentDB::DBCluster" "${count}"
  [ "${count}" != "unknown" ] && docdb_clusters=$((docdb_clusters + count))

  count=$(aws_count redshift describe-clusters 'Clusters')
  echo_count "AWS::Redshift::Cluster" "${count}"
  [ "${count}" != "unknown" ] && redshift_clusters=$((redshift_clusters + count))

  count=$(aws_count eks list-clusters 'clusters')
  echo_count "AWS::EKS::Cluster" "${count}"
  [ "${count}" != "unknown" ] && eks_clusters=$((eks_clusters + count))

  count=$(aws_count ec2 describe-vpcs 'Vpcs')
  echo_count "AWS::EC2::VPC" "${count}"
  [ "${count}" != "unknown" ] && vpcs=$((vpcs + count))

  count=$(aws_count lambda list-functions 'Functions')
  echo_count "AWS::Lambda::Function" "${count}"
  [ "${count}" != "unknown" ] && lambda_functions=$((lambda_functions + count))

  count=$(aws_count elbv2 describe-load-balancers 'LoadBalancers')
  echo_count "AWS::ELBv2::LoadBalancer" "${count}"
  [ "${count}" != "unknown" ] && elbv2_load_balancers=$((elbv2_load_balancers + count))

  count=$(aws_count elb describe-load-balancers 'LoadBalancerDescriptions')
  echo_count "AWS::ELB::LoadBalancer" "${count}"
  [ "${count}" != "unknown" ] && elb_load_balancers=$((elb_load_balancers + count))

  count=$(aws_count ec2 describe-instances 'Reservations[*].Instances')
  echo_count "AWS::EC2::Instance" "${count}"
  [ "${count}" != "unknown" ] && ec2_instances=$((ec2_instances + count))

  count=$(aws_count wafv2 list-web-acls 'WebACLs' --scope REGIONAL)
  echo_count "AWS::WAFv2::WebACL/Regional" "${count}"
  [ "${count}" != "unknown" ] && wafs=$((wafs + count))

  if [ "${REGION}" = "us-east-1" ]; then
    count=$(aws_count wafv2 list-web-acls 'WebACLs' --scope CLOUDFRONT)
    echo_count "AWS::WAFv2::WebACL/CloudFront" "${count}"
    [ "${count}" != "unknown" ] && cloudfront=$((cloudfront + count))

    count=$(aws_count s3api list-buckets 'Buckets')
    echo_count "AWS::S3::Bucket" "${count}"
    [ "${count}" != "unknown" ] && s3_buckets=$((s3_buckets + count))
  fi
}

FALLBACK_ALL_REGIONS="ap-south-2 ap-south-1 eu-south-1 eu-south-2 me-central-1 ca-central-1 eu-central-1 eu-central-2 us-west-1 us-west-2 af-south-1 eu-north-1 eu-west-3 eu-west-2 eu-west-1 ap-northeast-3 ap-northeast-2 me-south-1 ap-northeast-1 sa-east-1 ap-east-1 ap-southeast-1 ap-southeast-2 ap-southeast-3 ap-southeast-4 us-east-1 us-east-2"

scan_single_account() {
  local account_id=$(_aws --region us-east-1 sts get-caller-identity --query "Account" --output text)

  if [ -z "${account_id}" ]; then
    echo "Error getting account ID" >&2
    exit 1
  fi

  echo "[+] Scanning account $account_id"

  local regions=$(_aws ec2 describe-regions --query "Regions[].RegionName" --output text 2>/dev/null || echo "${FALLBACK_ALL_REGIONS}")

  rds_db_clusters=0
  rds_db_instances=0
  dynamo_db_tables=0
  docdb_clusters=0
  redshift_clusters=0
  eks_clusters=0
  vpcs=0
  lambda_functions=0
  elbv2_load_balancers=0
  elb_load_balancers=0
  ec2_instances=0
  wafs=0
  cloudfront=0
  s3_buckets=0

  for region in $regions; do
    scan_account_region "${region}"
  done

  echo "[+] Total Counts"
  echo "     * AWS::RDS::DBClusters: ${rds_db_clusters}"
  echo "     * AWS::RDS::DBInstance: ${rds_db_instances}"
  echo "     * AWS::DynamoDB::Table: ${dynamo_db_tables}"
  echo "     * AWS::DocumentDB::DBCluster: ${docdb_clusters}"
  echo "     * AWS::Redshift::Cluster: ${redshift_clusters}"
  echo "     * AWS::EKS::Cluster: ${eks_clusters}"
  echo "     * AWS::EC2::VPC: ${vpcs}"
  echo "     * AWS::Lambda::Function: ${lambda_functions}"
  echo "     * AWS::ELBv2::LoadBalancer: ${elbv2_load_balancers}"
  echo "     * AWS::ELB::LoadBalancer: ${elb_load_balancers}"
  echo "     * AWS::EC2::Instance: ${ec2_instances}"
  echo "     * AWS::WAFv2::WebACL/Regional: ${wafs}"
  echo "     * AWS::WAFv2::WebACL/CloudFront: ${cloudfront}"
  echo "     * AWS::S3::Bucket: ${s3_buckets}"
}

scan_single_account
