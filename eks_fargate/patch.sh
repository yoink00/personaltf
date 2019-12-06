#!/bin/sh

kubectl patch deployment coredns -n kube-system -p '{ "spec": { "template": { "metadata": { "annotations": {"$patch": "delete", "eks.amazonaws.com/compute-type": "ec2"}}}}}'
