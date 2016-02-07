# ecs-consul-agent

[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://registry.hub.docker.com/u/obatech/ecs-consul-agent/)

Wrapper around `gliderlabs/consul-agent` to make it easier to deploy to ECS hosts.

* Gets `PRIVATE_IP`, `REGION`,  address from EC2 meta-data.
* Joins to Consul Server via Hashicorp's Atlas if `ATLAS_INFRASTRUCTURE` AND `ATLAS_TOKEN` passed.
Otherwise join via `SERVER_IP`.

This typically goes hand-in-hand with `registrator`.

## Usage

    $ docker pull obatech/ec2-consul-agent:latest

## Example ECS Task Definition with Terraform (Template)

This file is a [Terraform Template](https://www.terraform.io/docs/providers/template/). `${atlas_token}` and `${atlas_infrastructure}` are passed in and the rendered version is used.

### task-definition.json.tpl

    {
        "name": "consul",
        "image": "obatech/ecs-consul-agent:latest",
        "cpu": 20,
        "memory": 80,
        "essential": true,
        "portMappings": [
          {
            "hostPort": 8301,
            "containerPort": 8301,
            "protocol": "tcp"
          },
          {
            "hostPort": 8301,
            "containerPort": 8301,
            "protocol": "udp"
          },
          {
            "hostPort": 8400,
            "containerPort": 8400,
            "protocol": "tcp"
          },
          {
            "hostPort": 8500,
            "containerPort": 8500,
            "protocol": "tcp"
          },
          {
            "hostPort": 53,
            "containerPort": 53,
            "protocol": "udp"
          }
        ],
        "mountPoints": [
          {
            "containerPath": "/var/run/docker.sock",
            "sourceVolume": "docker_socket",
            "readOnly": false
          },
          {
            "containerPath": "/data",
            "sourceVolume": "opt_consul",
            "readOnly": false
          },
          {
            "containerPath": "/etc/consul",
            "sourceVolume": "etc_consul",
            "readOnly": false
          }
        ],
        "environment": [
          {
            "name": "ATLAS_INFRASTRUCTURE",
            "value": "${atlas_infrastructure}"
          },
          {
            "name": "ATLAS_TOKEN",
            "value": "${atlas_token}"
          }
        ]
    }

You'll want to include this in your Task Definition for your ECS Service e.g. Django/Rails app.
Be sure to `link` them by using the `links` key:value in the Task Definitionm for example:

    "links": [
      "consul"
    ],

### Terraform resource

    resource "template_file" "app_task_definition_template" {
      template               = "${path.module}/task-definitions/${var.app_task_definition_template_file}"

      lifecycle              { create_before_destroy = true }

      vars {
        atlas_infrastructure = "${var.atlas_infrastructure}"
        atlas_token          = "${var.atlas_token}"
      }
    }

    # Using in an ECS resource

    resource "aws_ecs_task_definition" "app_task_definition" {
        family                = "${var.cluster_name}"
        container_definitions = "${template_file.app_task_definition_template.rendered}"

        ...
    }

