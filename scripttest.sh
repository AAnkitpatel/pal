#!/bin/bash

[[ -z $1 ]] && echo "[#] ERROR: A tenant MUST be provided as parameter" && exit 1
IFS=','
echo "TENANT, NAMESPACE, TOPIC, SUBSCRIPTION, CONSUMER NAME, ADDRESS, HOSTS, IP , FQDN, REGION" > $CSV_NAME

TENANT=$1
PULSAR_ADMIN_PATH="/home/ybisht/apache-pulsar-2.11.0/bin"

echo "[#] Login: Kindly provide valid ComodIT MFA Token:"
read mfa
[[ -z $mfa ]] && echo "[#] ERROR: Can't Authenticate without ComodIT MFA Token" && exit 1



CSV_NAME="pulsar-consumers_$TENANT.csv"

NAMESPACES=$(${PULSAR_ADMIN_PATH}/pulsar-admin namespaces list ${TENANT})

for NAMESPACE in ${NAMESPACES[@]}; do
    TOPICS=$(${PULSAR_ADMIN_PATH}/pulsar-admin topics list ${NAMESPACE})

    for TOPIC in ${TOPICS[@]}; do
        SUBSCRIPTIONS=$(${PULSAR_ADMIN_PATH}/pulsar-admin topics subscriptions ${TOPIC})
        TOPIC_STATS=$(${PULSAR_ADMIN_PATH}/pulsar-admin topics stats ${TOPIC})

        for SUBSCRIPTION in ${SUBSCRIPTIONS[@]}; do
            #echo -e "\n[#] Getting consumer in ${TOPIC} ${SUBSCRIPTION}"

            CONSUMERS=$(echo ${TOPIC_STATS} | jq '.subscriptions[].consumers[]')
            C_NAME=($(echo  "${CONSUMERS}" | jq  .consumerName))
            C_ADD=($(echo "${CONSUMERS}" | jq .address | tr -d '/' | sed 's/"//g' | cut -d ":" -f1))
        for regions in $(comodit organizations show Proxyclick-QA --mfa ${mfa} --raw | jq .environments | tr -d '['| tr -d ']' | tr -d '\n')
        do
        Environments=$(echo $regions | sed 's/^ *//g' | sed 's/ *$//g' | tr -d '"')

        for hosts in $(comodit environments show Proxyclick-QA ${Environments} --raw| jq .hosts | tr -d '\n'| tr -d '['| tr -d ']')
        do
                if [[ $hosts != *"Builder"* ]]
                then
                        HostName=$(echo $hosts | tr -d '"' | sed 's/^ *//g' | sed 's/ *$//g')

                        IP=$(comodit hosts instance show Proxyclick-QA ${Environments} ${HostName} --raw| jq .hostData.ip.external | tr -d '"')
                        fqdn=$(comodit hosts instance show Proxyclick-QA ${Environments} ${HostName} --raw| jq .hostData.hostname | tr -d '"')


                        echo "$HostName,$IP,$fqdn,$Environments" #>> ptr_resolver.csv
                fi
        done
done
            for ((i=0; i< ${#C_NAME[@]}; i++));  do

                    LINE="$TENANT, $NAMESPACE, $TOPIC, $SUBSCRIPTION, ${C_NAME[$i]}, ${C_ADD[$i]}"
                    #echo $LINE | tr -d '"' >> $CSV_NAME
                    #echo $C_ADD

            done
        done
    done
done

# ###########################################################################################

# for regions in $(comodit organizations show Proxyclick-QA --mfa ${mfa} --raw | jq .environments | tr -d '['| tr -d ']' | tr -d '\n')
# do
#         Environments=$(echo $regions | sed 's/^ *//g' | sed 's/ *$//g' | tr -d '"')

#         for hosts in $(comodit environments show Proxyclick-QA ${Environments} --raw| jq .hosts | tr -d '\n'| tr -d '['| tr -d ']')
#         do
#                 if [[ $hosts != *"Builder"* ]]
#                 then
#                         HostName=$(echo $hosts | tr -d '"' | sed 's/^ *//g' | sed 's/ *$//g')

#                         IP=$(comodit hosts instance show Proxyclick-QA ${Environments} ${HostName} --raw| jq .hostData.ip.external | tr -d '"')
#                         fqdn=$(comodit hosts instance show Proxyclick-QA ${Environments} ${HostName} --raw| jq .hostData.hostname | tr -d '"')


#                         # echo "$HostName,$IP,$fqdn,$Environments" #>> ptr_resolver.csv
#                 fi
#         done
# done
