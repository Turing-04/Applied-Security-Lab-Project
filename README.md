
<p align="center">
  <img src="/webserver/app/static/images/imovies_logo.png" alt="iMovies Logo" width="250" style="margin-bottom:0;"/>
</p>

# Applied-Security-Lab-Project 

## Introduction

This project develops a secure Certificate Authority (CA) system using Public Key Infrastructure (PKI) for iMovies. It aims to ensure secure communication within the company and with external informants

## Overview

We simulated the company's infrstructure through the use of VMs. The system is composed of `6` main components - a [central firewall](./firewall/) for routing and enforcing network security, a [Web server](./webserver/) that provides the user interface, a [certificate authority server](./CA-server/) that issues/revokes certificates, a [SQL server](./mysql_server/) for data storage and a [server for centralized backups and logging](./backup-server/). Finally there's a [user-gui](./user-gui/) VM designed for testing purposes, simulating a machine on the internet which can use iMovie's services. 

We also left two hidden intentional backdoors (a fairly easy one and a tougher one) to be found by another team. We also performed some pentest on another team's system to find their backdoors and other vulnerabilities. 


## Assignment and System Description

The [assignment](./assignment.pdf) of the project gives more detailed information about the required task, there's also some detailed information about this system and the security measures in place in our [System description report](./System_description_and_risk_analysis.pdf). 

## Review and pentesting of another team's system

The Red team report of the reviewed team is available [here](./review/group09-review-of-group-07.pdf) and the presentation we did about there system, including some of the fun backdoors we exploited can be found [here](./review/group09-review-of-group-07-slides.pdf).

## Deployment


To deploy the system, begin by setting up the virtual machines (VMs) using Vagrant. Run the `vagrantfile` in each component's directory to install the respective VMs. Once the VMs are ready, you can proceed with the deployment process. 
Detailed instructions for deploying the system from the `.ova` files are provided in [reviewers.md](./reviewers.md). This guide will walk you through the necessary steps to ensure a smooth and successful deployment of the system.

### Security notice

Some secrets were left in the repository (such as API keys) to facilitate local testing. DO NOT use these in any production environment. 