#!/bin/bash

set -e

echo "Setting up AWS Stack"

awslocal iam create-policy --policy-name app-access --policy-document "$(</etc/localstack/init/ready.d/app-access-policy.json)"
awslocal iam create-role --role-name app-role --assume-role-policy-document "$(</etc/localstack/init/ready.d/app-assume-policy.json)"
awslocal iam create-user --user-name app-static-user

awslocal iam attach-role-policy --role-name app-role --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
awslocal iam attach-user-policy --user-name app-static-user --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

echo "Done configuring aws stack"
