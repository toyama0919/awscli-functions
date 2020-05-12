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

ec2-stop() {
  for INSTANCE_ID in $(ec2-ids)
  do
    aws ec2 stop-instances --instance-ids $INSTANCE_ID
  done
}

ec2-start() {
  for INSTANCE_ID in $(ec2-ids stopped)
  do
    aws ec2 start-instances --instance-ids $INSTANCE_ID
  done
}

ami-list() {
  aws ec2 describe-images \
    --owners $(aws-current-account-id) \
    --query 'Images[].{Name:Name,ImageId:ImageId,State:State}' \
    | jq -c ".[]"
}

ami-id() {
  ami-list | peco | jq -r ".ImageId"
}
