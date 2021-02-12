# script

## import function(global)

```bash
sudo -E -H bash -c "git clone https://github.com/toyama0919/awscli-functions.git /opt/awscli-functions" && \
source /opt/awscli-functions/import.sh
```

## update function(global)

```bash
sudo -E -H bash -c "cd /opt/awscli-functions && git pull origin --rebase" && \
source /opt/awscli-functions/import.sh
```

## register profile

```bash
cat << 'EOS' >> ~/.bash_profile
source /opt/awscli-functions/import.sh
EOS
```
