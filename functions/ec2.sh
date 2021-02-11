ec2-host() {
  STATE=${1-running}
  aws ec2 describe-instances \
    --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`].Value,Roles:Tags[?Key==`Roles`].Value,InstanceId:InstanceId,PrivateIpAddress:PrivateIpAddress}' \
    --filter "Name=instance-state-name,Values=$STATE" \
    | jq -c ".[]"
}

ec2-id() {
  STATE=${1-running}
  ec2-host $STATE | peco | jq -r ".InstanceId"
}

ec2-ids() {
  STATE=${1-running}
  for d in $(ec2-host $STATE | peco)
  do
    echo $d | jq -r ".InstanceId"
  done
}

ec2-private-ip() {
  STATE=${1-running}
  ec2-host $STATE | peco | jq -r ".PrivateIpAddress"
}

ec2-ssh() {
  SSH_USER=${1-$USER}
  ssh -o 'StrictHostKeyChecking no' ${SSH_USER}@$(ec2-private-ip)
}

ec2-terminate() {
  for INSTANCE_ID in $(ec2-ids)
  do
    read -p "terminate? $(ec2-tag Name $INSTANCE_ID) (y/N): " yn
    if [[ $yn != [yY] ]]; then
      echo cancel
      continue
    fi

    SPOT_INSTANCE_REQUEST_ID=$(
      aws ec2 describe-spot-instance-requests \
        --filters Name=instance-id,Values=$INSTANCE_ID \
        | jq -r ".SpotInstanceRequests[].SpotInstanceRequestId"
    )
    if [ -n "$SPOT_INSTANCE_REQUEST_ID" ]; then
      aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $SPOT_INSTANCE_REQUEST_ID
    fi
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID
  done
}

ami-list() {
  aws ec2 describe-images \
    --owners self \
    --query 'Images[].{Name:Name,ImageId:ImageId,State:State}' \
    | jq -c ".[]"
}

ami-id() {
  ami-list | peco | jq -r ".ImageId"
}

# tag
ec2-tag() {
  TAG_NAME=$1
  INSTANCE_ID=$2
  aws ec2 describe-tags \
    --filters "Name=resource-id,Values=$INSTANCE_ID" \
    "Name=key,Values=$TAG_NAME" \
    | jq -r ".Tags[].Value"
}

# spot price
ec2-spot-prices() {
  if [ $# -le 0 ]; then
    echo not INSTANCE_TYPE parameter.
    return
  else
    INSTANCE_TYPE=$1
  fi
  aws ec2 describe-spot-price-history \
    --instance-types $INSTANCE_TYPE \
    --product-description 'Linux/UNIX (Amazon VPC)' \
    --start-time "$(date --iso-8601=seconds)" \
    | jq ".SpotPriceHistory | sort_by(.SpotPrice)"
}

ec2-spot-lowest-zone() {
  ec2-spot-prices $1 | jq -r ".[0].AvailabilityZone"
}

ec2-spot-lowest-private-subnet() {
  AZ=$(ec2-spot-lowest-zone $1)
  aws ec2 describe-subnets \
    --filters Name=tag:Name,Values='*private*' Name=availability-zone,Values=$AZ \
    | jq -r ".Subnets[0].SubnetId"
}
