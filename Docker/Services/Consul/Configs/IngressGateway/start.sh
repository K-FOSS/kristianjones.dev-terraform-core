#!/bin/sh

case ${NODE_HOST} in
     "node1.vps1.kristianjones.dev" )
           ARGS="-proxy-id node1vps1"
           echo "Node1 ${ARGS}"
           ;;
     "node2.vps1.kristianjones.dev" )
           ARGS="-proxy-id node2vps1"
           echo "Node2 ${ARGS}"
           ;;
     "node3.vps1.kristianjones.dev" )
           ARGS="-proxy-id node3vps1"
           echo "Node3 ${ARGS}"
           ;;
     * )
           echo "Error is not possible"
           ;;
esac

/entrypoint.sh consul connect envoy -gateway=ingress -address '{{ GetInterfaceIP "eth1" }}:8888' -register ${ARGS} -service=${SERVICE_NAME} -token=${CONSUL_HTTP_TOKEN}