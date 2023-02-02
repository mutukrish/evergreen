

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

_check_evergreen() {
    eval $(parse_yaml ~/.evergreen.yml)
    if [ "$user" = "" ]; then
      echo "Everygreen file is not configured";
      echo "Please follow the instructions in https://spruce.mongodb.com/preferences/cli";  
      exit 1;
    fi
    _setup_host
}

_setup_volume () {
    eval $(parse_yaml config.yml)
    volume_response=$(evergreen volume create -s $volume_size -t $volume_type -z $volume_zone)
    echo $volume_response
    volume_response=${volume_response#*"'"}; volume_response=${volume_response%"'"*}
    echo $volume_response
}

_setup_host() {
    eval $(parse_yaml config.yml)
    ssh_key=`cat ~/.ssh/$host_key.pub`
    eval $(parse_yaml ~/.evergreen.yml)
    host_response=$(curl -H Api-User:$user -H Api-Key:$api_key -d "{\"distro\":\"$host_distro\",\"keyname\":\"$ssh_key\", \"no_expiration\": true,\"homeVolumeSize\":500, \"region\":\"$host_region\",  \"savePublicKey\":true}"  https://evergreen.mongodb.com/api/rest/v2/hosts)
    echo $host_response
}





setup_evergreen () {
    #_setup_volume
    _check_evergreen
}

setup_evergreen