#!/bin/bash
set -ex

test_scratch_device=/dev/nvme0n1
if [ $# -ge 1 ] ; then
  test_scratch_device=$1
fi

lsblk

if [ ! -b "${test_scratch_device}" ] ; then
  echo "invalid scratch device, not a block device: ${test_scratch_device}" >&2
  exit 1
fi

sudo rm -rf /var/lib/rook/rook-integration-test
sudo mkdir -p /var/lib/rook/rook-integration-test/mon1 /var/lib/rook/rook-integration-test/mon2 /var/lib/rook/rook-integration-test/mon3

node_name=$(kubectl get nodes -o jsonpath={.items[*].metadata.name})

kubectl label nodes ${node_name} rook.io/has-disk=true

kubectl delete pv -l type=local

cat <<eof | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-vol1
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  local:
    path: "/var/lib/rook/rook-integration-test/mon1"
  nodeAffinity:
      required:
        nodeSelectorTerms:
          - matchExpressions:
              - key: rook.io/has-disk
                operator: In
                values:
                - "true"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-vol2
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  local:
    path: "/var/lib/rook/rook-integration-test/mon2"
  nodeAffinity:
      required:
        nodeSelectorTerms:
          - matchExpressions:
              - key: rook.io/has-disk
                operator: In
                values:
                - "true"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-vol3
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  local:
    path: "/var/lib/rook/rook-integration-test/mon3"
  nodeAffinity:
      required:
        nodeSelectorTerms:
          - matchExpressions:
              - key: rook.io/has-disk
                operator: In
                values:
                - "true"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-vol4
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Block
  local:
    path: "${test_scratch_device}"
  nodeAffinity:
      required:
        nodeSelectorTerms:
          - matchExpressions:
              - key: rook.io/has-disk
                operator: In
                values:
                - "true"
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: manual
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
eof
